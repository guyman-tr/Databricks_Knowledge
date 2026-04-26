# Column Lineage — BI_DB_dbo.BI_DB_CMR_Phase2_LiabilityDecomp

**Generated**: 2026-04-23 | **Writer SP**: SP_CMR_Phase2_LiabilityDecomp | **Batch**: 60

## Source Chain

```
BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New
  (filtered: Regulation IN CySEC/BVI/NFA/None/ASIC/ASIC & GAML, IsCreditReportValidCB=1)
  |-- SP_CMR_Phase2_LiabilityDecomp (@date, DELETE+INSERT, 9-branch UNION ALL pivot)
  |   Segmented by Regulation + PlayerStatus
  v
BI_DB_dbo.BI_DB_CMR_Phase2_LiabilityDecomp
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | Date | BI_DB_Client_Balance_Aggregate_Level_New | Date | GROUP BY passthrough from source. | Tier 2 |
| 2 | DateID | BI_DB_Client_Balance_Aggregate_Level_New | DateID | GROUP BY passthrough (= @dateID filter). | Tier 2 |
| 3 | ExcelOrder | ETL | Hardcoded | Ordinal 1–9 per UNION ALL branch. | Tier 2 |
| 4 | Metric | ETL | Hardcoded | String label per UNION ALL branch: Total Liability, Negative Total Liability, Closing Balace, Withdrawable Liability, Negative Withdrawable Liability, Liability In Used Margin, NegativeLiabilityInUsedMargin, In Process Cashouts, NegativeInProcessCashout. Note: 'Closing Balace' contains a typo (missing 'n'). | Tier 2 |
| 5 | Regulation | BI_DB_Client_Balance_Aggregate_Level_New | Regulation | GROUP BY passthrough. Scoped to CySEC, BVI, NFA, None, ASIC, ASIC & GAML only. | Tier 2 |
| 6 | PlayerStatus | BI_DB_Client_Balance_Aggregate_Level_New | PlayerStatus | GROUP BY passthrough. All statuses included (PlayerStatus filter commented out in SP). | Tier 2 |
| 7 | MetricValue | BI_DB_Client_Balance_Aggregate_Level_New | (per branch) | ISNULL(SUM(corresponding liability column), 0) per metric branch. | Tier 2 |
| 8 | UpdateDate | ETL | GETDATE() | Stamped at INSERT time via GETDATE(). | Propagation |

## UC External Lineage

UC Target: `_Not_Migrated`

*No UC lineage entries — table not migrated to Unity Catalog.*
