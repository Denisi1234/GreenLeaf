<?php
declare(strict_types=1);

/**
 * Comprehensive feature coverage for the TrackMauzo PHP backend.
 *
 * Runs against an isolated in-memory SQLite database and exercises every API
 * surface: auth/OTP, tenant + branch isolation, all resources (CRUD,
 * permissions, optimistic concurrency), inventory, checkout, voiding, staff
 * accounts, uploads, notifications, sync revisions, audit logs and error paths.
 *
 * Run: php backend/tests/feature_test.php
 */

require __DIR__ . '/../src/Database.php';
require __DIR__ . '/../src/Api.php';

$config = [
    'dsn' => 'sqlite::memory:',
    'user' => '',
    'password' => '',
    'registration' => true,
    'token_hours' => 12,
];
$db = new Database($config);
$db->migrate();
$api = new Api($db, $config);

$passed = 0;
$section = '';

function section(string $name): void
{
    global $section;
    $section = $name;
}

function check(bool $condition, string $message): void
{
    global $passed, $section;
    if (!$condition) {
        throw new RuntimeException("[$section] $message");
    }
    $passed++;
}

function callApi(string $method, string $path, array $body = [], string $token = '', ?int $version = null, ?string $storeId = null): array
{
    global $api;
    return $api->dispatch($method, $path, $body, $token, $version, 'local', $storeId);
}

function rejected(int $status, callable $operation, string $message = 'Expected rejection'): void
{
    try {
        $operation();
    } catch (ApiError $error) {
        check($error->status === $status, $message . ' (got ' . $error->status . ': ' . $error->getMessage() . ')');
        return;
    }
    throw new RuntimeException("Expected rejection (status $status) but call succeeded.");
}

function seedOtp(string $phone, string $code): void
{
    global $db;
    $db->execute(
        'INSERT OR REPLACE INTO otp_verifications (phone, code_hash, attempts, expires_at, created_at) VALUES (?, ?, 0, ?, ?)',
        [$phone, hash('sha256', $phone . ':' . $code), time() + 600, gmdate('c')]
    );
}

function registerOwner(string $phone, string $name, string $store, string $password): string
{
    global $db;
    $formatted = ApiValidator::formatTanzanianPhone($phone);
    $otp = 'otp-' . $formatted;
    $db->execute('DELETE FROM otp_verifications WHERE phone = ?', [$formatted]);
    $db->execute(
        'INSERT INTO otp_verifications (phone, code_hash, attempts, expires_at, created_at) VALUES (?, ?, 0, ?, ?)',
        [$formatted, hash('sha256', 'verified:' . $otp), time() + 600, gmdate('c')]
    );
    return callApi('POST', 'auth/register', [
        'phone' => $phone, 'password' => $password, 'name' => $name,
        'store_name' => $store, 'otp_token' => $otp,
    ])['data']['token'];
}

function productPayload(string $code, float $price, float $stock, array $extra = []): array
{
    return array_merge([
        'code' => $code,
        'name' => 'Product ' . $code,
        'category' => 'Test',
        'selling_price' => $price,
        'purchase_price' => max(0.0, $price - 1),
        'stock_count' => $stock,
        'art_type' => 'aquafina',
        'category_data_json' => '{}',
    ], $extra);
}

function createProduct(string $token, array $payload): array
{
    callApi('POST', 'products', $payload, $token);
    return callApi('GET', 'products/' . $payload['code'], [], $token)['data'];
}

function stockOf(string $code, string $token, ?string $storeId = null): float
{
    foreach (callApi('GET', 'products', [], $token, null, $storeId)['data'] as $row) {
        if (($row['code'] ?? '') === $code) {
            return (float) $row['stock_count'];
        }
    }
    return -1;
}

function sale(string $id, string $code, float $qty, float $unitPrice, string $method, array $extra = []): array
{
    return array_merge([
        'id' => $id,
        'date_time' => gmdate('c'),
        'date_label' => '2026-11-24',
        'time_label' => '10:00',
        'register_name' => 'Till 1',
        'payment_method' => $method,
        'cash_tendered' => 0.0,
        'change_due' => 0.0,
        'discount_amount' => 0.0,
        'total' => $unitPrice * $qty,
        'lines' => [[
            'item_code' => $code,
            'item_size' => 'unit',
            'item_unit' => 'Pcs',
            'quantity' => $qty,
            'unit_price' => number_format($unitPrice, 2, '.', ''),
            'unit_price_value' => $unitPrice,
        ]],
    ], $extra);
}

