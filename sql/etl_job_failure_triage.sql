-- Purpose: Triage recent ETL job failures and identify likely retry candidates.
-- Example source table: ETL_JOB_RUNS
-- Expected columns:
--   JOB_NAME, RUN_ID, START_TIME, END_TIME, STATUS, ERROR_CODE, ERROR_MESSAGE
-- Adapt table/column names to your monitoring schema before execution.

WITH ranked_runs AS (
    SELECT
        job_name,
        run_id,
        start_time,
        end_time,
        status,
        error_code,
        error_message,
        ROW_NUMBER() OVER (
            PARTITION BY job_name
            ORDER BY start_time DESC, run_id DESC
        ) AS run_rank,
        ROUND(
            (CAST(end_time AS DATE) - CAST(start_time AS DATE)) * 24 * 60,
            2
        ) AS duration_minutes
    FROM etl_job_runs
    WHERE start_time >= SYSDATE - 1
),
latest_failures AS (
    SELECT
        job_name,
        run_id,
        start_time,
        end_time,
        error_code,
        error_message,
        duration_minutes
    FROM ranked_runs
    WHERE run_rank = 1
      AND UPPER(status) IN ('FAILED', 'ERROR')
)
SELECT
    job_name,
    run_id,
    start_time,
    end_time,
    duration_minutes,
    error_code,
    error_message,
    CASE
        WHEN error_code IN ('ORA-00054', 'ORA-00060', 'TIMEOUT')
            THEN 'REVIEW_AND_RETRY'
        WHEN error_code IN ('ORA-00001', 'ORA-01400', 'ORA-02291')
            THEN 'DATA_OR_CONSTRAINT_ISSUE'
        WHEN error_code IN ('AUTH_FAILURE', 'ACCESS_DENIED')
            THEN 'CHECK_CREDENTIALS_OR_PERMISSIONS'
        ELSE 'MANUAL_INVESTIGATION'
    END AS recommended_action
FROM latest_failures
ORDER BY start_time DESC;

-- Operational notes:
-- 1. Retry only after confirming the failure is transient and the job is idempotent.
-- 2. For constraint/data errors, inspect rejected records and upstream changes first.
-- 3. Capture the incident ID, run ID, error text, RCA, and recovery evidence.
-- 4. This is a triage aid, not an automatic retry mechanism.
