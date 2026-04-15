-- ============================================================
-- File   : 03_geographic_performance.sql
-- Project: Bank Loan Dashboard (Power BI)
-- Purpose: State-level loan performance — reproduces the
--          "Total Loan Applications by State" choropleth map on
--          the Overview page.  Adds funded/received totals and
--          quality metrics not visible on the map but useful for
--          deeper analysis.
-- Columns used: address_state, loan_amount, total_payment,
--               int_rate, dti, loan_status
-- Expected output:
--   50-ish rows (one per US state present in the data).
--   California (CA) ranks #1 by applications — the darkest
--   state on the dashboard choropleth.
--   Top 5 by applications: CA, NY, TX, FL, NJ (approximate).
-- Known discrepancies vs Power BI:
--   ✅  Aggregation logic is identical to the map visual.
--   ⚠️  The choropleth uses a colour-saturation scale; the SQL
--       produces raw numbers.  The ranking here is by
--       applications; Power BI's fill intensity also reflects
--       applications, so the ordering is equivalent.
-- ============================================================

USE bank_loan_db;

-- ================================================================
-- Section A – Full state performance table (sorted by applications)
-- ================================================================
SELECT
    address_state                               AS state,
    COUNT(*)                                    AS total_applications,
    ROUND(SUM(loan_amount)   / 1e6, 2)          AS total_funded_m,
    ROUND(SUM(total_payment) / 1e6, 2)          AS total_received_m,
    ROUND(AVG(int_rate) * 100, 2)               AS avg_int_rate_pct,
    ROUND(AVG(dti)      * 100, 2)               AS avg_dti_pct,
    ROUND(
        SUM(CASE WHEN loan_status IN ('Fully Paid','Current') THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1)                  AS good_loan_pct,
    SUM(CASE WHEN loan_status IN ('Fully Paid','Current') THEN 1 ELSE 0 END)
                                                AS good_loans,
    SUM(CASE WHEN loan_status = 'Charged Off'   THEN 1 ELSE 0 END)
                                                AS bad_loans
FROM financial_loan
GROUP BY address_state
ORDER BY total_applications DESC;


-- ================================================================
-- Section B – Top 10 states by funded amount
-- ================================================================
WITH state_metrics AS (
    SELECT
        address_state                           AS state,
        COUNT(*)                                AS applications,
        SUM(loan_amount)                        AS funded,
        SUM(total_payment)                      AS received,
        ROUND(AVG(int_rate) * 100, 2)           AS avg_int_rate_pct,
        ROUND(AVG(dti)      * 100, 2)           AS avg_dti_pct
    FROM financial_loan
    GROUP BY address_state
)
SELECT
    state,
    applications,
    ROUND(funded   / 1e6, 2)   AS funded_m,
    ROUND(received / 1e6, 2)   AS received_m,
    avg_int_rate_pct,
    avg_dti_pct,
    ROUND(received / NULLIF(funded, 0), 4) AS repayment_ratio  -- > 1 means net positive
FROM state_metrics
ORDER BY funded DESC
LIMIT 10;


-- ================================================================
-- Section C – States with highest bad-loan (Charged Off) rate
-- ================================================================
SELECT
    address_state                                       AS state,
    COUNT(*)                                            AS total_applications,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END)
                                                        AS charged_off_count,
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1)                          AS charged_off_pct
FROM financial_loan
GROUP BY address_state
HAVING total_applications >= 100          -- filter out low-volume states
ORDER BY charged_off_pct DESC
LIMIT 10;
