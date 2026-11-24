<?php
declare(strict_types=1);

foreach (is_file(__DIR__ . '/.env') ? file(__DIR__ . '/.env', FILE_IGNORE_NEW_LINES) : [] as $line) {
    $line = trim($line);
    if ($line === '' || str_starts_with($line, '#') || !str_contains($line, '=')) {
        continue;
    }
    [$key, $value] = explode('=', $line, 2);
    if (getenv(trim($key)) === false) {
        putenv(trim($key) . '=' . trim($value, " \t\n\r\0\x0B\"'"));
    }
}

return [
    'dsn' => (getenv('DB_DSN') && !str_contains((string)getenv('DB_DSN'), 'alheqffk_')) ? getenv('DB_DSN') : 'sqlite:' . __DIR__ . '/storage/trackmauzo.sqlite',
    'user' => getenv('DB_USER') ?: '',
    'password' => getenv('DB_PASSWORD') ?: '',
    'origins' => array_map('trim', array_filter(explode(',', getenv('ALLOWED_ORIGINS') ?: 'http://localhost:53000,http://127.0.0.1:53000'))),
    'registration' => (getenv('ALLOW_REGISTRATION') ?: 'true') === 'true',
    'token_hours' => 12,
    'security' => [
        'force_https' => (getenv('FORCE_HTTPS') ?: 'false') === 'true',
        'trust_proxy' => (getenv('TRUST_PROXY') ?: 'false') === 'true',
        'hsts_max_age' => (int) (getenv('HSTS_MAX_AGE') ?: 31536000),
    ],
    'sms' => [
        'username' => getenv('NEXTSMS_USERNAME') ?: '',
        'password' => getenv('NEXTSMS_PASSWORD') ?: '',
        'sender_id' => getenv('NEXTSMS_SENDER_ID') ?: 'POS',
        'email' => getenv('NEXTSMS_EMAIL') ?: '',
        'endpoint' => getenv('NEXTSMS_ENDPOINT') ?: 'https://messaging-service.co.tz/api/sms/v1/text/single',
    ],
];
