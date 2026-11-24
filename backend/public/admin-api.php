<?php

declare(strict_types=1);

require_once __DIR__ . '/../src/Database.php';

header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');
header('Cache-Control: no-store, no-cache, must-revalidate');

$config = require __DIR__ . '/../config.php';
$db = new Database($config['db']);

$adminUser = (string) (getenv('ADMIN_PORTAL_USER') ?: ($config['admin_user'] ?? 'admin'));
$adminPass = (string) (getenv('ADMIN_PORTAL_PASS') ?: ($config['admin_pass'] ?? 'TrackMauzo@2026'));
$secret = (string) (getenv('ADMIN_PORTAL_SECRET') ?: ($config['admin_secret'] ?? hash('sha256', __DIR__ . $adminPass)));

function jsonResponse(int $status, array $payload): void
{
    http_response_code($status);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function makeAdminToken(string $user, string $secret): string
{
    $exp = time() + 86400; // 24 hours
    $payload = base64_encode(json_encode(['u' => $user, 'exp' => $exp]));
    $sig = hash_hmac('sha256', $payload, $secret);
    return $payload . '.' . $sig;
}

function verifyAdminToken(string $token, string $secret): bool
{
    $parts = explode('.', $token, 2);
    if (count($parts) !== 2) {
        return false;
    }
    [$payload, $sig] = $parts;
    $expected = hash_hmac('sha256', $payload, $secret);
    if (!hash_equals($expected, $sig)) {
        return false;
    }
    $data = json_decode(base64_decode($payload, true) ?: '', true);
    return is_array($data) && ($data['exp'] ?? 0) > time();
}

$action = (string) ($_GET['action'] ?? '');
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

if ($method === 'POST' && $action === 'login') {
    $raw = file_get_contents('php://input');
    $body = json_decode($raw ?: '{}', true);
    $user = trim((string) ($body['username'] ?? ''));
    $pass = (string) ($body['password'] ?? '');

    if (!hash_equals($adminUser, $user) || !hash_equals($adminPass, $pass)) {
        jsonResponse(401, ['error' => 'Invalid admin username or password.']);
    }

    jsonResponse(200, [
        'token' => makeAdminToken($user, $secret),
        'username' => $user,
    ]);
}

// All other endpoints require Bearer token
$authHeader = (string) ($_SERVER['HTTP_AUTHORIZATION'] ?? '');
$token = str_starts_with($authHeader, 'Bearer ') ? substr($authHeader, 7) : '';
if ($token === '' || !verifyAdminToken($token, $secret)) {
    jsonResponse(401, ['error' => 'Unauthorized. Please log in.']);
}

if ($method === 'GET' && $action === 'registrations') {
    $rows = $db->rows(
        'SELECT u.id, u.name, u.email AS phone, u.role, u.active, u.created_at, s.name AS store_name
         FROM users u
         LEFT JOIN stores s ON s.id = u.store_id
         ORDER BY u.created_at DESC
         LIMIT 250'
    );

    $totalUsersRow = $db->rows('SELECT COUNT(*) AS cnt FROM users');
    $totalStoresRow = $db->rows('SELECT COUNT(*) AS cnt FROM stores');
    $todayPrefix = gmdate('Y-m-d');
    $todayCount = 0;
    foreach ($rows as $r) {
        if (str_starts_with((string) ($r['created_at'] ?? ''), $todayPrefix)) {
            $todayCount++;
        }
    }

    jsonResponse(200, [
        'server_time' => gmdate('c'),
        'stats' => [
            'total_users' => (int) ($totalUsersRow[0]['cnt'] ?? count($rows)),
            'total_stores' => (int) ($totalStoresRow[0]['cnt'] ?? 0),
            'today_registrations' => $todayCount,
        ],
        'registrations' => $rows,
    ]);
}

jsonResponse(404, ['error' => 'Unknown action.']);
