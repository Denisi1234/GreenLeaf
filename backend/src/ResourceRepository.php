<?php
declare(strict_types=1);

final class ResourceRepository
{
    public const RESOURCES = [
        'profile', 'receipt-settings', 'tax-settings', 'roles', 'staff',
        'customers', 'debit-entries', 'expenses', 'register-shifts',
        'cash-movements', 'suppliers', 'receivings', 'receiving-lines',
        'suspended-sales', 'accounts', 'journal-entries', 'fixed-assets',
        'bank-transactions', 'audit-logs', 'stores',
        'recovery-sessions', 'learning-rules', 'cart', 'preferences',
    ];

    public function __construct(private Database $db)
    {
    }

    public function storeRevision(string $storeId): int
    {
        $rows = $this->db->rows('SELECT revision FROM stores WHERE id = ?', [$storeId]);
        return (int) ($rows[0]['revision'] ?? 0);
    }

    public function allVersions(string $storeId): array
    {
        $rows = $this->db->rows(
            'SELECT resource, version FROM resource_versions WHERE store_id = ?',
            [$storeId]
        );
        $versions = [];
        foreach ($rows as $row) {
            $versions[(string) $row['resource']] = (int) $row['version'];
        }
        return $versions;
    }

    public function resolveAccessibleStoreId(array $user, ?string $requestedStoreId): string
    {
        $primaryStoreId = (string) $user['store_id'];
        $candidate = trim((string) ($requestedStoreId ?? ''));
        if ($candidate === '' || $candidate === $primaryStoreId || $candidate === 'store-default') {
            return $primaryStoreId;
        }
        if (($user['role'] ?? '') !== 'owner') {
            throw new ApiError(403, 'Only store owners can switch store branches.');
        }
        // Verify branch belongs to this owner's primary store registry
        $branches = $this->resourceRows($primaryStoreId, 'stores');
        foreach ($branches as $branch) {
            if ((string) ($branch['id'] ?? '') === $candidate) {
                $this->ensureStoreRow($candidate, (string) ($branch['name'] ?? 'Branch'));
                return $candidate;
            }
        }
        throw new ApiError(403, 'Store branch not found or not accessible.');
    }

    public function ensureStoreRow(string $storeId, string $name = 'Store'): void
    {
        $exists = $this->db->rows('SELECT id FROM stores WHERE id = ?', [$storeId]);
        if ($exists !== []) {
            return;
        }
        $now = gmdate('c');
        $this->db->execute(
            'INSERT INTO stores (id, name, revision, created_at) VALUES (?, ?, 1, ?)',
            [$storeId, $name !== '' ? $name : 'Store', $now]
        );
    }

    public function listOwnerStores(array $user): array
    {
        $primaryStoreId = (string) $user['store_id'];
        $primaryRow = $this->db->rows('SELECT id, name FROM stores WHERE id = ?', [$primaryStoreId]);
        $primaryName = (string) ($primaryRow[0]['name'] ?? 'Main Store');
        $branches = $this->resourceRows($primaryStoreId, 'stores');
        $hasPrimary = false;
        foreach ($branches as $b) {
            if ((string) ($b['id'] ?? '') === $primaryStoreId) {
                $hasPrimary = true;
                break;
            }
        }
        if (!$hasPrimary) {
            array_unshift($branches, [
                'id' => $primaryStoreId,
                'name' => $primaryName,
                'address' => '',
                'contact' => '',
                'is_primary' => true,
            ]);
        }
        return $this->collection($primaryStoreId, 'stores', $branches);
    }

