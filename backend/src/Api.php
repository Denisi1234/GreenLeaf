<?php
declare(strict_types=1);

require_once __DIR__ . '/ApiError.php';
require_once __DIR__ . '/SmsService.php';
require_once __DIR__ . '/UploadService.php';
require_once __DIR__ . '/NotificationService.php';
require_once __DIR__ . '/ResourceRepository.php';
require_once __DIR__ . '/AuthService.php';
require_once __DIR__ . '/OrderService.php';

final class Api
{
    private SmsService $sms;
    private UploadService $uploads;
    private NotificationService $notifications;
    private ResourceRepository $resources;
    private AuthService $auth;
    private OrderService $orders;

    public function __construct(private Database $db, array $config)
    {
        $this->sms = new SmsService($config);
        $this->uploads = new UploadService($db);
        $this->notifications = new NotificationService($db);
        $this->resources = new ResourceRepository($db);
        $this->auth = new AuthService($db, $config, $this->resources, $this->sms);
        $this->orders = new OrderService($db, $this->resources, $this->auth);
    }

    public function dispatch(
        string $method,
        string $path,
        array $body,
        string $token,
        ?int $version,
        string $ip = 'local'
    ): array {
        $parts = array_map('rawurldecode', array_values(array_filter(explode('/', trim($path, '/')), 'strlen')));

        if ($method === 'GET' && ($parts === [] || $parts === ['health'])) {
            $this->db->rows('SELECT id FROM stores LIMIT 1');
            return ['data' => ['status' => 'ok', 'service' => 'TrackMauzo PHP API']];
        }

        // Public authentication & OTP routes
        if ($method === 'POST' && $parts === ['auth', 'register']) {
            $this->auth->throttle('register:' . $ip);
            return $this->auth->register($body);
        }
        if ($method === 'POST' && $parts === ['auth', 'login']) {
            $this->auth->throttle('login:' . $ip);
            return $this->auth->login($body);
        }
        if ($method === 'POST' && $parts === ['auth', 'otp', 'send']) {
            $this->auth->throttle('otp_send:' . $ip);
            return $this->auth->sendOtp($body);
        }
        if ($method === 'POST' && $parts === ['auth', 'otp', 'verify']) {
            $this->auth->throttle('otp_verify:' . $ip);
            return $this->auth->verifyOtp($body);
        }
        if ($method === 'POST' && $parts === ['auth', 'reset-password']) {
            $this->auth->throttle('reset_password:' . $ip);
            return $this->auth->resetPasswordWithOtp($body);
        }

        // Authenticated session
        $session = $this->auth->authenticate($token);
        $user = $session['user'];
        $storeId = $user['store_id'];
        $cartResource = $session['cartResource'];

        if ($parts === ['sms', 'send'] && $method === 'POST') {
            $this->auth->throttle('sms_send:' . $ip);
            $this->auth->requirePermission($user, 'View Reports');
            $phone = ApiValidator::formatTanzanianPhone((string) ($body['phone'] ?? ''));
            $text = trim((string) ($body['text'] ?? ''));
            if ($text === '' || strlen($text) > 500) {
                throw new ApiError(422, 'Provide a message of up to 500 characters.');
            }
            if (!$this->sms->send($phone, $text)) {
                throw new ApiError(502, 'Failed to send SMS.');
            }
            return ['data' => ['sent' => true, 'phone' => $phone]];
        }

        if (($parts[0] ?? '') === 'uploads') {
            if ($method === 'POST' && count($parts) === 1) {
                $this->auth->requireAny($user, ['Manage Inventory', 'Manage Staff', 'System Settings', 'View Reports']);
                return $this->uploads->upload($storeId, $body);
            }
            if ($method === 'GET' && count($parts) === 2) {
                return $this->uploads->get($storeId, $parts[1]);
            }
            throw new ApiError(405, 'Method not allowed.');
        }

        if ($parts === ['auth', 'me'] && $method === 'GET') {
            return ['data' => $this->auth->publicUser($user)];
        }
        if ($parts === ['auth', 'logout'] && $method === 'POST') {
            return $this->auth->logout($token);
        }
        if ($parts === ['auth', 'users'] && $method === 'POST') {
            $this->auth->requireOwner($user);
            return $this->auth->createUser($user, $body);
        }
        if (count($parts) === 3 && $parts[0] === 'staff' && $parts[2] === 'account' && $method === 'POST') {
            $this->auth->requirePermission($user, 'Manage Staff');
            return $this->resources->mutate($storeId, function () use ($user, $storeId, $parts, $body) {
                $staff = $body['staff'] ?? null;
                if (!is_array($staff)) {
                    throw new ApiError(422, 'Provide the staff record.');
                }
                $staff['id'] = $parts[1];
                $password = $body['password'] ?? '';
                if (!is_string($password)) {
                    throw new ApiError(422, 'Invalid password.');
                }
                $this->auth->checkPassword($password);
                $this->resources->staffAccount($user, $parts[1], $staff, $password);
                $this->resources->put($user, 'staff', $parts[1], $staff);
                $this->resources->bump($storeId, 'staff');
                return $this->resources->collection($storeId, 'staff', $this->resources->resourceRows($storeId, 'staff'));
            });
        }

        if ($parts === ['reports', 'summary'] && $method === 'GET') {
            $this->auth->requirePermission($user, 'View Reports');
            return $this->orders->summary($storeId);
        }
        if ($parts === ['notifications', 'device-token'] && $method === 'POST') {
            return $this->notifications->registerDeviceToken($user, $body);
        }
        if ($parts === ['notifications'] && $method === 'GET') {
            return $this->notifications->getNotifications($storeId);
        }
        if ($parts === ['notifications', 'send'] && $method === 'POST') {
            return $this->notifications->dispatchPushNotification($storeId, $body);
        }
        if ($parts === ['checkout'] && $method === 'POST') {
            $this->auth->requirePermission($user, 'View Sales');
            return $this->resources->mutate($storeId, fn () => $this->orders->checkout($user, $cartResource, $body));
        }
        if ($parts === ['products', 'stock-delta'] && $method === 'POST') {
            $this->auth->requirePermission($user, 'Manage Inventory');
            return $this->resources->mutate($storeId, fn () => $this->orders->applyProductStockDeltas($storeId, $body));
        }
        if (($parts[0] ?? '') === 'orders') {
            if ($method === 'GET' && count($parts) === 1) {
                $this->auth->requireAny($user, ['View Sales', 'View Reports']);
                return $this->resources->collection($storeId, 'orders', $this->orders->orderRows($storeId));
            }
            if ($method === 'POST' && count($parts) === 3 && $parts[2] === 'void') {
                $this->auth->requirePermission($user, 'Process Returns');
                return $this->resources->mutate($storeId, fn () => $this->orders->voidOrder($user, $parts[1]));
            }
            throw new ApiError(405, 'Use checkout to create a sale and void to reverse one.');
        }

        return $this->dispatchResource($user, $cartResource, $method, $parts, $body, $version);
    }

