-- Purpose: Detect a possible runtime regression in the latest successful ETL run.
-- Example source table: ETL_JOB_RUNS
-- Expected columns: JOB_NAME, RUN_ID, START_TIME, END_TIME, STATUS
-- Bind variables:
--   :p_lookback_days      - how far back to consider completed runs (for example, 30)
--   :p_regression_factor  - latest runtime multiplier over historical median (for example, 1.50)
-- Uses the latest successful run as the current run and up to seven prior
-- successful runs as its baseline. Oracle DATE/TIMESTAMP values are assumed
-- to use a consistent time zone.

WITH ranked_completed_runs AS (
    SELECT
        job_name,
        run_id,
        start_time,
        end_time,
        ROUND(
            (CAST(end_time AS DATE) - CAST(start_time AS DATE)) * 24 * 60,
            2
        ) AS runtime_minutes,
        ROW_NUMBER() OVER (
            PARTITION BY job_name
            ORDER BY start_time DESC, run_id DESC
        ) AS run_rank
    FROM etl_job_runs
    WHERE end_time IS NOT NULL
      AND UPPER(status) IN ('SUCCEEDED', 'SUCCESS', 'COMPLETED')
      AND start_time >= SYSDATE - :p_lookback_days
),
latest_run AS (
    SELECT
        job_name,
        run_id,
        start_time,
        runtime_minutes
    FROM ranked_completed_runs
    WHERE run_rank = 1
),
historical_baseline AS (
    SELECT
        job_name,
        COUNT(*) AS historical_run_count,
        ROUND(MEDIAN(runtime_minutes), 2) AS median_runtime_minutes
    FROM ranked_completed_runs
    WHERE run_rank BETWEEN 2 AND 8
    GROUP BY job_name
)
SELECT
    l.job_name,
    l.run_id AS latest_run_id,
    l.start_time AS latest_start_time,
    l.runtime_minutes AS latest_runtime_minutes,
    b.historical_run_count,
    b.median_runtime_minutes,
    ROUND(
        100 * (l.runtime_minutes - b.median_runtime_minutes)
            / NULLIF(b.median_runtime_minutes, 0),
        2
    ) AS increase_over_median_pct,
    CASE
        WHEN NVL(b.historical_run_count, 0) < 3
            THEN 'INSUFFICIENT_HISTORY'
        WHEN NVL(b.median_runtime_minutes, 0) = 0
            THEN 'REVIEW_ZERO_BASELINE'
        WHEN l.runtime_minutes > b.median_runtime_minutes * :p_regression_factor
            THEN 'POSSIBLE_RUNTIME_REGRESSION'
        ELSE 'WITHIN_EXPECTED_RANGE'
    END AS runtime_assessment
FROM latest_run l
LEFT JOIN historical_baseline b
  ON b.job_name = l.job_name
ORDER BY
    CASE
        WHEN NVL(b.historical_run_count, 0) < 3 THEN 2
        WHEN NVL(b.median_runtime_minutes, 0) = 0 THEN 1
        WHEN l.runtime_minutes > b.median_runtime_minutes * :p_regression_factor THEN 0
        ELSE 3
    END,
    increase_over_median_pct DESC NULLS LAST,
    l.job_name;

-- Operational notes:
-- 1. Treat this as an investigation signal, not proof of a code or infrastructure defect.
-- 2. Compare data volume, upstream delays, scheduler queue time, and recent deployments.
-- 3. Increase the lookback window or sample size when job frequency is low.
-- 4. Review jobs with fewer than three baseline runs manually; no regression is asserted.
-- 5. This query is read-only and does not change, stop, or restart ETL jobs.
