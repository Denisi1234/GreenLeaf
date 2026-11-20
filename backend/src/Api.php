<?php
declare(strict_types=1);

final class ApiError extends RuntimeException
{
    public function __construct(public readonly int $status, string $message)
    {
        parent::__construct($message);
    }
}

final class Api
{
    private const RESOURCES = [
        'profile', 'receipt-settings', 'roles', 'staff', 'customers', 'expenses',
        'recovery-sessions', 'learning-rules', 'cart', 'preferences',
    ];
    private array $user = [];
    private string $cartResource = '';

    public function __construct(private Database $db, private array $config)
    {
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
        if ($parts === ['auth', 'register'] && $method === 'POST') {
            $this->throttle('register:' . $ip);
            return $this->register($body);
        }
        if ($parts === ['auth', 'login'] && $method === 'POST') {
            $this->throttle('login:' . $ip);
            return $this->login($body);
        }
        if ($parts === ['auth', 'otp', 'send'] && $method === 'POST') {
            $this->throttle('otp_send:' . $ip);
            return $this->sendOtp($body);
        }
        if ($parts === ['auth', 'otp', 'verify'] && $method === 'POST') {
            $this->throttle('otp_verify:' . $ip);
            return $this->verifyOtp($body);
        }
        if ($parts === ['auth', 'reset-password'] && $method === 'POST') {
            $this->throttle('reset_password:' . $ip);
            return $this->resetPasswordWithOtp($body);
        }
        $this->authenticate($token);
        if ($parts === ['sms', 'send'] && $method === 'POST') {
            $this->throttle('sms_send:' . $ip);
            $this->requirePermission('View Reports');
            $phone = $this->formatTanzanianPhone((string) ($body['phone'] ?? ''));
            $text = trim((string) ($body['text'] ?? ''));
            if ($text === '' || strlen($text) > 500) {
                throw new ApiError(422, 'Provide a message of up to 500 characters.');
            }
            if (!$this->sendNextSms($phone, $text)) {
                throw new ApiError(502, 'Failed to send SMS.');
            }
            return ['data' => ['sent' => true, 'phone' => $phone]];
        }
        if (($parts[0] ?? '') === 'uploads') {
            if ($method === 'POST' && count($parts) === 1) {
                $this->requireAny(['Manage Inventory', 'Manage Staff', 'System Settings', 'View Reports']);
                $content = base64_decode((string) ($body['content'] ?? ''), true);
                $info = $content === false ? false : @getimagesizefromstring($content);
                if ($info === false || strlen($content) > 2097152 ||
                    !in_array($info['mime'], ['image/jpeg', 'image/png', 'image/webp'], true) ||
                    $info[0] * $info[1] > 24000000) {
                    throw new ApiError(422, 'Upload a JPEG, PNG, or WebP image up to 2 MB and 24 megapixels.');
                }
                $id = hash('sha256', $this->user['store_id'] . $content);
                if ($this->db->rows('SELECT id FROM uploads WHERE id = ?', [$id]) === []) {
                    $this->db->execute('INSERT INTO uploads VALUES (?, ?, ?, ?)', [$id, $this->user['store_id'], $info['mime'], base64_encode($content)]);
                }
                return ['data' => ['id' => $id]];
            }
            if ($method === 'GET' && count($parts) === 2) {
                $rows = $this->db->rows('SELECT mime, content FROM uploads WHERE id = ? AND store_id = ?', [$parts[1], $this->user['store_id']]);
                if ($rows === []) {
                    throw new ApiError(404, 'Image not found.');
                }
                return ['image' => $rows[0]['content'], 'mime' => $rows[0]['mime']];
            }
            throw new ApiError(405, 'Method not allowed.');
        }
        if ($parts === ['auth', 'me'] && $method === 'GET') {
            return ['data' => $this->publicUser($this->user)];
        }
        if ($parts === ['auth', 'logout'] && $method === 'POST') {
            $this->db->execute('DELETE FROM access_tokens WHERE token_hash = ?', [hash('sha256', $token)]);
            return ['data' => ['logged_out' => true]];
        }
        if ($parts === ['auth', 'users'] && $method === 'POST') {
            $this->owner();
            return $this->createUser($body);
        }
        if (count($parts) === 3 && $parts[0] === 'staff' && $parts[2] === 'account' && $method === 'POST') {
            $this->requirePermission('Manage Staff');
            return $this->mutate(function () use ($parts, $body) {
                $staff = $body['staff'] ?? null;
                if (!is_array($staff)) {
                    throw new ApiError(422, 'Provide the staff record.');
                }
                $staff['id'] = $parts[1];
                $password = $body['password'] ?? '';
                if (!is_string($password)) {
                    throw new ApiError(422, 'Invalid password.');
                }
                $this->checkPassword($password);
                $this->staffAccount($parts[1], $staff, $password);
                $this->put('staff', $parts[1], $staff);
                $this->bump('staff');
                return $this->collection('staff', $this->resourceRows('staff'));
            });
        }
        if ($parts === ['reports', 'summary'] && $method === 'GET') {
            $this->requirePermission('View Reports');
            return $this->summary();
        }
        if ($parts === ['notifications', 'device-token'] && $method === 'POST') {
            return $this->registerDeviceToken($body);
        }
        if ($parts === ['notifications'] && $method === 'GET') {
            return $this->getNotifications();
        }
        if ($parts === ['notifications', 'send'] && $method === 'POST') {
            return $this->dispatchPushNotification($body);
        }
        if ($parts === ['checkout'] && $method === 'POST') {
            $this->requirePermission('View Sales');
            return $this->mutate(fn () => $this->checkout($body));
        }
        if (($parts[0] ?? '') === 'orders') {
            if ($method === 'GET' && count($parts) === 1) {
                $this->requireAny(['View Sales', 'View Reports']);
                return $this->collection('orders', $this->orderRows());
            }
            if ($method === 'POST' && count($parts) === 3 && $parts[2] === 'void') {
                $this->requirePermission('Process Returns');
                return $this->mutate(fn () => $this->voidOrder($parts[1]));
            }
            throw new ApiError(405, 'Use checkout to create a sale and void to reverse one.');
        }
        $resource = $parts[0] ?? '';
        if ($resource !== 'products' && !in_array($resource, self::RESOURCES, true)) {
            throw new ApiError(404, 'API endpoint not found.');
        }
        if (count($parts) > 2) {
            throw new ApiError(404, 'API endpoint not found.');
        }
        $publicRead = $method === 'GET' && in_array($resource, ['products', 'profile', 'receipt-settings', 'customers'], true);
        if ($method === 'GET' && $resource === 'expenses') {
            $this->requireAny(['View Reports', 'Manage Payments']);
            $publicRead = true;
        }
        if (!$publicRead && !in_array($resource, ['cart', 'preferences'], true)) {
            $permission = match ($resource) {
                'products' => 'Manage Inventory',
                'staff' => 'Manage Staff',
                'roles' => $method === 'GET' ? 'Manage Staff' : 'System Settings',
                'customers', 'expenses' => 'Manage Payments',
                'profile', 'receipt-settings' => 'System Settings',
                default => 'View Reports',
            };
            $this->requirePermission($permission);
        }
        $resource = match ($resource) {
            'cart' => $this->cartResource,
            'preferences' => 'preferences:' . $this->user['id'],
            default => $resource,
        };
        if ($method === 'GET') {
            $rows = $this->resourceRows($resource);
            if (isset($parts[1])) {
                $rows = array_values(array_filter($rows, fn ($row) => (string) ($row['id'] ?? $row['code'] ?? '1') === $parts[1]));
                if ($rows === []) {
                    throw new ApiError(404, 'Record not found.');
                }
                return ['data' => $rows[0], 'version' => $this->version($resource)];
            }
            return $this->collection($resource, $rows);
        }
        return $this->mutate(function () use ($method, $resource, $parts, $body, $version) {
            if ($method === 'PUT' && count($parts) === 1) {
                if ($version === null || $version !== $this->version($resource)) {
                    throw new ApiError(409, 'Data changed on another device. Refresh before saving.');
                }
                $items = $body['items'] ?? null;
                if (!is_array($items) || !array_is_list($items) || count($items) > 10000) {
                    throw new ApiError(422, 'Provide an items array with at most 10000 records.');
                }
                $this->replace($resource, $items);
            } elseif ($method === 'PUT' && isset($parts[1])) {
                $this->put($resource, $parts[1], $body);
            } elseif ($method === 'POST' && count($parts) === 1) {
                $id = $resource === 'products'
                    ? $this->text($body, 'code')
                    : (string) ($body['id'] ?? bin2hex(random_bytes(12)));
                if ($resource === 'expenses' && !isset($body['id'])) {
                    $id = (string) random_int(1, 2147483647);
                    $body['id'] = (int) $id;
                }
                $this->put($resource, $id, $body);
            } elseif ($method === 'DELETE' && isset($parts[1])) {
                $this->delete($resource, $parts[1]);
            } else {
                throw new ApiError(405, 'Method not allowed.');
            }
            $this->bump($resource);
            return $this->collection($resource, $this->resourceRows($resource));
        });
    }

