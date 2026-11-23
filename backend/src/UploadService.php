<?php
declare(strict_types=1);

final class UploadService
{
    private const MAX_BYTES = 2097152;
    private const MAX_ENCODED_BYTES = 4194304;

    public function __construct(private Database $db)
    {
    }

    public function upload(string $storeId, array $body): array
    {
        $encoded = (string) ($body['content'] ?? '');
        if ($encoded === '' || strlen($encoded) > self::MAX_ENCODED_BYTES) {
            throw new ApiError(422, 'Upload a JPEG, PNG, or WebP image up to 2 MB and 24 megapixels.');
        }
        $content = base64_decode($encoded, true);
        $info = $content === false ? false : @getimagesizefromstring($content);
        if (
            $info === false ||
            strlen($content) > self::MAX_BYTES ||
            !in_array($info['mime'], ['image/jpeg', 'image/png', 'image/webp'], true) ||
            $info[0] * $info[1] > 24000000
        ) {
            throw new ApiError(422, 'Upload a JPEG, PNG, or WebP image up to 2 MB and 24 megapixels.');
        }

        $id = hash('sha256', $storeId . $content);
        // Idempotent write so a retried or concurrent upload never fails the sync.
        $insert = $this->db->isMysql() ? 'INSERT IGNORE' : 'INSERT OR IGNORE';
        $this->db->execute(
            "$insert INTO uploads (id, store_id, mime, content) VALUES (?, ?, ?, ?)",
            [$id, $storeId, $info['mime'], base64_encode($content)]
        );
        return ['data' => ['id' => $id, 'path' => 'uploads/' . $id]];
    }

    /**
     * Reads an image that belongs to any store the signed-in user can access.
     *
     * @param list<string> $storeIds Accessible stores, including branch stores.
     */
    public function get(array $storeIds, string $id): array
    {
        if ($storeIds === [] || preg_match('/\A[a-f0-9]{64}\z/', $id) !== 1) {
            throw new ApiError(404, 'Image not found.');
        }
        $placeholders = implode(', ', array_fill(0, count($storeIds), '?'));
        $rows = $this->db->rows(
            "SELECT mime, content FROM uploads WHERE id = ? AND store_id IN ($placeholders)",
            [$id, ...array_values($storeIds)]
        );
        if ($rows === []) {
            throw new ApiError(404, 'Image not found.');
        }
        return ['image' => $rows[0]['content'], 'mime' => $rows[0]['mime']];
    }
}
