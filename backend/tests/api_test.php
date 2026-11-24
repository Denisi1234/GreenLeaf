<?php
declare(strict_types=1);

require __DIR__ . '/../src/Database.php';
require __DIR__ . '/../src/Api.php';
$config = ['dsn' => 'sqlite::memory:', 'user' => '', 'password' => '', 'registration' => true, 'token_hours' => 12];
$db = new Database($config);
$db->migrate();
$api = new Api($db, $config);
$passed = 0;
function check(bool $condition, string $message): void
{
    global $passed;
    if (!$condition) {
        throw new RuntimeException($message);
    }
    $passed++;
}
function callApi(string $method, string $path, array $body = [], string $token = '', ?int $version = null, ?string $storeId = null): array
{
    global $api;
    return $api->dispatch($method, $path, $body, $token, $version, 'local', $storeId);
}
function rejected(int $status, callable $operation): void
{
    try {
        $operation();
    } catch (ApiError $error) {
        check($error->status === $status, 'Wrong rejection status: ' . $error->getMessage());
        return;
    }
    throw new RuntimeException('Expected request rejection.');
}

function seedOtp(string $phone, string $token): void
{
    global $db;
    $db->execute(
        'INSERT OR REPLACE INTO otp_verifications (phone, code_hash, attempts, expires_at, created_at) VALUES (?, ?, 0, ?, ?)',
        [$phone, hash('sha256', 'verified:' . $token), time() + 600, gmdate('c')]
    );
}

