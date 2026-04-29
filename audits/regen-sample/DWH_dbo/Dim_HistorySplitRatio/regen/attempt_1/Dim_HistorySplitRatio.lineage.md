# DWH_dbo.Dim_HistorySplitRatio — Column Lineage

## Source Objects

| # | Source Object | Schema | Role | Wiki Available |
|---|--------------|--------|------|---------------|
| 1 | History.SplitRatio | etoro (production) | Primary source | YES — `DB_Schema/etoro/Wiki/History/Tables/History.SplitRatio.md` |
| 2 | DWH_staging.etoro_History_SplitRatio | DWH_staging | Staging relay | No wiki (staging table) |

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Tier |
|-----------|-------------|--------------|-----------|------|
| ID | History.SplitRatio | ID | passthrough | Tier 1 |
| InstrumentID | History.SplitRatio | InstrumentID | passthrough | Tier 1 |
| MinDate | History.SplitRatio | MinDate | passthrough | Tier 1 |
| MaxDate | History.SplitRatio | MaxDate | passthrough | Tier 1 |
| PriceRatio | History.SplitRatio | PriceRatio | passthrough | Tier 1 |
| AmountRatio | History.SplitRatio | AmountRatio | passthrough | Tier 1 |
| PriceRatioUnAdjusted | History.SplitRatio | PriceRatioUnAdjusted | passthrough (money → decimal(19,4)) | Tier 1 |
| AmountRatioUnAdjusted | History.SplitRatio | AmountRatioUnAdjusted | passthrough (money → decimal(19,4)) | Tier 1 |
| UpdateDate | — | — | ETL-computed: GETDATE() | Tier 2 |

## ETL Chain

```
etoro.History.SplitRatio (production, etoroDB-REAL)
  |-- Generic Pipeline (Bronze export, daily Override) ---|
  v
DWH_staging.etoro_History_SplitRatio
  |-- SP_Dim_HistorySplitRatio_DL_To_Synapse (TRUNCATE + INSERT) ---|
  v
DWH_dbo.Dim_HistorySplitRatio (16,014 rows)
  |-- Generic Pipeline (Override, delta/parquet) ---|
  v
dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio (UC Gold)
```

## Lost Columns (in production, not in DWH)

The production `History.SplitRatio` table has 28 columns. The DWH dimension carries only 8 + UpdateDate. Notable dropped columns:

| Production Column | Why Not in DWH |
|------------------|----------------|
| IsCompletedOpenPositions | Operational flag — not needed for analytics |
| IsCompletedClosePositions | Operational flag |
| IsCompletedOpenOrders | Operational flag |
| IsCompletedCloseOrders | Operational flag |
| IsCompletedPricAndAmount | Operational flag |
| IsCompletedModifyPrice | Operational flag |
| IsCompleteHoldingFees | Operational flag |
| IsNotificationSent | Operational flag |
| IsNotificationStartSent | Operational flag |
| IsCurrencyPriceChanged | Operational flag |
| IsRedisUpdated | Operational flag |
| UnitsBefore | Raw input — ratios are the computed output |
| UnitsAfter | Raw input — ratios are the computed output |
| PriceRatioUnAdjustedFull | Ultra-high precision variant — decimal(19,4) sufficient for DWH |
| AmountRatioUnAdjustedFull | Ultra-high precision variant |
| DbLoginName | Computed audit column |
| AppLoginName | Computed audit column |
| SysStartTime | Temporal versioning column |
| SysEndTime | Temporal versioning column |
| HostName | Computed audit column |
