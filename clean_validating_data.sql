INSERT INTO rejected_records
(source_table, record_id, issue_type, issue_details, rejected_data)
SELECT
    'stg_customers',
    COALESCE(customer_id,'NULL'),
    'Invalid ID Format',
    'customer_id contains invalid non-numeric value',
    to_jsonb(stg_customers)
FROM stg_customers
WHERE customer_id IS NULL OR NULLIF(REGEXP_REPLACE(customer_id,'[^0-9.]','','g'),'') IS NULL;

DELETE FROM stg_customers
WHERE customer_id IS NULL OR NULLIF(REGEXP_REPLACE(customer_id,'[^0-9.]','','g'),'') IS NULL;

INSERT INTO rejected_records
(source_table, record_id, issue_type, issue_details, rejected_data)
SELECT
    'stg_customers',
    customer_id,
    'Invalid Timestamp Format',
    'created_at contains invalid timestamp',
    to_jsonb(stg_customers)
FROM stg_customers
WHERE created_at IS NULL OR created_at !~ '^\d{4}-\d{2}-\d{2}';

DELETE FROM stg_customers
WHERE created_at IS NULL OR created_at !~ '^\d{4}-\d{2}-\d{2}';

DELETE FROM stg_customers a
USING stg_customers b
WHERE a.ctid < b.ctid
AND LOWER(TRIM(a.email)) = LOWER(TRIM(b.email)) AND a.email IS NOT NULL;

UPDATE stg_customers SET status = LOWER(TRIM(status));
UPDATE stg_customers SET status = 'active' WHERE status IS NULL OR status NOT IN ('active','inactive');

INSERT INTO customers
SELECT DISTINCT ON (NULLIF(REGEXP_REPLACE(customer_id,'[^0-9.]','','g'),'')::NUMERIC::INT)
    NULLIF(REGEXP_REPLACE(customer_id,'[^0-9.]','','g'),'')::NUMERIC::INT,
    customer_fname,
    customer_lname,
    email,
    phone,
    created_at::TIMESTAMP,
    LEFT(status, 10)
FROM stg_customers
ORDER BY
    NULLIF(REGEXP_REPLACE(customer_id,'[^0-9.]','','g'),'')::NUMERIC::INT,
    created_at::TIMESTAMP DESC
ON CONFLICT (customer_id)
DO UPDATE
SET
    customer_fname = EXCLUDED.customer_fname,
    customer_lname = EXCLUDED.customer_lname,
    email = EXCLUDED.email,
    phone = EXCLUDED.phone,
    status = EXCLUDED.status,
    created_at = EXCLUDED.created_at;

DELETE FROM stg_accounts
WHERE account_id IS NULL OR NULLIF(REGEXP_REPLACE(account_id,'[^0-9.]','','g'),'') IS NULL;

DELETE FROM stg_accounts
WHERE balance IS NULL OR NULLIF(REGEXP_REPLACE(balance,'[^0-9.-]','','g'),'') IS NULL OR NULLIF(REGEXP_REPLACE(balance,'[^0-9.-]','','g'),'')::DECIMAL <= 0;

UPDATE stg_accounts SET status = LOWER(TRIM(status));
UPDATE stg_accounts SET status = 'active' WHERE status IS NULL OR status NOT IN ('active','inactive');

INSERT INTO accounts
SELECT DISTINCT ON (NULLIF(REGEXP_REPLACE(account_id,'[^0-9.]','','g'),'')::NUMERIC::INT)
    NULLIF(REGEXP_REPLACE(account_id,'[^0-9.]','','g'),'')::NUMERIC::INT,
    NULLIF(REGEXP_REPLACE(customer_id,'[^0-9.]','','g'),'')::NUMERIC::INT,
   	LEFT(account_type, 10),
    NULLIF(REGEXP_REPLACE(balance,'[^0-9.-]','','g'),'')::DECIMAL(18,4),
    LEFT(status, 10),
    created_at::TIMESTAMP
FROM stg_accounts
ORDER BY
    NULLIF(REGEXP_REPLACE(account_id,'[^0-9.]','','g'),'')::NUMERIC::INT,
    created_at::TIMESTAMP DESC
ON CONFLICT (account_id)
DO UPDATE
SET
    customer_id = EXCLUDED.customer_id,
    account_type = EXCLUDED.account_type,
    balance = EXCLUDED.balance,
    status = EXCLUDED.status,
    created_at = EXCLUDED.created_at;

DELETE FROM stg_transactions
WHERE transaction_id IS NULL OR NULLIF(REGEXP_REPLACE(transaction_id,'[^0-9.]','','g'),'') IS NULL;

DELETE FROM stg_transactions
WHERE amount IS NULL OR NULLIF(REGEXP_REPLACE(amount,'[^0-9.-]','','g'),'') IS NULL OR NULLIF(REGEXP_REPLACE(amount,'[^0-9.-]','','g'),'')::DECIMAL <= 0;

DELETE FROM stg_transactions
WHERE created_at IS NULL OR created_at !~ '^\d{4}-\d{2}-\d{2}';

UPDATE stg_transactions SET status = LOWER(TRIM(status));