// ---------------------------------------------------------------------------
section('bootstrap');
// ---------------------------------------------------------------------------
$tokenA = registerOwner('0711110001', 'Owner A', 'Shop A', 'Password-a1');
$tokenB = registerOwner('0711110002', 'Owner B', 'Shop B', 'Password-b1');
check(is_string($tokenA) && $tokenA !== '', 'Owner A registration returned a token.');
check(is_string($tokenB) && $tokenB !== '', 'Owner B registration returned a token.');

$me = callApi('GET', 'auth/me', [], $tokenA)['data'];
check(($me['role'] ?? '') === 'owner', 'Owner role is reported.');
check(!array_key_exists('password_hash', $me), 'auth/me never exposes the password hash.');
check(!array_key_exists('email', $me), 'auth/me never exposes the login column.');

// ---------------------------------------------------------------------------
section('health & routing');
// ---------------------------------------------------------------------------
$health = callApi('GET', 'health');
check(($health['data']['status'] ?? '') === 'ok', 'Health endpoint reports ok.');
$root = callApi('GET', '');
check(($root['data']['status'] ?? '') === 'ok', 'Root endpoint reports ok.');
rejected(404, fn () => callApi('GET', 'does-not-exist', [], $tokenA), 'Unknown resource returns 404.');
rejected(405, fn () => callApi('POST', 'orders', [], $tokenA), 'Unsupported orders method returns 405.');

// ---------------------------------------------------------------------------
section('tenant isolation');
// ---------------------------------------------------------------------------
createProduct($tokenA, productPayload('A-1', 10.0, 5.0));
$rowsA = callApi('GET', 'products', [], $tokenA)['data'];
$rowsB = callApi('GET', 'products', [], $tokenB)['data'];
check(count($rowsA) === 1 && count($rowsB) === 0, 'Products are isolated per shop.');

// ---------------------------------------------------------------------------
section('products & inventory');
// ---------------------------------------------------------------------------
$p = productPayload('P-MAIN', 10.0, 100.0);
$saved = createProduct($tokenA, $p);
check(($saved['code'] ?? '') === 'P-MAIN', 'Product created with its code.');
check(stockOf('P-MAIN', $tokenA) === 100.0, 'Product stock persisted.');
check((callApi('GET', 'products/P-MAIN', [], $tokenA)['data']['code'] ?? '') === 'P-MAIN', 'Single product fetch by code.');

rejected(422, fn () => createProduct($tokenA, productPayload('BAD-ART', 1.0, 1.0, ['art_type' => 'nope'])), 'Invalid art type rejected.');
rejected(422, fn () => createProduct($tokenA, productPayload('BAD-STOCK', 1.0, -5.0)), 'Negative stock rejected.');
rejected(422, fn () => createProduct($tokenA, productPayload('BAD-PRICE', -1.0, 1.0)), 'Negative price rejected.');
rejected(422, fn () => createProduct($tokenA, productPayload('BAD-META', 1.0, 1.0, ['category_data_json' => 'not-json'])), 'Invalid product metadata rejected.');

callApi('POST', 'products/stock-delta', ['deltas' => ['P-MAIN' => 25, 'UNKNOWN' => 5]], $tokenA);
check(stockOf('P-MAIN', $tokenA) === 125.0, 'Stock delta increments.');
callApi('POST', 'products/stock-delta', ['deltas' => ['P-MAIN' => -200]], $tokenA);
check(stockOf('P-MAIN', $tokenA) === 0.0, 'Stock delta clamps at zero.');

// ---------------------------------------------------------------------------
section('sync revision');
// ---------------------------------------------------------------------------
$rev1 = callApi('GET', 'sync/revision', [], $tokenA)['data'];
check(is_int($rev1['revision']) && is_array($rev1['versions']), 'Sync revision shape is valid.');
callApi('POST', 'products/stock-delta', ['deltas' => ['P-MAIN' => 10]], $tokenA);
$rev2 = callApi('GET', 'sync/revision', [], $tokenA)['data'];
check($rev2['revision'] > $rev1['revision'], 'Store revision advances after a mutation.');