    public function createBranchStore(array $user, array $body): array
    {
        $primaryStoreId = (string) $user['store_id'];
        $name = trim((string) ($body['name'] ?? ''));
        if ($name === '') {
            throw new ApiError(422, 'Provide a store name.');
        }
        $id = trim((string) ($body['id'] ?? ''));
        if ($id === '' || strlen($id) > 100) {
            $id = 'store-' . bin2hex(random_bytes(8));
        }
        $record = [
            'id' => $id,
            'name' => $name,
            'address' => trim((string) ($body['address'] ?? '')),
            'contact' => trim((string) ($body['contact'] ?? '')),
            'created_at' => gmdate('c'),
        ];
        return $this->mutate($primaryStoreId, function () use ($user, $primaryStoreId, $id, $name, $record) {
            $this->ensureStoreRow($id, $name);
            $this->put($user, 'stores', $id, $record);
            $this->bump($primaryStoreId, 'stores');
            return $this->listOwnerStores($user);
        });
    }

    public function mutate(string $storeId, callable $operation): array
    {
        return $this->db->transaction(function () use ($storeId, $operation) {
            $this->db->execute('UPDATE stores SET revision = revision + 1 WHERE id = ?', [$storeId]);
            return $operation();
        });
    }

    public function version(string $storeId, string $resource): int
    {
        $rows = $this->db->rows(
            'SELECT version FROM resource_versions WHERE store_id = ? AND resource = ?',
            [$storeId, $resource]
        );
        return (int) ($rows[0]['version'] ?? 0);
    }

    public function bump(string $storeId, string $resource): void
    {
        $next = $this->version($storeId, $resource) + 1;
        $this->db->execute(
            'DELETE FROM resource_versions WHERE store_id = ? AND resource = ?',
            [$storeId, $resource]
        );
        $this->db->execute(
            'INSERT INTO resource_versions VALUES (?, ?, ?)',
            [$storeId, $resource, $next]
        );
    }

    public function collection(string $storeId, string $resource, array $items): array
    {
        return ['data' => array_values($items), 'version' => $this->version($storeId, $resource)];
    }

    public function resourceRows(string $storeId, string $resource): array
    {
        if ($resource === 'products') {
            $rows = $this->db->rows(
                'SELECT payload, stock_count FROM products WHERE store_id = ? ORDER BY code',
                [$storeId]
            );
            return array_map(function ($row) {
                $item = json_decode($row['payload'], true, 512, JSON_THROW_ON_ERROR);
                $item['stock_count'] = ApiValidator::normalizeQuantity((float) $row['stock_count']);
                $item['stock_state'] = ApiValidator::stockState($item['stock_count']);
                return $item;
            }, $rows);
        }
        $rows = $this->db->rows(
            'SELECT payload FROM records WHERE store_id = ? AND resource = ? ORDER BY position, record_id',
            [$storeId, $resource]
        );
        return array_map(fn ($row) => json_decode($row['payload'], true, 512, JSON_THROW_ON_ERROR), $rows);
    }

    public function replace(array $user, string $resource, array $items): void
    {
        $storeId = $user['store_id'];
        $ids = [];
        if ($resource === 'staff') {
            $keep = array_map(fn ($item) => (string) ($item['id'] ?? ''), $items);
            foreach ($this->db->rows('SELECT staff_id FROM staff_accounts WHERE store_id = ?', [$storeId]) as $account) {
                if (!in_array($account['staff_id'], $keep, true)) {
                    $this->deleteStaffAccount($storeId, $account['staff_id']);
                }
            }
        }
        if ($resource === 'products') {
            $this->db->execute('DELETE FROM products WHERE store_id = ?', [$storeId]);
        } else {
            $this->db->execute('DELETE FROM records WHERE store_id = ? AND resource = ?', [$storeId, $resource]);
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
            $this->put($user, $resource, $id, $item, $position);
        }
    }

