# Column Lineage — BI_DB_dbo.BI_DB_CMR_Phase2_USA_CustomerBalance_ApexAdjusted

**Generated**: 2026-04-23 | **Writer SP**: SP_CMR_Phase2_USA_CustomerBalance_ApexAdjusted | **Batch**: 60

## Source Chain

```
BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New
  (filtered: Regulation IN FinCEN/FinCEN+FINRA/eToroUS, IsCreditReportValidCB=1)
  |-- SP_CMR_Phase2_USA_CustomerBalance_ApexAdjusted (@date, DELETE+INSERT)
  |   Phase 1: build #temp (wide-format with Apex-adjusted columns)
  |   Phase 2: 40-branch UNION ALL pivot into long format
  v
BI_DB_dbo.BI_DB_CMR_Phase2_USA_CustomerBalance_ApexAdjusted
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | Date | BI_DB_Client_Balance_Aggregate_Level_New | Date | GROUP BY passthrough via #temp. | Tier 2 |
| 2 | DateID | BI_DB_Client_Balance_Aggregate_Level_New | DateID | GROUP BY passthrough (= @dateID filter). | Tier 2 |
| 3 | ExcelOrder | ETL | Hardcoded | Ordinal 1–40 per UNION ALL branch. | Tier 2 |
| 4 | Metric | ETL | Hardcoded | String label per UNION ALL branch (40 metrics: OpeningBalanceAdjusted through GapNonFinra). | Tier 2 |
| 5 | MetricValue | #temp / BI_DB_Client_Balance_Aggregate_Level_New | (per branch) | SUM of Apex-adjusted metric from #temp. Key adjustments: OpeningBalanceAdjusted = OpeningBalance − RealStocksOpeningBalance (for FinCEN+FINRA); ClosingBalanceAdjusted = ClosingBalance − RealStocksClosingBalance; CompensationAdjusted excludes CompensationsApexUSStocks; ClientBalanceCommissionAdjusted excludes real-stocks commission. Metrics 37–40 are gap variants (Gap, GapTotal, GapFinra, GapNonFinra). | Tier 2 |
| 6 | UpdateDate | ETL | GETDATE() | Stamped at INSERT time via GETDATE(). | Propagation |

## Apex Adjustment Logic

| Column | Formula (FinCEN+FINRA only) | Purpose |
|--------|----------------------------|---------|
| OpeningBalanceAdjusted | OpeningBalance − RealStocksOpeningBalance | Removes real stock opening from cash balance |
| ClosingBalanceAdjusted | ClosingBalance − RealStocksClosingBalance | Removes real stock closing from cash balance |
| CompensationAdjusted | Compensation − CompensationsApexUSStocks | Removes Apex US stock compensation from total |
| ClientBalanceCommissionAdjusted | ClientBalanceCommission − ClientBalanceCommissionRealStocks | Removes real-stocks commission |
| RealStockInvestedAmountChangeAdjusted | −1 × (TotalRealStocksEquityChange − UnrealizedPnLChangeStocksReal − ClientBalanceRealizedPnLRealStocks) | Net real stocks invested amount change |

## UC External Lineage

UC Target: `_Not_Migrated`

*No UC lineage entries — table not migrated to Unity Catalog.*
