/// Minimal SQLite schema shared by the in-memory test databases.
///
/// The tables mirror the production schema created by [PosLocalDatabase] so
/// store and sync tests can exercise the real persistence code paths.
const List<String> testDatabaseSchema = <String>[
  '''
  CREATE TABLE IF NOT EXISTS inventory_products (
    code TEXT,
    store_id TEXT NOT NULL,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    purchase_price REAL NOT NULL,
    selling_price REAL NOT NULL,
    stock_count INTEGER NOT NULL,
    stock_state TEXT NOT NULL,
    art_type TEXT NOT NULL,
    image_path TEXT,
    category_data_json TEXT NOT NULL DEFAULT '{}',
    PRIMARY KEY (code, store_id)
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS cart_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    store_id TEXT NOT NULL,
    code TEXT,
    category TEXT,
    name TEXT NOT NULL,
    size TEXT NOT NULL,
    price TEXT NOT NULL,
    art_type TEXT NOT NULL,
    image_path TEXT
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS orders (
    id TEXT PRIMARY KEY,
    store_id TEXT NOT NULL,
    date_time TEXT NOT NULL,
    date_label TEXT NOT NULL,
    time_label TEXT NOT NULL,
    total REAL NOT NULL,
    status TEXT NOT NULL,
    cashier_name TEXT NOT NULL,
    register_name TEXT NOT NULL,
    payment_method TEXT NOT NULL,
    cash_tendered REAL NOT NULL,
    change_due REAL NOT NULL,
    customer_name TEXT,
    discount_amount REAL,
    discount_label TEXT
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS order_lines (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id TEXT NOT NULL,
    item_code TEXT,
    item_category TEXT,
    item_name TEXT NOT NULL,
    item_size TEXT NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price TEXT NOT NULL,
    unit_price_value REAL NOT NULL,
    unit_cost REAL,
    art_type TEXT NOT NULL,
    image_path TEXT
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS customers (
    id TEXT PRIMARY KEY,
    store_id TEXT NOT NULL,
    name TEXT NOT NULL,
    email TEXT NOT NULL DEFAULT '',
    phone TEXT NOT NULL,
    address TEXT NOT NULL DEFAULT '',
    debit_balance REAL NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT '',
    tags TEXT NOT NULL DEFAULT ''
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS debit_entries (
    id TEXT PRIMARY KEY,
    store_id TEXT NOT NULL,
    customer_id TEXT NOT NULL,
    customer_name TEXT NOT NULL,
    type TEXT NOT NULL,
    amount REAL NOT NULL DEFAULT 0,
    note TEXT NOT NULL DEFAULT '',
    order_id TEXT,
    recorded_by TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS expenses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    store_id TEXT NOT NULL,
    title TEXT NOT NULL,
    amount REAL NOT NULL,
    category TEXT NOT NULL,
    payment_method TEXT NOT NULL,
    date TEXT NOT NULL,
    notes TEXT,
    vendor TEXT NOT NULL DEFAULT '',
    tax_amount REAL NOT NULL DEFAULT 0,
    receipt_path TEXT,
    status TEXT NOT NULL DEFAULT 'submitted',
    created_at TEXT NOT NULL DEFAULT '',
    updated_at TEXT NOT NULL DEFAULT ''
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS register_shifts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    store_id TEXT NOT NULL,
    register TEXT NOT NULL DEFAULT 'Register 1',
    opened_by TEXT NOT NULL DEFAULT '',
    opened_at TEXT NOT NULL,
    opening_float REAL NOT NULL DEFAULT 0,
    closed_at TEXT,
    closed_by TEXT NOT NULL DEFAULT '',
    counted_cash REAL NOT NULL DEFAULT 0,
    notes TEXT NOT NULL DEFAULT ''
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS cash_movements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    store_id TEXT NOT NULL,
    shift_id TEXT NOT NULL,
    type TEXT NOT NULL,
    amount REAL NOT NULL DEFAULT 0,
    reason TEXT NOT NULL DEFAULT '',
    at TEXT NOT NULL,
    recorded_by TEXT NOT NULL DEFAULT ''
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS suppliers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    store_id TEXT NOT NULL,
    name TEXT NOT NULL,
    phone TEXT NOT NULL DEFAULT '',
    email TEXT NOT NULL DEFAULT '',
    address TEXT NOT NULL DEFAULT '',
    opening_balance REAL NOT NULL DEFAULT 0,
    notes TEXT NOT NULL DEFAULT ''
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS receivings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    store_id TEXT NOT NULL,
    supplier_id INTEGER,
    supplier_name TEXT NOT NULL DEFAULT '',
    date TEXT NOT NULL,
    invoice_no TEXT NOT NULL DEFAULT '',
    total REAL NOT NULL DEFAULT 0,
    received_by TEXT NOT NULL DEFAULT '',
    notes TEXT NOT NULL DEFAULT ''
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS receiving_lines (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    store_id TEXT NOT NULL,
    receiving_id INTEGER NOT NULL,
    product_name TEXT NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 0,
    unit_cost REAL NOT NULL DEFAULT 0,
    selling_price REAL NOT NULL DEFAULT 0
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS accounts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    store_id TEXT NOT NULL,
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    opening_balance REAL NOT NULL DEFAULT 0
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS journal_entries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    store_id TEXT NOT NULL,
    date TEXT NOT NULL,
    memo TEXT NOT NULL DEFAULT '',
    created_by TEXT NOT NULL DEFAULT ''
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS journal_lines (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    store_id TEXT NOT NULL,
    entry_id INTEGER NOT NULL,
    account_id INTEGER NOT NULL,
    debit REAL NOT NULL DEFAULT 0,
    credit REAL NOT NULL DEFAULT 0
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS fixed_assets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    store_id TEXT NOT NULL,
    name TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT '',
    purchase_date TEXT NOT NULL,
    cost REAL NOT NULL DEFAULT 0,
    salvage_value REAL NOT NULL DEFAULT 0,
    useful_life_years INTEGER NOT NULL DEFAULT 5
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS bank_transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    store_id TEXT NOT NULL,
    date TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    amount REAL NOT NULL DEFAULT 0,
    reference TEXT NOT NULL DEFAULT '',
    matched INTEGER NOT NULL DEFAULT 0,
    account_name TEXT NOT NULL DEFAULT 'Bank'
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS tax_settings (
    id INTEGER PRIMARY KEY,
    enabled INTEGER NOT NULL DEFAULT 0,
    rate_percent REAL NOT NULL DEFAULT 0,
    prices_include_tax INTEGER NOT NULL DEFAULT 1,
    tax_id TEXT NOT NULL DEFAULT '',
    tax_label TEXT NOT NULL DEFAULT 'VAT',
    track_expense_tax INTEGER NOT NULL DEFAULT 1
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS receipt_settings (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    show_store_contact INTEGER NOT NULL DEFAULT 1,
    show_tax_id INTEGER NOT NULL DEFAULT 1,
    show_order_number INTEGER NOT NULL DEFAULT 1,
    show_date_time INTEGER NOT NULL DEFAULT 1,
    show_cashier INTEGER NOT NULL DEFAULT 1,
    show_customer INTEGER NOT NULL DEFAULT 1,
    show_payment_method INTEGER NOT NULL DEFAULT 1,
    show_item_count INTEGER NOT NULL DEFAULT 1,
    show_discount INTEGER NOT NULL DEFAULT 1,
    header TEXT NOT NULL DEFAULT '',
    footer TEXT NOT NULL DEFAULT ''
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS staff_roles (
    id TEXT PRIMARY KEY,
    store_id TEXT NOT NULL,
    title TEXT NOT NULL,
    subtitle TEXT NOT NULL,
    permissions_json TEXT NOT NULL,
    sort_order INTEGER NOT NULL
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS staff_members (
    id TEXT PRIMARY KEY,
    store_id TEXT NOT NULL,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT NOT NULL,
    role_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    username TEXT NOT NULL DEFAULT '',
    password_hash TEXT NOT NULL DEFAULT '',
    password_salt TEXT NOT NULL DEFAULT '',
    employee_number TEXT NOT NULL DEFAULT '',
    job_title TEXT NOT NULL DEFAULT '',
    department TEXT NOT NULL DEFAULT '',
    hire_date TEXT NOT NULL DEFAULT '',
    employment_type TEXT NOT NULL DEFAULT '',
    hourly_rate REAL NOT NULL DEFAULT 0,
    emergency_contact_name TEXT NOT NULL DEFAULT '',
    emergency_contact_phone TEXT NOT NULL DEFAULT '',
    emergency_contact_relation TEXT NOT NULL DEFAULT '',
    address TEXT NOT NULL DEFAULT '',
    notes TEXT NOT NULL DEFAULT '',
    avatar_path TEXT,
    status TEXT NOT NULL DEFAULT 'active',
    updated_at TEXT NOT NULL DEFAULT ''
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS app_profile (
    id INTEGER PRIMARY KEY,
    store_name TEXT NOT NULL,
    owner_name TEXT NOT NULL,
    role_title TEXT NOT NULL,
    business_category TEXT NOT NULL,
    contact_number TEXT NOT NULL,
    email_address TEXT NOT NULL,
    physical_address TEXT NOT NULL,
    tax_id TEXT NOT NULL DEFAULT '',
    weekday_open TEXT NOT NULL DEFAULT '',
    weekday_close TEXT NOT NULL DEFAULT '',
    saturday_open TEXT NOT NULL DEFAULT '',
    saturday_close TEXT NOT NULL DEFAULT '',
    sunday_schedule TEXT NOT NULL DEFAULT '',
    open_24_hours INTEGER NOT NULL DEFAULT 0,
    logo_path TEXT,
    capability_overrides_json TEXT,
    member_since TEXT NOT NULL
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS stores (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    contact TEXT NOT NULL
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS suspended_sales (
    id TEXT PRIMARY KEY,
    store_id TEXT NOT NULL,
    payload_json TEXT NOT NULL,
    created_at TEXT NOT NULL
  )
  ''',
];