    public function put(array $user, string $resource, string $id, array $item, int $position = 0): void
    {
        $storeId = $user['store_id'];
        if ($id === '' || strlen($id) > 200) {
            throw new ApiError(422, 'Invalid record identifier.');
        }
        unset($item['store_id']);
        if ($resource === 'products') {
            $item['code'] = $id;
            ApiValidator::text($item, 'name');
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
            if ((!is_int($stock) && !is_float($stock)) || !is_finite((float) $stock) || $stock < 0 || $stock > 2147483647) {
                throw new ApiError(422, 'Stock must be a non-negative number.');
            }
            $normalizedStock = ApiValidator::normalizeQuantity((float) $stock);
            $item['stock_count'] = $normalizedStock;
            $price = ApiValidator::cents($item['selling_price'] ?? null);
            $cost = ApiValidator::cents($item['purchase_price'] ?? null);
            $this->db->execute('DELETE FROM products WHERE store_id = ? AND code = ?', [$storeId, $id]);
            $this->db->execute(
                'INSERT INTO products VALUES (?, ?, ?, ?, ?, ?)',
                [$storeId, $id, $normalizedStock, $price, $cost, json_encode($item, JSON_THROW_ON_ERROR)]
            );
            return;
        }
        if ($resource === 'customers') {
            $item['id'] = $id;
            ApiValidator::text($item, 'name');
            ApiValidator::cents($item['debit_balance'] ?? 0);
        }
        if ($resource === 'staff') {
            $item['id'] = $id;
            $this->checkRoleGrant($user, (string) ($item['role_id'] ?? ''));
            unset($item['password_hash'], $item['password_salt']);
            $this->staffAccount($user, $id, $item);
        }
        if ($resource === 'roles' && $user['role'] !== 'owner') {
            $permissions = json_decode($item['permissions_json'] ?? '[]', true, 512, JSON_THROW_ON_ERROR);
            if (!is_array($permissions) || array_diff($permissions, $user['permissions'] ?? []) !== []) {
                throw new ApiError(403, 'You cannot grant permissions beyond your own role.');
            }
        }
        if ($resource === 'expenses') {
            if (!ctype_digit($id) || (int) $id < 1) {
                throw new ApiError(422, 'An expense requires a positive integer identifier.');
            }
            $item['id'] = (int) $id;
            ApiValidator::text($item, 'title');
            ApiValidator::cents($item['amount'] ?? null);
        }
        if ($resource === 'receipt-settings') {
            $item['header'] = (string) ($item['header'] ?? '');
            $item['footer'] = (string) ($item['footer'] ?? '');
            if (preg_match('/\A.{0,160}\z/us', $item['header']) !== 1) {
                throw new ApiError(422, 'Receipt header is too long.');
            }
            if (preg_match('/\A.{0,160}\z/us', $item['footer']) !== 1) {
                throw new ApiError(422, 'Receipt footer is too long.');
            }
            foreach ([
                'show_store_contact',
                'show_tax_id',
                'show_order_number',
                'show_date_time',
                'show_cashier',
                'show_customer',
                'show_payment_method',
                'show_item_count',
                'show_discount',
            ] as $flagKey) {
                $item[$flagKey] = !array_key_exists($flagKey, $item) ? 1 : (empty($item[$flagKey]) ? 0 : 1);
            }
        }
        if ($resource === 'tax-settings') {
            $item['enabled'] = empty($item['enabled']) ? 0 : 1;
            $item['rate_percent'] = max(0.0, min(100.0, (float) ($item['rate_percent'] ?? 0)));
            $item['prices_include_tax'] = !array_key_exists('prices_include_tax', $item) || !empty($item['prices_include_tax']) ? 1 : 0;
            $item['tax_id'] = substr(trim((string) ($item['tax_id'] ?? '')), 0, 80);
            $item['tax_label'] = substr(trim((string) ($item['tax_label'] ?? 'VAT')), 0, 40) ?: 'VAT';
            $item['track_expense_tax'] = !array_key_exists('track_expense_tax', $item) || !empty($item['track_expense_tax']) ? 1 : 0;
        }
        $this->db->execute(
            'DELETE FROM records WHERE store_id = ? AND resource = ? AND record_id = ?',
            [$storeId, $resource, $id]
        );
        $this->db->execute(
            'INSERT INTO records VALUES (?, ?, ?, ?, ?)',
            [$storeId, $resource, $id, $position, json_encode($item, JSON_THROW_ON_ERROR)]
        );
    }