// ---------------------------------------------------------------------------
section('optimistic concurrency');
// ---------------------------------------------------------------------------
rejected(404, fn () => callApi('GET', 'suppliers/NOPE', [], $tokenA), 'Missing record returns 404.');
callApi('PUT', 'suppliers', ['items' => [['id' => 'SUP-A', 'name' => 'Alpha']]], $tokenA, 0);
rejected(409, fn () => callApi('PUT', 'suppliers', ['items' => [['id' => 'SUP-B', 'name' => 'Beta']]], $tokenA, 0), 'Stale collection replace rejected.');
check(count(callApi('GET', 'suppliers', [], $tokenA)['data']) === 1, 'Stale replace must not wipe data.');
callApi('PUT', 'suppliers', ['items' => [['id' => 'SUP-A', 'name' => 'Alpha 2']]], $tokenA, 1);
check((callApi('GET', 'suppliers/SUP-A', [], $tokenA)['data']['name'] ?? '') === 'Alpha 2', 'Fresh collection replace succeeds.');
rejected(422, fn () => callApi('PUT', 'suppliers', ['items' => ['k' => 'v']], $tokenA, 2), 'Non-list replace rejected.');
rejected(422, fn () => callApi('PUT', 'suppliers', ['items' => [['id' => 'DUP'], ['id' => 'DUP']]], $tokenA, 2), 'Duplicate ids rejected.');
rejected(422, fn () => callApi('PUT', 'suppliers/' . str_repeat('a', 201), ['name' => 'Long'], $tokenA), 'Over-long record id rejected.');

// ---------------------------------------------------------------------------
section('generic resource CRUD');
// ---------------------------------------------------------------------------
$genericResources = [
    'debit-entries' => ['id' => 'GEN-debit-entries', 'note' => 'x', 'amount' => 5],
    'receivings' => ['id' => 'GEN-receivings', 'supplier_id' => 'SUP-A', 'total' => 50],
    'receiving-lines' => ['id' => 'GEN-receiving-lines', 'receiving_id' => 'R1', 'product_code' => 'P-MAIN'],
    'register-shifts' => ['id' => 'GEN-register-shifts', 'opening_cash' => 100],
    'cash-movements' => ['id' => 'GEN-cash-movements', 'type' => 'in', 'amount' => 20],
    'suspended-sales' => ['id' => 'GEN-suspended-sales', 'total' => 12],
    'accounts' => ['id' => 'GEN-accounts', 'code' => '1000', 'name' => 'Cash'],
    'journal-entries' => ['id' => 'GEN-journal-entries', 'date' => '2026-11-24'],
    'fixed-assets' => ['id' => 'GEN-fixed-assets', 'name' => 'Fridge', 'cost' => 900],
    'bank-transactions' => ['id' => 'GEN-bank-transactions', 'bank' => 'NMB', 'amount' => 300],
    'recovery-sessions' => ['id' => 'GEN-recovery-sessions', 'state' => 'open'],
    'learning-rules' => ['id' => 'GEN-learning-rules', 'rule' => 'x'],
];
foreach ($genericResources as $resource => $payload) {
    callApi('POST', $resource, $payload, $tokenA);
    $single = callApi('GET', $resource . '/' . $payload['id'], [], $tokenA)['data'];
    check(($single['id'] ?? '') === $payload['id'], "$resource stores and fetches a record.");
    callApi('DELETE', $resource . '/' . $payload['id'], [], $tokenA);
    rejected(404, fn () => callApi('GET', $resource . '/' . $payload['id'], [], $tokenA), "$resource delete removes the record.");
}

// ---------------------------------------------------------------------------
section('cart & preferences isolation');
// ---------------------------------------------------------------------------
callApi('PUT', 'cart/1', ['items' => [['id' => 'A-1', 'qty' => 2]]], $tokenA);
check(count(callApi('GET', 'cart', [], $tokenA)['data']) === 1, 'Cart persists for its owner session.');
check(count(callApi('GET', 'cart', [], $tokenB)['data']) === 0, 'Carts are isolated per signed-in session.');
callApi('PUT', 'preferences/1', ['language' => 'sw'], $tokenA);
check((callApi('GET', 'preferences', [], $tokenA)['data'][0]['language'] ?? '') === 'sw', 'Preferences persist per user.');
check(count(callApi('GET', 'preferences', [], $tokenB)['data']) === 0, 'Preferences are isolated per user.');