UPDATE stg_transactions SET status = 'pending' WHERE status IS NULL OR status NOT IN ('success','failed','pending');

INSERT INTO transactions
SELECT DISTINCT ON (NULLIF(REGEXP_REPLACE(transaction_id,'[^0-9.]','','g'),'')::NUMERIC::INT)
    NULLIF(REGEXP_REPLACE(transaction_id,'[^0-9.]','','g'),'')::NUMERIC::INT,
    NULLIF(REGEXP_REPLACE(customer_id,'[^0-9.]','','g'),'')::NUMERIC::INT,
	NULLIF(REGEXP_REPLACE(account_id,'[^0-9.]','','g'),'')::NUMERIC::INT,
    NULLIF(REGEXP_REPLACE(amount,'[^0-9.-]','','g'),'')::DECIMAL(18,4),
    LEFT(transaction_type, 10),
    LEFT(status, 10),
    payment_method_id::NUMERIC::INT,
    reference_id,
    created_at::TIMESTAMP
FROM stg_transactions
ORDER BY
    NULLIF(REGEXP_REPLACE(transaction_id,'[^0-9.]','','g'),'')::NUMERIC::INT,
    created_at::TIMESTAMP DESC
ON CONFLICT (transaction_id)
DO UPDATE
SET
    customer_id = EXCLUDED.customer_id,
    account_id = EXCLUDED.account_id,
    amount = EXCLUDED.amount,
    transaction_type = EXCLUDED.transaction_type,
    status = EXCLUDED.status,
    payment_method_id = EXCLUDED.payment_method_id,
    reference_id = EXCLUDED.reference_id,
    created_at = EXCLUDED.created_at;

DELETE FROM stg_invoices
WHERE invoice_id IS NULL OR NULLIF(REGEXP_REPLACE(invoice_id,'[^0-9.]','','g'),'') IS NULL;

DELETE FROM stg_invoices
WHERE invoice_date IS NULL OR invoice_date !~ '^\d{4}-\d{2}-\d{2}$';

DELETE FROM stg_invoices
WHERE total_amount IS NULL OR NULLIF(REGEXP_REPLACE(total_amount,'[^0-9.-]','','g'),'') IS NULL OR NULLIF(REGEXP_REPLACE(total_amount,'[^0-9.-]','','g'),'')::DECIMAL <= 0;

INSERT INTO invoices
SELECT DISTINCT ON (NULLIF(REGEXP_REPLACE(invoice_id,'[^0-9.]','','g'),'')::NUMERIC::INT)
    NULLIF(REGEXP_REPLACE(invoice_id,'[^0-9.]','','g'),'')::NUMERIC::INT,
    NULLIF(REGEXP_REPLACE(customer_id,'[^0-9.]','','g'),'')::NUMERIC::INT,
    total_amount::DECIMAL(18,4),
    invoice_date::DATE,
    LEFT(status, 10),
    created_at::TIMESTAMP
FROM stg_invoices
ORDER BY
    NULLIF(REGEXP_REPLACE(invoice_id,'[^0-9.]','','g'),'')::NUMERIC::INT,
    created_at::TIMESTAMP DESC
ON CONFLICT (invoice_id)
DO UPDATE
SET
    customer_id = EXCLUDED.customer_id,
    total_amount = EXCLUDED.total_amount,
    invoice_date = EXCLUDED.invoice_date,
    status = EXCLUDED.status,
    created_at = EXCLUDED.created_at;

DELETE FROM stg_payments
WHERE payment_id IS NULL OR NULLIF(REGEXP_REPLACE(payment_id,'[^0-9.]','','g'),'') IS NULL;

DELETE FROM stg_payments
WHERE amount IS NULL OR NULLIF(REGEXP_REPLACE(amount,'[^0-9.-]','','g'),'') IS NULL OR NULLIF(REGEXP_REPLACE(amount,'[^0-9.-]','','g'),'')::DECIMAL <= 0;

INSERT INTO payments
SELECT DISTINCT ON (NULLIF(REGEXP_REPLACE(payment_id,'[^0-9.]','','g'),'')::NUMERIC::INT)
    NULLIF(REGEXP_REPLACE(payment_id,'[^0-9.]','','g'),'')::NUMERIC::INT,
    NULLIF(REGEXP_REPLACE(invoice_id,'[^0-9.]','','g'),'')::NUMERIC::INT,
    amount::DECIMAL(18,4),
    payment_date::TIMESTAMP,
    payment_method_id::NUMERIC::INT,
    LEFT(status, 10),
    reference_id
FROM stg_payments
ORDER BY
    NULLIF(REGEXP_REPLACE(payment_id,'[^0-9.]','','g'),'')::NUMERIC::INT,
    payment_date::TIMESTAMP DESC
ON CONFLICT (payment_id)
DO UPDATE
SET
    invoice_id = EXCLUDED.invoice_id,
    amount = EXCLUDED.amount,
    payment_date = EXCLUDED.payment_date,
    payment_method_id = EXCLUDED.payment_method_id,
    status = EXCLUDED.status,
    reference_id = EXCLUDED.reference_id;