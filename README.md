# Enterprise Production Support Framework

## Overview
This repository simulates real-time production support activities in an Enterprise Data Warehouse (EDW/ADW) environment.

It demonstrates monitoring, debugging, and troubleshooting techniques used in enterprise reporting platforms.

## Tech Stack
- Oracle SQL / PL-SQL
- AWS Glue
- AWS Step Functions
- Linux Shell Scripting
- Data Warehouse Monitoring

## Production Support Features
✔ Job Failure Monitoring
✔ Data Validation Checks
✔ Duplicate Detection
✔ Performance Debugging
✔ Glue Job Monitoring
✔ Incident Resolution Queries

## Real-Time Use Case
Designed based on enterprise reporting pipelines where production incidents require SQL debugging, ETL monitoring, and system health checks.

---

## AI-powered Incident Root Cause Suggestions
Leverage AI to accelerate incident resolution by automatically suggesting likely root causes based on incident data, logs, and historical patterns.

### How it Works
- Ingests job logs, error messages, and monitoring data.
- Uses AI/ML models trained on historical incidents to suggest probable root causes.
- Provides actionable recommendations for resolution.

### Real Example Cases

**Case 1: Data Load Failure**
- **Incident:** Glue job failed with `ORA-00001: unique constraint violated`.
- **AI Suggestion:** Duplicate records detected in source data. Check upstream deduplication logic or source extract process.
- **Resolution:** Added deduplication step in ETL pipeline.

**Case 2: Performance Degradation**
- **Incident:** Nightly ETL job exceeded SLA by 2 hours.
- **AI Suggestion:** Recent increase in data volume detected. Query plan regression suspected. Review recent changes to SQL or indexes.
- **Resolution:** Optimized SQL and added new index.

**Case 3: Data Quality Alert**
- **Incident:** Data validation check failed for `customer_email` field (nulls detected).
- **AI Suggestion:** Upstream source system change detected (new optional field). Review source schema and update ETL mapping.
- **Resolution:** Adjusted ETL mapping to handle optional field.

**Case 4: Job Dependency Failure**
- **Incident:** Downstream report not refreshed; upstream job failed silently.
- **AI Suggestion:** Missing dependency configuration in workflow. Review job orchestration and add explicit dependency.
- **Resolution:** Updated Step Function to include dependency check.
