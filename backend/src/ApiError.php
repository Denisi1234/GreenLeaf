<?php
declare(strict_types=1);

final class ApiError extends RuntimeException
{
    public function __construct(public readonly int $status, string $message)
    {
        parent::__construct($message);
    }
}

final class ApiValidator
{
    public static function text(array $body, string $key): string
    {
        $value = $body[$key] ?? '';
        if (!is_string($value) || trim($value) === '' || strlen($value) > 200) {
            throw new ApiError(422, 'Enter a valid ' . str_replace('_', ' ', $key) . '.');
        }
        return trim($value);
    }

    public static function cents(mixed $value): int
    {
        if (!is_numeric($value) || !is_finite((float) $value) || (float) $value < 0 || (float) $value > 100000000000) {
            throw new ApiError(422, 'Invalid monetary amount.');
        }
        return (int) round((float) $value * 100);
    }

    public static function formatTanzanianPhone(string $rawPhone): string
    {
        $digits = preg_replace('/\D+/', '', $rawPhone) ?? '';
        if (str_starts_with($digits, '0')) {
            $digits = '255' . substr($digits, 1);
        } elseif (strlen($digits) === 9) {
            $digits = '255' . $digits;
        }
        if (strlen($digits) < 10 || strlen($digits) > 15) {
            throw new ApiError(422, 'Enter a valid phone number (e.g., 0712345678 or 255712345678).');
        }
        return $digits;
    }

    public static function normalizeQuantity(float $value): int|float
    {
        $rounded = round($value, 3);
        if (abs($rounded) < 0.0005) {
            return 0;
        }
        $whole = (int) round($rounded);
        return abs($rounded - $whole) < 0.0005 ? $whole : $rounded;
    }

    public static function stockState(int|float $stock): string
    {
        return $stock <= 0 ? 'outOfStock' : ($stock <= 10 ? 'lowStock' : 'inStock');
    }
}
