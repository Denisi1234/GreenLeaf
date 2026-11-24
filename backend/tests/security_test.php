<?php

declare(strict_types=1);

require_once __DIR__ . '/../src/Security.php';

$checks = 0;

function check(bool $condition, string $message): void
{
    global $checks;
    $checks++;
    if (!$condition) {
        fwrite(STDERR, "[security] {$message}\n");
        exit(1);
    }
}

check(Security::isHttps(['HTTPS' => 'on']), 'Detects HTTPS from the server flag.');
check(Security::isHttps(['HTTPS' => '1']), 'Detects HTTPS when the flag is 1.');
check(!Security::isHttps(['HTTPS' => 'off']), 'Treats HTTPS=off as plain HTTP.');
check(!Security::isHttps(['HTTPS' => '0']), 'Treats HTTPS=0 as plain HTTP.');
check(!Security::isHttps([]), 'Treats a missing flag as plain HTTP.');
check(!Security::isHttps(['HTTP_X_FORWARDED_PROTO' => 'https']), 'Ignores forwarded proto unless trusted.');
check(Security::isHttps(['HTTP_X_FORWARDED_PROTO' => 'https'], true), 'Trusts a forwarded HTTPS proto.');
check(Security::isHttps(['HTTP_X_FORWARDED_PROTO' => 'https, http'], true), 'Uses the first forwarded proto.');
check(!Security::isHttps(['HTTP_X_FORWARDED_PROTO' => 'http'], true), 'Rejects a forwarded HTTP proto.');

check(Security::requiresHttps(true, false), 'Requires HTTPS when forced over plain HTTP.');
check(!Security::requiresHttps(true, true), 'Allows HTTPS when forced.');
check(!Security::requiresHttps(false, false), 'Allows plain HTTP when not forced.');

$plain = Security::headers(false);
check($plain['X-Content-Type-Options'] === 'nosniff', 'Sends nosniff.');
check($plain['X-Frame-Options'] === 'DENY', 'Sends frame denial.');
check($plain['Referrer-Policy'] === 'no-referrer', 'Sends a referrer policy.');
check(str_contains($plain['Content-Security-Policy'], "frame-ancestors 'none'"), 'Sends a restrictive CSP.');
check($plain['Cache-Control'] === 'no-store', 'Disables caching.');
check(array_key_exists('Permissions-Policy', $plain), 'Sends a permissions policy.');
check(!array_key_exists('Strict-Transport-Security', $plain), 'Omits HSTS over plain HTTP.');

$secure = Security::headers(true);
check(isset($secure['Strict-Transport-Security']), 'Sends HSTS over HTTPS.');
check($secure['Strict-Transport-Security'] === 'max-age=31536000; includeSubDomains', 'Uses the default HSTS policy.');
check(Security::headers(true, 600)['Strict-Transport-Security'] === 'max-age=600; includeSubDomains', 'Honours a custom HSTS age.');
check(!array_key_exists('Strict-Transport-Security', Security::headers(true, 0)), 'Allows disabling HSTS with a zero age.');

echo "{$checks} security checks passed.\n";
