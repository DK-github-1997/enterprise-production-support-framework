-- Purpose: Summarize completed ETL runs that exceeded each job's configured runtime SLA.
-- Example source tables:
--   ETL_JOB_RUNS(JOB_NAME, RUN_ID, START_TIME, END_TIME, STATUS)
--   ETL_JOB_SLA_CONFIG(JOB_NAME, SLA_MINUTES) -- one active row per JOB_NAME
-- Bind variables :p_from_date and :p_to_date define the reporting window.
-- Oracle DATE/TIMESTAMP values are assumed to use a consistent time zone.
--
-- This is a read-only operational trend query. It does not restart or modify jobs.

WITH completed_runs AS (
    SELECT
        r.job_name,
        r.run_id,
        r.start_time,
        r.end_time,
        c.sla_minutes,
        (CAST(r.end_time AS DATE) - CAST(r.start_time AS DATE)) * 24 * 60
            AS elapsed_minutes
    FROM etl_job_runs r
    JOIN etl_job_sla_config c
      ON c.job_name = r.job_name
    WHERE r.end_time IS NOT NULL
      AND UPPER(r.status) IN ('SUCCEEDED', 'SUCCESS', 'COMPLETED')
      AND r.start_time >= :p_from_date
      AND r.start_time <  :p_to_date
      AND c.sla_minutes > 0
)
SELECT
    job_name,
    COUNT(*) AS completed_run_count,
    SUM(CASE WHEN elapsed_minutes > sla_minutes THEN 1 ELSE 0 END)
        AS sla_breach_count,
    ROUND(
        100 * SUM(CASE WHEN elapsed_minutes > sla_minutes THEN 1 ELSE 0 END)
            / NULLIF(COUNT(*), 0),
        2
    ) AS sla_breach_pct,
    ROUND(AVG(elapsed_minutes), 2) AS avg_runtime_minutes,
    ROUND(MAX(elapsed_minutes), 2) AS max_runtime_minutes,
    MAX(sla_minutes) AS configured_sla_minutes
FROM completed_runs
GROUP BY job_name
ORDER BY sla_breach_pct DESC, sla_breach_count DESC, job_name;

-- Operational interpretation:
-- 1. Prioritize jobs with repeated breaches, not only a single slow execution.
-- 2. Compare average and maximum runtime with recent data-volume changes.
-- 3. Confirm the SLA configuration has exactly one active row per job.
-- 4. Investigate scheduler delays, upstream dependencies, resource pressure, and SQL plans.
-- 5. Failed and still-running executions are intentionally excluded from this completed-run KPI.
