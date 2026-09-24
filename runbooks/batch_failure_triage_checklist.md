# Batch Failure Triage Checklist

A reusable production-support checklist for investigating a failed or delayed batch job.

## 1. Confirm the impact

- Identify the affected application, job, and business process.
- Record the first observed failure time and current status.
- Check whether downstream jobs, reports, or interfaces are blocked.
- Confirm the SLA and business priority.

## 2. Check the failure point

- Review scheduler/job status and the latest execution details.
- Check application logs around the failure timestamp.
- Validate database connectivity and required object availability.
- Check input-file arrival, file size, and expected naming pattern when applicable.
- Review recent deployments or configuration changes.

## 3. Validate data and dependencies

- Confirm source data is available for the expected business date.
- Check for duplicate, missing, or unexpected records.
- Verify dependent services and upstream jobs completed successfully.
- Compare the failed run with the most recent successful run.

## 4. Recover safely

- Follow the approved restart or rerun procedure.
- Avoid manual data changes unless they are authorized and documented.
- Reconcile record counts or control totals after recovery.
- Confirm downstream processing completes successfully.

## 5. Close and prevent recurrence

Document:

- Incident timeline
- Root cause
- Resolution and validation performed
- Business impact
- Preventive action or monitoring improvement

> Portfolio note: This checklist is a generic sample for demonstrating production-support troubleshooting practices. It does not represent confidential client procedures or production data.
