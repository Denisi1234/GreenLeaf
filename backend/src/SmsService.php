<?php
declare(strict_types=1);

final class SmsService
{
    public function __construct(private array $config)
    {
    }

    public function send(string $phone, string $message): bool
    {
        $smsConfig = $this->config['sms'] ?? [];
        $username = (string) ($smsConfig['username'] ?? '');
        $password = (string) ($smsConfig['password'] ?? '');
        $senderId = (string) ($smsConfig['sender_id'] ?? 'POS');
        $endpoint = (string) ($smsConfig['endpoint'] ?? 'https://messaging-service.co.tz/api/sms/v1/text/single');

        $normalizedPhone = $this->normalizePhone($phone);
        if ($username === '' || $password === '' || $normalizedPhone === '') {
            return false;
        }

        $payload = json_encode([
            'from' => $senderId,
            'to' => $normalizedPhone,
            'text' => $message,
        ], JSON_THROW_ON_ERROR);

        $authHeader = 'Basic ' . base64_encode($username . ':' . $password);

        $ch = curl_init($endpoint);
        curl_setopt_array($ch, [
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => $payload,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 12,
            CURLOPT_SSL_VERIFYPEER => true,
            CURLOPT_SSL_VERIFYHOST => 2,
            CURLOPT_HTTPHEADER => [
                'Authorization: ' . $authHeader,
                'Content-Type: application/json',
                'Accept: application/json',
            ],
        ]);

        curl_exec($ch);
        $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        return $code >= 200 && $code < 300;
    }

    private function normalizePhone(string $raw): string
    {
        $digits = preg_replace('/\D+/', '', $raw) ?? '';
        if ($digits === '') {
            return '';
        }
        // Convert local Tanzanian format (06xxxxxxxx / 07xxxxxxxx) to 255xxxxxxxxx
        if (strlen($digits) === 10 && str_starts_with($digits, '0')) {
            return '255' . substr($digits, 1);
        }
        return $digits;
    }
}
