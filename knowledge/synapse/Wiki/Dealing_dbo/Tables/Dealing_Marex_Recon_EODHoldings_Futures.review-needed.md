# Review Needed — Dealing_Marex_Recon_EODHoldings_Futures

**Generated**: 2026-03-21
**Quality Score**: 7.0/10

## Items for Human Review

1. **No eToro hedge column** — Unlike base Marex recon, this table has no `eToro_Units` — reconciliation compares Marex vs Clients only. Confirm this is intentional: futures positions are passed through 1:1 from clients to Marex (no internal hedging layer), so there is no separate eToro hedge book to reconcile against.

2. **ADJ columns purpose** — `ForexRate_AfterADJ` and `ADJ_Value` were added in July 2025. Describe what "ADJ" means in the context of futures FX rates. Is this an exchange adjustment, a settlement adjustment, or something specific to Marex's futures clearing process?

3. **SellCurrency vs Currency** — Two currency columns exist: `SellCurrency` (settlement currency) and `Currency` (underlying instrument currency). Confirm the exact definition and source of each, and clarify when they differ (e.g., for cross-currency futures like ES futures priced in USD but based on a USD index).

4. **CID granularity volume** — This table stores one row per CID × Contract × IsBuy × OrderID combination. Confirm the expected row count and whether partitioning or aggregation is needed for performance in downstream reports.

5. **Marex_USDAmount naming** — Base Marex tables use `Marex_AmountUSD` but this table uses `Marex_USDAmount`. Confirm this is intentional and not a naming inconsistency to be corrected.

6. **Marex futures position source** — The exact LP feed table name for the Marex futures position file is not confirmed in the DDL or SP (only partially read). Confirm the staging table name (likely `LP_EdnF_*` or similar) used for futures EOD positions.

## Reviewer Corrections

_None yet._
