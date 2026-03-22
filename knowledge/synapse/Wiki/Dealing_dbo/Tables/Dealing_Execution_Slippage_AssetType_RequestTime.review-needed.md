---
object: Dealing_Execution_Slippage_AssetType_RequestTime
schema: Dealing_dbo
type: table
batch: 11
review_flags:
  - pipeline_gap
quality_score: 8.5
---

## Review Flags

### FLAG 1 — PIPELINE GAP (MEDIUM)
**Severity**: Medium
**Description**: Table last updated 2025-01-11 (~2.5 months stale as of 2026-03-21). Unlike the SendTime variant where the Kusto feed is the identified root cause, this table's gap is unexplained — it doesn't depend on Kusto. The broader `SP_Execution_Slippage` scheduling may have stopped.
**Action**: Check if `SP_Execution_Slippage` is still scheduled in the ADF/orchestration pipeline. The January 2025 cutoff appears in both RequestTime tables simultaneously, suggesting the SP itself stopped running rather than a data feed issue.
