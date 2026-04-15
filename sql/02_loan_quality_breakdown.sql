-- ============================================================
-- File   : 02_loan_quality_breakdown.sql
-- Project: Bank Loan Dashboard (Power BI)
-- Purpose: Reproduce the Good Loan / Bad Loan split and the
--          Loan Status detail table on the Summary page.
--          Also includes a grade-level breakdown shown in the
--          Overview page filters.
-- Columns used: loan_status, loan_amount, total_payment,
--               int_rate, dti, issue_date, grade
-- Expected output:
--   Good Loan % : 86.2   (Fully Paid + Current)
--   Bad  Loan % : 13.8   (Charged Off)
--   Good applications : 33,243
--   Bad  applications :  5,333
--   Good funded_m  : 370.2   ($370.2 M)
--   Bad  funded_m  :  65.5   ($65.5 M)
--   Good received_m: 435.8   ($435.8 M)
--   Bad  received_m:  37.3   ($37.3 M)
--   Loan Status table: three rows — Current, Charged Off, Fully Paid
--   Grade table: rows A–G with application counts and avg metrics
-- Known discrepancies vs Power BI:
--   ✅  Good/Bad split logic matches Power BI classification.
--   ✅  Funded = SUM(loan_amount), Received = SUM(total_payment).
--   ⚠️  MTD columns in the Loan Status table use the same Dec 2021
--       hardcoded window as 01_kpi_summary.sql.
-- ============================================================

USE bank_loan_db;

-- ================================================================
-- Section A – Good Loan vs Bad Loan summary
-- ================================================================
WITH loan_class AS (
    SELECT *,
        CASE
            WHEN loan_status IN ('Fully Paid', 'Current') THEN 'Good Loan'
            ELSE 'Bad Loan'
        END AS loan_quality
    FROM financial_loan
),
totals AS (
    SELECT COUNT(*) AS grand_total FROM financial_loan
)
SELECT
    lc.loan_quality,
    COUNT(*)                                    AS applications,
    ROUND(COUNT(*) * 100.0 / t.grand_total, 1) AS pct_of_total,     -- expect 86.2 / 13.8
    ROUND(SUM(loan_amount)   / 1e6, 1)          AS funded_m,
    ROUND(SUM(total_payment) / 1e6, 1)          AS received_m,
    ROUND(AVG(int_rate) * 100, 2)               AS avg_int_rate_pct,
    ROUND(AVG(dti)      * 100, 2)               AS avg_dti_pct
FROM loan_class lc
CROSS JOIN totals t
GROUP BY lc.loan_quality, t.grand_total
ORDER BY lc.loan_quality DESC;   -- Good Loan first


-- ================================================================
-- Section B – Loan Status detail table (Current / Charged Off / Fully Paid)
--             Matches the grid shown at the bottom of Summary page
-- ================================================================
SELECT
    loan_status,
    COUNT(*)                                AS total_loan_applications,
    SUM(loan_amount)                        AS total_funded_amount,
    SUM(total_payment)                      AS total_amount_received,

    -- MTD figures (December 2021)
    SUM(CASE WHEN YEAR(issue_date) = 2021
              AND MONTH(issue_date) = 12
             THEN loan_amount   ELSE 0 END) AS mtd_funded_amount,
    SUM(CASE WHEN YEAR(issue_date) = 2021
              AND MONTH(issue_date) = 12
             THEN total_payment ELSE 0 END) AS mtd_amount_received,

    ROUND(AVG(int_rate) * 100, 2)           AS avg_interest_rate_pct,
    ROUND(AVG(dti)      * 100, 2)           AS avg_dti_pct
FROM financial_loan
GROUP BY loan_status
ORDER BY
    FIELD(loan_status, 'Current', 'Charged Off', 'Fully Paid');


-- ================================================================
-- Section C – Grade breakdown (A–G)
--             Drives the Grade slicer on both dashboard pages
-- ================================================================
SELECT
    grade,
    COUNT(*)                            AS applications,
    ROUND(SUM(loan_amount)   / 1e6, 2) AS funded_m,
    ROUND(SUM(total_payment) / 1e6, 2) AS received_m,
    ROUND(AVG(int_rate) * 100, 2)      AS avg_int_rate_pct,
    ROUND(AVG(dti)      * 100, 2)      AS avg_dti_pct,
    SUM(CASE WHEN loan_status IN ('Fully Paid','Current') THEN 1 ELSE 0 END)
                                        AS good_loans,
    SUM(CASE WHEN loan_status = 'Charged Off'             THEN 1 ELSE 0 END)
                                        AS bad_loans
FROM financial_loan
GROUP BY grade
ORDER BY grade;