// ---------------------------------------------------------------------------
section('audit logs');
// ---------------------------------------------------------------------------
callApi('POST', 'audit-logs', ['id' => 'AUD-TEST', 'action' => 'test'], $tokenA);
check(count(callApi('GET', 'audit-logs', [], $tokenA)['data']) === 1, 'Audit log appended and listed.');
rejected(405, fn () => callApi('PUT', 'audit-logs/AUD-TEST', ['action' => 'x'], $tokenA), 'Audit logs are immutable (PUT).');
rejected(405, fn () => callApi('DELETE', 'audit-logs/AUD-TEST', [], $tokenA), 'Audit logs are immutable (DELETE).');

// ---------------------------------------------------------------------------
section('staff & auth/users');
// ---------------------------------------------------------------------------
$staffPhone = ApiValidator::formatTanzanianPhone('0711110011');
$staff = ['id' => 'STAFF-1', 'name' => 'Neema', 'phone' => '0711110011', 'status' => 'active', 'role_id' => 'cashier'];
callApi('POST', 'staff/STAFF-1/account', ['staff' => $staff, 'password' => 'Staff-aaa1'], $tokenA);
$staffToken = callApi('POST', 'auth/login', ['phone' => $staffPhone, 'password' => 'Staff-aaa1'])['data']['token'];
check((callApi('GET', 'auth/me', [], $staffToken)['data']['role'] ?? '') === 'cashier', 'Staff phone login works.');

$staff['status'] = 'inactive';
callApi('PUT', 'staff/STAFF-1', $staff, $tokenA);
rejected(401, fn () => callApi('GET', 'auth/me', [], $staffToken), 'Deactivating staff revokes their token.');
$staff['status'] = 'active';
callApi('POST', 'staff/STAFF-1/account', ['staff' => $staff, 'password' => 'Staff-bbb2'], $tokenA);
$staffToken = callApi('POST', 'auth/login', ['phone' => $staffPhone, 'password' => 'Staff-bbb2'])['data']['token'];
check((callApi('GET', 'auth/me', [], $staffToken)['data']['role'] ?? '') === 'cashier', 'Re-enabled staff can sign in again.');

$cashierPhone = ApiValidator::formatTanzanianPhone('0711110010');
callApi('POST', 'auth/users', ['name' => 'Cashier', 'phone' => '0711110010', 'password' => 'Cashier-aa1'], $tokenA);
$cashier = callApi('POST', 'auth/login', ['phone' => $cashierPhone, 'password' => 'Cashier-aa1'])['data']['token'];
check(is_string($cashier) && $cashier !== '', 'Owner-created cashier can sign in.');
rejected(403, fn () => callApi('POST', 'auth/users', ['name' => 'X', 'phone' => '0711110099', 'password' => 'whatever1'], $cashier), 'Only owners can create users.');

// Role escalation guard
callApi('PUT', 'roles/manager', ['id' => 'manager', 'permissions_json' => json_encode(['View Sales', 'Manage Inventory', 'Manage Staff'])], $tokenA);
callApi('PUT', 'roles/admin', ['id' => 'admin', 'permissions_json' => json_encode(['View Sales', 'System Settings', 'Manage Staff'])], $tokenA);
$managerPhone = ApiValidator::formatTanzanianPhone('0711110012');
$manager = ['id' => 'MANAGER-1', 'name' => 'Manager', 'phone' => '0711110012', 'status' => 'active', 'role_id' => 'manager'];
callApi('POST', 'staff/MANAGER-1/account', ['staff' => $manager, 'password' => 'Manager-aa1'], $tokenA);
$managerToken = callApi('POST', 'auth/login', ['phone' => $managerPhone, 'password' => 'Manager-aa1'])['data']['token'];
callApi('PUT', 'products/P-MAIN', productPayload('P-MAIN', 10.0, 10.0), $managerToken);
check(stockOf('P-MAIN', $managerToken) === 10.0, 'Manager can manage inventory.');
$escalated = $manager;
$escalated['role_id'] = 'admin';
rejected(403, fn () => callApi('PUT', 'staff/MANAGER-1', $escalated, $managerToken), 'Manager cannot assign an elevated role.');
rejected(403, fn () => callApi('PUT', 'receipt-settings/1', ['footer' => 'x'], $managerToken), 'Manager cannot change system settings.');