    private function authenticate(string $token): void
    {
        $rows = $this->db->rows(
            'SELECT u.* FROM users u JOIN access_tokens t ON t.user_id = u.id WHERE t.token_hash = ? AND t.expires_at > ? AND u.active = 1',
            [hash('sha256', $token), time()]
        );
        if ($token === '' || $rows === []) {
            throw new ApiError(401, 'Sign in to continue.');
        }
        $this->user = $rows[0];
        $this->user['permissions'] = ['View Sales'];
        $links = $this->db->rows(
            "SELECT r.payload FROM staff_accounts a JOIN records r ON r.store_id = a.store_id AND r.record_id = a.staff_id AND r.resource = 'staff' WHERE a.user_id = ?",
            [$this->user['id']]
        );
        if ($links !== []) {
            $staff = json_decode($links[0]['payload'], true, 512, JSON_THROW_ON_ERROR);
            $roles = $this->db->rows("SELECT payload FROM records WHERE store_id = ? AND resource = 'roles' AND record_id = ?", [$this->user['store_id'], $staff['role_id'] ?? '']);
            $role = $roles === [] ? [] : json_decode($roles[0]['payload'], true, 512, JSON_THROW_ON_ERROR);
            $this->user['permissions'] = json_decode($role['permissions_json'] ?? '[]', true, 512, JSON_THROW_ON_ERROR);
        }
        $this->cartResource = 'cart:' . substr(hash('sha256', $token), 0, 32);
    }

    private function owner(): void
    {
        if ($this->user['role'] !== 'owner') {
            throw new ApiError(403, 'This action requires the business owner.');
        }
    }

    private function requirePermission(string $permission): void
    {
        if ($this->user['role'] !== 'owner' && !in_array($permission, $this->user['permissions'] ?? [], true)) {
            throw new ApiError(403, 'This action requires ' . $permission . ' permission.');
        }
    }

    private function requireAny(array $permissions): void
    {
        if ($this->user['role'] !== 'owner' && array_intersect($permissions, $this->user['permissions'] ?? []) === []) {
            throw new ApiError(403, 'Your account does not have permission for this action.');
        }
    }

