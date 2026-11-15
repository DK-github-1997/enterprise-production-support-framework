-- Purpose: Identify ETL runs that may be stuck or running beyond an operational threshold.
-- Example source table: ETL_JOB_RUNS
-- Expected columns: JOB_NAME, RUN_ID, START_TIME, END_TIME, STATUS
-- Bind variable :p_stale_minutes is the agreed threshold (for example, 90).
-- Review the scheduler and application logs before taking any recovery action.

WITH active_runs AS (
    SELECT
        job_name,
        run_id,
        start_time,
        end_time,
        status,
        ROUND((SYSDATE - CAST(start_time AS DATE)) * 24 * 60, 2) AS elapsed_minutes
    FROM etl_job_runs
    WHERE UPPER(status) IN ('RUNNING', 'IN_PROGRESS')
      AND end_time IS NULL
)
SELECT
    job_name,
    run_id,
    start_time,
    elapsed_minutes,
    CASE
        WHEN elapsed_minutes >= :p_stale_minutes THEN 'INVESTIGATE_POSSIBLE_STALE_RUN'
        ELSE 'RUNNING_WITHIN_THRESHOLD'
    END AS triage_status
FROM active_runs
ORDER BY elapsed_minutes DESC, job_name, run_id;

-- Operational notes:
-- 1. Compare elapsed time with the job's normal runtime and SLA, not only a global threshold.
-- 2. Check scheduler state, worker/container status, database sessions, and recent log activity.
-- 3. Confirm whether the run is genuinely stuck before requesting an approved restart.
-- 4. Check idempotency and partial-load state before rerunning a job.
-- 5. This query is read-only; it does not cancel, kill, or restart jobs.
