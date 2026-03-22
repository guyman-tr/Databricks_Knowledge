---
object: Dealing_Manual_Exec
review_date: 2026-03-21
reviewer: ""
status: Needs Review
---

# Dealing_Manual_Exec — Review Notes

## Auto-Generated Flags

- **STALE since 2024-11-02**: SP has not produced data for ~16 months. Has this report been replaced by another system? Is the table still queried in Tableau/dashboards?
- **HBC_PI NULL Volume**: Block trade PI executions have NULL volume in this table. Is this intentional — is there a separate table for HBC_PI volume?
- **Special InstrumentID cases (19, 22)**: Volume multiplied by 0.01 and 0.001 respectively. What instruments are these? If these are common instruments, this special case may cause confusion.
- **SP runtime ~36 minutes**: Very slow. Was this causing scheduling issues that led to the staleness?

## Reviewer Corrections

<!-- Add corrections here. Mark resolved issues with [RESOLVED]. -->
