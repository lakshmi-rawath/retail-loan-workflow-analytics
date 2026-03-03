-- ============================================================
-- MODULE 1: APPROVAL FUNNEL & CONVERSION ANALYSIS (SQLite)
-- ============================================================

-- 1) Case count per funnel stage
SELECT
  activity,
  COUNT(DISTINCT case_id) AS stage_cases,
  ROUND(
    COUNT(DISTINCT case_id) * 100.0 /
    (SELECT COUNT(DISTINCT case_id)
     FROM bpi2012_events
     WHERE activity = 'A_SUBMITTED'),
    1
  ) AS pct_of_submitted
FROM bpi2012_events
WHERE activity IN (
  'A_SUBMITTED','A_PREACCEPTED','A_ACCEPTED',
  'A_FINALIZED','A_ACTIVATED','A_DECLINED','A_CANCELLED'
)
GROUP BY activity
ORDER BY stage_cases DESC;

-- 2) Stage-to-stage conversion using the TRUE funnel order
WITH funnel AS (
  SELECT 'A_SUBMITTED'   AS stage, COUNT(DISTINCT case_id) AS cases FROM bpi2012_events WHERE activity='A_SUBMITTED'
  UNION ALL
  SELECT 'A_PREACCEPTED' AS stage, COUNT(DISTINCT case_id) AS cases FROM bpi2012_events WHERE activity='A_PREACCEPTED'
  UNION ALL
  SELECT 'A_ACCEPTED'    AS stage, COUNT(DISTINCT case_id) AS cases FROM bpi2012_events WHERE activity='A_ACCEPTED'
  UNION ALL
  SELECT 'A_FINALIZED'   AS stage, COUNT(DISTINCT case_id) AS cases FROM bpi2012_events WHERE activity='A_FINALIZED'
  UNION ALL
  SELECT 'A_ACTIVATED'   AS stage, COUNT(DISTINCT case_id) AS cases FROM bpi2012_events WHERE activity='A_ACTIVATED'
),
with_prev AS (
  SELECT
    stage,
    cases AS stage_cases,
    LAG(cases) OVER (
      ORDER BY CASE stage
        WHEN 'A_SUBMITTED'   THEN 1
        WHEN 'A_PREACCEPTED' THEN 2
        WHEN 'A_ACCEPTED'    THEN 3
        WHEN 'A_FINALIZED'   THEN 4
        WHEN 'A_ACTIVATED'   THEN 5
      END
    ) AS prev_stage_cases
  FROM funnel
)
SELECT
  stage,
  stage_cases,
  prev_stage_cases,
  ROUND(stage_cases * 100.0 / prev_stage_cases, 1) AS stage_conversion_pct
FROM with_prev
WHERE prev_stage_cases IS NOT NULL;

-- 3) Final outcome split (Activated / Declined / Cancelled) out of Submitted baseline
SELECT
  CASE
    WHEN activity = 'A_ACTIVATED' THEN 'Activated (Funded)'
    WHEN activity = 'A_DECLINED'  THEN 'Declined (Credit)'
    WHEN activity = 'A_CANCELLED' THEN 'Cancelled (Attrition)'
  END AS final_outcome,
  COUNT(DISTINCT case_id) AS case_count,
  ROUND(
    COUNT(DISTINCT case_id) * 100.0 /
    (SELECT COUNT(DISTINCT case_id)
     FROM bpi2012_events
     WHERE activity = 'A_SUBMITTED'),
    1
  ) AS pct_of_submitted
FROM bpi2012_events
WHERE activity IN ('A_ACTIVATED','A_DECLINED','A_CANCELLED')
GROUP BY activity
ORDER BY case_count DESC;
