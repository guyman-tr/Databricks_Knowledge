---
object: Dealing_Execution_Slippage
schema: Dealing_dbo
type: table
batch: 11
review_flags:
  - pipeline_stale
  - kusto_feed_broken
  - tier_gap
quality_score: 8.0
---

## Review Flags

### FLAG 1 — PIPELINE STALE (HIGH)
**Severity**: High
**Description**: `Dealing_Execution_Slippage` and `Dealing_Execution_Slippage_AssetType` have no data after 2024-10-03 (5+ months stale). The `_RequestTime` variants continue populating normally. Root cause is likely `CopyFromLake.PricesFromProvider_MarketCurrencyPrice` (Kusto LP prices) feed failure — required only by the SendTime slippage path that populates these tables.
**Action**: Confirm whether SR-257525 (Jun 2024 price table change) broke the Kusto feed. Verify if this data is intentionally deprecated or if the pipeline needs repair.

### FLAG 2 — KUSTO FEED STATUS UNKNOWN (MEDIUM)
**Severity**: Medium
**Description**: `CopyFromLake.PricesFromProvider_MarketCurrencyPrice` is the Kusto (Liquidity Provider market data) price source. Its last-seen data in this table is Oct 2024. It's unclear whether this feed is permanently discontinued or temporarily broken.
**Action**: Check `CopyFromLake.PricesFromProvider_MarketCurrencyPrice` for current data freshness. If discontinued, update the wiki to mark this table as deprecated.

### FLAG 3 — TIER GAP: HedgingMode LOOKUP (LOW)
**Severity**: Low
**Description**: `HedgingMode` column is documented as Tier 2 (SP_Execution_Slippage), but the lookup source `Dealing_staging.Etoro_Hedge_HBCOrderLog` has no upstream wiki coverage. The CBH/HBC distinction is inferred from SP logic.
**Action**: Verify CBH=Clearing Broker Hedging (Apex/BNY), HBC=Hedge By Company in production documentation. Confirm NULL means unmatched or a third mode.

### FLAG 4 — SlippagePctFromLP FORMULA VERIFICATION NEEDED (LOW)
**Severity**: Low
**Description**: `SlippagePctFromLP` computes `SlippageFromLP / LPPrice`. The SP divides by `PriceAtSent` (Kusto LP price) as the denominator. When the Kusto feed is broken, this column cannot be populated for the SendTime path.
**Action**: Confirm denominator is `LPPrice` (PricesFromProvider price at SendTime) not `ExecutionRate`. Verify sign convention matches documentation.
