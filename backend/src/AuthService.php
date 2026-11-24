<?php
declare(strict_types=1);

final class AuthService
{
    public function __construct(
        private Database $db,
        private array $config,
        private ResourceRepository $resources,
        private SmsService $sms,
    ) {
    }

    public function authenticate(string $token): array
    {
        $rows = $this->db->rows(
            'SELECT u.* FROM users u JOIN access_tokens t ON t.user_id = u.id WHERE t.token_hash = ? AND t.expires_at > ? AND u.active = 1',
            [hash('sha256', $token), time()]
        );
        if ($token === '' || $rows === []) {
            throw new ApiError(401, 'Sign in to continue.');
        }
        $user = $rows[0];
        $user['permissions'] = ['View Sales'];
        $links = $this->db->rows(
            "SELECT r.payload FROM staff_accounts a JOIN records r ON r.store_id = a.store_id AND r.record_id = a.staff_id AND r.resource = 'staff' WHERE a.user_id = ?",
            [$user['id']]
        );
        if ($links !== []) {
            $staff = json_decode($links[0]['payload'], true, 512, JSON_THROW_ON_ERROR);
            $roles = $this->db->rows(
                "SELECT payload FROM records WHERE store_id = ? AND resource = 'roles' AND record_id = ?",
                [$user['store_id'], $staff['role_id'] ?? '']
            );
            $role = $roles === [] ? [] : json_decode($roles[0]['payload'], true, 512, JSON_THROW_ON_ERROR);
            $user['permissions'] = json_decode($role['permissions_json'] ?? '[]', true, 512, JSON_THROW_ON_ERROR);
        }
        return [
            'user' => $user,
            'cartResource' => 'cart:' . substr(hash('sha256', $token), 0, 32),
        ];
    }

    public function requireOwner(array $user): void
    {
        if ($user['role'] !== 'owner') {
            throw new ApiError(403, 'This action requires the business owner.');
        }
    }

    public function requirePermission(array $user, string $permission): void
    {
        if ($user['role'] !== 'owner' && !in_array($permission, $user['permissions'] ?? [], true)) {
            throw new ApiError(403, 'This action requires ' . $permission . ' permission.');
        }
    }

    public function requireAny(array $user, array $permissions): void
    {
        if ($user['role'] !== 'owner' && array_intersect($permissions, $user['permissions'] ?? []) === []) {
            throw new ApiError(403, 'Your account does not have permission for this action.');
        }
    }

    public function checkPassword(string $password): void
    {
        if (strlen($password) < 6 || strlen($password) > 72) {
            throw new ApiError(422, 'Nenosiri lazima liwe na herufi kuanzia 6.');
        }
    }

    public function publicUser(array $user): array
    {
        return array_intersect_key($user, array_flip(['id', 'store_id', 'name', 'phone', 'role', 'permissions']));
    }

    public function throttle(string $key): void
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