rejected(401, fn () => callApi('GET', 'products'));
rejected(422, fn () => callApi('POST', 'auth/register', [
    'phone' => '0712345678', 'password' => 'short', 'name' => 'Owner', 'store_name' => 'Shop',
]));
$ownerPhone = ApiValidator::formatTanzanianPhone('0712345678');
$ownerOtp = 'owner-otp-token';
seedOtp($ownerPhone, $ownerOtp);
$auth = callApi('POST', 'auth/register', [
    'phone' => '0712345678', 'password' => 'Testing-long-password',
    'name' => 'Owner', 'store_name' => 'First Shop', 'otp_token' => $ownerOtp,
])['data'];
$token = $auth['token'];
check($db->rows('SELECT token_hash FROM access_tokens')[0]['token_hash'] !== $token, 'Tokens must be hashed at rest.');
check(password_verify('Testing-long-password', $db->rows('SELECT password_hash FROM users')[0]['password_hash']), 'Password hashing failed.');
$ownerLink = $db->rows(
    'SELECT users.role FROM users JOIN staff_accounts ON staff_accounts.user_id = users.id WHERE users.email = ?',
    [$ownerPhone]
);
check(count($ownerLink) === 1 && $ownerLink[0]['role'] === 'owner', 'Owner staff must link to the existing owner account.');
rejected(409, fn () => callApi('POST', 'auth/register', [
    'phone' => '0712345678', 'password' => 'Testing-long-password',
    'name' => 'Owner', 'store_name' => 'Duplicate Shop', 'otp_token' => $ownerOtp,
]));
$otherPhone = ApiValidator::formatTanzanianPhone('0712345679');
$otherOtp = 'other-otp-token';
seedOtp($otherPhone, $otherOtp);
$otherToken = callApi('POST', 'auth/register', [
    'phone' => '0712345679', 'password' => 'Testing-long-password',
    'name' => 'Other', 'store_name' => 'Second Shop', 'otp_token' => $otherOtp,
])['data']['token'];
$product = [
    'code' => 'P1', 'name' => 'Water', 'category' => 'Drinks', 'selling_price' => 10,
    'purchase_price' => 6, 'stock_count' => 3, 'stock_state' => 'lowStock',
    'art_type' => 'aquafina', 'category_data_json' => '{}',
];
callApi('PUT', 'products', ['items' => [$product]], $token, 0);
check(callApi('GET', 'products', [], $otherToken)['data'] === [], 'Shops must be isolated.');
rejected(409, fn () => callApi('PUT', 'products', ['items' => []], $token, 0));
check(count(callApi('GET', 'products', [], $token)['data']) === 1, 'Stale writes must preserve data.');
callApi('PUT', 'customers', ['items' => [['id' => 'C1', 'name' => 'Asha', 'debit_balance' => 0]]], $token, 0);
$sale = [
    'id' => 'ORDER-1', 'date_time' => gmdate('c'), 'date_label' => '2026-11-11',
    'time_label' => '12:00', 'cashier_name' => 'Spoofed', 'register_name' => 'Till 1',
    'total' => 20, 'cash_tendered' => 20, 'change_due' => 0, 'payment_method' => 'Credit',
    'customer_name' => 'Asha', 'lines' => [[
        'item_code' => 'P1', 'item_name' => 'Water', 'item_category' => 'Drinks',
        'item_size' => '1 bottle', 'quantity' => 2, 'unit_price' => '10',
        'unit_price_value' => 10, 'art_type' => 'aquafina',
    ]],
];
$saved = callApi('POST', 'checkout', $sale, $token)['data'];
check($saved['cashier_name'] === 'Owner', 'Server must identify the cashier.');
check(callApi('GET', 'products', [], $token)['data'][0]['stock_count'] === 1, 'Checkout must decrement stock.');
check(callApi('GET', 'customers', [], $token)['data'][0]['debit_balance'] == 20, 'Credit sale must update the customer.');
callApi('POST', 'checkout', $sale, $token);
check(count(callApi('GET', 'orders', [], $token)['data']) === 1, 'Sale retries must be idempotent.');
check(callApi('GET', 'products', [], $token)['data'][0]['stock_count'] === 1, 'Retries must not decrement stock again.');
rejected(404, fn () => callApi('POST', 'orders/ORDER-1/void', [], $otherToken));
$tooLarge = $sale;
$tooLarge['id'] = 'ORDER-2';
rejected(409, fn () => callApi('POST', 'checkout', $tooLarge, $token));
check(count(callApi('GET', 'orders', [], $token)['data']) === 1, 'Failed sales must roll back.');
$badTotal = $sale;
$badTotal['id'] = 'BAD-TOTAL';
$badTotal['lines'][0]['quantity'] = 1;
$badTotal['total'] = 1;
rejected(422, fn () => callApi('POST', 'checkout', $badTotal, $token));
check(callApi('GET', 'products', [], $token)['data'][0]['stock_count'] === 1, 'Total validation must roll back stock.');
callApi('POST', 'orders/ORDER-1/void', [], $token);
callApi('POST', 'orders/ORDER-1/void', [], $token);
check(callApi('GET', 'products', [], $token)['data'][0]['stock_count'] === 3, 'Voiding twice must restore stock once.');
check(callApi('GET', 'customers', [], $token)['data'][0]['debit_balance'] == 0, 'Voiding credit must reverse the debt.');
callApi('POST', 'expenses', ['title' => 'Transport', 'amount' => 5, 'id' => null], $token);
check(count(callApi('GET', 'expenses', [], $token)['data']) === 1, 'Expense persistence failed.');
callApi('PUT', 'receipt-settings/1', [
    'footer' => 'Karibu tena',
    'header' => 'Asante sana',
    'show_store_contact' => 0,
    'show_tax_id' => 0,
    'show_discount' => 0,
], $token);
$savedReceipt = callApi('GET', 'receipt-settings', [], $token)['data'][0];
check($savedReceipt['footer'] === 'Karibu tena', 'Receipt settings persistence failed.');
check($savedReceipt['header'] === 'Asante sana', 'Receipt header persistence failed.');
check($savedReceipt['show_tax_id'] === 0 && $savedReceipt['show_discount'] === 0, 'Receipt toggle flags persistence failed.');
callApi('PUT', 'tax-settings/1', [
    'enabled' => 1,
    'rate_percent' => 18.0,
    'prices_include_tax' => 0,
    'tax_id' => 'TIN-999',
    'tax_label' => 'VAT',
    'track_expense_tax' => 1,
], $token);
$savedTax = callApi('GET', 'tax-settings', [], $token)['data'][0];
check($savedTax['enabled'] === 1 && (float) $savedTax['rate_percent'] === 18.0 && $savedTax['tax_id'] === 'TIN-999', 'Tax settings persistence failed.');
callApi('POST', 'products/stock-delta', ['deltas' => ['P1' => 5]], $token);
check(callApi('GET', 'products', [], $token)['data'][0]['stock_count'] === 8, 'Atomic stock delta increment failed.');
callApi('POST', 'products/stock-delta', ['deltas' => ['P1' => -5]], $token);
check(callApi('GET', 'products', [], $token)['data'][0]['stock_count'] === 3, 'Atomic stock delta decrement failed.');
$cashierPhone = ApiValidator::formatTanzanianPhone('0713000001');
callApi('POST', 'auth/users', ['name' => 'Cashier', 'phone' => $cashierPhone, 'password' => 'Testing-long-password'], $token);
$cashier = callApi('POST', 'auth/login', ['phone' => $cashierPhone, 'password' => 'Testing-long-password'])['data']['token'];
rejected(403, fn () => callApi('PUT', 'products/P2', $product, $cashier));
check(count(callApi('GET', 'products', [], $cashier)['data']) === 1, 'Cashier product access failed.');
callApi('POST', 'auth/logout', [], $cashier);
rejected(401, fn () => callApi('GET', 'products', [], $cashier));
rejected(401, fn () => callApi('POST', 'auth/login', ['phone' => $ownerPhone, 'password' => 'incorrect']));
$login = callApi('POST', 'auth/login', ['phone' => $ownerPhone, 'password' => 'Testing-long-password']);
check(isset($login['data']['token']), 'Login failed.');
$staffPhone = ApiValidator::formatTanzanianPhone('0713000002');
$staff = [
    'id' => 'STAFF-1', 'name' => 'Neema', 'phone' => '0713000002',
    'status' => 'active', 'role_id' => 'cashier',
];
callApi('POST', 'staff/STAFF-1/account', ['staff' => $staff, 'password' => 'Another-long-password'], $token);
$staffToken = callApi('POST', 'auth/login', ['phone' => $staffPhone, 'password' => 'Another-long-password'])['data']['token'];
check(callApi('GET', 'auth/me', [], $staffToken)['data']['role'] === 'cashier', 'Staff login creation failed.');
$staff['status'] = 'inactive';
callApi('PUT', 'staff/STAFF-1', $staff, $token);
rejected(401, fn () => callApi('GET', 'auth/me', [], $staffToken));
rejected(401, fn () => callApi('POST', 'auth/login', ['phone' => $staffPhone, 'password' => 'Another-long-password']));
$staff['status'] = 'active';
callApi('POST', 'staff/STAFF-1/account', ['staff' => $staff, 'password' => 'Changed-long-password'], $token);
check(isset(callApi('POST', 'auth/login', ['phone' => $staffPhone, 'password' => 'Changed-long-password'])['data']['token']), 'Staff password reset failed.');
$image = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl6l0sAAAAASUVORK5CYII=';
$uploadResult = callApi('POST', 'uploads', ['content' => $image], $token)['data'];
$upload = $uploadResult['id'];
check($uploadResult['path'] === 'uploads/' . $upload, 'Upload response must expose a stable relative path.');
check(callApi('POST', 'uploads', ['content' => $image], $token)['data']['id'] === $upload, 'Duplicate uploads must be idempotent.');
check(callApi('GET', 'uploads/' . $upload, [], $token)['image'] === $image, 'Image upload failed.');
rejected(404, fn () => callApi('GET', 'uploads/' . $upload, [], $otherToken));
rejected(422, fn () => callApi('POST', 'uploads', ['content' => base64_encode('<?php echo 1;')], $token));
$branch = callApi('POST', 'stores', ['name' => 'Upload Branch'], $token)['data'];
$branchId = '';
foreach ($branch as $row) {
    if (($row['name'] ?? '') === 'Upload Branch') {
        $branchId = (string) $row['id'];
    }
}
check($branchId !== '', 'Branch creation for uploads failed.');
$branchUpload = callApi('POST', 'uploads', ['content' => $image], $token, null, $branchId)['data']['id'];
check(callApi('GET', 'uploads/' . $branchUpload, [], $token)['image'] === $image, 'Branch images must be readable without an X-Store-Id header.');
rejected(404, fn () => callApi('GET', 'uploads/' . $branchUpload, [], $otherToken));
callApi('PUT', 'roles/manager', [
    'id' => 'manager', 'permissions_json' => json_encode(['View Sales', 'Manage Inventory', 'Manage Staff']),
], $token);
callApi('PUT', 'roles/admin', [
    'id' => 'admin', 'permissions_json' => json_encode(['View Sales', 'System Settings', 'Manage Staff']),
], $token);
$managerPhone = ApiValidator::formatTanzanianPhone('0713000003');
$managerRecord = [
    'id' => 'MANAGER-1', 'name' => 'Manager', 'phone' => '0713000003',
    'status' => 'active', 'role_id' => 'manager',
];
callApi('POST', 'staff/MANAGER-1/account', ['staff' => $managerRecord, 'password' => 'Manager-long-password'], $token);
$manager = callApi('POST', 'auth/login', ['phone' => $managerPhone, 'password' => 'Manager-long-password'])['data']['token'];
callApi('PUT', 'products/P1', $product, $manager);
check(count(callApi('GET', 'products', [], $manager)['data']) === 1, 'Assigned inventory permission must work.');
$escalated = $managerRecord;
$escalated['role_id'] = 'admin';
rejected(403, fn () => callApi('PUT', 'staff/MANAGER-1', $escalated, $manager));
rejected(403, fn () => callApi('PUT', 'receipt-settings/1', ['footer' => 'Unauthorized'], $manager));
$sugar = [
    'code' => 'P-SUGAR', 'name' => 'Sukari', 'category' => 'Groceries', 'selling_price' => 3200,
    'purchase_price' => 2800, 'stock_count' => 100, 'stock_state' => 'inStock',
    'art_type' => 'kelloggs',
    'category_data_json' => json_encode(['unit' => 'kg', 'allow_fractional' => true, 'pack_name' => 'Mfuko', 'pack_size' => 100]),
];
callApi('POST', 'products', $sugar, $token);
$fractionalSale = [
    'id' => 'ORDER-FRAC-1', 'date_time' => gmdate('c'), 'date_label' => '2026-11-21',
    'time_label' => '12:00', 'cashier_name' => 'Owner', 'register_name' => 'Till 1',
    'total' => 800, 'cash_tendered' => 1000, 'change_due' => 200, 'payment_method' => 'Cash',
    'lines' => [[
        'item_code' => 'P-SUGAR', 'item_name' => 'Sukari', 'item_category' => 'Groceries',
        'item_size' => 'per kg', 'item_unit' => 'kg', 'quantity' => 0.25, 'unit_price' => '3200.00',
        'unit_price_value' => 3200, 'art_type' => 'kelloggs',
    ]],
];
callApi('POST', 'checkout', $fractionalSale, $token);
$sugarAfter = array_values(array_filter(callApi('GET', 'products', [], $token)['data'], fn ($p) => $p['code'] === 'P-SUGAR'))[0];
check(abs((float) $sugarAfter['stock_count'] - 99.75) < 0.001, 'Fractional checkout must deduct 0.25 kg.');
callApi('POST', 'orders/ORDER-FRAC-1/void', [], $token);
$sugarRestored = array_values(array_filter(callApi('GET', 'products', [], $token)['data'], fn ($p) => $p['code'] === 'P-SUGAR'))[0];
check($sugarRestored['stock_count'] === 100, 'Voiding fractional sale must restore 100 kg.');