    private function credentials(array $body): array
    {
        $rawIdentifier = trim((string) ($body['phone'] ?? $body['email'] ?? $body['username'] ?? ''));
        $password = $body['password'] ?? '';
        if ($rawIdentifier === '' || !is_string($password)) {
            throw new ApiError(422, 'Enter your phone number and password.');
        }

        // Check if phone or email
        $isEmail = filter_var($rawIdentifier, FILTER_VALIDATE_EMAIL);
        $identifier = $isEmail ? strtolower($rawIdentifier) : $this->formatTanzanianPhone($rawIdentifier);
        return [$identifier, $password, (bool) $isEmail];
    }

    private function register(array $body): array
    {
        if (!$this->config['registration']) {
            throw new ApiError(403, 'Account registration is disabled.');
        }
        [$identifier, $password, $isEmail] = $this->credentials($body);
        $name = $this->text($body, 'name');
        $storeName = trim((string) ($body['store_name'] ?? '')) ?: ($name . "'s Shop");
        $this->checkPassword($password);

        // Standardize identifier column (use as email/phone handle)
        $phone = $isEmail ? '' : $identifier;
        $email = $isEmail ? $identifier : ($phone . '@trackmauzo.app');

        if ($this->db->rows('SELECT id FROM users WHERE email = ?', [$email]) !== []) {
            throw new ApiError(409, 'An account with this phone number already exists.');
        }

        // Require verified OTP token for phone-based live registration
        if (!$isEmail) {
            $otpToken = trim((string) ($body['otp_token'] ?? ''));
            if ($otpToken === '') {
                throw new ApiError(403, 'Thibitisha namba yako ya simu kwa OTP kwanza kabla ya kusajili.');
            }
            $otpRows = $this->db->rows(
                'SELECT * FROM otp_verifications WHERE phone = ? AND expires_at > ?',
                [$phone, time()]
            );
            $expectedHash = hash('sha256', 'verified:' . $otpToken);
            if ($otpRows === [] || !hash_equals((string) $otpRows[0]['code_hash'], $expectedHash)) {
                throw new ApiError(403, 'Uthibitisho wa OTP umeisha muda au si sahihi. Omba OTP mpya.');
            }
        }

        $res = $this->db->transaction(function () use ($email, $phone, $password, $name, $storeName, $isEmail) {
            if (!$isEmail) {
                $this->db->execute('DELETE FROM otp_verifications WHERE phone = ?', [$phone]);
            }
            $storeId = bin2hex(random_bytes(16));
            $userId = bin2hex(random_bytes(16));
            $created = gmdate('c');
            $this->db->execute('INSERT INTO stores (id, name, created_at) VALUES (?, ?, ?)', [$storeId, $storeName, $created]);
            $this->db->execute(
                'INSERT INTO users (id, store_id, name, email, password_hash, role, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
                [$userId, $storeId, $name, $email, password_hash($password, PASSWORD_DEFAULT), 'owner', $created]
            );
            $this->user = ['id' => $userId, 'store_id' => $storeId, 'name' => $name, 'email' => $email, 'role' => 'owner'];
            $this->put('profile', '1', [
                'store_name' => $storeName, 'owner_name' => $name, 'role_title' => 'Owner',
                'email_address' => $email, 'contact_number' => $phone, 'physical_address' => '',
                'business_category' => 'Retail', 'member_since' => $created, 'open_24_hours' => 0,
            ]);
            $this->put('receipt-settings', '1', ['show_store_contact' => 1, 'footer' => '']);

            // Create staff record for owner
            $staffId = 'staff-' . $userId;
            $this->put('staff', $staffId, [
                'id' => $staffId,
                'name' => $name,
                'email' => $email,
                'phone' => $phone,
                'role_id' => 'owner',
                'username' => $phone ?: $email,
                'created_at' => $created,
                'updated_at' => $created,
                'status' => 'active',
                'password_hash' => 'server-managed',
                'password_salt' => '',
            ]);
            $this->db->execute(
                'INSERT INTO staff_accounts (store_id, staff_id, user_id) VALUES (?, ?, ?)',
                [$storeId, $staffId, $userId]
            );

            return $this->issueToken($this->user);
        });

        // Send welcoming SMS to user upon successful registration
        if ($phone !== '') {
            $welcomeText = "Habari $name, Karibu TrackMauzo! Duka lako '$storeName' limesajiliwa kwa mafanikio. Tumia namba hii kuingia.";
            $this->sendNextSms($phone, $welcomeText);
        }

        return $res;
    }

    private function checkPassword(string $password): void
    {
        if (strlen($password) < 6 || strlen($password) > 72) {
            throw new ApiError(422, 'Nenosiri lazima liwe na herufi kuanzia 6.');
        }
    }

    private function createUser(array $body): array
    {
        [$email, $password] = $this->credentials($body);
        $this->checkPassword($password);
        $name = $this->text($body, 'name');
        $id = bin2hex(random_bytes(16));
        $this->db->execute(
            'INSERT INTO users (id, store_id, name, email, password_hash, role, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [$id, $this->user['store_id'], $name, $email, password_hash($password, PASSWORD_DEFAULT), 'cashier', gmdate('c')]
        );
        return ['data' => ['id' => $id, 'email' => $email, 'name' => $name, 'role' => 'cashier']];
    }

    private function login(array $body): array
    {
        [$identifier, $password, $isEmail] = $this->credentials($body);
        $email = $isEmail ? $identifier : ($identifier . '@trackmauzo.app');

        $rows = $this->db->rows('SELECT * FROM users WHERE (email = ? OR email = ?) AND active = 1', [$email, $identifier]);
        $hash = $rows[0]['password_hash'] ?? '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2uheWG/igi.';
        if (!password_verify($password, $hash) || $rows === []) {
            throw new ApiError(401, 'Namba ya simu au nenosiri si sahihi.');
        }
        return $this->issueToken($rows[0]);
    }

