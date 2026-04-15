-- ============================================================
-- File   : 00_setup.sql
-- Project: Bank Loan Dashboard (Power BI)
-- Purpose: Create the database, table, and load the raw CSV.
--          Handles DD-MM-YYYY date strings, leading-space trim
--          on the term column, and decimal-encoded rate/DTI fields.
-- Columns used: all 24 columns
-- Expected output:
--   After LOAD DATA: 38,576 rows (≈ 38.6 K as shown on the dashboard)
--   Sanity check query returns total_applications = 38576,
--   funded_m ≈ 435.8, received_m ≈ 473.1
-- Known discrepancies vs Power BI:
--   None — this file only loads data.
--   Rate/DTI are stored as raw decimals (e.g. 0.1200 = 12 %).
--   Multiply × 100 in SELECT statements (see 01_kpi_summary.sql).
-- ============================================================

-- ----------------------------------------------------------------
-- 1. Database
-- ----------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS bank_loan_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE bank_loan_db;

-- ----------------------------------------------------------------
-- 2. Table
-- ----------------------------------------------------------------
DROP TABLE IF EXISTS financial_loan;

CREATE TABLE financial_loan (
    id                    INT             NOT NULL,
    address_state         VARCHAR(2)      NOT NULL,
    application_type      VARCHAR(20)     NOT NULL,
    emp_length            VARCHAR(20),            -- e.g. '< 1 year', '10+ years'
    emp_title             VARCHAR(100),
    grade                 VARCHAR(1)      NOT NULL,
    home_ownership        VARCHAR(20)     NOT NULL,
    issue_date            DATE            NOT NULL, -- converted from DD-MM-YYYY
    last_credit_pull_date DATE,
    last_payment_date     DATE,
    loan_status           VARCHAR(20)     NOT NULL, -- Current | Charged Off | Fully Paid
    next_payment_date     DATE,                    -- NULL for completed loans
    member_id             INT,
    purpose               VARCHAR(50),
    sub_grade             VARCHAR(3),
    term                  VARCHAR(15),             -- '36 months' or '60 months' (leading space trimmed)
    verification_status   VARCHAR(20),
    annual_income         DECIMAL(15, 2),
    dti                   DECIMAL(8, 4),           -- stored as 0.1330 → 13.30 %
    installment           DECIMAL(10, 2),
    int_rate              DECIMAL(8, 4),           -- stored as 0.1200 → 12.00 %
    loan_amount           INT,                     -- used as "funded amount" in the dashboard
    total_acc             INT,
    total_payment         DECIMAL(12, 2),          -- used as "amount received" in the dashboard
    PRIMARY KEY (id)
);

-- ----------------------------------------------------------------
-- 3. Load CSV
--    • Update the file path to match your local machine.
--    • Enable LOCAL INFILE first if needed:
--        SET GLOBAL local_infile = 1;
--      or launch MySQL Workbench / CLI with --local-infile=1
--    • The CSV uses DD-MM-YYYY dates and a leading space in `term`.
-- ----------------------------------------------------------------
LOAD DATA LOCAL INFILE 'C:/path/to/data/financial_loan.csv'
INTO TABLE financial_loan
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    @id, @address_state, @application_type, @emp_length, @emp_title,
    @grade, @home_ownership,
    @issue_date, @last_credit_pull_date, @last_payment_date,
    @loan_status, @next_payment_date,
    @member_id, @purpose, @sub_grade, @term, @verification_status,
    @annual_income, @dti, @installment, @int_rate,
    @loan_amount, @total_acc, @total_payment
)
SET
    id                    = @id,
    address_state         = @address_state,
    application_type      = @application_type,
    emp_length            = NULLIF(TRIM(@emp_length), ''),
    emp_title             = NULLIF(TRIM(@emp_title), ''),
    grade                 = @grade,
    home_ownership        = @home_ownership,
    issue_date            = STR_TO_DATE(@issue_date,            '%d-%m-%Y'),
    last_credit_pull_date = NULLIF(STR_TO_DATE(@last_credit_pull_date, '%d-%m-%Y'), NULL),
    last_payment_date     = NULLIF(STR_TO_DATE(@last_payment_date,     '%d-%m-%Y'), NULL),
    loan_status           = @loan_status,
    next_payment_date     = NULLIF(STR_TO_DATE(@next_payment_date,     '%d-%m-%Y'), NULL),
    member_id             = @member_id,
    purpose               = @purpose,
    sub_grade             = @sub_grade,
    term                  = TRIM(@term),          -- strip leading space from CSV
    verification_status   = @verification_status,
    annual_income         = @annual_income,
    dti                   = @dti,
    installment           = @installment,
    int_rate              = @int_rate,
    loan_amount           = @loan_amount,
    total_acc             = @total_acc,
    total_payment         = @total_payment;

-- ----------------------------------------------------------------
-- 4. Sanity check — should match dashboard headline numbers
-- ----------------------------------------------------------------
SELECT
    COUNT(*)                                        AS total_applications,  -- expect 38,576
    ROUND(SUM(loan_amount)   / 1000000, 1)          AS funded_m,            -- expect 435.8
    ROUND(SUM(total_payment) / 1000000, 1)          AS received_m,          -- expect 473.1
    ROUND(AVG(int_rate) * 100, 1)                   AS avg_int_rate_pct,    -- expect 12.0
    ROUND(AVG(dti)      * 100, 1)                   AS avg_dti_pct,         -- expect 13.3
    MIN(issue_date)                                 AS earliest_issue,
    MAX(issue_date)                                 AS latest_issue
FROM financial_loan;
