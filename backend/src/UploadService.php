<?php
declare(strict_types=1);

final class UploadService
{
    public function __construct(private Database $db)
    {
    }

    public function upload(string $storeId, array $body): array
    {
        $content = base64_decode((string) ($body['content'] ?? ''), true);
        $info = $content === false ? false : @getimagesizefromstring($content);
        if (
            $info === false ||
            strlen($content) > 2097152 ||
            !in_array($info['mime'], ['image/jpeg', 'image/png', 'image/webp'], true) ||
            $info[0] * $info[1] > 24000000
        ) {
            throw new ApiError(422, 'Upload a JPEG, PNG, or WebP image up to 2 MB and 24 megapixels.');
        }

        $id = hash('sha256', $storeId . $content);
        if ($this->db->rows('SELECT id FROM uploads WHERE id = ?', [$id]) === []) {
            $this->db->execute(
                'INSERT INTO uploads VALUES (?, ?, ?, ?)',
                [$id, $storeId, $info['mime'], base64_encode($content)]
            );
        }
        return ['data' => ['id' => $id]];
    }

    public function get(string $storeId, string $id): array
    {
        $rows = $this->db->rows(
            'SELECT mime, content FROM uploads WHERE id = ? AND store_id = ?',
            [$id, $storeId]
        );
        if ($rows === []) {
            throw new ApiError(404, 'Image not found.');
        }
        return ['image' => $rows[0]['content'], 'mime' => $rows[0]['mime']];
    }
}
