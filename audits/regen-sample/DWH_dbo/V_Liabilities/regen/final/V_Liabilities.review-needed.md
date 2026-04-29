# Review Needed: DWH_dbo.V_Liabilities

## Items for Human Review

### 1. Dead JOIN — Fact_Guru_Copiers (gc)

The LEFT JOIN to `Fact_Guru_Copiers gc` on `a.CID = gc.CID AND b.DateKey = gc.DateID` only contributes `CopyFundAUM` to the view. No other `gc.*` columns are selected. The comment `--- 2021.01.11 - Boris Slutski` suggests this was added intentionally, but it's worth confirming whether additional gc columns were planned but never added. The JOIN costs query performance for 98.6% of rows that get NULL.

### 2. CopyFundAUM Source Ambiguity

`CopyFundAUM` appears in the SELECT without a table alias prefix. It resolves to `Fact_Guru_Copiers.CopyFundAUM` because neither `Fact_SnapshotEquity` nor `Fact_CustomerUnrealized_PnL` have a column by that name. If a future schema change adds `CopyFundAUM` to either of those tables, this view will break with an ambiguous column error.

### 3. Unaliased Columns from Fact_CustomerUnrealized_PnL

Multiple columns from `c` (Fact_CustomerUnrealized_PnL) are selected without the `c.` prefix: `StocksPositionPnL`, `MirrorStocksPositionPnL`, `CryptoPositionPnL`, `ManualCryptoPositionPnL`, `CopyCryptoPositionPnL`, `CopyFundPnL`, `NOP`, `Notional`, and all NOP/Notional variants, plus PnL variants for stocks real, crypto real, futures real, and stock margin. These resolve unambiguously today but are fragile to schema evolution.

### 4. TotalStockOrders in Liability Formula

`TotalStockOrders` is hardcoded to 0 in Fact_SnapshotEquity since 2019 but remains in all four liability CASE expressions. This is harmless but adds unnecessary complexity to the formulas. Consider whether this can be cleaned up in the view definition.

### 5. Tier 1 Inheritance Verification

All Tier 1 descriptions were copied verbatim from the upstream wikis:
- **Fact_SnapshotEquity**: 22 columns inherited (CID through TotalStockMarginLoanValue)
- **Fact_CustomerUnrealized_PnL**: 28 columns inherited (PositionPnL through PositionPnLStocksMargin)
- **V_M2M_Date_DateRange**: 2 columns inherited (DateID, FullDate)
- **Fact_Guru_Copiers**: 1 column inherited (CopyFundAUM)

Note: All upstream wikis are Tier 2 (DWH-computed). The Tier 1 in this view means "passthrough from documented upstream Synapse object" — the ultimate production origin is multi-hop (production DB → staging → SP → fact table → this view).
