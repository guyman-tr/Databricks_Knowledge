# Column Lineage: DWH_dbo.Dim_ContactType

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_ContactType` |
| **UC Target** | Not in Generic Pipeline — not exported to UC |
| **Primary Source** | Unknown |
| **ETL SP** | None |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
[Unknown production source]
  -> [No ETL implemented]
    -> DWH_dbo.Dim_ContactType (0 rows, never populated)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **unknown** | Source and mapping unknown — table has 0 rows and no ETL was found. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| ContactTypeID | Unknown | Unknown | unknown | Intended as natural key; 0 rows loaded |
| Name | Unknown | Unknown | unknown | Short contact type label; 0 rows loaded |
| DWHContactTypeID | Unknown | Unknown | unknown | DWH surrogate — would equal ContactTypeID per SP_Dictionaries pattern; 0 rows loaded |
| UpdateDate | — | — | ETL-computed | Would be set to GETDATE() by ETL SP; never set — 0 rows |
| InsertDate | — | — | ETL-computed | Would be set to GETDATE() by ETL SP; never set — 0 rows |
| StatusID | — | — | ETL-computed | Would be set to 1 (active) by SP_Dictionaries pattern; never set — 0 rows |

## Summary

| Category | Count |
|----------|-------|
| **Unknown** | 3 |
| **ETL-computed** | 3 |
| **Total** | 6 |
