---
object: Dealing_dbo.Dealing_Daily_Latency_StatusUpdateTime
review_status: pending
documented: 2026-03-21
---

# Review Needed: Dealing_Daily_Latency_StatusUpdateTime

## Auto-Generated Flags

- [ ] **VERY LIMITED DATA**: Only Jul–Oct 2024 (3 months). Verify if this was intentionally a short pilot or an interrupted pipeline.
- [ ] **Relationship to main table**: Confirm that `SP_Latency_Report_StatusUpdateTime` uses "Routed" EMS events throughout vs the main SP using "Filled." The intent may have been to provide a faster latency signal for alerting.
- [ ] **Columns with spaces**: Same naming pattern as parent table — confirm BI tool compatibility.

## Reviewer Corrections

<!-- Add corrections here. -->