// ---------------------------------------------------------------------------
section('permission matrix (cashier)');
// ---------------------------------------------------------------------------
check(count(callApi('GET', 'products', [], $cashier)['data']) >= 1, 'Cashier can read the catalog.');
rejected(403, fn () => createProduct($cashier, productPayload('CASH-NO', 1.0, 1.0)), 'Cashier cannot create products.');
rejected(403, fn () => callApi('POST', 'products/stock-delta', ['deltas' => ['P-MAIN' => 1]], $cashier), 'Cashier cannot adjust stock.');
check(is_array(callApi('GET', 'customers', [], $cashier)['data']), 'Cashier can read customers.');
rejected(403, fn () => callApi('POST', 'customers', ['name' => 'Nope'], $cashier), 'Cashier cannot write customers.');
rejected(403, fn () => callApi('GET', 'suppliers', [], $cashier), 'Cashier cannot read suppliers.');
rejected(403, fn () => callApi('GET', 'accounts', [], $cashier), 'Cashier cannot read accounting.');
rejected(403, fn () => callApi('GET', 'audit-logs', [], $cashier), 'Cashier cannot read audit logs.');
rejected(403, fn () => callApi('GET', 'expenses', [], $cashier), 'Cashier cannot read expenses.');
rejected(403, fn () => callApi('GET', 'notifications', [], $cashier), 'Cashier cannot read notifications.');
rejected(403, fn () => callApi('POST', 'notifications/send', ['title' => 'T', 'message' => 'M'], $cashier), 'Cashier cannot send notifications.');
rejected(403, fn () => callApi('POST', 'uploads', ['content' => ''], $cashier), 'Cashier cannot upload images.');
check(is_array(callApi('GET', 'register-shifts', [], $cashier)['data']), 'Cashier can read shift records.');
check((callApi('GET', 'profile', [], $cashier)['data'][0]['store_name'] ?? 'Shop A') !== '', 'Cashier can read the store profile.');
callApi('PUT', 'preferences/2', ['language' => 'en'], $cashier);
check(count(callApi('GET', 'preferences', [], $cashier)['data']) === 1, 'Cashier can set own preferences.');

// ---------------------------------------------------------------------------
section('checkout & payments');
// ---------------------------------------------------------------------------
createProduct($tokenA, productPayload('CH-CASH', 10.0, 100.0));
createProduct($tokenA, productPayload('CH-CARD', 20.0, 50.0));
createProduct($tokenA, productPayload('CH-CRED', 15.0, 50.0));
createProduct($tokenA, productPayload('CH-DISC', 100.0, 10.0));
createProduct($tokenA, productPayload('CH-PRICE', 10.0, 5.0));
createProduct($tokenA, productPayload('CH-FRAC', 1000.0, 10.0, ['category_data_json' => json_encode(['unit' => 'kg', 'allow_fractional' => true])]));

// Cash sale
$cashSale = sale('O-CASH', 'CH-CASH', 3, 10.0, 'Cash', ['cash_tendered' => 30.0]);
$done = callApi('POST', 'checkout', $cashSale, $tokenA)['data'];
check(($done['status'] ?? '') === 'Completed', 'Cash sale completes.');
check((($done['cashier_name'] ?? '') === 'Owner A'), 'Server stamps the cashier identity.');
check(stockOf('CH-CASH', $tokenA) === 97.0, 'Cash sale decrements stock.');
rejected(409, fn () => callApi('POST', 'checkout', array_merge($cashSale, ['total' => 99.0]), $tokenA), 'Reused sale id with different body rejected.');
callApi('POST', 'checkout', $cashSale, $tokenA);
check(stockOf('CH-CASH', $tokenA) === 97.0, 'Idempotent sale retry does not double-decrement.');

