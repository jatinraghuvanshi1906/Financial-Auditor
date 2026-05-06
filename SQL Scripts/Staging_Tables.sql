-- Customers
CREATE TABLE stg_customers (
    customer_id TEXT,
    customer_fname TEXT,
    customer_lname TEXT,
    email TEXT,
    phone TEXT,
    created_at TEXT,
    status TEXT
);

-- Transactions
CREATE TABLE stg_transactions (
    transaction_id TEXT,
    customer_id TEXT,
    account_id TEXT,
    amount TEXT,
    transaction_type TEXT,
    status TEXT,
    payment_method_id TEXT,
    reference_id TEXT,
    created_at TEXT
);

-- Invoices
CREATE TABLE stg_invoices (
    invoice_id TEXT,
    customer_id TEXT,
    total_amount TEXT,
    invoice_date TEXT,
    status TEXT,
    created_at TEXT
);

-- Payments
CREATE TABLE stg_payments (
    payment_id TEXT,
    invoice_id TEXT,
    amount TEXT,
    payment_date TEXT,
    payment_method_id TEXT,
    status TEXT,
    reference_id TEXT
);

-- Payment Methods
CREATE TABLE stg_payment_methods (
    method_id TEXT,
    method_type TEXT,
    provider TEXT
);

-- Currency
CREATE TABLE stg_currency (
    currency_code TEXT,
    currency_name TEXT,
    exchange_rate TEXT
);

-- Accounts
CREATE TABLE stg_accounts (
    account_id TEXT,
    customer_id TEXT,
    account_type TEXT,
    balance TEXT,
    status TEXT,
    created_at TEXT
);

-- Transaction Items
CREATE TABLE stg_transaction_items (
    item_id TEXT,
    transaction_id TEXT,
    product_id TEXT,
    quantity TEXT,
    price TEXT
);

-- Products
CREATE TABLE stg_products (
    product_id TEXT,
    product_name TEXT,
    category TEXT,
    price TEXT
);
