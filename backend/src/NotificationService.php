<?php
declare(strict_types=1);

final class NotificationService
{
    public function __construct(private Database $db)
    {
    }

    public function registerDeviceToken(array $user, array $body): array
    {
        $token = trim((string) ($body['token'] ?? ''));
        $platform = trim((string) ($body['platform'] ?? 'android'));
        if ($token === '') {
            throw new ApiError(422, 'Device push token is required.');
        }

        $now = gmdate('Y-m-d H:i:s');
        $existing = $this->db->rows('SELECT id FROM device_tokens WHERE token = ?', [$token]);
        if ($existing !== []) {
            $this->db->execute(
                'UPDATE device_tokens SET store_id = ?, user_id = ?, platform = ?, updated_at = ? WHERE token = ?',
                [$user['store_id'], $user['id'] ?? null, $platform, $now, $token]
            );
        } else {
            $this->db->execute(
                'INSERT INTO device_tokens (store_id, user_id, token, platform, updated_at) VALUES (?, ?, ?, ?, ?)',
                [$user['store_id'], $user['id'] ?? null, $token, $platform, $now]
            );
        }

        return ['data' => ['registered' => true, 'platform' => $platform]];
    }

    public function getNotifications(string $storeId): array
    {
        $rows = $this->db->rows(
            'SELECT * FROM push_notifications WHERE store_id = ? ORDER BY id DESC LIMIT 50',
            [$storeId]
        );
        return ['data' => $rows];
    }

    public function dispatchPushNotification(string $storeId, array $body): array
    {
        $title = trim((string) ($body['title'] ?? ''));
        $message = trim((string) ($body['message'] ?? ''));
        $category = trim((string) ($body['category'] ?? 'general'));
        $payload = isset($body['payload'])
            ? (is_string($body['payload']) ? $body['payload'] : json_encode($body['payload']))
            : null;

        if ($title === '' || $message === '') {
            throw new ApiError(422, 'Title and message are required.');
        }

        $now = gmdate('Y-m-d H:i:s');
        $this->db->execute(
            'INSERT INTO push_notifications (store_id, title, message, category, payload, created_at) VALUES (?, ?, ?, ?, ?, ?)',
            [$storeId, $title, $message, $category, $payload, $now]
        );

        $tokens = $this->db->rows(
            'SELECT token, platform FROM device_tokens WHERE store_id = ?',
            [$storeId]
        );

        return [
            'data' => [
                'delivered_to_tokens' => count($tokens),
                'title' => $title,
                'message' => $message,
                'category' => $category,
                'created_at' => $now,
            ],
        ];
    }
}
