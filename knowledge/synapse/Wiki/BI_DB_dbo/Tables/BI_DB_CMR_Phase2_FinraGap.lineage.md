# Column Lineage — BI_DB_dbo.BI_DB_CMR_Phase2_FinraGap

**Generated**: 2026-04-23 | **Writer SP**: SP_CMR_Automation_Phase2_FinraGap | **Batch**: 60

## Source Chain

```
BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New
  (filtered: Regulation IN ('FinCEN+FINRA'), IsCreditReportValidCB=1, Club<>'Internal')
  |-- SP_CMR_Automation_Phase2_FinraGap (@date, DELETE+INSERT, 11-branch UNION ALL pivot)
  v
BI_DB_dbo.BI_DB_CMR_Phase2_FinraGap
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | Date | BI_DB_Client_Balance_Aggregate_Level_New | Date | GROUP BY passthrough from source. | Tier 2 |
| 2 | DateID | BI_DB_Client_Balance_Aggregate_Level_New | DateID | GROUP BY passthrough (= @dateID filter). | Tier 2 |
| 3 | ExcelOrder | ETL | Hardcoded | Ordinal 1–11 per UNION ALL branch. | Tier 2 |
| 4 | Metric | ETL | Hardcoded | String label per UNION ALL branch (RealStocksOpeningBalance, RealStocksInvestedAmountChangeExcAirdrops, CompensationsApexUSStocks(-), ClientBalanceRealizedPnLRealStocks, UnrealizedPnLChangeStocksReal, RealStocksClosingBalance, FinraGapBreakdownTotal, DividendsPaid, Compensation, CompensationAdjusted, ApexAirdrops). | Tier 2 |
| 5 | MetricValue | BI_DB_Client_Balance_Aggregate_Level_New | (per branch) | SUM of corresponding real-stocks column per metric. Metric 7 (FinraGapBreakdownTotal) is a composite formula: −1 × (OpeningBalance − InvestedAmountChange + RealizedPnL + UnrealizedPnL − ClosingBalance). | Tier 2 |
| 6 | UpdateDate | ETL | GETDATE() | Stamped at INSERT time via GETDATE(). | Tier 2 |

## UC External Lineage

UC Target: `_Not_Migrated`

*No UC lineage entries — table not migrated to Unity Catalog.*
