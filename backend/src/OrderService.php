<?php
declare(strict_types=1);

final class OrderService
{
    public function __construct(
        private Database $db,
        private ResourceRepository $resources,
        private AuthService $auth,
    ) {
    }

    public function orderRows(string $storeId): array
    {
        $rows = $this->db->rows(
            "SELECT payload FROM orders WHERE store_id = ? AND status = 'Completed' ORDER BY id DESC",
            [$storeId]
        );
        return array_map(fn ($row) => json_decode($row['payload'], true, 512, JSON_THROW_ON_ERROR), $rows);
    }

    public function applyProductStockDeltas(string $storeId, array $body): array
    {
        $deltas = $body['deltas'] ?? null;
        if (!is_array($deltas)) {
            throw new ApiError(422, 'Provide a deltas map of product codes to integer adjustments.');
        }
        foreach ($deltas as $code => $rawDelta) {
            if (!is_string($code) || trim($code) === '' || !is_numeric($rawDelta)) {
                continue;
            }
            $delta = (int) $rawDelta;
            if ($delta === 0) {
                continue;
            }
            $rows = $this->db->rows(
                'SELECT stock_count, payload FROM products WHERE store_id = ? AND code = ?',
                [$storeId, $code]
            );
            if ($rows === []) {
                continue;
            }
            $current = (int) $rows[0]['stock_count'];
            $next = max(0, min(2147483647, $current + $delta));
            $payload = json_decode($rows[0]['payload'], true, 512, JSON_THROW_ON_ERROR);
            $payload['stock_count'] = $next;
            $payload['stock_state'] = ApiValidator::stockState($next);
            $this->db->execute(
                'UPDATE products SET stock_count = ?, payload = ? WHERE store_id = ? AND code = ?',
                [$next, json_encode($payload, JSON_THROW_ON_ERROR), $storeId, $code]
            );
        }
        $this->resources->bump($storeId, 'products');
        return $this->resources->collection($storeId, 'products', $this->resources->resourceRows($storeId, 'products'));
    }

    public function checkout(array $user, string $cartResource, array $order): array
    {
        $storeId = $user['store_id'];
        $id = ApiValidator::text($order, 'id');
        $hash = hash('sha256', json_encode($order, JSON_THROW_ON_ERROR));
        $order['id'] = $id;
        $existing = $this->db->rows(
            'SELECT request_hash, payload, status FROM orders WHERE store_id = ? AND id = ?',
            [$storeId, $id]
        );
        if ($existing !== []) {
            if ($existing[0]['request_hash'] !== $hash || $existing[0]['status'] !== 'Completed') {
                throw new ApiError(409, 'This sale identifier is already used.');
            }
            return $this->checkoutResult($storeId, $cartResource, json_decode($existing[0]['payload'], true, 512, JSON_THROW_ON_ERROR));
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
            $code = ApiValidator::text($line, 'item_code');
            $quantity = $line['quantity'] ?? null;
            if (!is_int($quantity) || $quantity < 1 || $quantity > 1000000) {
                throw new ApiError(422, 'Quantity must be a positive integer.');
            }
            $products = $this->db->rows('SELECT * FROM products WHERE store_id = ? AND code = ?', [$storeId, $code]);
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
            if (ApiValidator::cents($line['unit_price_value'] ?? null) !== (int) $product['price_cents']) {
                throw new ApiError(409, 'The price changed for ' . $code . '. Refresh the inventory.');
            }
            $line['unit_cost'] = (int) $product['cost_cents'] / 100;
            $subtotal += (int) $product['price_cents'] * $quantity;
            if ($subtotal > 10000000000000) {
                throw new ApiError(422, 'The sale exceeds the supported total.');
            }
            $this->db->execute(
                'UPDATE products SET stock_count = stock_count - ? WHERE store_id = ? AND code = ?',
                [$quantity, $storeId, $code]
            );
        }
        unset($line);

        $discount = ApiValidator::cents($order['discount_amount'] ?? 0);
        if ($discount > 0) {
            $this->auth->requirePermission($user, 'Discounts');
        }
        if ($discount > $subtotal || ApiValidator::cents($order['total'] ?? null) !== $subtotal - $discount) {
            throw new ApiError(422, 'The sale total does not match its items and discount.');
        }

        $total = $subtotal - $discount;
        $method = $order['payment_method'] ?? 'Cash';
        if (!in_array($method, ['Cash', 'Credit', 'Card', 'Mobile Money', 'M-Pesa', 'Bank Transfer'], true)) {
            throw new ApiError(422, 'Unsupported payment method.');
        }
        $cash = ApiValidator::cents($order['cash_tendered'] ?? 0);
        if ($method === 'Cash' && $cash < $total) {
            throw new ApiError(422, 'Cash tendered is less than the total.');
        }

        $customerId = null;
        if ($method === 'Credit') {
            $matches = array_values(array_filter(
                $this->resources->resourceRows($storeId, 'customers'),
                fn ($customer) => $customer['name'] === ($order['customer_name'] ?? '')
            ));
            if (count($matches) !== 1) {
                throw new ApiError(422, 'Choose a unique customer credit account.');
            }
            $customer = $matches[0];
            $customerId = (string) $customer['id'];
            $customer['debit_balance'] = (ApiValidator::cents($customer['debit_balance'] ?? 0) + $total) / 100;
            $this->resources->put($user, 'customers', $customerId, $customer);
            $this->resources->bump($storeId, 'customers');
        }

        $order['cashier_name'] = $user['name'];
        $order['total'] = $total / 100;
        $order['discount_amount'] = $discount / 100;
        $order['status'] = 'Completed';
        $order['cash_tendered'] = $method === 'Cash' ? $cash / 100 : 0;
        $order['change_due'] = $method === 'Cash' ? ($cash - $total) / 100 : 0;
        $order['lines'] = $lines;

        $this->db->execute(
            'INSERT INTO orders VALUES (?, ?, ?, ?, ?, ?, ?)',
            [$storeId, $id, $hash, 'Completed', $total, $customerId, json_encode($order, JSON_THROW_ON_ERROR)]
        );
        foreach ($lines as $index => $line) {
            $this->db->execute(
                'INSERT INTO order_lines VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
                [$storeId, $id, $index, $line['item_code'], $line['quantity'], ApiValidator::cents($line['unit_price_value']), ApiValidator::cents($line['unit_cost']), json_encode($line, JSON_THROW_ON_ERROR)]
            );
        }

        $this->resources->replace($user, $cartResource, []);
        $this->resources->bump($storeId, 'products');
        $this->resources->bump($storeId, 'orders');
        $this->resources->bump($storeId, $cartResource);
        return $this->checkoutResult($storeId, $cartResource, $order);
    }

