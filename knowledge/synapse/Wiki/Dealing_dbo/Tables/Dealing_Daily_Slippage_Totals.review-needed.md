---
object: Dealing_Daily_Slippage_Totals
schema: Dealing_dbo
type: table
batch: 11
review_flags:
  - pipeline_gap
  - spaced_column_names
  - new_columns_partial_history
quality_score: 8.5
---

## Review Flags

### FLAG 1 — PIPELINE GAP (MEDIUM)
**Severity**: Medium
**Description**: Last updated 2025-01-11 (~2.5 months stale). Both TVR and non-TVR tables stopped at the same date, confirming it's a SP scheduling issue, not a data feed failure.
**Action**: Check ADF pipeline for `SP_Slippage_Report`. Determine if the Jan 2025 cutoff is intentional or a scheduling failure.

### FLAG 2 — SPACED COLUMN NAMES (LOW)
**Severity**: Low
**Description**: Metric columns use spaces in names (`[Total No of Trades]`, `[Total Slippage $]`, etc.). All SQL queries must wrap these in square brackets. This is a legacy naming convention from the pre-Synapse era.
**Action**: Consider creating a view with snake_case aliases for downstream BI tools to avoid quoting requirements.

### FLAG 3 — WithinFirst5Minutes_MarketHours AND IsSettled PARTIAL HISTORY (LOW)
**Severity**: Low
**Description**: `WithinFirst5Minutes_MarketHours` was added Sep 2024 (SR-273115) and `IsSettled` was added Oct 2024 (SR-276862). Historical data (2017-2024) will have NULL for these columns. Aggregations using these columns should filter or COALESCE to avoid NULL-driven distortions.
**Action**: Document the cutoff dates for these columns in any BI reports that use them. Pre-2024 NULLs should be treated as "not applicable" not "not within first 5 minutes / not settled."
