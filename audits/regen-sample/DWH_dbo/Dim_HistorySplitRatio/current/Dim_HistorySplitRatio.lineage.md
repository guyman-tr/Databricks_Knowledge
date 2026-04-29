# Column Lineage: DWH_dbo.Dim_HistorySplitRatio

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_HistorySplitRatio` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio` |
| **Primary Source** | `PriceLog.History.SplitRatio` (PriceLog / AZR-W-PRICEDB-2-Price) |
| **ETL SP** | `DWH_dbo.SP_Dim_HistorySplitRatio_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
PriceLog.History.SplitRatio  (AZR-W-PRICEDB-2-Price)
  |-- Generic Pipeline (Override, 60min) ---|
  v
Bronze/PriceLog/History/SplitRatio/
  (dealing.bronze_pricelog_history_splitratio)
  |-- staging import ---|
  v
DWH_staging.etoro_History_SplitRatio
  |-- SP_Dim_HistorySplitRatio_DL_To_Synapse (TRUNCATE + INSERT, daily) ---|
  v
DWH_dbo.Dim_HistorySplitRatio  (15,899 rows)
  |-- Generic Pipeline (Override, 1440min) ---|
  v
Gold/sql_dp_prod_we/DWH_dbo/Dim_HistorySplitRatio/
  (dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| ID | PriceLog.History.SplitRatio | ID | passthrough | Sequential PK from price server |
| InstrumentID | PriceLog.History.SplitRatio | InstrumentID | passthrough | FK to Dim_Currency / Dim_Instrument |
| MinDate | PriceLog.History.SplitRatio | MinDate | passthrough | Start of ratio date range |
| MaxDate | PriceLog.History.SplitRatio | MaxDate | passthrough | End of ratio date range; 2100-01-01 = active |
| PriceRatio | PriceLog.History.SplitRatio | PriceRatio | passthrough | Cumulative price adjustment multiplier |
| AmountRatio | PriceLog.History.SplitRatio | AmountRatio | passthrough | Cumulative amount adjustment multiplier |
| PriceRatioUnAdjusted | PriceLog.History.SplitRatio | PriceRatioUnAdjusted | passthrough | Incremental (non-cumulative) price ratio |
| AmountRatioUnAdjusted | PriceLog.History.SplitRatio | AmountRatioUnAdjusted | passthrough | Incremental (non-cumulative) amount ratio |
| UpdateDate | -- | -- | ETL-computed | GETDATE() at load time; not from source |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 8 |
| **ETL-computed** | 1 |
| **Total** | 9 |