    public function voidOrder(array $user, string $id): array
    {
        $storeId = $user['store_id'];
        $orders = $this->db->rows('SELECT * FROM orders WHERE store_id = ? AND id = ?', [$storeId, $id]);
        if ($orders === []) {
            throw new ApiError(404, 'Sale not found.');
        }
        $order = $orders[0];
        if ($order['status'] === 'Voided') {
            return ['data' => ['voided' => true]];
        }
        $lines = $this->db->rows('SELECT * FROM order_lines WHERE store_id = ? AND order_id = ?', [$storeId, $id]);
        foreach ($lines as $line) {
            $updated = $this->db->execute(
                'UPDATE products SET stock_count = stock_count + ? WHERE store_id = ? AND code = ?',
                [$line['quantity'], $storeId, $line['product_code']]
            );
            if ($updated !== 1) {
                throw new ApiError(409, 'Restore product ' . $line['product_code'] . ' before voiding this sale.');
            }
        }
        if ($order['customer_id'] !== null) {
            foreach ($this->resources->resourceRows($storeId, 'customers') as $customer) {
                if ((string) $customer['id'] === $order['customer_id']) {
                    $customer['debit_balance'] = max(0, ApiValidator::cents($customer['debit_balance'] ?? 0) - (int) $order['total_cents']) / 100;
                    $this->resources->put($user, 'customers', (string) $customer['id'], $customer);
                }
            }
            $this->resources->bump($storeId, 'customers');
        }
        $this->db->execute("UPDATE orders SET status = 'Voided' WHERE store_id = ? AND id = ?", [$storeId, $id]);
        $this->resources->bump($storeId, 'products');
        $this->resources->bump($storeId, 'orders');
        return ['data' => ['voided' => true]];
    }

    public function summary(string $storeId): array
    {
        $orders = $this->db->rows(
            "SELECT COUNT(*) AS sales, COALESCE(SUM(total_cents), 0) AS cents FROM orders WHERE store_id = ? AND status = 'Completed'",
            [$storeId]
        )[0];
        $expenses = array_sum(array_map(
            fn ($row) => ApiValidator::cents($row['amount']),
            $this->resources->resourceRows($storeId, 'expenses')
        ));
        return [
            'data' => [
                'sales' => (int) $orders['sales'],
                'revenue' => (int) $orders['cents'] / 100,
                'expenses' => $expenses / 100,
            ],
        ];
    }

    private function checkoutResult(string $storeId, string $cartResource, array $order): array
    {
        return [
            'data' => $order,
            'products' => $this->resources->resourceRows($storeId, 'products'),
            'customers' => $this->resources->resourceRows($storeId, 'customers'),
            'versions' => [
                'products' => $this->resources->version($storeId, 'products'),
                'customers' => $this->resources->version($storeId, 'customers'),
                'orders' => $this->resources->version($storeId, 'orders'),
                'cart' => $this->resources->version($storeId, $cartResource),
            ],
        ];
    }
}
