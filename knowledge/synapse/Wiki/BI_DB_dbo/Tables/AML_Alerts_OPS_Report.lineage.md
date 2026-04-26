# Lineage: BI_DB_dbo.AML_Alerts_OPS_Report

**Generated**: 2026-04-23
**Schema**: BI_DB_dbo
**Object**: AML_Alerts_OPS_Report
**Object Type**: Table
**Writer SP**: None identified (external/OPS tool feed — no SSDT SP writes to this table)
**Production Source**: Unknown — no Generic Pipeline mapping, no External table, no writer SP in SSDT

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | AlertIdentifier | Unknown | Unknown | — | Tier 4 |
| 2 | AlertType | Unknown | Unknown | — | Tier 4 |
| 3 | CID | Unknown (likely etoro production) | CID | Passthrough | Tier 4 |
| 4 | Assigned | Unknown | Unknown | — | Tier 4 |
| 5 | Regulation | Unknown | Unknown | — | Tier 4 |
| 6 | FirstAlert | Unknown | Unknown | — | Tier 4 |
| 7 | FirstHandled | Unknown | Unknown | — | Tier 4 |
| 8 | FirstAssigned | Unknown | Unknown | — | Tier 4 |
| 9 | AssignedNotHandled | Unknown | Unknown | ETL computed flag | Tier 4 |
| 10 | AssignedAndHandled | Unknown | Unknown | ETL computed flag | Tier 4 |
| 11 | NotAssigned | Unknown | Unknown | ETL computed flag | Tier 4 |
| 12 | UpdateDate | Unknown | Unknown | ETL timestamp | Tier 4 |

## ETL Pipeline

```
Unknown external source (OPS tool / manual load)
  |-- Unknown feed mechanism --|
  v
BI_DB_dbo.AML_Alerts_OPS_Report (0 rows — empty as of 2026-04-23)
  |-- No downstream consumers identified --|
  v
(No UC target — Not_Migrated)
```

## Notes

- Backup table `AML_Alerts_OPS_Report_Backup_20241117` created 2024-12-01 confirms historical data existed
- Backup CID column was bigint vs current int — schema change occurred
- Table is currently empty (0 rows as of 2026-04-23)
- No OpsDB registration; no writer SP in SSDT BI_DB_dbo
- Likely populated by an AML OPS reporting tool or manual SQL inserts
