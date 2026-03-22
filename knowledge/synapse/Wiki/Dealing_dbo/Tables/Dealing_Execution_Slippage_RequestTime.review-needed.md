---
object: Dealing_Execution_Slippage_RequestTime
schema: Dealing_dbo
type: table
batch: 11
review_flags:
  - pipeline_gap
  - sign_convention_confusion
quality_score: 8.5
---

## Review Flags

### FLAG 1 — PIPELINE GAP (MEDIUM)
**Severity**: Medium
**Description**: Last updated 2025-01-11. SP_Execution_Slippage does not depend on Kusto for the RequestTime path, so this gap is not the Kusto feed issue. The SP itself appears to have stopped being scheduled.
**Action**: Check ADF/orchestration schedule for `SP_Execution_Slippage`. Determine if the Jan 2025 cutoff is intentional (pipeline replaced) or a scheduling failure.

### FLAG 2 — OPPOSITE SIGN BETWEEN Slippage AND SlippageInDollar (LOW)
**Severity**: Low
**Description**: `Slippage` (points) and `SlippageInDollar` intentionally have opposite signs — one measures "LP cost to eToro" positive, the other "eToro gain" positive. This is consistent with the SP but confusing for consumers who join both columns.
**Action**: Consider adding a note to any BI reports using these columns. Confirm this sign convention is documented in the Dealing team's internal wiki.
