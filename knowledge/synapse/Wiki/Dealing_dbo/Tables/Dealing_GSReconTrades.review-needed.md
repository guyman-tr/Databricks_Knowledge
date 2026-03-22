# Review Needed — Dealing_GSReconTrades

**Generated**: 2026-03-21
**Quality Score**: 7.8/10

## Items for Human Review

1. **Total_Commission_USD** — Unique to the trades table vs EOD holdings. Confirm what commission basis GS charges and whether this aligns with other LP commission tracking tables.

2. **GS_FXRate vs eToro_FXRate discrepancy** — Same as EOD holdings table. Confirm this is expected and whether the FX rate difference is ever material enough to affect the reconciliation break analysis.

3. **CFDs only scope** — All rows are `activity = 'Stocks - CFDs'` via the GS HS mapping filter. Confirm no Real Stocks ever flow through GS (e.g., historical data, edge cases).
