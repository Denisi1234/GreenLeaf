<?php

declare(strict_types=1);

require_once __DIR__ . '/../src/Database.php';
require_once __DIR__ . '/../src/ApiError.php';
require_once __DIR__ . '/../src/SmsService.php';

header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');
header('Cache-Control: no-store, no-cache, must-revalidate');

$config = require __DIR__ . '/../config.php';
try {
    $db = new Database($config['db'] ?? $config);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['error' => 'DB error: ' . $e->getMessage()]);
    exit;
}

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
    $exp = time() + 86400;
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

    // Order & revenue summary
    $orderRows = $db->rows("SELECT store_id, payload FROM records WHERE resource = 'orders'");
    $totalOrders = 0;
    $totalRevenue = 0.0;
    foreach ($orderRows as $or) {
        $o = json_decode((string) $or['payload'], true);
        if (!is_array($o) || strtolower((string) ($o['status'] ?? '')) === 'voided') {
            continue;
        }
        $totalOrders++;
        $totalRevenue += (float) ($o['total'] ?? 0);
    }

    jsonResponse(200, [
        'server_time' => gmdate('c'),
        'stats' => [
            'total_users' => (int) ($totalUsersRow[0]['cnt'] ?? count($rows)),
            'total_stores' => (int) ($totalStoresRow[0]['cnt'] ?? 0),
            'today_registrations' => $todayCount,
            'total_orders' => $totalOrders,
            'total_revenue' => round($totalRevenue, 2),
        ],
        'registrations' => $rows,
    ]);
}

if ($method === 'GET' && $action === 'stores') {
    $stores = $db->rows('SELECT id, name, created_at FROM stores ORDER BY created_at DESC LIMIT 200');
    $userCounts = [];
    foreach ($db->rows('SELECT store_id, COUNT(*) AS cnt FROM users GROUP BY store_id') as $uc) {
        $userCounts[(string) $uc['store_id']] = (int) $uc['cnt'];
    }
    $orderStats = [];
    foreach ($db->rows("SELECT store_id, payload FROM records WHERE resource = 'orders'") as $or) {
        $sid = (string) $or['store_id'];
        $o = json_decode((string) $or['payload'], true);
        if (!is_array($o) || strtolower((string) ($o['status'] ?? '')) === 'voided') {
            continue;
        }
        if (!isset($orderStats[$sid])) {
            $orderStats[$sid] = ['orders' => 0, 'revenue' => 0.0];
        }
        $orderStats[$sid]['orders']++;
        $orderStats[$sid]['revenue'] += (float) ($o['total'] ?? 0);
    }

    $result = [];
    foreach ($stores as $s) {
        $sid = (string) $s['id'];
        $result[] = [
            'id' => $sid,
            'name' => $s['name'],
            'created_at' => $s['created_at'],
            'users_count' => $userCounts[$sid] ?? 0,
            'orders_count' => $orderStats[$sid]['orders'] ?? 0,
            'revenue' => round($orderStats[$sid]['revenue'] ?? 0.0, 2),
        ];
    }

    jsonResponse(200, ['stores' => $result]);
}

if ($method === 'GET' && $action === 'orders') {
    $storeNames = [];
    foreach ($db->rows('SELECT id, name FROM stores') as $s) {
        $storeNames[(string) $s['id']] = (string) $s['name'];
    }

    $orderRows = $db->rows("SELECT store_id, record_id, payload, updated_at FROM records WHERE resource = 'orders' ORDER BY updated_at DESC LIMIT 200");
    $orders = [];
    foreach ($orderRows as $or) {
        $o = json_decode((string) $or['payload'], true);
        if (!is_array($o)) {
            continue;
        }
        $orders[] = [
            'id' => $o['id'] ?? $or['record_id'],
            'store_name' => $storeNames[(string) $or['store_id']] ?? $or['store_id'],
            'cashier_name' => $o['cashier_name'] ?? '-',
            'payment_method' => $o['payment_method'] ?? '-',
            'total' => (float) ($o['total'] ?? 0),
            'status' => $o['status'] ?? 'completed',
            'date_time' => $o['date_time'] ?? $or['updated_at'],
        ];
    }

    jsonResponse(200, ['orders' => $orders]);
}

