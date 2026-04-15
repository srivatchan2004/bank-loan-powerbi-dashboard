-- ============================================================
-- File   : 05_monthly_trend.sql
-- Project: Bank Loan Dashboard (Power BI)
-- Purpose: Reproduce the "Total Loan Applications by Month" line
--          chart on the Overview page and compute month-over-month
--          growth rates for all headline KPIs.
--          Uses a CASE WHEN CTE to classify/label each record by
--          quarter, then LAG() to compute period-over-period change.
-- Columns used: issue_date, loan_amount, total_payment,
--               int_rate, dti, loan_status
-- Expected output:
--   12 rows (Jan–Dec 2021).
--   Applications peak in December (MTD ≈ 4,300).
--   Steady upward trend matching the Overview line chart.
--   December MoM: applications +6.9 %, funded +13.0 %,
--                 received +15.8 %, int_rate +3.5 %, dti +2.7 %
-- Known discrepancies vs Power BI:
--   ✅  Monthly totals are identical to the line chart values.
--   ⚠️  Power BI uses DAX time-intelligence (DATEADD, PARALLELPERIOD)
--       for MoM%; this script uses LAG() which gives the same
--       arithmetic result but is evaluated at query time, not
--       model time.
--   ⚠️  The dataset covers a single year (2021) so YoY comparison
--       is not possible; MoM is used instead.
-- ============================================================

USE bank_loan_db;

-- ================================================================
-- Step 1 – Monthly aggregates with quarter label via CASE WHEN
-- ================================================================
WITH monthly_base AS (
    SELECT
        YEAR(issue_date)                    AS yr,
        MONTH(issue_date)                   AS mth,
        MONTHNAME(issue_date)               AS month_name,

        -- Quarter label using CASE WHEN
        CASE
            WHEN MONTH(issue_date) BETWEEN 1 AND 3  THEN 'Q1'
            WHEN MONTH(issue_date) BETWEEN 4 AND 6  THEN 'Q2'
            WHEN MONTH(issue_date) BETWEEN 7 AND 9  THEN 'Q3'
            ELSE                                          'Q4'
        END                                 AS quarter,

        -- Volume flags
        CASE
            WHEN MONTH(issue_date) = 12 THEN 'Peak Month (Dec)'
            WHEN MONTH(issue_date) =  1 THEN 'Start of Year (Jan)'
            ELSE 'Mid-Year'
        END                                 AS period_label,

        COUNT(*)                            AS applications,
        SUM(loan_amount)                    AS funded,
        SUM(total_payment)                  AS received,
        AVG(int_rate)                       AS avg_int_rate,   -- raw decimal
        AVG(dti)                            AS avg_dti,        -- raw decimal
        SUM(CASE WHEN loan_status IN ('Fully Paid','Current') THEN 1 ELSE 0 END)
                                            AS good_loans,
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END)
                                            AS bad_loans
    FROM financial_loan
    GROUP BY yr, mth, month_name
),

-- ================================================================
-- Step 2 – Add LAG() columns for MoM calculation
-- ================================================================
monthly_with_lag AS (
    SELECT *,
        LAG(applications)  OVER (ORDER BY yr, mth) AS prev_applications,
        LAG(funded)        OVER (ORDER BY yr, mth) AS prev_funded,
        LAG(received)      OVER (ORDER BY yr, mth) AS prev_received,
        LAG(avg_int_rate)  OVER (ORDER BY yr, mth) AS prev_avg_int_rate,
        LAG(avg_dti)       OVER (ORDER BY yr, mth) AS prev_avg_dti
    FROM monthly_base
)

-- ================================================================
-- Step 3 – Final output with formatted metrics and MoM %
-- ================================================================
SELECT
    yr                                          AS year,
    mth                                         AS month_num,
    month_name,
    quarter,
    period_label,

    -- Volume
    applications,
    ROUND(funded   / 1e6, 2)                    AS funded_m,
    ROUND(received / 1e6, 2)                    AS received_m,

    -- Rate metrics (convert from decimal to %)
    ROUND(avg_int_rate * 100, 2)                AS avg_int_rate_pct,
    ROUND(avg_dti      * 100, 2)                AS avg_dti_pct,

    -- Good vs Bad split per month
    good_loans,
    bad_loans,
    ROUND(good_loans * 100.0 / applications, 1) AS good_loan_pct,

    -- MoM % changes (NULL for January — no prior month)
    ROUND((applications - prev_applications) / prev_applications * 100, 1)
                                                AS mom_applications_pct,
    ROUND((funded - prev_funded)             / prev_funded       * 100, 1)
                                                AS mom_funded_pct,
    ROUND((received - prev_received)         / prev_received     * 100, 1)
                                                AS mom_received_pct,
    ROUND((avg_int_rate - prev_avg_int_rate) / prev_avg_int_rate * 100, 1)
                                                AS mom_int_rate_pct,
    ROUND((avg_dti - prev_avg_dti)           / prev_avg_dti      * 100, 1)
                                                AS mom_dti_pct

FROM monthly_with_lag
ORDER BY yr, mth;


-- ================================================================
-- Bonus – Quarterly rollup (CASE WHEN quarter used for grouping)
-- ================================================================
SELECT
    yr,
    CASE
        WHEN MONTH(issue_date) BETWEEN 1 AND 3 THEN 'Q1'
        WHEN MONTH(issue_date) BETWEEN 4 AND 6 THEN 'Q2'
        WHEN MONTH(issue_date) BETWEEN 7 AND 9 THEN 'Q3'
        ELSE                                        'Q4'
    END                                     AS quarter,
    COUNT(*)                                AS applications,
    ROUND(SUM(loan_amount)   / 1e6, 2)      AS funded_m,
    ROUND(SUM(total_payment) / 1e6, 2)      AS received_m,
    ROUND(AVG(int_rate) * 100, 2)           AS avg_int_rate_pct,
    ROUND(AVG(dti)      * 100, 2)           AS avg_dti_pct
FROM financial_loan
GROUP BY yr, quarter
ORDER BY yr,
    FIELD(quarter, 'Q1', 'Q2', 'Q3', 'Q4');