// Card / Mobile / Bank
callApi('POST', 'checkout', sale('O-CARD', 'CH-CARD', 1, 20.0, 'Card'), $tokenA);
callApi('POST', 'checkout', sale('O-MOBILE', 'CH-CARD', 1, 20.0, 'Mobile Money'), $tokenA);
callApi('POST', 'checkout', sale('O-BANK', 'CH-CARD', 1, 20.0, 'Bank Transfer'), $tokenA);
check(stockOf('CH-CARD', $tokenA) === 47.0, 'Non-cash payment methods settle without cash checks.');

// Credit sale
callApi('POST', 'customers', ['name' => 'Gemma', 'debit_balance' => 0], $tokenA);
callApi('POST', 'checkout', sale('O-CRED', 'CH-CRED', 1, 15.0, 'Credit', ['customer_name' => 'Gemma']), $tokenA);
$gemma = null;
foreach (callApi('GET', 'customers', [], $tokenA)['data'] as $c) {
    if (($c['name'] ?? '') === 'Gemma') {
        $gemma = $c;
    }
}
check($gemma !== null && abs((float) $gemma['debit_balance'] - 15.0) < 0.001, 'Credit sale increases the customer balance.');
check(stockOf('CH-CRED', $tokenA) === 49.0, 'Credit sale decrements stock.');

// Duplicate customer names block credit
callApi('POST', 'customers', ['name' => 'Twin', 'debit_balance' => 0], $tokenA);
callApi('POST', 'customers', ['name' => 'Twin', 'debit_balance' => 0], $tokenA);
rejected(422, fn () => callApi('POST', 'checkout', sale('O-TWIN', 'CH-CRED', 1, 15.0, 'Credit', ['customer_name' => 'Twin']), $tokenA), 'Ambiguous credit customer rejected.');
check(stockOf('CH-CRED', $tokenA) === 49.0, 'Rejected credit sale rolls back stock.');

// Validation failures
rejected(422, fn () => callApi('POST', 'checkout', sale('O-BADCASH', 'CH-CASH', 1, 10.0, 'Cash', ['cash_tendered' => 5.0]), $tokenA), 'Insufficient cash rejected.');
rejected(422, fn () => callApi('POST', 'checkout', sale('O-BADMETHOD', 'CH-CASH', 1, 10.0, 'Bitcoin'), $tokenA), 'Unsupported payment method rejected.');
rejected(409, fn () => callApi('POST', 'checkout', sale('O-BADPRICE', 'CH-PRICE', 1, 9.0, 'Cash', ['cash_tendered' => 9.0]), $tokenA), 'Price mismatch rejected.');
check(stockOf('CH-PRICE', $tokenA) === 5.0, 'Failed sales roll back stock.');

// Owner discount works, cashier discount blocked
callApi('POST', 'checkout', sale('O-DISC', 'CH-DISC', 1, 100.0, 'Cash', ['cash_tendered' => 90.0, 'discount_amount' => 10.0, 'total' => 90.0]), $tokenA);
check(stockOf('CH-DISC', $tokenA) === 9.0, 'Owner discount sale succeeds.');
rejected(403, fn () => callApi('POST', 'checkout', sale('O-CDISC', 'CH-DISC', 1, 100.0, 'Cash', ['cash_tendered' => 90.0, 'discount_amount' => 10.0, 'total' => 90.0]), $cashier), 'Cashier discount requires permission.');
check(stockOf('CH-DISC', $tokenA) === 9.0, 'Blocked customer discount rolls back stock.');

// Cashier can sell
callApi('POST', 'checkout', sale('O-CASHIER', 'CH-CASH', 1, 10.0, 'Cash', ['cash_tendered' => 10.0]), $cashier);
check(stockOf('CH-CASH', $tokenA) === 96.0, 'Cashier can complete a sale.');

// Fractional sale
callApi('POST', 'checkout', sale('O-FRAC', 'CH-FRAC', 0.25, 1000.0, 'Cash', ['cash_tendered' => 250.0]), $tokenA);
check(abs(stockOf('CH-FRAC', $tokenA) - 9.75) < 0.001, 'Fractional quantity deducts precisely.');

