-- ============================================================
-- MODULE 2: BOTTLENECK & PROCESS TIME (SQLite)
-- IMPORTANT:
-- 1) stage_durations = TOUCH TIME per task instance (minutes)
-- 2) events timeline = END-TO-END calendar time per case (days)
-- These are different metrics and should not be added together.
-- ============================================================

-- 1) Stage duration ranking (W_ stages only = human workflow tasks)
SELECT
  activity,
  ROUND(AVG(duration_minutes), 2) AS avg_duration_min,
  ROUND(MAX(duration_minutes), 2) AS max_duration_min,
  COUNT(*) AS task_instances
FROM bpi2012_stage_durations
WHERE activity LIKE 'W_%'
GROUP BY activity
ORDER BY avg_duration_min DESC;

-- 2) End-to-end case time (calendar days) by outcome group
-- SQLite way: use julianday(max_ts) - julianday(min_ts)
WITH case_times AS (
  SELECT
    case_id,
    (julianday(MAX(ts)) - julianday(MIN(ts))) * 24.0 AS total_hours
  FROM bpi2012_events
  GROUP BY case_id
),
outcomes AS (
  SELECT
    ct.case_id,
    ct.total_hours,
    CASE
      WHEN EXISTS (
        SELECT 1 FROM bpi2012_events e
        WHERE e.case_id = ct.case_id AND e.activity = 'A_ACTIVATED'
      ) THEN 'Activated'
      WHEN EXISTS (
        SELECT 1 FROM bpi2012_events e
        WHERE e.case_id = ct.case_id AND e.activity = 'A_DECLINED'
      ) THEN 'Declined'
      WHEN EXISTS (
        SELECT 1 FROM bpi2012_events e
        WHERE e.case_id = ct.case_id AND e.activity = 'A_CANCELLED'
      ) THEN 'Cancelled'
      ELSE 'Other'
    END AS outcome_group
  FROM case_times ct
)
SELECT
  outcome_group,
  COUNT(*) AS case_count,
  ROUND(AVG(total_hours), 1) AS avg_hours,
  ROUND(AVG(total_hours) / 24.0, 1) AS avg_days
FROM outcomes
GROUP BY outcome_group
ORDER BY avg_days DESC;

-- 3) Outlier detection (long touch-time tasks)
-- NOTE: Use your actual activity names from bpi2012_stage_durations.
-- Common Dutch names in BPI 2012 include:
--   W_Valideren aanvraag  (Validate Application)
--   W_Nabellen incomplete dossiers (Chase Incomplete Files)
--   W_Completeren aanvraag (Complete Application)
--   W_Nabellen offertes (Offer Follow-Up)
SELECT
  case_id,
  activity,
  ROUND(duration_minutes, 1) AS duration_min,
  ROUND(duration_minutes / 60.0, 1) AS duration_hours
FROM bpi2012_stage_durations
WHERE activity LIKE 'W_%'
  AND duration_minutes > 120
ORDER BY duration_minutes DESC
LIMIT 20;
