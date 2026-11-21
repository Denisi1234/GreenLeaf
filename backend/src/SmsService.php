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

        if ($username === '' || $password === '') {
            return false;
        }

        $payload = json_encode([
            'from' => $senderId,
            'to' => $phone,
            'text' => $message,
        ], JSON_THROW_ON_ERROR);

        $authHeader = 'Basic ' . base64_encode($username . ':' . $password);

        $ch = curl_init($endpoint);
        curl_setopt_array($ch, [
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => $payload,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 12,
            CURLOPT_SSL_VERIFYPEER => false,
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
}