// Void
rejected(403, fn () => callApi('POST', 'orders/O-CARD/void', [], $cashier), 'Cashier cannot void sales.');
callApi('POST', 'orders/O-CASH/void', [], $tokenA);
check(stockOf('CH-CASH', $tokenA) === 99.0, 'Void restores stock.');
callApi('POST', 'orders/O-CASH/void', [], $tokenA);
check(stockOf('CH-CASH', $tokenA) === 99.0, 'Voiding twice restores stock once.');
callApi('POST', 'orders/O-CRED/void', [], $tokenA);
$gemmaAfter = null;
foreach (callApi('GET', 'customers', [], $tokenA)['data'] as $c) {
    if (($c['name'] ?? '') === 'Gemma') {
        $gemmaAfter = $c;
    }
}
check(abs((float) $gemmaAfter['debit_balance']) < 0.001, 'Voiding a credit sale reverses the debt.');
rejected(404, fn () => callApi('POST', 'orders/NOPE/void', [], $tokenA), 'Voiding a missing sale returns 404.');

// Orders listing + summary
check(count(callApi('GET', 'orders', [], $tokenA)['data']) >= 5, 'Completed orders are listed.');
$summary = callApi('GET', 'reports/summary', [], $tokenA)['data'];
check(isset($summary['sales'], $summary['revenue'], $summary['expenses']), 'Reports summary exposes sales, revenue and expenses.');
callApi('POST', 'expenses', ['title' => 'Transport', 'amount' => 5], $tokenA);
check((float) callApi('GET', 'reports/summary', [], $tokenA)['data']['expenses'] === 5.0, 'Expenses feed the summary.');

// ---------------------------------------------------------------------------
section('multi-store branches');
// ---------------------------------------------------------------------------
$branches = callApi('POST', 'stores', ['name' => 'Branch X'], $tokenA)['data'];
$branchId = '';
foreach ($branches as $row) {
    if (($row['name'] ?? '') === 'Branch X') {
        $branchId = (string) $row['id'];
    }
}
check($branchId !== '', 'Owner can create a branch store.');
check(count(callApi('GET', 'stores', [], $tokenA)['data']) >= 2, 'Branch list includes the new store.');
createProduct($tokenA, productPayload('BR-ONLY', 7.0, 3.0)); // primary sanity
callApi('POST', 'products', productPayload('BR-PROD', 8.0, 4.0), $tokenA, null, $branchId);
check(stockOf('BR-PROD', $tokenA, $branchId) === 4.0, 'Branch product stored in the branch.');
check(stockOf('BR-PROD', $tokenA) < 0, 'Branch product invisible in the primary store.');
rejected(403, fn () => callApi('POST', 'stores', ['name' => 'Nope'], $cashier), 'Only owners create branches.');
rejected(403, fn () => callApi('GET', 'products', [], $cashier, null, $branchId), 'Non-owners cannot switch branches.');

// ---------------------------------------------------------------------------
section('uploads');
// ---------------------------------------------------------------------------
$png = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl6l0sAAAAASUVORK5CYII=';
$upload = callApi('POST', 'uploads', ['content' => $png], $tokenA)['data'];
check(($upload['path'] ?? '') === 'uploads/' . $upload['id'], 'Upload returns a stable relative path.');
check(callApi('GET', 'uploads/' . $upload['id'], [], $tokenA)['image'] === $png, 'Uploaded image is readable.');
check(callApi('POST', 'uploads', ['content' => $png], $tokenA)['data']['id'] === $upload['id'], 'Duplicate uploads are idempotent.');
rejected(422, fn () => callApi('POST', 'uploads', ['content' => base64_encode('not an image')], $tokenA), 'Non-image upload rejected.');
$uploadB = callApi('POST', 'uploads', ['content' => $png], $tokenB)['data'];
rejected(404, fn () => callApi('GET', 'uploads/' . $uploadB['id'], [], $tokenA), 'Cross-shop image access denied.');

