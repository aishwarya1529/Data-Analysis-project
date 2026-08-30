-- create database UPI_Transactions;

use UPI_Transactions;
SET SQL_SAFE_UPDATES = 0;

/*
-- Step 1: Standardize datetime format (Commented out to prevent Error 1411 on re-run)
UPDATE upi_transactions 
SET transacted_at = STR_TO_DATE(transacted_at, '%d-%m-%Y %H:%i')
WHERE transacted_at IS NOT NULL AND transacted_at LIKE '%-%';
*/

/*
-- Step 2: Optimize column data types and lengths to prevent string truncation (Completed)
ALTER TABLE upi_transactions 
    MODIFY COLUMN transaction_id VARCHAR(100) NOT NULL,
    MODIFY COLUMN transacted_at DATETIME,
    MODIFY COLUMN transaction_type VARCHAR(100),
    MODIFY COLUMN merchant_category VARCHAR(100),
    MODIFY COLUMN amt_inr DECIMAL(10, 2),
    MODIFY COLUMN transaction_status VARCHAR(50),
    MODIFY COLUMN sender_age_grp VARCHAR(50),
    MODIFY COLUMN receiver_age_grp VARCHAR(50),
    MODIFY COLUMN sender_state VARCHAR(100),
    MODIFY COLUMN sender_bank VARCHAR(100),
    MODIFY COLUMN receiver_bank VARCHAR(100),
    MODIFY COLUMN device_type VARCHAR(50),
    MODIFY COLUMN network_type VARCHAR(50),
    MODIFY COLUMN fraud_flag TINYINT(1),
    MODIFY COLUMN hour_of_day TINYINT UNSIGNED,
    MODIFY COLUMN day_of_week VARCHAR(50),
    MODIFY COLUMN is_weekend TINYINT(1);
*/

/*
-- Step 3: Enforce entity integrity by assigning the Primary Key (Commented out to avoid duplicate key error)
ALTER TABLE upi_transactions 
    ADD PRIMARY KEY (transaction_id);
*/

-- Verify a small sample of the finalized dataset
SELECT * FROM upi_transactions LIMIT 10;

DESCRIBE upi_transactions;

-- DATA ANALYSIS

SELECT COUNT(*) AS total_transactions
FROM upi_transactions;

select round(sum(amt_inr),2) as total_transaction_val
from upi_transactions;

-- Failure rate
select round(
       SUM(case when transaction_status = 'FAILED' then 1 else 0 end)*100/count(*),2)
       AS failre_rate_pct
from upi_transactions;


SELECT
    transaction_status,
    COUNT(*) AS transaction_count,
    ROUND(SUM(amt_inr), 2) AS transaction_value
FROM upi_transactions
GROUP BY transaction_status;

-- Which banks are experiencing the highest UPI payment failure rates?
SELECT sender_bank,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN transaction_status = 'FAILED' THEN 1 ELSE 0 END) AS failed_transactions,
    ROUND(SUM(CASE WHEN transaction_status = 'FAILED' THEN 1 ELSE 0 END) * 100.0/ COUNT(*), 2
    ) AS failure_rate_pct
FROM upi_transactions
GROUP BY sender_bank
ORDER BY failure_rate_pct DESC;

-- Does P2P or P2M have a higher failure rate?

SELECT transaction_type,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN transaction_status = 'FAILED' THEN 1 ELSE 0 END) AS failed_transactions,
    ROUND(SUM(CASE WHEN transaction_status = 'FAILED' THEN 1 ELSE 0 END) * 100.0/ COUNT(*), 2
    ) AS failure_rate_pct
FROM upi_transactions
GROUP BY transaction_type
ORDER BY failure_rate_pct DESC;

-- At what hours do UPI failures happen most?
SELECT
    hour_of_day,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN transaction_status = 'FAILED' THEN 1 ELSE 0 END) AS failed_transactions,
    ROUND(
        SUM(CASE WHEN transaction_status = 'FAILED' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2
    ) AS failure_rate_pct
FROM upi_transactions
GROUP BY hour_of_day
ORDER BY hour_of_day;

-- Which network type has the highest UPI failure rate?
SELECT network_type,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN transaction_status = 'FAILED' THEN 1 ELSE 0 END) AS failed_transactions,
    ROUND(SUM(CASE WHEN transaction_status = 'FAILED' THEN 1 ELSE 0 END) * 100.0/ COUNT(*), 2
    ) AS failure_rate_pct
FROM upi_transactions
GROUP BY network_type
ORDER BY failure_rate_pct DESC;

-- Does device type affect payment reliability?
SELECT device_type,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN transaction_status = 'FAILED' THEN 1 ELSE 0 END) AS failed_transactions,
    ROUND(SUM(CASE WHEN transaction_status = 'FAILED' THEN 1 ELSE 0 END) * 100.0/ COUNT(*), 2
    ) AS failure_rate_pct
FROM upi_transactions
GROUP BY device_type
ORDER BY failure_rate_pct DESC;


-- Which banks have the highest failed transaction value?
SELECT
    sender_bank,
    COUNT(*) AS failed_transactions,
    ROUND(SUM(amt_inr), 2) AS failed_transaction_value,
    ROUND(AVG(amt_inr), 2) AS avg_failed_transaction_value
FROM upi_transactions
WHERE transaction_status = 'FAILED'
GROUP BY sender_bank
ORDER BY failed_transaction_value DESC;


-- Which merchant categories generate the highest transaction value?
--  Where is the UPI money mainly moving

SELECT
    merchant_category,
    COUNT(*) AS total_transactions,
    ROUND(SUM(amt_inr), 2) AS total_transaction_value,
    ROUND(AVG(amt_inr), 2) AS avg_transaction_value
FROM upi_transactions
WHERE transaction_status = 'SUCCESS'
GROUP BY merchant_category
ORDER BY total_transaction_value DESC;

-- Which merchant categories show the highest fraud exposure?

SELECT
    merchant_category,
    SUM(fraud_flag) AS fraud_transactions,
    ROUND(SUM(CASE WHEN fraud_flag = 1 THEN amt_inr ELSE 0 END), 2) AS fraud_transaction_value,
    ROUND(SUM(fraud_flag) * 100.0 / COUNT(*), 2) AS fraud_rate_pct
FROM upi_transactions
GROUP BY merchant_category
ORDER BY fraud_transaction_value DESC;


-- Which transaction types have the highest fraud exposure?

SELECT
    transaction_type,
    COUNT(*) AS total_transactions,
    SUM(fraud_flag) AS fraud_transactions,
    ROUND(SUM(CASE WHEN fraud_flag = 1 THEN amt_inr ELSE 0 END), 2) AS fraud_transaction_value
FROM upi_transactions
GROUP BY transaction_type
ORDER BY fraud_transaction_value DESC;

-- Do weekdays and weekends show different transaction behaviour?
SELECT
    CASE
        WHEN is_weekend = 1 THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    COUNT(*) AS total_transactions,
    ROUND(SUM(amt_inr), 2) AS total_transaction_value,
    ROUND(AVG(amt_inr), 2) AS avg_transaction_value
FROM upi_transactions
GROUP BY day_type;
