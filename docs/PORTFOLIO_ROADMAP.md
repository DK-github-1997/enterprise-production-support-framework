# L2/L3 Application & Production Support Portfolio Roadmap

## Positioning
Enterprise application support for data platforms: incident triage, SQL diagnostics, Linux operations, batch monitoring, controlled recovery, RCA, and SLA reporting.

## Existing evidence to retain
- `sql/stale_etl_run_detection.sql`: identifies long-running jobs; read-only.
- `sql/etl_sla_breach_summary.sql`: summarizes completed-run SLA breaches.
- `data-validation-framework`: reusable data-quality and reconciliation checks.

Do not duplicate those SQL checks here. This repository focuses on operational workflows around them.

## Project roadmap
| Priority | Project | Evidence to publish |
|---|---|---|
| 1 | Linux application log triage | Safe read-only script, sample logs, output and runbook |
| 2 | Incident lifecycle and severity matrix | P1-P4 examples, impact, ownership, escalation and SLA |
| 3 | Batch failure RCA playbooks | Symptom → evidence → root cause → recovery → validation |
| 4 | Controlled rerun and rollback runbook | Idempotency gate, approvals, checkpoints and verification |
| 5 | Daily application health-check automation | Service, scheduler, disk, log, DB and dependency checks |

## Standard project structure
```
scripts/linux/
runbooks/incidents/
runbooks/recovery/
sql/diagnostics/
sample_logs/
docs/
```

## Safety rules
- Diagnostic scripts are read-only by default.
- Never kill sessions, restart services, delete files, or rerun jobs automatically.
- Mask credentials and customer identifiers in sample logs.
- Recovery steps must include approval, impact assessment, pre-checks, and post-recovery validation.

## Definition of done
Each incident scenario includes alert, business impact, timeline, evidence, root cause, resolution, validation, prevention, and a concise interview-ready explanation.