if ($method === 'GET' && $action === 'system') {
    $reportLogs = [];
    try {
        $reportLogs = $db->rows('SELECT store_id, report_date, sent_at FROM daily_report_logs ORDER BY sent_at DESC LIMIT 50');
    } catch (Throwable) {
        $reportLogs = [];
    }

    $activeOtps = 0;
    try {
        $otpRow = $db->rows('SELECT COUNT(*) AS cnt FROM otp_verifications WHERE expires_at > ?', [time()]);
        $activeOtps = (int) ($otpRow[0]['cnt'] ?? 0);
    } catch (Throwable) {
        $activeOtps = 0;
    }

    jsonResponse(200, [
        'server_time' => gmdate('c'),
        'php_version' => PHP_VERSION,
        'active_otps' => $activeOtps,
        'daily_report_logs' => $reportLogs,
    ]);
}

if ($method === 'POST' && $action === 'toggle_user') {
    $raw = file_get_contents('php://input');
    $body = json_decode($raw ?: '{}', true);
    $userId = trim((string) ($body['user_id'] ?? ''));
    $active = (int) ($body['active'] ?? 1) === 1 ? 1 : 0;
    if ($userId === '') {
        jsonResponse(422, ['error' => 'user_id is required.']);
    }
    $db->execute('UPDATE users SET active = ? WHERE id = ?', [$active, $userId]);
    jsonResponse(200, ['ok' => true, 'user_id' => $userId, 'active' => $active]);
}

if ($method === 'POST' && $action === 'reset_user_password') {
    $raw = file_get_contents('php://input');
    $body = json_decode($raw ?: '{}', true);
    $userId = trim((string) ($body['user_id'] ?? ''));
    $newPass = (string) ($body['new_password'] ?? '');
    if ($userId === '' || strlen($newPass) < 6 || strlen($newPass) > 72) {
        jsonResponse(422, ['error' => 'Provide user_id and a password of 6-72 characters.']);
    }
    $db->execute('UPDATE users SET password_hash = ? WHERE id = ?', [password_hash($newPass, PASSWORD_DEFAULT), $userId]);
    jsonResponse(200, ['ok' => true, 'message' => 'Password updated successfully.']);
}

if ($method === 'POST' && $action === 'bulk_sms') {
    $raw = file_get_contents('php://input');
    $body = json_decode($raw ?: '{}', true);
    $message = trim((string) ($body['message'] ?? ''));
    $target = (string) ($body['target'] ?? 'all_owners');
    $singlePhone = trim((string) ($body['phone'] ?? ''));

    if ($message === '' || strlen($message) > 500) {
        jsonResponse(422, ['error' => 'Message must be between 1 and 500 characters.']);
    }

    $phones = [];
    if ($target === 'single') {
        if ($singlePhone === '') {
            jsonResponse(422, ['error' => 'Phone number is required for single target.']);
        }
        try {
            $phones[] = ApiValidator::formatTanzanianPhone($singlePhone);
        } catch (Throwable $e) {
            jsonResponse(422, ['error' => $e->getMessage()]);
        }
    } else {
        $sql = $target === 'all_users'
            ? 'SELECT DISTINCT email FROM users WHERE active = 1'
            : "SELECT DISTINCT email FROM users WHERE active = 1 AND role = 'owner'";
        foreach ($db->rows($sql) as $row) {
            $rawEmail = str_replace('@trackmauzo.app', '', (string) ($row['email'] ?? ''));
            try {
                $phones[] = ApiValidator::formatTanzanianPhone($rawEmail);
            } catch (Throwable) {
                // skip invalid phone
            }
        }
        $phones = array_values(array_unique($phones));
    }

    $sms = new SmsService($config['sms'] ?? []);
    $sent = 0;
    $failed = 0;
    foreach ($phones as $p) {
        if ($sms->send($p, $message)) {
            $sent++;
        } else {
            $failed++;
        }
    }

    jsonResponse(200, [
        'ok' => true,
        'total' => count($phones),
        'sent' => $sent,
        'failed' => $failed,
    ]);
}

jsonResponse(404, ['error' => 'Unknown action.']);
