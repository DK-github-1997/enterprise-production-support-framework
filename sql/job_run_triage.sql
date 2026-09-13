-- Production support job-run triage sample.
-- Quickly classifies recent ETL runs for first-level investigation.

SELECT
    job_name,
    run_id,
    start_time,
    end_time,
    status,
    CASE
        WHEN status = 'FAILED' THEN 'CHECK_ERROR_LOG'
        WHEN end_time IS NULL THEN 'CHECK_RUNNING_JOB'
        WHEN (end_time - start_time) * 24 * 60 > 60 THEN 'CHECK_SLA_BREACH'
        ELSE 'CHECK_DATA_VALIDATION'
    END AS first_triage_action
FROM etl_job_run_history
WHERE start_time >= SYSDATE - 1
ORDER BY start_time DESC;