    public function delete(string $storeId, string $resource, string $id): void
    {
        if ($resource === 'staff') {
            $this->deleteStaffAccount($storeId, $id);
        }
        if ($resource === 'products') {
            $this->db->execute('DELETE FROM products WHERE store_id = ? AND code = ?', [$storeId, $id]);
            return;
        }
        $this->db->execute(
            'DELETE FROM records WHERE store_id = ? AND resource = ? AND record_id = ?',
            [$storeId, $resource, $id]
        );
    }

    public function staffAccount(array $user, string $id, array &$staff, ?string $password = null): void
    {
        $storeId = $user['store_id'];
        $this->checkRoleGrant($user, (string) ($staff['role_id'] ?? ''));
        $accounts = $this->db->rows(
            'SELECT user_id FROM staff_accounts WHERE store_id = ? AND staff_id = ?',
            [$storeId, $id]
        );
        if ($accounts === [] && $password === null) {
            return;
        }
        $email = strtolower(ApiValidator::text($staff, 'email'));
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new ApiError(422, 'Enter a valid staff email.');
        }
        $name = ApiValidator::text($staff, 'name');
        $active = ($staff['status'] ?? 'active') === 'active' ? 1 : 0;
        if ($accounts === []) {
            $userId = bin2hex(random_bytes(16));
            $this->db->execute(
                'INSERT INTO users (id, store_id, name, email, password_hash, role, active, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
                [$userId, $storeId, $name, $email, password_hash($password, PASSWORD_DEFAULT), 'cashier', $active, gmdate('c')]
            );
            $this->db->execute('INSERT INTO staff_accounts VALUES (?, ?, ?)', [$storeId, $id, $userId]);
        } else {
            $userId = $accounts[0]['user_id'];
            $this->db->execute(
                'UPDATE users SET name = ?, email = ?, active = ? WHERE id = ?',
                [$name, $email, $active, $userId]
            );
            if ($password !== null) {
                $this->db->execute(
                    'UPDATE users SET password_hash = ? WHERE id = ?',
                    [password_hash($password, PASSWORD_DEFAULT), $userId]
                );
            }
            if ($password !== null || $active === 0) {
                $this->db->execute('DELETE FROM access_tokens WHERE user_id = ?', [$userId]);
            }
        }
        $staff['password_hash'] = 'server-managed';
        $staff['password_salt'] = '';
    }

    public function checkRoleGrant(array $user, string $roleId): void
    {
        if ($user['role'] === 'owner') {
            return;
        }
        $roles = $this->db->rows(
            "SELECT payload FROM records WHERE store_id = ? AND resource = 'roles' AND record_id = ?",
            [$user['store_id'], $roleId]
        );
        $role = $roles === [] ? [] : json_decode($roles[0]['payload'], true, 512, JSON_THROW_ON_ERROR);
        $permissions = json_decode($role['permissions_json'] ?? '[]', true, 512, JSON_THROW_ON_ERROR);
        if (!is_array($permissions) || array_diff($permissions, $user['permissions'] ?? []) !== []) {
            throw new ApiError(403, 'You cannot assign a role with permissions beyond your own.');
        }
    }

    public function deleteStaffAccount(string $storeId, string $id): void
    {
        $accounts = $this->db->rows(
            'SELECT user_id FROM staff_accounts WHERE store_id = ? AND staff_id = ?',
            [$storeId, $id]
        );
        $this->db->execute('DELETE FROM staff_accounts WHERE store_id = ? AND staff_id = ?', [$storeId, $id]);
        foreach ($accounts as $account) {
            $this->db->execute('DELETE FROM users WHERE id = ?', [$account['user_id']]);
        }
    }
}
