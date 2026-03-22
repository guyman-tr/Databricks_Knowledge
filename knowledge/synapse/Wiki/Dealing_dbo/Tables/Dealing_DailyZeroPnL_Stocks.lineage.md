# Column Lineage: Dealing_dbo.Dealing_DailyZeroPnL_Stocks

**Generated**: 2026-03-21 | **Batch**: 5 | **Writer SP**: SP_DailyZeroPnL_Stocks

## Pipeline Summary

```
BI_DB_dbo.BI_DB_PositionPnL         ─┐
DWH_dbo.Dim_Position                ─┤
DWH_dbo.Fact_SnapshotCustomer       ─┤─► SP_DailyZeroPnL_Stocks ──► Dealing_DailyZeroPnL_Stocks
DWH_dbo.Dim_Instrument              ─┤                              (DELETE+INSERT by Date)
DWH_dbo.Dim_Regulation              ─┤
DWH_dbo.Fact_CurrencyPriceWithSplit ─┤
BI_DB_dbo.BI_DB_IndexesMapping_Static┘
```

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
| IsManual | DWH_dbo.Dim_Position | IsManual | GROUP BY key |
| Leverage | DWH_dbo.Dim_Position | Leverage | GROUP BY key |
| IsCFD | DWH_dbo.Dim_Position | IsSettled / HedgeServerID | 0 if IsSettled=1 or HedgeServerID in Real list, else 1 |
| Regulation | DWH_dbo.Dim_Regulation | Name | JOIN via Fact_SnapshotCustomer.RegulationID |
| MifID | DWH_dbo.Fact_SnapshotCustomer | MifidCategorizationID | GROUP BY key |
| RealizedCommission | DWH_dbo.Dim_Position | CommissionOnClose | SUM for positions where CloseDateID=@RepDate |
| RealizedZero | BI_DB_dbo.BI_DB_PositionPnL | NetProfit + CommissionOnClose − DailyPnL_prev | SUM(eToro zero formula) for closed positions |
| ChangeInUnrealizedZero | BI_DB_dbo.BI_DB_PositionPnL | DailyPnL | SUM for open positions (unrealized component) |
| TotalZero | — | RealizedZero + ChangeInUnrealizedZero | Computed sum |
| NOP | BI_DB_dbo.BI_DB_PositionPnL | NOP × sign(2*IsBuy-1) | SUM with USD conversion via Fact_CurrencyPriceWithSplit |
| OpenPositions | BI_DB_dbo.BI_DB_PositionPnL | — | COUNT of open positions |
| NOP_Units | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal × (2*IsBuy-1) | SUM signed units |
| VolumeOnOpen | DWH_dbo.Dim_Position | VolumeOnOpen | SUM for positions opened on @RepDate |
| VolumeOnClose | DWH_dbo.Dim_Position | VolumeOnClose | SUM for positions closed on @RepDate |
| OpenPositionValue | BI_DB_dbo.BI_DB_PositionPnL | NOP | SUM USD value of open positions |
| UpdateDate | GETDATE() | — | Batch timestamp |
| InstrumentName | DWH_dbo.Dim_Instrument | Name | Direct join |
| Units | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal | SUM net units |
| Currency | DWH_dbo.Dim_Instrument | SellCurrency | Direct join |

## Key Filters Applied in SP

| Filter | Value | Source |
|--------|-------|--------|
| InstrumentTypeID | IN (5, 6) — Stocks and ETFs only | DWH_dbo.Dim_Instrument |
| Customer validity | IsValidCustomer=1, IsDepositor=1 (standard filter) | DWH_dbo.Fact_SnapshotCustomer |
| Report date | BI_DB_PositionPnL.DateID = @RepDate | Daily parameter |

## ETL Pattern

- DELETE WHERE Date=@dd → INSERT
- Idempotent daily reload
