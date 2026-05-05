
INSERT INTO audit_results
SELECT 'Duplicate','Duplicate Customer Email',email,
'Multiple customers share same email','Medium',NULL,count(*)
FROM customers
WHERE email IS NOT NULL
GROUP BY email
HAVING COUNT(*) > 1;



INSERT INTO audit_results
SELECT 'Duplicate','Duplicate Transaction Reference',reference_id,
'Duplicate transaction reference_id detected','High',NULL,count(*)
FROM TRANSACTIONS
WHERE reference_id IS NOT NULL
GROUP BY reference_id
HAVING COUNT(*) > 1;

INSERT INTO audit_results
SELECT 'Duplicate','Duplicate Payment Reference',reference_id,
'Duplicate payment reference_id detected','High',NULL,count(*)
FROM payments
GROUP BY reference_id
HAVING COUNT(*) > 1;


INSERT INTO audit_results
SELECT 'Referential Integrity','Invalid Customer in Transaction',
t.transaction_id::TEXT,
'Transaction linked to non-existent customer','High',t.amount,NULL
FROM transactions t
LEFT JOIN customers c ON t.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


INSERT INTO audit_results
SELECT 'Referential Integrity','Payment Without Invoice',
p.payment_id::TEXT,
'Payment has no matching invoice','High',p.amount,NULL
FROM payments p
LEFT JOIN invoices i ON p.invoice_id = i.invoice_id
WHERE i.invoice_id IS NULL;


INSERT INTO audit_results
SELECT 'Mismatch','Invoice Payment Mismatch',
i.invoice_id::TEXT,
'Invoice amount does not match total payments','High',
ABS(i.total_amount - COALESCE(SUM(p.amount),0)),NULL
FROM invoices i
LEFT JOIN payments p ON i.invoice_id = p.invoice_id
GROUP BY i.invoice_id, i.total_amount
HAVING i.total_amount != COALESCE(SUM(p.amount),0);


INSERT INTO audit_results
SELECT 'Revenue Leakage','Unpaid Invoice Amount',
i.invoice_id::TEXT,
'Invoice amount greater than payments','High',
i.total_amount - COALESCE(SUM(p.amount),0),NULL
FROM invoices i
LEFT JOIN payments p ON i.invoice_id = p.invoice_id
GROUP BY i.invoice_id, i.total_amount
HAVING i.total_amount > COALESCE(SUM(p.amount),0);


INSERT INTO audit_results
SELECT 'Invalid','Negative Transaction Amount',
transaction_id::TEXT,
'Transaction amount is zero or negative','Medium',amount,NULL
FROM transactions
WHERE amount <= 0;


INSERT INTO audit_results
SELECT 'Invalid','Negative Account Balance',
account_id::TEXT,
'Account balance is negative','High',balance,NULL
FROM accounts
WHERE balance < 0;


INSERT INTO audit_results
SELECT 'Missing','Missing Transaction Fields',
transaction_id::TEXT,
'Critical fields missing','High',NULL,
CASE
        WHEN customer_id IS NULL THEN 'customer_id'
        WHEN amount IS NULL THEN 'amount'
        WHEN created_at IS NULL THEN 'created_at'
        WHEN account_id IS NULL THEN 'account_id'
        ELSE 'unknown' 
		END
FROM transactions
WHERE customer_id IS NULL OR amount IS NULL OR created_at IS NULL OR account_id IS NULL;


INSERT INTO audit_results
SELECT 
    'Invalid',
    'Invalid Transaction Status',
    transaction_id::TEXT,
    'Invalid status value',
    'Low',
    NULL,
    COALESCE(status, 'NULL status') AS impact_value
FROM transactions
WHERE status IS NULL
   OR LOWER(status) NOT IN ('success', 'failed', 'pending');

   

INSERT INTO audit_results
SELECT 'Mismatch','Paid Invoice Without Payment',
i.invoice_id::TEXT,
'Invoice marked paid but no payment found','High',i.total_amount,NULL
FROM invoices i
LEFT JOIN payments p ON i.invoice_id = p.invoice_id
WHERE LOWER(i.status) = 'paid' AND p.invoice_id IS NULL;


