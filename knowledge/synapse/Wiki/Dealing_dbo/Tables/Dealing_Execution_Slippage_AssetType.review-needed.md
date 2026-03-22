---
object: Dealing_Execution_Slippage_AssetType
schema: Dealing_dbo
type: table
batch: 11
review_flags:
  - pipeline_stale
  - kusto_feed_broken
quality_score: 8.5
---

## Review Flags

### FLAG 1 — PIPELINE STALE (HIGH)
**Severity**: High
**Description**: Table has no data after 2024-10-03. Same root cause as `Dealing_Execution_Slippage`: Kusto LP price feed (`CopyFromLake.PricesFromProvider_MarketCurrencyPrice`) stopped populating. The `_RequestTime` variant (`Dealing_Execution_Slippage_AssetType_RequestTime`) is still active (last: 2025-01-11).
**Action**: Determine whether the Kusto-based SendTime slippage pipeline is intentionally deprecated or needs repair.

### FLAG 2 — NO HBC CRYPTO DATA RECENTLY (LOW)
**Severity**: Low
**Description**: Final rows in table (Sep-Oct 2024) show only `Crypto Currencies / CBH` combinations. This may mean other asset classes had no CBH/HBC hedging activity in the final weeks, or that data truncation masked it.
**Action**: Verify whether the Crypto-only tail is an artifact of data sparsity as feed degraded or a legitimate business change (e.g., Stocks hedging routing change).
