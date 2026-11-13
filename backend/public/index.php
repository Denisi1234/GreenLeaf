<?php
declare(strict_types=1);

require __DIR__ . '/../src/Database.php';
require __DIR__ . '/../src/Api.php';
$config = require __DIR__ . '/../config.php';
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
header('X-Content-Type-Options: nosniff');
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
if (in_array($origin, $config['origins'], true)) {
    header('Access-Control-Allow-Origin: ' . $origin);
    header('Vary: Origin');
    header('Access-Control-Allow-Headers: Authorization, Content-Type, If-Match');
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
}
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code($origin === '' || in_array($origin, $config['origins'], true) ? 204 : 403);
    exit;
}
try {
    $input = file_get_contents('php://input', false, null, 0, 4194305);
    if (strlen($input) > 4194304) {
        throw new ApiError(413, 'Request exceeds the 4 MB limit.');
    }
    $body = $input === '' ? [] : json_decode($input, true, 64, JSON_THROW_ON_ERROR);
    if (!is_array($body)) {
        throw new ApiError(422, 'Send a JSON object.');
    }
    $path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH) ?: '/';
    if ($path !== '/' && !str_starts_with($path, '/api/')) {
        throw new ApiError(404, 'API endpoint not found.');
    }
    $authorization = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
    $token = str_starts_with($authorization, 'Bearer ') ? substr($authorization, 7) : '';
    $version = isset($_SERVER['HTTP_IF_MATCH']) ? filter_var(trim($_SERVER['HTTP_IF_MATCH'], '"'), FILTER_VALIDATE_INT) : null;
    $api = new Api(new Database($config), $config);
    $result = $api->dispatch(
        $_SERVER['REQUEST_METHOD'],
        $path === '/' ? '' : substr($path, 5),
        $body,
        $token,
        is_int($version) ? $version : null,
        $_SERVER['REMOTE_ADDR'] ?? 'local'
    );
    if (isset($result['image'])) {
        header('Content-Type: ' . $result['mime']);
        echo base64_decode($result['image'], true);
    } else {
        echo json_encode($result, JSON_THROW_ON_ERROR | JSON_UNESCAPED_UNICODE);
    }
} catch (ApiError $error) {
    http_response_code($error->status);
    echo json_encode(['error' => $error->getMessage()]);
} catch (JsonException $error) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid JSON.']);
} catch (PDOException $error) {
    error_log($error::class . ': ' . $error->getMessage());
    $duplicate = $error->getCode() === '23000' &&
        (str_contains(strtolower($error->getMessage()), 'unique') || ($error->errorInfo[1] ?? 0) === 1062);
    http_response_code($duplicate ? 409 : 500);
    echo json_encode(['error' => $duplicate ? 'A record with these details already exists.' : 'The database could not complete this request.']);
} catch (Throwable $error) {
    error_log($error::class . ': ' . $error->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'The server could not complete this request.']);
}