INSERT INTO audit_results
SELECT 'Invalid','Future Transaction',
transaction_id::TEXT,
'Transaction timestamp is in future','Medium',amount,NULL
FROM transactions
WHERE created_at > CURRENT_TIMESTAMP;


INSERT INTO audit_results
SELECT 'Invalid','Payment Before Invoice',
p.payment_id::TEXT,
'Payment date is before invoice date','Medium',p.amount,NULL
FROM payments p
JOIN invoices i ON p.invoice_id = i.invoice_id
WHERE p.payment_date < i.invoice_date;


INSERT INTO audit_results
SELECT 'Suspicious','High Value Transaction',
transaction_id::TEXT,
'Transaction significantly higher than average','High',amount,NULL
FROM transactions
WHERE amount > (SELECT AVG(amount) + 3 * STDDEV(amount) FROM transactions);


INSERT INTO audit_results
SELECT 'Fraud','High Frequency Transactions',
customer_id::TEXT,
'Too many transactions in short time','High',NULL,COUNT(*)
FROM transactions
WHERE created_at > CURRENT_TIMESTAMP - INTERVAL '1 hour'
GROUP BY customer_id
HAVING COUNT(*) > 5;


INSERT INTO audit_results
SELECT 'Fraud','Multiple Failed Transactions',
customer_id::TEXT,
'Multiple failed transactions detected','Medium',NULL,COUNT(*)
FROM transactions
WHERE LOWER(status)='failed'
GROUP BY customer_id
HAVING COUNT(*) > 3;


INSERT INTO audit_results
SELECT 'Referential Integrity','Invalid Product in Transaction Item',
ti.item_id::TEXT,
'Transaction item has invalid product','Medium',ti.price,NULL
FROM transaction_items ti
LEFT JOIN products p ON ti.product_id = p.product_id
WHERE p.product_id IS NULL;

-- 19. Product Price Mismatch
INSERT INTO audit_results
SELECT 'Mismatch','Product Price Mismatch',
ti.item_id::TEXT,
'Transaction item price differs from product price','Medium',
ABS(ti.price - p.price),NULL
FROM transaction_items ti
JOIN products p ON ti.product_id = p.product_id
WHERE COALESCE(ti.price,0) <> COALESCE(p.price,0);


INSERT INTO audit_results
SELECT 'Referential Integrity','Account Without Customer',
a.account_id::TEXT,
'Account linked to invalid customer','High',a.balance,NULL
FROM accounts a
LEFT JOIN customers c ON a.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


INSERT INTO audit_results
SELECT 'Missing','Missing Customer Contact',
customer_id::TEXT,
'Customer missing both email and phone','Low',NULL,
CASE WHEN EMAIL IS NULL THEN 'EMAIL'
 WHEN PHONE IS NULL THEN 'PHONE'
END
FROM customers
WHERE email IS NULL AND phone IS NULL;


INSERT INTO audit_results
SELECT 'Business Rule','Multiple Accounts per Customer',
customer_id::TEXT,
'Customer has more than allowed accounts','Low',NULL,COUNT(*)
FROM accounts
GROUP BY customer_id
HAVING COUNT(*) > 3;


INSERT INTO audit_results
SELECT 'Suspicious','Midnight High Transactions',
customer_id::TEXT,
'High transaction during unusual hours','Medium',amount,NULL
FROM transactions
WHERE EXTRACT(HOUR FROM created_at) BETWEEN 1 AND 4
AND amount > (SELECT AVG(amount) FROM transactions);


INSERT INTO audit_results
SELECT 'Fraud','Continuous Failed Attempts',
customer_id::TEXT,
'Repeated failures in short window','High',NULL,COUNT(*)
FROM transactions
WHERE LOWER(status)='failed'
GROUP BY customer_id, DATE(created_at)
HAVING COUNT(*) > 3
AND MAX(created_at) - MIN(created_at) <= INTERVAL '20 minutes';



INSERT INTO fraud_flags (transaction_id, issue_type, severity,created_at)
SELECT 
    record_id::INT,
    rule_name,
    severity,
	created_at
FROM audit_results
WHERE issue_type IN
('Fraud','Suspicious')
  AND severity = 'High';