    private function issueToken(array $user): array
    {
        $token = bin2hex(random_bytes(32));
        $expires = time() + $this->config['token_hours'] * 3600;
        $this->db->execute('DELETE FROM access_tokens WHERE expires_at <= ?', [time()]);
        $this->db->execute('INSERT INTO access_tokens (token_hash, user_id, expires_at) VALUES (?, ?, ?)', [hash('sha256', $token), $user['id'], $expires]);
        $this->authenticate($token);
        return ['data' => ['token' => $token, 'expires_at' => $expires, 'user' => $this->publicUser($this->user)]];
    }

    private function publicUser(array $user): array
    {
        return array_intersect_key($user, array_flip(['id', 'store_id', 'name', 'email', 'role', 'permissions']));
    }

    private function throttle(string $key): void
    {
        $key = hash('sha256', $key);
        $this->db->execute('DELETE FROM login_attempts WHERE window_start < ?', [time() - 900]);
        $rows = $this->db->rows('SELECT attempts FROM login_attempts WHERE attempt_key = ?', [$key]);
        if ((int) ($rows[0]['attempts'] ?? 0) >= 20) {
            throw new ApiError(429, 'Too many attempts. Try again in 15 minutes.');
        }
        if ($rows === []) {
            $this->db->execute('INSERT INTO login_attempts VALUES (?, 1, ?)', [$key, time()]);
        } else {
            $this->db->execute('UPDATE login_attempts SET attempts = attempts + 1 WHERE attempt_key = ?', [$key]);
        }
    }

    private function formatTanzanianPhone(string $rawPhone): string
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

    private function sendNextSms(string $phone, string $message): bool
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

