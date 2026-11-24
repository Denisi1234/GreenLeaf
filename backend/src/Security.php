<?php

declare(strict_types=1);

final class Security
{
    public static function isHttps(array $server, bool $trustProxy = false): bool
    {
        if ($trustProxy) {
            $forwarded = (string) ($server['HTTP_X_FORWARDED_PROTO'] ?? '');
            $proto = strtolower(trim(explode(',', $forwarded)[0]));
            if ($proto === 'https') {
                return true;
            }
        }
        $https = strtolower(trim((string) ($server['HTTPS'] ?? '')));
        return $https !== '' && $https !== 'off' && $https !== '0';
    }

    public static function requiresHttps(bool $forceHttps, bool $https): bool
    {
        return $forceHttps && !$https;
    }

    /**
     * @return array<string, string>
     */
    public static function headers(bool $https, int $hstsMaxAge = 31536000): array
    {
        $headers = [
            'Cache-Control' => 'no-store',
            'X-Content-Type-Options' => 'nosniff',
            'X-Frame-Options' => 'DENY',
            'Referrer-Policy' => 'no-referrer',
            'Content-Security-Policy' => "default-src 'none'; frame-ancestors 'none'; base-uri 'none'",
            'Permissions-Policy' => 'camera=(), microphone=(), geolocation=()',
        ];
        if ($https && $hstsMaxAge > 0) {
            $headers['Strict-Transport-Security'] = 'max-age=' . $hstsMaxAge . '; includeSubDomains';
        }
        return $headers;
    }

    /**
     * @param array<string, string> $headers
     */
    public static function apply(array $headers): void
    {
        foreach ($headers as $name => $value) {
            header($name . ': ' . $value);
        }
    }
}
