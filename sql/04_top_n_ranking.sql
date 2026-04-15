-- ============================================================
-- File   : 04_top_n_ranking.sql
-- Project: Bank Loan Dashboard (Power BI)
-- Purpose: Rank loan purposes, employment lengths, and terms
--          using ROW_NUMBER() window functions inside CTEs.
--          Reproduces the three bar/donut charts on the Overview
--          page: "By Purpose", "By Employee Length", "By Term".
-- Columns used: purpose, emp_length, term, loan_amount,
--               total_payment, int_rate, loan_status
-- Expected output:
--   Purpose  rank 1 : debt_consolidation (largest bar by far)
--   Purpose  rank 2 : credit_card
--   Emp len  rank 1 : 10+ years
--   Term     split  : ~73 % 36 months, ~27 % 60 months
--     (approx — exact split visible in the donut chart)
-- Known discrepancies vs Power BI:
--   ✅  Aggregation and ranking logic match the bar chart order.
--   ⚠️  Power BI's bar charts sort by a single measure (usually
--       applications count); this file ranks by applications
--       which matches that default sort.
-- ============================================================

USE bank_loan_db;

-- ================================================================
-- Section A – Top loan purposes  (Overview: "By Purpose" bar chart)
-- ================================================================
WITH purpose_metrics AS (
    SELECT
        purpose,
        COUNT(*)                                AS applications,
        ROUND(SUM(loan_amount)   / 1e6, 2)      AS funded_m,
        ROUND(SUM(total_payment) / 1e6, 2)      AS received_m,
        ROUND(AVG(int_rate) * 100, 2)           AS avg_int_rate_pct,
        ROUND(AVG(dti)      * 100, 2)           AS avg_dti_pct,
        ROUND(
            SUM(CASE WHEN loan_status IN ('Fully Paid','Current') THEN 1 ELSE 0 END)
            * 100.0 / COUNT(*), 1)              AS good_loan_pct
    FROM financial_loan
    GROUP BY purpose
),
purpose_ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (ORDER BY applications DESC) AS rnk
    FROM purpose_metrics
)
SELECT
    rnk,
    purpose,
    applications,
    funded_m,
    received_m,
    avg_int_rate_pct,
    avg_dti_pct,
    good_loan_pct
FROM purpose_ranked
ORDER BY rnk;


-- ================================================================
-- Section B – Loans by employment length  (Overview: "By Emp Length")
-- ================================================================
WITH emp_metrics AS (
    SELECT
        emp_length,
        COUNT(*)                                AS applications,
        ROUND(SUM(loan_amount)   / 1e6, 2)      AS funded_m,
        ROUND(AVG(int_rate) * 100, 2)           AS avg_int_rate_pct,
        ROUND(
            SUM(CASE WHEN loan_status IN ('Fully Paid','Current') THEN 1 ELSE 0 END)
            * 100.0 / COUNT(*), 1)              AS good_loan_pct
    FROM financial_loan
    GROUP BY emp_length
),
emp_ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (ORDER BY applications DESC) AS rnk
    FROM emp_metrics
)
SELECT
    rnk,
    COALESCE(emp_length, 'Not Specified')   AS emp_length,
    applications,
    funded_m,
    avg_int_rate_pct,
    good_loan_pct
FROM emp_ranked
ORDER BY rnk;


-- ================================================================
-- Section C – Loan term split  (Overview: "By Term" donut chart)
-- ================================================================
WITH term_metrics AS (
    SELECT
        term,
        COUNT(*)                                AS applications,
        ROUND(SUM(loan_amount)   / 1e6, 2)      AS funded_m,
        ROUND(AVG(int_rate) * 100, 2)           AS avg_int_rate_pct
    FROM financial_loan
    GROUP BY term
),
total AS (SELECT COUNT(*) AS grand FROM financial_loan),
term_ranked AS (
    SELECT
        tm.*,
        ROUND(tm.applications * 100.0 / t.grand, 1)    AS pct_of_total,
        ROW_NUMBER() OVER (ORDER BY tm.applications DESC) AS rnk
    FROM term_metrics tm
    CROSS JOIN total t
)
SELECT
    rnk,
    term,
    applications,
    pct_of_total,
    funded_m,
    avg_int_rate_pct
FROM term_ranked
ORDER BY rnk;