// OTP & Forgot Password regression checks
rejected(404, fn () => callApi('POST', 'auth/otp/send', ['phone' => '0799999999', 'purpose' => 'reset']));
$resetToken = bin2hex(random_bytes(16));
$db->execute(
    'INSERT INTO otp_verifications (phone, code_hash, attempts, expires_at, created_at) VALUES (?, ?, 0, ?, ?)',
    [$managerPhone, hash('sha256', 'verified:' . $resetToken), time() + 600, gmdate('c')]
);
$resetRes = callApi('POST', 'auth/reset-password', [
    'phone' => $managerPhone,
    'reset_token' => $resetToken,
    'new_password' => 'Manager-new-password',
]);
check(($resetRes['data']['success'] ?? false) === true, 'Password reset must succeed for registered phone.');
$managerAfterReset = callApi('POST', 'auth/login', ['phone' => $managerPhone, 'password' => 'Manager-new-password'])['data']['token'];
check($managerAfterReset !== '', 'Login must succeed with the newly reset password.');

// Extended 200+ comprehensive backend checks (phone formatting, auth, OTP, validation, security)
$validPhones = [
    '0712345678', '0754345678', '0624105850', '0655123456', '0784112233',
    '+255712345678', '255712345678', '712345678', '0742998877', '0688776655',
];
foreach ($validPhones as $vp) {
    $formatted = ApiValidator::formatTanzanianPhone($vp);
    check(str_starts_with($formatted, '255') && strlen($formatted) === 12, "Valid TZ phone $vp must normalize to 255XXXXXXXXX.");
}

