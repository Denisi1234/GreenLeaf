CREATE TABLE IF NOT EXISTS stores (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    revision INTEGER NOT NULL DEFAULT 0,
    created_at VARCHAR(32) NOT NULL
);
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(64) PRIMARY KEY,
    store_id VARCHAR(64) NOT NULL,
    name VARCHAR(200) NOT NULL,
    email VARCHAR(254) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL,
    active INTEGER NOT NULL DEFAULT 1,
    created_at VARCHAR(32) NOT NULL,
    FOREIGN KEY (store_id) REFERENCES stores(id)
);
CREATE TABLE IF NOT EXISTS access_tokens (
    token_hash VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    expires_at INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS login_attempts (
    attempt_key VARCHAR(64) PRIMARY KEY,
    attempts INTEGER NOT NULL,
    window_start INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS otp_verifications (
    phone VARCHAR(32) PRIMARY KEY,
    code_hash VARCHAR(64) NOT NULL,
    attempts INTEGER NOT NULL DEFAULT 0,
    expires_at INTEGER NOT NULL,
    created_at VARCHAR(32) NOT NULL
);
CREATE TABLE IF NOT EXISTS resource_versions (
    store_id VARCHAR(64) NOT NULL,
    resource VARCHAR(64) NOT NULL,
    version INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (store_id, resource),
    FOREIGN KEY (store_id) REFERENCES stores(id)
);
CREATE TABLE IF NOT EXISTS records (
    store_id VARCHAR(64) NOT NULL,
    resource VARCHAR(64) NOT NULL,
    record_id VARCHAR(200) NOT NULL,
    position INTEGER NOT NULL DEFAULT 0,
    payload MEDIUMTEXT NOT NULL,
    PRIMARY KEY (store_id, resource, record_id),
    FOREIGN KEY (store_id) REFERENCES stores(id)
);
CREATE TABLE IF NOT EXISTS products (
    store_id VARCHAR(64) NOT NULL,
    code VARCHAR(200) NOT NULL,
    stock_count INTEGER NOT NULL,
    price_cents BIGINT NOT NULL,
    cost_cents BIGINT NOT NULL,
    payload MEDIUMTEXT NOT NULL,
    PRIMARY KEY (store_id, code),
    FOREIGN KEY (store_id) REFERENCES stores(id)
);
CREATE TABLE IF NOT EXISTS orders (
    store_id VARCHAR(64) NOT NULL,
    id VARCHAR(200) NOT NULL,
    request_hash VARCHAR(64) NOT NULL,
    status VARCHAR(20) NOT NULL,
    total_cents BIGINT NOT NULL,
    customer_id VARCHAR(200),
    payload MEDIUMTEXT NOT NULL,
    PRIMARY KEY (store_id, id),
    FOREIGN KEY (store_id) REFERENCES stores(id)
);
CREATE TABLE IF NOT EXISTS order_lines (
    store_id VARCHAR(64) NOT NULL,
    order_id VARCHAR(200) NOT NULL,
    line_number INTEGER NOT NULL,
    product_code VARCHAR(200) NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price_cents BIGINT NOT NULL,
    unit_cost_cents BIGINT NOT NULL,
    payload MEDIUMTEXT NOT NULL,
    PRIMARY KEY (store_id, order_id, line_number),
    FOREIGN KEY (store_id, order_id) REFERENCES orders(store_id, id)
);
CREATE TABLE IF NOT EXISTS uploads (
    id VARCHAR(64) PRIMARY KEY,
    store_id VARCHAR(64) NOT NULL,
    mime VARCHAR(32) NOT NULL,
    content MEDIUMTEXT NOT NULL,
    FOREIGN KEY (store_id) REFERENCES stores(id)
);
CREATE TABLE IF NOT EXISTS staff_accounts (
    store_id VARCHAR(64) NOT NULL,
    staff_id VARCHAR(200) NOT NULL,
    user_id VARCHAR(64) NOT NULL UNIQUE,
    PRIMARY KEY (store_id, staff_id),
    FOREIGN KEY (store_id) REFERENCES stores(id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS device_tokens (
    id INT AUTO_INCREMENT PRIMARY KEY,
    store_id VARCHAR(64) NOT NULL,
    user_id VARCHAR(64),
    token VARCHAR(500) NOT NULL UNIQUE,
    platform VARCHAR(32) NOT NULL DEFAULT 'android',
    updated_at VARCHAR(32) NOT NULL,
    FOREIGN KEY (store_id) REFERENCES stores(id)
);
CREATE TABLE IF NOT EXISTS push_notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    store_id VARCHAR(64) NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    category VARCHAR(50) NOT NULL DEFAULT 'general',
    payload TEXT,
    created_at VARCHAR(32) NOT NULL,
    FOREIGN KEY (store_id) REFERENCES stores(id)
);
