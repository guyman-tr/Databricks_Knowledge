---
object: Dealing_dbo.Dealing_Daily_Latency
review_status: pending
documented: 2026-03-21
---

# Review Needed: Dealing_Daily_Latency

## Auto-Generated Flags

- [ ] **STALE PIPELINE**: Table last updated 2025-01-11. Verify if SP_Latency_Report was intentionally decommissioned or if this is a CopyFromLake feed disruption requiring fix.
- [ ] **Very high max latency**: 30,855,223 ms (~8.6 hours). Confirm this is an outlier/reconnect artifact, not a real latency value. Consider adding MAX(Date) filter for analytics queries.
- [ ] **Columns with spaces** (`No of Trades`, `Avg Latency (millisec)`, etc.) — non-standard naming. Document whether this is intentional for BI tool compatibility.
- [ ] **StatusUpdateTime variants**: Parallel `_StatusUpdateTime` family tables also stopped Oct 2024 (only 3 months of data). Verify if this is expected scope or a scheduling gap.

## Reviewer Corrections

<!-- Add corrections here. Mark resolved with [RESOLVED] prefix. -->