// ---------------------------------------------------------------------------
section('notifications');
// ---------------------------------------------------------------------------
rejected(422, fn () => callApi('POST', 'notifications/device-token', [], $tokenA), 'Device token requires a value.');
check(callApi('POST', 'notifications/device-token', ['token' => 'dev-owner-a', 'platform' => 'android'], $tokenA)['data']['registered'] === true, 'Device token registered.');
check(callApi('POST', 'notifications/device-token', ['token' => 'dev-cashier', 'platform' => 'android'], $cashier)['data']['registered'] === true, 'Any signed-in user may register a device.');
rejected(422, fn () => callApi('POST', 'notifications/send', ['title' => '', 'message' => 'M'], $tokenA), 'Notification requires a title.');
$sent = callApi('POST', 'notifications/send', ['title' => 'Hi', 'message' => 'There'], $tokenA)['data'];
check(($sent['delivered_to_tokens'] ?? 0) >= 1, 'Notification dispatches to registered devices.');
check(count(callApi('GET', 'notifications', [], $tokenA)['data']) >= 1, 'Sent notifications are listed.');

// ---------------------------------------------------------------------------
section('OTP & password reset');
// ---------------------------------------------------------------------------
rejected(409, fn () => callApi('POST', 'auth/otp/send', ['phone' => '0711110002', 'purpose' => 'register'], ''), 'OTP registration blocked for an existing phone.');
rejected(404, fn () => callApi('POST', 'auth/otp/send', ['phone' => '0711110009', 'purpose' => 'reset'], ''), 'OTP reset requires a registered phone.');
rejected(502, fn () => callApi('POST', 'auth/otp/send', ['phone' => '0711110003', 'purpose' => 'register'], ''), 'OTP send surfaces SMS gateway failure.');

$phoneB = ApiValidator::formatTanzanianPhone('0711110002');
seedOtp($phoneB, '123456');
rejected(422, fn () => callApi('POST', 'auth/otp/verify', ['phone' => '0711110002', 'code' => '000000'], ''), 'Wrong OTP rejected.');
$verified = callApi('POST', 'auth/otp/verify', ['phone' => '0711110002', 'code' => '123456'], '')['data'];
check(($verified['verified'] ?? false) === true && is_string($verified['reset_token']), 'Correct OTP issues a reset token.');
rejected(401, fn () => callApi('POST', 'auth/reset-password', ['phone' => '0711110002', 'reset_token' => 'bad', 'new_password' => 'Another-b2'], ''), 'Invalid reset token rejected.');
check(callApi('POST', 'auth/reset-password', ['phone' => '0711110002', 'reset_token' => $verified['reset_token'], 'new_password' => 'Another-b2'], '')['data']['success'] === true, 'Password reset succeeds with a valid token.');
$relogin = callApi('POST', 'auth/login', ['phone' => '0711110002', 'password' => 'Another-b2']);
check(isset($relogin['data']['token']), 'User can sign in with the new password.');

// OTP lockout after too many attempts
$phoneZ = ApiValidator::formatTanzanianPhone('0711110005');
$db->execute('DELETE FROM otp_verifications WHERE phone = ?', [$phoneZ]);
$db->execute('INSERT INTO otp_verifications (phone, code_hash, attempts, expires_at, created_at) VALUES (?, ?, 5, ?, ?)', [$phoneZ, hash('sha256', $phoneZ . ':123456'), time() + 600, gmdate('c')]);
rejected(429, fn () => callApi('POST', 'auth/otp/verify', ['phone' => '0711110005', 'code' => '123456'], ''), 'OTP locks out after repeated failures.');

// ---------------------------------------------------------------------------
section('sms & throttling');
// ---------------------------------------------------------------------------
rejected(403, fn () => callApi('POST', 'sms/send', ['phone' => '0711110001', 'text' => 'hi'], $cashier), 'Cashier cannot send SMS.');
rejected(422, fn () => callApi('POST', 'sms/send', ['phone' => '0711110001', 'text' => str_repeat('x', 501)], $tokenA), 'Over-long SMS rejected.');
rejected(502, fn () => callApi('POST', 'sms/send', ['phone' => '0711110001', 'text' => 'hello'], $tokenA), 'SMS send surfaces gateway failure.');
check((int) ($db->rows('SELECT COUNT(*) AS c FROM login_attempts')[0]['c'] ?? 0) > 0, 'Auth throttling records attempts.');

// ---------------------------------------------------------------------------
section('session teardown');
// ---------------------------------------------------------------------------
callApi('POST', 'auth/logout', [], $cashier);
rejected(401, fn () => callApi('GET', 'auth/me', [], $cashier), 'Logout revokes the token.');

echo "$passed API checks passed.\n";