    public function register(array $body): array
    {
        if (!$this->config['registration']) {
            throw new ApiError(403, 'Account registration is disabled.');
        }
        [$phone, $password] = $this->credentials($body);
        $name = ApiValidator::text($body, 'name');
        $storeName = trim((string) ($body['store_name'] ?? '')) ?: ($name . "'s Shop");
        $this->checkPassword($password);

        if ($this->db->rows('SELECT id FROM users WHERE email = ?', [$phone]) !== []) {
            throw new ApiError(409, 'An account with this phone number already exists.');
        }

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

        $res = $this->db->transaction(function () use ($phone, $password, $name, $storeName) {
            $this->db->execute('DELETE FROM otp_verifications WHERE phone = ?', [$phone]);
            $storeId = bin2hex(random_bytes(16));
            $userId = bin2hex(random_bytes(16));
            $created = gmdate('c');
            $this->db->execute('INSERT INTO stores (id, name, created_at) VALUES (?, ?, ?)', [$storeId, $storeName, $created]);
            $this->db->execute(
                'INSERT INTO users (id, store_id, name, email, password_hash, role, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
                [$userId, $storeId, $name, $phone, password_hash($password, PASSWORD_DEFAULT), 'owner', $created]
            );
            $user = ['id' => $userId, 'store_id' => $storeId, 'name' => $name, 'email' => $phone, 'role' => 'owner'];
            $this->resources->put($user, 'profile', '1', [
                'store_name' => $storeName, 'owner_name' => $name, 'role_title' => 'Owner',
                'email_address' => $phone, 'contact_number' => $phone, 'physical_address' => '',
                'business_category' => 'Retail', 'member_since' => $created, 'open_24_hours' => 0,
            ]);
            $this->resources->put($user, 'receipt-settings', '1', ['show_store_contact' => 1, 'footer' => '']);

            $staffId = 'staff-' . $userId;
            $this->resources->put($user, 'staff', $staffId, [
                'id' => $staffId,
                'name' => $name,
                'email' => $phone,
                'phone' => $phone,
                'role_id' => 'owner',
                'username' => $phone,
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

            return $this->issueToken($user);
        });

        if ($phone !== '') {
            $welcomeText = "Habari $name, Karibu TrackMauzo! Duka lako '$storeName' limesajiliwa kwa mafanikio. Tumia namba hii kuingia.";
            $this->sms->send($phone, $welcomeText);
        }

        return $res;
    }

    public function login(array $body): array
    {
        [$phone, $password] = $this->credentials($body);

        $rows = $this->db->rows(
            'SELECT * FROM users WHERE (email = ? OR email = ?) AND active = 1',
            [$phone, $phone . '@trackmauzo.app']
        );
        $hash = $rows[0]['password_hash'] ?? '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2uheWG/igi.';
        if (!password_verify($password, $hash) || $rows === []) {
            throw new ApiError(401, 'Namba ya simu au nenosiri si sahihi.');
        }
        return $this->issueToken($rows[0]);
    }

    public function logout(string $token): array
    {
        $this->db->execute('DELETE FROM access_tokens WHERE token_hash = ?', [hash('sha256', $token)]);
        return ['data' => ['logged_out' => true]];
    }

    public function createUser(array $ownerUser, array $body): array
    {
        [$phone, $password] = $this->credentials($body);
        $this->checkPassword($password);
        $name = ApiValidator::text($body, 'name');
        $id = bin2hex(random_bytes(16));
        $this->db->execute(
            'INSERT INTO users (id, store_id, name, email, password_hash, role, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [$id, $ownerUser['store_id'], $name, $phone, password_hash($password, PASSWORD_DEFAULT), 'cashier', gmdate('c')]
        );
        return ['data' => ['id' => $id, 'phone' => $phone, 'name' => $name, 'role' => 'cashier']];
    }

    public function sendOtp(array $body): array
    {
        $rawPhone = (string) ($body['phone'] ?? '');
        $phone = ApiValidator::formatTanzanianPhone($rawPhone);
        $purpose = strtolower(trim((string) ($body['purpose'] ?? '')));

        if ($purpose === 'register') {
            if ($this->isPhoneRegistered($phone)) {
                throw new ApiError(409, 'Namba hii ya simu tayari imesajiliwa. Tafadhali ingia (Sign in).');
            }
        } else {
            if (!$this->isPhoneRegistered($phone)) {
                throw new ApiError(404, 'Namba hii ya simu haijasajiliwa kwenye mfumo.');
            }
        }

        $this->db->execute(
            'CREATE TABLE IF NOT EXISTS otp_verifications (
                phone VARCHAR(32) PRIMARY KEY,
                code_hash VARCHAR(64) NOT NULL,
                attempts INTEGER NOT NULL DEFAULT 0,
                expires_at INTEGER NOT NULL,
                created_at VARCHAR(32) NOT NULL
            )'
        );

        $existing = $this->db->rows('SELECT expires_at FROM otp_verifications WHERE phone = ?', [$phone]);
        if ($existing !== []) {
            $sentAt = (int) $existing[0]['expires_at'] - 600;
            if ((time() - $sentAt) < 60) {
                throw new ApiError(429, 'Tafadhali subiri sekunde 60 kabla ya kuomba namba nyingine ya uthibitisho.');
            }
        }

        $code = (string) random_int(100000, 999999);
        $hash = hash('sha256', $phone . ':' . $code);
        $expires = time() + 600;

        $this->db->execute('DELETE FROM otp_verifications WHERE phone = ? OR expires_at < ?', [$phone, time()]);
        $this->db->execute(
            'INSERT INTO otp_verifications (phone, code_hash, attempts, expires_at, created_at) VALUES (?, ?, 0, ?, ?)',
            [$phone, $hash, $expires, gmdate('c')]
        );

        $smsText = "Namba yako ya uthibitisho ya TrackMauzo (OTP) ni $code. Usitoe namba hii kwa mtu yeyote.";
        if (!$this->sms->send($phone, $smsText)) {
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

    public function verifyOtp(array $body): array
    {
        $rawPhone = (string) ($body['phone'] ?? '');
        $code = trim((string) ($body['code'] ?? ''));
        $phone = ApiValidator::formatTanzanianPhone($rawPhone);

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

    public function resetPasswordWithOtp(array $body): array
    {
        $rawPhone = (string) ($body['phone'] ?? '');
        $resetToken = trim((string) ($body['reset_token'] ?? ''));
        $newPassword = $body['new_password'] ?? '';
        $phone = ApiValidator::formatTanzanianPhone($rawPhone);

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

        $this->db->execute('DELETE FROM otp_verifications WHERE phone = ?', [$phone]);

        $updated = false;
        $newHash = password_hash($newPassword, PASSWORD_DEFAULT);

        // Update owner or direct user account matched by phone or synthetic email
        $userRows = $this->db->rows(
            'SELECT id FROM users WHERE (email = ? OR email = ?) AND active = 1',
            [$phone, $phone . '@trackmauzo.app']
        );
        foreach ($userRows as $uRow) {
            $this->db->execute('UPDATE users SET password_hash = ? WHERE id = ?', [$newHash, $uRow['id']]);
            $updated = true;
        }

        // Also update any linked staff account
        $staffRows = $this->db->rows("SELECT * FROM records WHERE resource = 'staff'");
        foreach ($staffRows as $sRow) {
            $staff = json_decode($sRow['payload'], true);
            if (is_array($staff)) {
                $stPhone = preg_replace('/\D+/', '', (string) ($staff['phone'] ?? ''));
                if ($stPhone !== '' && (str_ends_with($phone, $stPhone) || str_ends_with($stPhone, substr($phone, 3)))) {
                    $acc = $this->db->rows(
                        'SELECT user_id FROM staff_accounts WHERE staff_id = ? AND store_id = ?',
                        [$sRow['record_id'], $sRow['store_id']]
                    );
                    if ($acc !== []) {
                        $this->db->execute(
                            'UPDATE users SET password_hash = ? WHERE id = ?',
                            [$newHash, $acc[0]['user_id']]
                        );
                        $updated = true;
                    }
                }
            }
        }

        if (!$updated) {
            throw new ApiError(404, 'Akaunti yenye namba hii ya simu haikupatikana.');
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

    private function credentials(array $body): array
    {
        $rawIdentifier = trim((string) ($body['phone'] ?? $body['username'] ?? ''));
        $password = $body['password'] ?? '';
        if ($rawIdentifier === '' || !is_string($password)) {
            throw new ApiError(422, 'Enter your phone number and password.');
        }

        $identifier = ApiValidator::formatTanzanianPhone($rawIdentifier);
        return [$identifier, $password];
    }

    private function isPhoneRegistered(string $phone): bool
    {
        if (
            $this->db->rows(
                'SELECT id FROM users WHERE (email = ? OR email = ?) AND active = 1',
                [$phone, $phone . '@trackmauzo.app']
            ) !== []
        ) {
            return true;
        }

        $staffRows = $this->db->rows("SELECT payload FROM records WHERE resource = 'staff'");
        foreach ($staffRows as $sRow) {
            $staff = json_decode($sRow['payload'], true);
            if (!is_array($staff)) {
                continue;
            }
            $stPhone = preg_replace('/\D+/', '', (string) ($staff['phone'] ?? ''));
            if ($stPhone !== '' && (str_ends_with($phone, $stPhone) || str_ends_with($stPhone, substr($phone, 3)))) {
                return true;
            }
        }
        return false;
    }

    private function issueToken(array $user): array
    {
        $token = bin2hex(random_bytes(32));
        $expires = time() + $this->config['token_hours'] * 3600;
        $this->db->execute('DELETE FROM access_tokens WHERE expires_at <= ?', [time()]);
        $this->db->execute(
            'INSERT INTO access_tokens (token_hash, user_id, expires_at) VALUES (?, ?, ?)',
            [hash('sha256', $token), $user['id'], $expires]
        );
        $auth = $this->authenticate($token);
        return [
            'data' => [
                'token' => $token,
                'expires_at' => $expires,
                'user' => $this->publicUser($auth['user']),
            ],
        ];
    }
}
