# Column Lineage: BI_DB_dbo.BI_DB_DailyZeroPnL_Stocks

**Generated**: 2026-04-28 | **Batch**: regen-attempt-1 | **Writer SP**: SP_DailyZeroPnL_Stocks (via Dealing_dbo migration)

## Pipeline Summary

```
DWH_dbo.Dim_Position               ─┐
DWH_dbo.Fact_SnapshotCustomer      ─┤
DWH_dbo.Dim_Instrument             ─┤─► SP_DailyZeroPnL_Stocks ──► Dealing_dbo.Dealing_DailyZeroPnL_Stocks
DWH_dbo.Dim_Regulation             ─┤                              (DELETE+INSERT by Date, daily)
BI_DB_dbo.BI_DB_PositionPnL        ─┤
BI_DB_dbo.BI_DB_IndexesMapping_Static┘

                                        ↓ migration 2024-09
                                   BI_DB_dbo.BI_DB_DailyZeroPnL_Stocks
                                   (dormant — last row 2024-02-09)

                                        ↓ Generic Pipeline (Append, 1440 min)
                                   bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks
```

## Source Objects

| Source Object | Schema | Type | Role |
|--------------|--------|------|------|
| Dealing_DailyZeroPnL_Stocks | Dealing_dbo | Table | Migration source (identical schema, same SP origin) |
| SP_DailyZeroPnL_Stocks | Dealing_dbo | Stored Procedure | Original writer SP |
| Dim_Position | DWH_dbo | Table | Position attributes (OpenDateID, CloseDateID, HedgeServerID, Leverage) |
| Fact_SnapshotCustomer | DWH_dbo | Table | Customer regulation and MiFID snapshot |
| Dim_Instrument | DWH_dbo | Table | Instrument metadata (InstrumentType, Industry, SellCurrency) |
| Dim_Regulation | DWH_dbo | Table | Regulation name lookup |
| BI_DB_PositionPnL | BI_DB_dbo | Table | Position P&L fact (NOP, DailyPnL) |
| BI_DB_IndexesMapping_Static | BI_DB_dbo | Table | Stock index membership mapping |

## Column-Level Lineage

| Column | Source Table | Source Column | Transformation |
|--------|-------------|---------------|----------------|
| Date | @RepDate parameter | — | Report date parameter |
| HedgeServerID | DWH_dbo.Dim_Position | HedgeServerID | GROUP BY key |
| Industry | DWH_dbo.Dim_Instrument | Industry | GROUP BY key |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | GROUP BY key |
| InstrumentID | DWH_dbo.Dim_Position | InstrumentID | GROUP BY key |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Direct join |
| StockIndex | BI_DB_dbo.BI_DB_IndexesMapping_Static | IndexName | LEFT JOIN on InstrumentID; NULL if not in index |
| IsManual | DWH_dbo.Dim_Position | MirrorID | CASE WHEN MirrorID=0 THEN 1 ELSE 0 |
| Leverage | DWH_dbo.Dim_Position | Leverage | GROUP BY key |
| IsCFD | DWH_dbo.Dim_Position | IsSettled | CASE WHEN IsSettled=1 THEN 0 ELSE 1 |
| Regulation | DWH_dbo.Dim_Regulation | Name | JOIN via Fact_SnapshotCustomer.RegulationID; ISNULL → 'Unknown' |
| MifID | DWH_dbo.Fact_SnapshotCustomer | MifidCategorizationID | GROUP BY key |
| RealizedCommission | DWH_dbo.Dim_Position | CommissionOnClose / FullCommissionByUnits | SUM(TotalCommission) for closed positions |
| RealizedZero | BI_DB_dbo.BI_DB_PositionPnL / Dim_Position | NetProfit + CommissionOnClose − PrevDayPnL | SUM(eToro zero formula) for closed positions |
| ChangeInUnrealizedZero | BI_DB_dbo.BI_DB_PositionPnL | DailyPnL | SUM for open positions (unrealized component) |
| TotalZero | — | RealizedZero + ChangeInUnrealizedZero | Aggregated computed sum |
| NOP | BI_DB_dbo.BI_DB_PositionPnL | NOP × sign(2*IsBuy-1) | SUM NOP with directional sign |
| OpenPositions | BI_DB_dbo.BI_DB_PositionPnL | OpenPosition | SUM signed open position value |
| NOP_Units | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal (Units) | SUM signed units |
| VolumeOnOpen | DWH_dbo.Dim_Position | Volume (when OpenDateID=@RepDate) | SUM volume for positions opened on report date |
| VolumeOnClose | DWH_dbo.Dim_Position | VolumeOnClose (when CloseDateID=@RepDate) | SUM volume for positions closed on report date |
| OpenPositionValue | BI_DB_dbo.BI_DB_PositionPnL | Amount + PositionPnL | SUM aggregated USD open position value |
| UpdateDate | GETDATE() | — | Batch execution timestamp |
| InstrumentName | DWH_dbo.Dim_Instrument | Name | Direct join (AS InstrumentName) |
| Units | BI_DB_dbo.BI_DB_PositionPnL / #Units | OpenUnits + CloseUnits | SUM net units via #Units temp table join |
| Currency | DWH_dbo.Dim_Instrument | SellCurrency | Direct join (AS Currency) |

## Key Filters Applied in SP

| Filter | Value | Source |
|--------|-------|--------|
| InstrumentTypeID | IN (5, 6) — Stocks and ETFs only | DWH_dbo.Dim_Instrument |
| Customer validity | IsValidCustomer=1 | DWH_dbo.Fact_SnapshotCustomer |
| Report date range | OpenDateID <= @RepDate AND (CloseDateID >= @RepDate OR CloseDateID = 0) | DWH_dbo.Dim_Position |

## Upstream Wiki Used

| Wiki File | Path |
|-----------|------|
| Dealing_DailyZeroPnL_Stocks.md | knowledge/synapse/Wiki/Dealing_dbo/Tables/Dealing_DailyZeroPnL_Stocks.md |
