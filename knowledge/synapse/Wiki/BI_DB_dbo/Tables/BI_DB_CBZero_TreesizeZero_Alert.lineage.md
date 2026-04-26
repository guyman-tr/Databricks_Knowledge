# Column Lineage — BI_DB_dbo.BI_DB_CBZero_TreesizeZero_Alert

Generated: 2026-04-23 | Writer SP: SP_Client_Balance_and_DailyZero_TreeSize_Alert | ETL Frequency: Daily

## Production Source

| Property | Value |
|----------|-------|
| **Primary Source** | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New + BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW |
| **Source Layer** | BI_DB_dbo internal tables |
| **UC Target** | `_Not_Migrated` |
| **Upstream Wiki** | BI_DB_Client_Balance_CID_Level_New and BI_DB_DailyZero_TreeSize_NEW (BI_DB_dbo siblings) |

## ETL Pipeline

```
BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New  (aggregated to total CBZero per date)
BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW        (aggregated to total TreesizeZero per date)
  |-- SP_Client_Balance_and_DailyZero_TreeSize_Alert @date --|
  |-- Filter: (ABS(CBZero - TreesizeZero) / ABS(CBZero)) * 100 >= 0.5 --|
  |-- TRUNCATE BI_DB_CBZero_TreesizeZero_Alert + INSERT --|
  v
BI_DB_dbo.BI_DB_CBZero_TreesizeZero_Alert
  (0 rows when reconciliation discrepancy < 0.5%; rows present only when alert fires)
  |-- UC: _Not_Migrated --|
```

## Column Lineage

| # | DWH Column | Source Object | Source Column | Transform | Tier |
|---|------------|---------------|---------------|-----------|------|
| 1 | DateID | BI_DB_Client_Balance_CID_Level_New / BI_DB_DailyZero_TreeSize_NEW | Date column | YYYYMMDD integer key derived from @date parameter | Tier 2 |
| 2 | CBZero | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Aggregated balance | SUM or aggregation of client balance zero-balance metric for @date | Tier 2 |
| 3 | TreesizeZero | BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW | Aggregated treesize | SUM or aggregation of daily zero treesize metric for @date | Tier 2 |
| 4 | PercentDiff | — | — | Computed: (ABS(CBZero - TreesizeZero) / ABS(CBZero)) * 100 — reconciliation divergence percentage | Tier 2 |

## Tier Summary

| Tier | Count | Notes |
|------|-------|-------|
| Tier 2 | 4 | All columns SP-computed from two BI_DB sibling tables |
| Propagation | 0 | No UpdateDate column |
