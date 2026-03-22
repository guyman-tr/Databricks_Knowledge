---
object: Dealing_Daily_Slippage_Totals_TriggerVSReceived
schema: Dealing_dbo
type: table
batch: 11
review_flags:
  - pipeline_gap
  - missing_columns_vs_sibling
quality_score: 8.5
---

## Review Flags

### FLAG 1 — PIPELINE GAP (MEDIUM)
**Severity**: Medium
**Description**: Last updated 2025-01-11. Same SP scheduling issue as all other Slippage tables.
**Action**: Check ADF pipeline for `SP_Slippage_Report`.

### FLAG 2 — MISSING WithinFirst5Minutes_MarketHours AND IsSettled (LOW)
**Severity**: Low
**Description**: These columns were added to `Dealing_Daily_Slippage_Totals` in Sep-Oct 2024 (SR-273115, SR-276862) but were NOT added to this TVR table. If users need these dimensions for TVR analysis, they must use a JOIN to the non-TVR table or access `Dealing_Daily_Slippage_Positions_TriggerVSReceived` (which also lacks these columns).
**Action**: Consider adding `WithinFirst5Minutes_MarketHours` and `IsSettled` to this table in a future SP update for parity with the non-TVR table.
