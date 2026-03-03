-- ============================================================
-- DATA QUALITY CHECK
-- BPI 2012 Retail Loan Workflow Analytics (SQLite)
-- Run this first before any analysis
-- ============================================================

-- 1. Row counts across tables
SELECT 'bpi2012_cases' AS table_name, COUNT(*) AS total_rows FROM bpi2012_cases
UNION ALL
SELECT 'bpi2012_events', COUNT(*) FROM bpi2012_events
UNION ALL
SELECT 'bpi2012_stage_durations', COUNT(*) FROM bpi2012_stage_durations;

-- 2. Null check — cases table
-- Expected: Case ID 90 has null REG_DATE and AMOUNT_REQ
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN REG_DATE IS NULL THEN 1 ELSE 0 END) AS null_reg_date,
    SUM(CASE WHEN AMOUNT_REQ IS NULL THEN 1 ELSE 0 END) AS null_amount
FROM bpi2012_cases;

-- 3. Null check — events.resource
-- Many null resources correspond to SCHEDULE lifecycle (system-created tasks)
SELECT
    COUNT(*) AS total_events,
    SUM(CASE WHEN resource IS NULL THEN 1 ELSE 0 END) AS null_resource_events,
    ROUND(
        SUM(CASE WHEN resource IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        1
    ) AS null_pct
FROM bpi2012_events;

-- 4. Confirm null resources are primarily SCHEDULE lifecycle
SELECT
    lifecycle,
    COUNT(*) AS event_count
FROM bpi2012_events
WHERE resource IS NULL
GROUP BY lifecycle
ORDER BY event_count DESC;

-- 5. Zero duration check
-- Automated A_ prefix activities should show duration = 0
-- Human W_ prefix activities should have positive duration
SELECT
    activity,
    COUNT(*) AS zero_duration_rows
FROM bpi2012_stage_durations
WHERE duration_minutes = 0
GROUP BY activity
ORDER BY zero_duration_rows DESC;