    private function dispatchResource(
        array $user,
        string $cartResource,
        string $method,
        array $parts,
        array $body,
        ?int $version,
    ): array {
        $storeId = $user['store_id'];
        $resource = $parts[0] ?? '';
        if (($resource !== 'products' && !in_array($resource, ResourceRepository::RESOURCES, true)) || count($parts) > 2) {
            throw new ApiError(404, 'API endpoint not found.');
        }

        $publicRead = $method === 'GET' && in_array($resource, ['products', 'profile', 'receipt-settings', 'tax-settings', 'customers', 'debit-entries'], true);
        if ($method === 'GET' && $resource === 'expenses') {
            $this->auth->requireAny($user, ['View Reports', 'Manage Payments']);
            $publicRead = true;
        }
        if (!$publicRead && !in_array($resource, ['cart', 'preferences'], true)) {
            $permission = match ($resource) {
                'products', 'suppliers', 'receivings' => 'Manage Inventory',
                'staff' => 'Manage Staff',
                'roles' => $method === 'GET' ? 'Manage Staff' : 'System Settings',
                'customers', 'debit-entries', 'expenses' => 'Manage Payments',
                'register-shifts', 'cash-movements' => 'View Sales',
                'profile', 'receipt-settings', 'tax-settings' => 'System Settings',
                default => 'View Reports',
            };
            $this->auth->requirePermission($user, $permission);
        }

        $resource = match ($resource) {
            'cart' => $cartResource,
            'preferences' => 'preferences:' . $user['id'],
            default => $resource,
        };

        if ($method === 'GET') {
            $rows = $this->resources->resourceRows($storeId, $resource);
            if (isset($parts[1])) {
                $rows = array_values(array_filter($rows, fn ($row) => (string) ($row['id'] ?? $row['code'] ?? '1') === $parts[1]));
                if ($rows === []) {
                    throw new ApiError(404, 'Record not found.');
                }
                return ['data' => $rows[0], 'version' => $this->resources->version($storeId, $resource)];
            }
            return $this->resources->collection($storeId, $resource, $rows);
        }

        return $this->resources->mutate($storeId, function () use ($user, $storeId, $method, $resource, $parts, $body, $version) {
            if ($method === 'PUT' && count($parts) === 1) {
                if ($version === null || $version !== $this->resources->version($storeId, $resource)) {
                    throw new ApiError(409, 'Data changed on another device. Refresh before saving.');
                }
                $items = $body['items'] ?? null;
                if (!is_array($items) || !array_is_list($items) || count($items) > 10000) {
                    throw new ApiError(422, 'Provide an items array with at most 10000 records.');
                }
                $this->resources->replace($user, $resource, $items);
            } elseif ($method === 'PUT' && isset($parts[1])) {
                $this->resources->put($user, $resource, $parts[1], $body);
            } elseif ($method === 'POST' && count($parts) === 1) {
                $id = $resource === 'products'
                    ? ApiValidator::text($body, 'code')
                    : (string) ($body['id'] ?? bin2hex(random_bytes(12)));
                if ($resource === 'expenses' && !isset($body['id'])) {
                    $id = (string) random_int(1, 2147483647);
                    $body['id'] = (int) $id;
                }
                $this->resources->put($user, $resource, $id, $body);
            } elseif ($method === 'DELETE' && isset($parts[1])) {
                $this->resources->delete($storeId, $resource, $parts[1]);
            } else {
                throw new ApiError(405, 'Method not allowed.');
            }
            $this->resources->bump($storeId, $resource);
            return $this->resources->collection($storeId, $resource, $this->resources->resourceRows($storeId, $resource));
        });
    }
}
