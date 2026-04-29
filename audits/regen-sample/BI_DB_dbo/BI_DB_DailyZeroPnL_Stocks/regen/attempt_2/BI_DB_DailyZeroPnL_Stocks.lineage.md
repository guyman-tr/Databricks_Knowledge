# Column Lineage: BI_DB_dbo.BI_DB_DailyZeroPnL_Stocks

**Generated**: 2026-04-28 | **Batch**: regen-attempt-2 | **Upstream**: Dealing_dbo.Dealing_DailyZeroPnL_Stocks (schema-identical migration)

## Pipeline Summary

```
DWH_dbo.Dim_Position               ─┐
DWH_dbo.Fact_SnapshotCustomer      ─┤
DWH_dbo.Dim_Instrument             ─┤─► SP_DailyZeroPnL_Stocks ──► Dealing_dbo.Dealing_DailyZeroPnL_Stocks
DWH_dbo.Dim_Regulation             ─┤                              (DELETE+INSERT by Date, daily, ~275M rows)
BI_DB_dbo.BI_DB_PositionPnL        ─┤
BI_DB_dbo.BI_DB_IndexesMapping_Static┘

                                        ↓ one-time migration 2024-09
                                   BI_DB_dbo.BI_DB_DailyZeroPnL_Stocks
                                   (dormant — last row 2024-02-09, 197.6M rows)

                                        ↓ Generic Pipeline (Append, 1440 min)
                                   bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks
```

## Source Objects

| Source Object | Schema | Type | Role |
|--------------|--------|------|------|
| Dealing_DailyZeroPnL_Stocks | Dealing_dbo | Table | Immediate upstream (schema-identical migration source) |
| SP_DailyZeroPnL_Stocks | Dealing_dbo | Stored Procedure | Original writer SP (loads Dealing table daily) |
| Dim_Position | DWH_dbo | Table | Position attributes (OpenDateID, CloseDateID, HedgeServerID, Leverage) |
| Fact_SnapshotCustomer | DWH_dbo | Table | Customer regulation and MiFID snapshot |
| Dim_Instrument | DWH_dbo | Table | Instrument metadata (InstrumentType, Industry, SellCurrency) |
| Dim_Regulation | DWH_dbo | Table | Regulation name lookup |
| BI_DB_PositionPnL | BI_DB_dbo | Table | Position P&L fact (NOP, DailyPnL) |
| BI_DB_IndexesMapping_Static | BI_DB_dbo | Table | Stock index membership mapping |

## Column-Level Lineage

| Column | Source Table | Source Column | Transformation | Tier |
|--------|-------------|---------------|----------------|------|
| Date | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | Date | Passthrough migration | Tier 1 |
| HedgeServerID | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | HedgeServerID | Passthrough migration | Tier 1 |
| Industry | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | Industry | Passthrough migration | Tier 1 |
| InstrumentType | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | InstrumentType | Passthrough migration | Tier 1 |
| InstrumentID | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | InstrumentID | Passthrough migration | Tier 1 |
| InstrumentDisplayName | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | InstrumentDisplayName | Passthrough migration | Tier 1 |
| StockIndex | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | StockIndex | Passthrough migration | Tier 1 |
| IsManual | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | IsManual | Passthrough migration | Tier 1 |
| Leverage | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | Leverage | Passthrough migration | Tier 1 |
| IsCFD | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | IsCFD | Passthrough migration | Tier 1 |
| Regulation | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | Regulation | Passthrough migration | Tier 1 |
| MifID | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | MifID | Passthrough migration | Tier 1 |
| RealizedCommission | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | RealizedCommission | Passthrough migration | Tier 1 |
| RealizedZero | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | RealizedZero | Passthrough migration | Tier 1 |
| ChangeInUnrealizedZero | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | ChangeInUnrealizedZero | Passthrough migration | Tier 1 |
| TotalZero | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | TotalZero | Passthrough migration | Tier 1 |
| NOP | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | NOP | Passthrough migration (FX conversion applied in source SP) | Tier 1 |
| OpenPositions | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | OpenPositions | Passthrough migration | Tier 1 |
| NOP_Units | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | NOP_Units | Passthrough migration | Tier 1 |
| VolumeOnOpen | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | VolumeOnOpen | Passthrough migration | Tier 1 |
| VolumeOnClose | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | VolumeOnClose | Passthrough migration | Tier 1 |
| OpenPositionValue | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | OpenPositionValue | Passthrough migration (computed from NOP and FX rate in source SP) | Tier 1 |
| UpdateDate | GETDATE() at batch time | — | Batch metadata timestamp; no upstream traceability | Tier 3 |
| InstrumentName | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | InstrumentName | Passthrough migration | Tier 1 |
| Units | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | Units | Passthrough migration | Tier 1 |
| Currency | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | Currency | Passthrough migration | Tier 1 |

## Key Filters Applied in Source SP

| Filter | Value | Source |
|--------|-------|--------|
| InstrumentTypeID | IN (5, 6) — Stocks and ETFs only | DWH_dbo.Dim_Instrument |
| Customer validity | IsValidCustomer=1 | DWH_dbo.Fact_SnapshotCustomer |
| Report date range | OpenDateID <= @RepDate AND (CloseDateID >= @RepDate OR CloseDateID = 0) | DWH_dbo.Dim_Position |

## Upstream Wiki Used

| Wiki File | Path |
|-----------|------|
| Dealing_DailyZeroPnL_Stocks.md | knowledge/synapse/Wiki/Dealing_dbo/Tables/Dealing_DailyZeroPnL_Stocks.md |