        $response = curl_exec($ch);
        $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        return $code >= 200 && $code < 300;
    }

    private function sendOtp(array $body): array
    {
        $rawPhone = (string) ($body['phone'] ?? '');
        $phone = $this->formatTanzanianPhone($rawPhone);
        $purpose = strtolower(trim((string) ($body['purpose'] ?? '')));

        if ($purpose === 'register') {
            $email = $phone . '@trackmauzo.app';
            if ($this->db->rows('SELECT id FROM users WHERE email = ?', [$email]) !== []) {
                throw new ApiError(409, 'Namba hii ya simu tayari imesajiliwa. Tafadhali ingia (Sign in).');
            }
        }

        // Generate 6-digit secure code
        $code = (string) random_int(100000, 999999);
        $hash = hash('sha256', $phone . ':' . $code);
        $expires = time() + 600; // 10 minutes

        $this->db->execute(
            'CREATE TABLE IF NOT EXISTS otp_verifications (
                phone VARCHAR(32) PRIMARY KEY,
                code_hash VARCHAR(64) NOT NULL,
                attempts INTEGER NOT NULL DEFAULT 0,
                expires_at INTEGER NOT NULL,
                created_at VARCHAR(32) NOT NULL
            )'
        );

        $this->db->execute('DELETE FROM otp_verifications WHERE phone = ? OR expires_at < ?', [$phone, time()]);
        $this->db->execute(
            'INSERT INTO otp_verifications (phone, code_hash, attempts, expires_at, created_at) VALUES (?, ?, 0, ?, ?)',
            [$phone, $hash, $expires, gmdate('c')]
        );

        $smsText = "Namba yako ya uthibitisho ya TrackMauzo (OTP) ni $code. Usitoe namba hii kwa mtu yeyote.";
        $sent = $this->sendNextSms($phone, $smsText);
        if (!$sent) {
            throw new ApiError(502, 'Imeshindwa kutuma SMS ya uthibitisho. Hakikisha namba ya simu na ujaribu tena.');
        }

        return [
            'data' => [
                'sent' => true,
                'phone' => $phone,
                'expires_in' => 600,
                'message' => 'OTP sent successfully.',
            ],
        ];
    }

    private function verifyOtp(array $body): array
    {
        $rawPhone = (string) ($body['phone'] ?? '');
        $code = trim((string) ($body['code'] ?? ''));
        $phone = $this->formatTanzanianPhone($rawPhone);

        if (strlen($code) !== 6 || !ctype_digit($code)) {
            throw new ApiError(422, 'Enter a valid 6-digit verification code.');
        }

        $rows = $this->db->rows(
            'SELECT * FROM otp_verifications WHERE phone = ? AND expires_at > ?',
            [$phone, time()]
        );

        if ($rows === []) {
            throw new ApiError(404, 'No active OTP verification found or code has expired. Request a new one.');
        }

        $row = $rows[0];
        if ((int) $row['attempts'] >= 5) {
            $this->db->execute('DELETE FROM otp_verifications WHERE phone = ?', [$phone]);
            throw new ApiError(429, 'Too many failed attempts. Request a new code.');
        }

        $expectedHash = hash('sha256', $phone . ':' . $code);
        if (!hash_equals($row['code_hash'], $expectedHash)) {
            $this->db->execute('UPDATE otp_verifications SET attempts = attempts + 1 WHERE phone = ?', [$phone]);
            throw new ApiError(422, 'Invalid verification code.');
        }

        // Generate temporary reset verification token valid for 15 minutes
        $resetToken = bin2hex(random_bytes(24));
        $this->db->execute(
            'UPDATE otp_verifications SET code_hash = ?, expires_at = ? WHERE phone = ?',
            [hash('sha256', 'verified:' . $resetToken), time() + 900, $phone]
        );

        return [
            'data' => [
                'verified' => true,
                'phone' => $phone,
                'reset_token' => $resetToken,
            ],
        ];
    }

    private function resetPasswordWithOtp(array $body): array
    {
        $rawPhone = (string) ($body['phone'] ?? '');
        $resetToken = trim((string) ($body['reset_token'] ?? ''));
        $newPassword = $body['new_password'] ?? '';
        $phone = $this->formatTanzanianPhone($rawPhone);

        if (!is_string($newPassword)) {
            throw new ApiError(422, 'Invalid password.');
        }
        $this->checkPassword($newPassword);

        $rows = $this->db->rows(
            'SELECT * FROM otp_verifications WHERE phone = ? AND expires_at > ?',
            [$phone, time()]
        );
        if ($rows === []) {
            throw new ApiError(401, 'Verification expired. Please request a new OTP.');
        }

        $expected = hash('sha256', 'verified:' . $resetToken);
        if (!hash_equals($rows[0]['code_hash'], $expected)) {
            throw new ApiError(401, 'Invalid or expired verification session.');
        }

        // Clean up OTP session
        $this->db->execute('DELETE FROM otp_verifications WHERE phone = ?', [$phone]);

        // Find user by phone in staff records or phone field
        $updated = false;
        $staffRows = $this->db->rows("SELECT * FROM records WHERE resource = 'staff'");
        foreach ($staffRows as $sRow) {
            $staff = json_decode($sRow['payload'], true);
            if (is_array($staff)) {
                $stPhone = preg_replace('/\D+/', '', (string) ($staff['phone'] ?? ''));
                if ($stPhone !== '' && (str_ends_with($phone, $stPhone) || str_ends_with($stPhone, substr($phone, 3)))) {
                    // Find linked user
                    $acc = $this->db->rows('SELECT user_id FROM staff_accounts WHERE staff_id = ? AND store_id = ?', [$sRow['record_id'], $sRow['store_id']]);
                    if ($acc !== []) {
                        $this->db->execute(
                            'UPDATE users SET password_hash = ? WHERE id = ?',
                            [password_hash($newPassword, PASSWORD_DEFAULT), $acc[0]['user_id']]
                        );
                        $updated = true;
                    }
                }
            }
        }

        return [
            'data' => [
                'success' => true,
                'phone' => $phone,
                'user_updated' => $updated,
                'message' => 'Password reset successfully.',
            ],
        ];
    }

    private function text(array $body, string $key): string
    {
        $value = $body[$key] ?? '';
        if (!is_string($value) || trim($value) === '' || strlen($value) > 200) {
            throw new ApiError(422, 'Enter a valid ' . str_replace('_', ' ', $key) . '.');
        }
        return trim($value);
    }

    private function cents(mixed $value): int
    {
        if (!is_numeric($value) || !is_finite((float) $value) || (float) $value < 0 || (float) $value > 100000000000) {
            throw new ApiError(422, 'Invalid monetary amount.');
        }
        return (int) round((float) $value * 100);
    }

    private function mutate(callable $operation): array
    {
        return $this->db->transaction(function () use ($operation) {
            // This row lock serializes writes for one shop across all PHP workers.
            $this->db->execute('UPDATE stores SET revision = revision + 1 WHERE id = ?', [$this->user['store_id']]);
            return $operation();
        });
    }

    private function version(string $resource): int
    {
        $rows = $this->db->rows('SELECT version FROM resource_versions WHERE store_id = ? AND resource = ?', [$this->user['store_id'], $resource]);
        return (int) ($rows[0]['version'] ?? 0);
    }

    private function bump(string $resource): void
    {
        $next = $this->version($resource) + 1;
        $this->db->execute('DELETE FROM resource_versions WHERE store_id = ? AND resource = ?', [$this->user['store_id'], $resource]);
        $this->db->execute('INSERT INTO resource_versions VALUES (?, ?, ?)', [$this->user['store_id'], $resource, $next]);
    }

    private function collection(string $resource, array $items): array
    {
        return ['data' => array_values($items), 'version' => $this->version($resource)];
    }

    private function resourceRows(string $resource): array
    {
        if ($resource === 'products') {
            $rows = $this->db->rows('SELECT payload, stock_count FROM products WHERE store_id = ? ORDER BY code', [$this->user['store_id']]);
            return array_map(function ($row) {
                $item = json_decode($row['payload'], true, 512, JSON_THROW_ON_ERROR);
                $item['stock_count'] = (int) $row['stock_count'];
                $item['stock_state'] = $this->stockState($item['stock_count']);
                return $item;
            }, $rows);
        }
        $rows = $this->db->rows('SELECT payload FROM records WHERE store_id = ? AND resource = ? ORDER BY position, record_id', [$this->user['store_id'], $resource]);
        return array_map(fn ($row) => json_decode($row['payload'], true, 512, JSON_THROW_ON_ERROR), $rows);
    }

    private function replace(string $resource, array $items): void
    {
        $ids = [];
        if ($resource === 'staff') {
            $keep = array_map(fn ($item) => (string) ($item['id'] ?? ''), $items);
            foreach ($this->db->rows('SELECT staff_id FROM staff_accounts WHERE store_id = ?', [$this->user['store_id']]) as $account) {
                if (!in_array($account['staff_id'], $keep, true)) {
                    $this->deleteStaffAccount($account['staff_id']);
                }
            }
        }
        if ($resource === 'products') {
            $this->db->execute('DELETE FROM products WHERE store_id = ?', [$this->user['store_id']]);
        } else {
            $this->db->execute('DELETE FROM records WHERE store_id = ? AND resource = ?', [$this->user['store_id'], $resource]);
        }
        foreach ($items as $position => $item) {
            if (!is_array($item)) {
                throw new ApiError(422, 'Every record must be an object.');
            }
            $id = (string) ($item[$resource === 'products' ? 'code' : 'id'] ?? $position);
            if (isset($ids[$id])) {
                throw new ApiError(422, 'Duplicate record identifier.');
            }
            $ids[$id] = true;
            $this->put($resource, $id, $item, $position);
        }
    }

    private function put(string $resource, string $id, array $item, int $position = 0): void
    {
        if ($id === '' || strlen($id) > 200) {
            throw new ApiError(422, 'Invalid record identifier.');
        }
        unset($item['store_id']);
        if ($resource === 'products') {
            $item['code'] = $id;
            $this->text($item, 'name');
            $item['category'] = (string) ($item['category'] ?? '');
            $item['art_type'] ??= 'aquafina';
            if (!in_array($item['art_type'], ['aquafina', 'coke', 'lays', 'galaxy', 'kelloggs', 'dove', 'colgate', 'dettol', 'tide'], true)) {
                throw new ApiError(422, 'Invalid product artwork type.');
            }
            $item['category_data_json'] ??= '{}';
            if (!is_string($item['category_data_json']) || !is_array(json_decode($item['category_data_json'], true))) {
                throw new ApiError(422, 'Invalid product metadata.');
            }
            $stock = $item['stock_count'] ?? null;
            if (!is_int($stock) || $stock < 0 || $stock > 2147483647) {
                throw new ApiError(422, 'Stock must be a non-negative integer.');
            }
            $price = $this->cents($item['selling_price'] ?? null);
            $cost = $this->cents($item['purchase_price'] ?? null);
            $this->db->execute('DELETE FROM products WHERE store_id = ? AND code = ?', [$this->user['store_id'], $id]);
            $this->db->execute('INSERT INTO products VALUES (?, ?, ?, ?, ?, ?)', [$this->user['store_id'], $id, $stock, $price, $cost, json_encode($item, JSON_THROW_ON_ERROR)]);
            return;
        }
        if ($resource === 'customers') {
            $item['id'] = $id;
            $this->text($item, 'name');
            $this->cents($item['debit_balance'] ?? 0);
        }
        if ($resource === 'staff') {
            $item['id'] = $id;
            $this->checkRoleGrant((string) ($item['role_id'] ?? ''));
            unset($item['password_hash'], $item['password_salt']);
            $this->staffAccount($id, $item);
        }
        if ($resource === 'roles' && $this->user['role'] !== 'owner') {
            $permissions = json_decode($item['permissions_json'] ?? '[]', true, 512, JSON_THROW_ON_ERROR);
            if (!is_array($permissions) || array_diff($permissions, $this->user['permissions'] ?? []) !== []) {
                throw new ApiError(403, 'You cannot grant permissions beyond your own role.');
            }
        }
        if ($resource === 'expenses') {
            if (!ctype_digit($id) || (int) $id < 1) {
                throw new ApiError(422, 'An expense requires a positive integer identifier.');
            }
            $item['id'] = (int) $id;
            $this->text($item, 'title');
            $this->cents($item['amount'] ?? null);
        }
        if ($resource === 'receipt-settings') {
            $item['footer'] = (string) ($item['footer'] ?? '');
            if (preg_match('/\A.{0,160}\z/us', $item['footer']) !== 1) {
                throw new ApiError(422, 'Receipt footer is too long.');
            }
            $item['show_store_contact'] = empty($item['show_store_contact']) ? 0 : 1;
        }
        $this->db->execute('DELETE FROM records WHERE store_id = ? AND resource = ? AND record_id = ?', [$this->user['store_id'], $resource, $id]);
        $this->db->execute('INSERT INTO records VALUES (?, ?, ?, ?, ?)', [$this->user['store_id'], $resource, $id, $position, json_encode($item, JSON_THROW_ON_ERROR)]);
    }

    private function delete(string $resource, string $id): void
    {
        if ($resource === 'staff') {
            $this->deleteStaffAccount($id);
        }
        if ($resource === 'products') {
            $this->db->execute('DELETE FROM products WHERE store_id = ? AND code = ?', [$this->user['store_id'], $id]);
            return;
        }
        $this->db->execute('DELETE FROM records WHERE store_id = ? AND resource = ? AND record_id = ?', [$this->user['store_id'], $resource, $id]);
    }

    private function staffAccount(string $id, array &$staff, ?string $password = null): void
    {
        $this->checkRoleGrant((string) ($staff['role_id'] ?? ''));
        $accounts = $this->db->rows('SELECT user_id FROM staff_accounts WHERE store_id = ? AND staff_id = ?', [$this->user['store_id'], $id]);
        if ($accounts === [] && $password === null) {
            return;
        }
        $email = strtolower($this->text($staff, 'email'));
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new ApiError(422, 'Enter a valid staff email.');
        }
        $name = $this->text($staff, 'name');
        $active = ($staff['status'] ?? 'active') === 'active' ? 1 : 0;
        if ($accounts === []) {
            $userId = bin2hex(random_bytes(16));
            $this->db->execute(
                'INSERT INTO users (id, store_id, name, email, password_hash, role, active, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
                [$userId, $this->user['store_id'], $name, $email, password_hash($password, PASSWORD_DEFAULT), 'cashier', $active, gmdate('c')]
            );
            $this->db->execute('INSERT INTO staff_accounts VALUES (?, ?, ?)', [$this->user['store_id'], $id, $userId]);
        } else {
            $userId = $accounts[0]['user_id'];
            $this->db->execute('UPDATE users SET name = ?, email = ?, active = ? WHERE id = ?', [$name, $email, $active, $userId]);
            if ($password !== null) {
                $this->db->execute('UPDATE users SET password_hash = ? WHERE id = ?', [password_hash($password, PASSWORD_DEFAULT), $userId]);
            }
            if ($password !== null || $active === 0) {
                $this->db->execute('DELETE FROM access_tokens WHERE user_id = ?', [$userId]);
            }
        }
        $staff['password_hash'] = 'server-managed';
        $staff['password_salt'] = '';
    }

    private function checkRoleGrant(string $roleId): void
    {
        if ($this->user['role'] === 'owner') {
            return;
        }
        $roles = $this->db->rows("SELECT payload FROM records WHERE store_id = ? AND resource = 'roles' AND record_id = ?", [$this->user['store_id'], $roleId]);
        $role = $roles === [] ? [] : json_decode($roles[0]['payload'], true, 512, JSON_THROW_ON_ERROR);
        $permissions = json_decode($role['permissions_json'] ?? '[]', true, 512, JSON_THROW_ON_ERROR);
        if (!is_array($permissions) || array_diff($permissions, $this->user['permissions'] ?? []) !== []) {
            throw new ApiError(403, 'You cannot assign a role with permissions beyond your own.');
        }
    }

    private function deleteStaffAccount(string $id): void
    {
        $accounts = $this->db->rows('SELECT user_id FROM staff_accounts WHERE store_id = ? AND staff_id = ?', [$this->user['store_id'], $id]);
        $this->db->execute('DELETE FROM staff_accounts WHERE store_id = ? AND staff_id = ?', [$this->user['store_id'], $id]);
        foreach ($accounts as $account) {
            $this->db->execute('DELETE FROM users WHERE id = ?', [$account['user_id']]);
        }
    }

    private function orderRows(): array
    {
        $rows = $this->db->rows("SELECT payload FROM orders WHERE store_id = ? AND status = 'Completed' ORDER BY id DESC", [$this->user['store_id']]);
        return array_map(fn ($row) => json_decode($row['payload'], true, 512, JSON_THROW_ON_ERROR), $rows);
    }

    private function stockState(int $stock): string
    {
        return $stock === 0 ? 'outOfStock' : ($stock <= 10 ? 'lowStock' : 'inStock');
    }

    private function checkout(array $order): array
    {
        $id = $this->text($order, 'id');
        $hash = hash('sha256', json_encode($order, JSON_THROW_ON_ERROR));
        $order['id'] = $id;
        $existing = $this->db->rows('SELECT request_hash, payload, status FROM orders WHERE store_id = ? AND id = ?', [$this->user['store_id'], $id]);
        if ($existing !== []) {
            if ($existing[0]['request_hash'] !== $hash || $existing[0]['status'] !== 'Completed') {
                throw new ApiError(409, 'This sale identifier is already used.');
            }
            return $this->checkoutResult(json_decode($existing[0]['payload'], true, 512, JSON_THROW_ON_ERROR));
        }
        $lines = $order['lines'] ?? [];
        if (!is_array($lines) || !array_is_list($lines) || $lines === [] || count($lines) > 500) {
            throw new ApiError(422, 'A sale must have between 1 and 500 lines.');
        }
        $subtotal = 0;
        foreach ($lines as &$line) {
            if (!is_array($line)) {
                throw new ApiError(422, 'Invalid sale line.');
            }
            $code = $this->text($line, 'item_code');
            $quantity = $line['quantity'] ?? null;
            if (!is_int($quantity) || $quantity < 1 || $quantity > 1000000) {
                throw new ApiError(422, 'Quantity must be a positive integer.');
            }
            $products = $this->db->rows('SELECT * FROM products WHERE store_id = ? AND code = ?', [$this->user['store_id'], $code]);
            if ($products === [] || (int) $products[0]['stock_count'] < $quantity) {
                throw new ApiError(409, 'Insufficient stock for ' . $code . '. Refresh the inventory.');
            }
            $product = $products[0];
            $details = json_decode($product['payload'], true, 512, JSON_THROW_ON_ERROR);
            $line['item_name'] = $details['name'];
            $line['item_category'] = $details['category'] ?? '';
            $line['image_path'] = $details['image_path'] ?? null;
            $line['art_type'] = $details['art_type'];
            $line['item_size'] = (string) ($line['item_size'] ?? '');
            $line['unit_price'] = number_format((int) $product['price_cents'] / 100, 2, '.', '');
            $line['unit_price_value'] = (int) $product['price_cents'] / 100;
            if ($this->cents($line['unit_price_value'] ?? null) !== (int) $product['price_cents']) {
                throw new ApiError(409, 'The price changed for ' . $code . '. Refresh the inventory.');
            }
            $line['unit_cost'] = (int) $product['cost_cents'] / 100;
            $subtotal += (int) $product['price_cents'] * $quantity;
            if ($subtotal > 10000000000000) {
                throw new ApiError(422, 'The sale exceeds the supported total.');
            }
            $this->db->execute('UPDATE products SET stock_count = stock_count - ? WHERE store_id = ? AND code = ?', [$quantity, $this->user['store_id'], $code]);
        }
        unset($line);
        $discount = $this->cents($order['discount_amount'] ?? 0);
        if ($discount > 0) {
            $this->requirePermission('Discounts');
        }
        if ($discount > $subtotal || $this->cents($order['total'] ?? null) !== $subtotal - $discount) {
            throw new ApiError(422, 'The sale total does not match its items and discount.');
        }
        $total = $subtotal - $discount;
        $method = $order['payment_method'] ?? 'Cash';
        if (!in_array($method, ['Cash', 'Credit', 'Card', 'Mobile Money', 'M-Pesa', 'Bank Transfer'], true)) {
            throw new ApiError(422, 'Unsupported payment method.');
        }
        $cash = $this->cents($order['cash_tendered'] ?? 0);
        if ($method === 'Cash' && $cash < $total) {
            throw new ApiError(422, 'Cash tendered is less than the total.');
        }
        $customerId = null;
        if ($method === 'Credit') {
            $matches = array_values(array_filter($this->resourceRows('customers'), fn ($customer) => $customer['name'] === ($order['customer_name'] ?? '')));
            if (count($matches) !== 1) {
                throw new ApiError(422, 'Choose a unique customer credit account.');
            }
            $customer = $matches[0];
            $customerId = (string) $customer['id'];
            $customer['debit_balance'] = ($this->cents($customer['debit_balance'] ?? 0) + $total) / 100;
            $this->put('customers', $customerId, $customer);
            $this->bump('customers');
        }
        $order['cashier_name'] = $this->user['name'];
        $order['total'] = $total / 100;
        $order['discount_amount'] = $discount / 100;
        $order['status'] = 'Completed';
        $order['cash_tendered'] = $method === 'Cash' ? $cash / 100 : 0;
        $order['change_due'] = $method === 'Cash' ? ($cash - $total) / 100 : 0;
        $order['lines'] = $lines;
        $this->db->execute('INSERT INTO orders VALUES (?, ?, ?, ?, ?, ?, ?)', [$this->user['store_id'], $id, $hash, 'Completed', $total, $customerId, json_encode($order, JSON_THROW_ON_ERROR)]);
        foreach ($lines as $index => $line) {
            $this->db->execute('INSERT INTO order_lines VALUES (?, ?, ?, ?, ?, ?, ?, ?)', [$this->user['store_id'], $id, $index, $line['item_code'], $line['quantity'], $this->cents($line['unit_price_value']), $this->cents($line['unit_cost']), json_encode($line, JSON_THROW_ON_ERROR)]);
        }
        $this->replace($this->cartResource, []);
        $this->bump('products');
        $this->bump('orders');
        $this->bump($this->cartResource);
        return $this->checkoutResult($order);
    }

    private function checkoutResult(array $order): array
    {
        return [
            'data' => $order,
            'products' => $this->resourceRows('products'),
            'customers' => $this->resourceRows('customers'),
            'versions' => [
                'products' => $this->version('products'),
                'customers' => $this->version('customers'),
                'orders' => $this->version('orders'),
                'cart' => $this->version($this->cartResource),
            ],
        ];
    }

    private function voidOrder(string $id): array
    {
        $orders = $this->db->rows('SELECT * FROM orders WHERE store_id = ? AND id = ?', [$this->user['store_id'], $id]);
        if ($orders === []) {
            throw new ApiError(404, 'Sale not found.');
        }
        $order = $orders[0];
        if ($order['status'] === 'Voided') {
            return ['data' => ['voided' => true]];
        }
        $lines = $this->db->rows('SELECT * FROM order_lines WHERE store_id = ? AND order_id = ?', [$this->user['store_id'], $id]);
        foreach ($lines as $line) {
            $updated = $this->db->execute('UPDATE products SET stock_count = stock_count + ? WHERE store_id = ? AND code = ?', [$line['quantity'], $this->user['store_id'], $line['product_code']]);
            if ($updated !== 1) {
                throw new ApiError(409, 'Restore product ' . $line['product_code'] . ' before voiding this sale.');
            }
        }
        if ($order['customer_id'] !== null) {
            foreach ($this->resourceRows('customers') as $customer) {
                if ((string) $customer['id'] === $order['customer_id']) {
                    $customer['debit_balance'] = max(0, $this->cents($customer['debit_balance'] ?? 0) - (int) $order['total_cents']) / 100;
                    $this->put('customers', (string) $customer['id'], $customer);
                }
            }
            $this->bump('customers');
        }
        $this->db->execute("UPDATE orders SET status = 'Voided' WHERE store_id = ? AND id = ?", [$this->user['store_id'], $id]);
        $this->bump('products');
        $this->bump('orders');
        return ['data' => ['voided' => true]];
    }

    private function summary(): array
    {
        $orders = $this->db->rows("SELECT COUNT(*) AS sales, COALESCE(SUM(total_cents), 0) AS cents FROM orders WHERE store_id = ? AND status = 'Completed'", [$this->user['store_id']])[0];
        $expenses = array_sum(array_map(fn ($row) => $this->cents($row['amount']), $this->resourceRows('expenses')));
        return ['data' => ['sales' => (int) $orders['sales'], 'revenue' => (int) $orders['cents'] / 100, 'expenses' => $expenses / 100]];
    }

    private function registerDeviceToken(array $body): array
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
                [$this->user['store_id'], $this->user['id'] ?? null, $platform, $now, $token]
            );
        } else {
            $this->db->execute(
                'INSERT INTO device_tokens (store_id, user_id, token, platform, updated_at) VALUES (?, ?, ?, ?, ?)',
                [$this->user['store_id'], $this->user['id'] ?? null, $token, $platform, $now]
            );
        }

        return ['data' => ['registered' => true, 'platform' => $platform]];
    }

    private function getNotifications(): array
    {
        $rows = $this->db->rows(
            'SELECT * FROM push_notifications WHERE store_id = ? ORDER BY id DESC LIMIT 50',
            [$this->user['store_id']]
        );
        return ['data' => $rows];
    }

    private function dispatchPushNotification(array $body): array
    {
        $title = trim((string) ($body['title'] ?? ''));
        $message = trim((string) ($body['message'] ?? ''));
        $category = trim((string) ($body['category'] ?? 'general'));
        $payload = isset($body['payload']) ? (is_string($body['payload']) ? $body['payload'] : json_encode($body['payload'])) : null;

        if ($title === '' || $message === '') {
            throw new ApiError(422, 'Title and message are required.');
        }

        $now = gmdate('Y-m-d H:i:s');
        $this->db->execute(
            'INSERT INTO push_notifications (store_id, title, message, category, payload, created_at) VALUES (?, ?, ?, ?, ?, ?)',
            [$this->user['store_id'], $title, $message, $category, $payload, $now]
        );

        $tokens = $this->db->rows(
            'SELECT token, platform FROM device_tokens WHERE store_id = ?',
            [$this->user['store_id']]
        );

        return [
            'data' => [
                'delivered_to_tokens' => count($tokens),
                'title' => $title,
                'message' => $message,
                'category' => $category,
                'created_at' => $now,
            ]
        ];
    }
}
