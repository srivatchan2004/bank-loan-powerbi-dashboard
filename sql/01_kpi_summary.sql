-- ============================================================
-- File   : 01_kpi_summary.sql
-- Project: Bank Loan Dashboard (Power BI)
-- Purpose: Reproduce every headline KPI card on the Summary page:
--          total, MTD (Dec 2021), and MoM % change (Nov → Dec).
-- Columns used: issue_date, loan_amount, total_payment, int_rate, dti
-- Expected output (matches dashboard cards):
--   total_applications : 38,576  (≈ 38.6 K)
--   total_funded_m     : 435.8   ($435.8 M)
--   total_received_m   : 473.1   ($473.1 M)
--   avg_int_rate_pct   : 12.0
--   avg_dti_pct        : 13.3
--   mtd_applications   : 4,300   (≈ 4.3 K)
--   mtd_funded_m       : 54.0    ($54.0 M)
--   mtd_received_m     : 58.1    ($58.1 M)
--   mtd_avg_int_rate   : 12.4
--   mtd_avg_dti        : 13.7
--   mom_applications_pct : 6.9
--   mom_funded_pct       : 13.0
--   mom_received_pct     : 15.8
--   mom_int_rate_pct     : 3.5
--   mom_dti_pct          : 2.7
-- Known discrepancies vs Power BI:
--   ⚠️  MTD: Power BI computes MTD dynamically against TODAY(); this
--       script hardcodes December 2021 as the reference month because
--       the dataset ends in 2021. In a live system, replace the
--       hardcoded year/month with YEAR(CURDATE())/MONTH(CURDATE()).
--   ✅  All other formulas match DAX equivalents exactly.
-- ============================================================

USE bank_loan_db;

-- ----------------------------------------------------------------
-- Step 1 – Aggregate by month so we can compute MTD and MoM in one pass
-- ----------------------------------------------------------------
WITH monthly AS (
    SELECT
        YEAR(issue_date)  AS yr,
        MONTH(issue_date) AS mth,
        COUNT(*)                        AS applications,
        SUM(loan_amount)                AS funded,
        SUM(total_payment)              AS received,
        AVG(int_rate)                   AS avg_int_rate,   -- raw decimal
        AVG(dti)                        AS avg_dti         -- raw decimal
    FROM financial_loan
    GROUP BY yr, mth
),

-- ----------------------------------------------------------------
-- Step 2 – Tag the current month (Dec 2021) and previous month (Nov 2021)
-- ----------------------------------------------------------------
tagged AS (
    SELECT *,
        CASE WHEN yr = 2021 AND mth = 12 THEN 'current'
             WHEN yr = 2021 AND mth = 11 THEN 'previous'
             ELSE 'other' END           AS period
    FROM monthly
)

-- ----------------------------------------------------------------
-- Step 3 – Pivot into a single summary row
-- ----------------------------------------------------------------
SELECT
    -- Overall totals (all-time)
    (SELECT COUNT(*)                          FROM financial_loan)          AS total_applications,
    ROUND((SELECT SUM(loan_amount)            FROM financial_loan) / 1e6, 1) AS total_funded_m,
    ROUND((SELECT SUM(total_payment)          FROM financial_loan) / 1e6, 1) AS total_received_m,
    ROUND((SELECT AVG(int_rate) * 100         FROM financial_loan), 1)        AS avg_int_rate_pct,
    ROUND((SELECT AVG(dti)      * 100         FROM financial_loan), 1)        AS avg_dti_pct,

    -- MTD (December 2021)
    MAX(CASE WHEN period = 'current' THEN applications  END)                AS mtd_applications,
    ROUND(MAX(CASE WHEN period = 'current' THEN funded   END) / 1e6, 1)     AS mtd_funded_m,
    ROUND(MAX(CASE WHEN period = 'current' THEN received END) / 1e6, 1)     AS mtd_received_m,
    ROUND(MAX(CASE WHEN period = 'current' THEN avg_int_rate END) * 100, 1) AS mtd_avg_int_rate_pct,
    ROUND(MAX(CASE WHEN period = 'current' THEN avg_dti      END) * 100, 1) AS mtd_avg_dti_pct,

    -- MoM % change  = (current - previous) / previous × 100
    ROUND(
        (MAX(CASE WHEN period = 'current'  THEN applications END) -
         MAX(CASE WHEN period = 'previous' THEN applications END)) /
         MAX(CASE WHEN period = 'previous' THEN applications END) * 100
    , 1)                                                                     AS mom_applications_pct,

    ROUND(
        (MAX(CASE WHEN period = 'current'  THEN funded END) -
         MAX(CASE WHEN period = 'previous' THEN funded END)) /
         MAX(CASE WHEN period = 'previous' THEN funded END) * 100
    , 1)                                                                     AS mom_funded_pct,

    ROUND(
        (MAX(CASE WHEN period = 'current'  THEN received END) -
         MAX(CASE WHEN period = 'previous' THEN received END)) /
         MAX(CASE WHEN period = 'previous' THEN received END) * 100
    , 1)                                                                     AS mom_received_pct,

    ROUND(
        (MAX(CASE WHEN period = 'current'  THEN avg_int_rate END) -
         MAX(CASE WHEN period = 'previous' THEN avg_int_rate END)) /
         MAX(CASE WHEN period = 'previous' THEN avg_int_rate END) * 100
    , 1)                                                                     AS mom_int_rate_pct,

    ROUND(
        (MAX(CASE WHEN period = 'current'  THEN avg_dti END) -
         MAX(CASE WHEN period = 'previous' THEN avg_dti END)) /
         MAX(CASE WHEN period = 'previous' THEN avg_dti END) * 100
    , 1)                                                                     AS mom_dti_pct

FROM tagged
WHERE period IN ('current', 'previous');
