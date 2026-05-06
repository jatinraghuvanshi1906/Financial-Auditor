CREATE TABLE rejected_records (
    reject_id BIGSERIAL PRIMARY KEY,
    source_table VARCHAR(100),
    record_id VARCHAR(100),
    issue_type VARCHAR(100),
    issue_details TEXT,
    rejected_data JSONB,
    rejected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_fname VARCHAR(50),
	customer_lname VARCHAR(50),
	email VARCHAR(100),
	phone VARCHAR(15),
	created_at TIMESTAMP,
	status VARCHAR(10)
);

CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    customer_id INT,
	account_id INT,
    amount DECIMAL(12,4),
    transaction_type VARCHAR(10),
    status VARCHAR(20),
    payment_method_id INT,
    reference_id VARCHAR(100),
	created_at TIMESTAMP
);

CREATE TABLE invoices (
    invoice_id INT PRIMARY KEY,
    customer_id INT,
    total_amount DECIMAL(12,4),
    invoice_date DATE,
    status VARCHAR(20),
	created_at TIMESTAMP
);

CREATE TABLE payments (
    payment_id INT PRIMARY KEY,
	invoice_id INT,
    amount DECIMAL(12,4),
    payment_date TIMESTAMP,
    payment_method_id INT,
    status VARCHAR(20),
    reference_id VARCHAR(100)
);

CREATE TABLE payment_methods (
	method_id INT PRIMARY KEY,
	method_type VARCHAR(30),
	provider VARCHAR(100)
);

CREATE TABLE currency (
	currency_code CHAR(3) PRIMARY KEY,
	currency_name VARCHAR(20),
	exchange_rate DECIMAL(10,2)
);

CREATE TABLE fraud_flags (
	flag_id INT PRIMARY KEY,
	transaction_id INT,
	issue_type VARCHAR(50),
	severity VARCHAR(10),
	created_at TIMESTAMP
);

CREATE TABLE audit_logs (
    log_id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(100),
    record_id VARCHAR(100),
    column_name VARCHAR(100),
    audit_action VARCHAR(50),   -- INSERT / UPDATE / DELETE / ANOMALY
    issue_type VARCHAR(100),    -- Missing / Invalid / Fraud / Duplicate etc.
    severity VARCHAR(20),       -- Low / Medium / High / Critical
    old_value TEXT,
    new_value TEXT,
    detected_by VARCHAR(100),   -- SQL Rule / Airflow / dbt / Manual
    source_system VARCHAR(100), -- Payments / CRM / ERP
    remarks TEXT,
    status VARCHAR(50),         -- Open / Investigating / Resolved
    created_by VARCHAR(100),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE accounts (
	account_id INT PRIMARY KEY,
	customer_id INT,
	account_type VARCHAR(10),
	balance DECIMAL(12,4),
	status VARCHAR(20),
	created_at TIMESTAMP
);

CREATE TABLE transaction_items (
	item_id INT PRIMARY KEY, 
	transaction_id INT, 
	product_id INT, 
	quantity INT, 
	price DECIMAL(12,4)
);

CREATE TABLE products (
	product_id INT PRIMARY KEY, 
	product_name VARCHAR(100), 
	category VARCHAR(100), 
	price DECIMAL(12,4)
);

CREATE TABLE rejected_records (
    reject_id BIGSERIAL PRIMARY KEY,
    source_table VARCHAR(100),
    record_id VARCHAR(100),
    issue_type VARCHAR(100),
    issue_details TEXT,
    rejected_data JSONB,
    rejected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);