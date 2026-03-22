# Review Needed — Dealing_IGReconTrades

**Generated**: 2026-03-21
**Quality Score**: 7.8/10

## Items for Human Review

1. **Rejected trade filter** — `LP_IG_OH_OrderHistory.Result NOT LIKE '%Rejected:%'` excludes rejected orders. Confirm expected rejection rate and whether partial fills or amendments are handled correctly.

2. **IG_Rate as weighted average** — IG rate is computed as `SUM(Deal Level × Deal Size) / SUM(ABS(Deal Size))`. Confirm this correctly represents execution price, especially for partial fills.

3. **IG_FXRate source** — FX rates for trades are pulled from `LP_IG_PS_EODPositions` (EOD positions table), not from a dedicated trade FX source. This means trade FX rates use EOD rates rather than intraday rates. Confirm this is acceptable for reconciliation purposes.

## Reviewer Corrections

_None yet._