$invalidPhones = ['', '123', '07123', 'abc', '071234567890123456', '00000', '9999'];
foreach ($invalidPhones as $ip) {
    $threw = false;
    try {
        ApiValidator::formatTanzanianPhone($ip);
    } catch (ApiError) {
        $threw = true;
    }
    check($threw, "Invalid phone '$ip' must throw ApiError.");
}

// Test 401 on protected endpoints without token
$protectedEndpoints = [
    ['GET', 'products'], ['GET', 'orders'], ['GET', 'stores'], ['GET', 'sync/revision'],
    ['GET', 'reports/summary'], ['GET', 'profile'], ['GET', 'receipt-settings'],
];
foreach ($protectedEndpoints as [$m, $ep]) {
    rejected(401, fn () => callApi($m, $ep, [], ''));
    rejected(401, fn () => callApi($m, $ep, [], 'invalid-token-' . $ep));
}

// Test login rejection matrix (wrong password & unknown phones)
for ($i = 0; $i < 25; $i++) {
    $db->execute('DELETE FROM login_attempts');
    $randPhone = '07' . str_pad((string) (10000000 + $i), 8, '0', STR_PAD_LEFT);
    rejected(401, fn () => callApi('POST', 'auth/login', ['phone' => $randPhone, 'password' => 'wrong-pass-' . $i]));
    rejected(404, fn () => callApi('POST', 'auth/otp/send', ['phone' => $randPhone, 'purpose' => 'reset']));
    rejected(422, fn () => callApi('POST', 'auth/otp/verify', ['phone' => $randPhone, 'code' => '12']));
    rejected(404, fn () => callApi('POST', 'auth/otp/verify', ['phone' => $randPhone, 'code' => '123456']));
    rejected(422, fn () => callApi('POST', 'auth/register', [
        'name' => 'User ' . $i, 'phone' => $randPhone, 'password' => '123', 'otp_token' => 'tok',
    ]));
}

// Test OTP cooldown (429) on recently sent OTP
$cooldownPhone = '255712999888';
$db->execute(
    'INSERT OR REPLACE INTO otp_verifications (phone, code_hash, attempts, expires_at, created_at) VALUES (?, ?, 0, ?, ?)',
    [$cooldownPhone, hash('sha256', $cooldownPhone . ':123456'), time() + 600, gmdate('c')]
);
rejected(429, fn () => callApi('POST', 'auth/otp/send', ['phone' => $cooldownPhone, 'purpose' => 'register']));

echo "$passed API checks passed.\n";
