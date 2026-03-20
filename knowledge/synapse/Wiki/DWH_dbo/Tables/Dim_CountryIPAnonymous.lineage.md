# Column Lineage: DWH_dbo.Dim_CountryIPAnonymous

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_CountryIPAnonymous` |
| **UC Target** | _Pending - resolved during write-objects_ |
| **Primary Source** | `IP2Location Anonymous IP database` (external commercial provider) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_Country_DL_To_Synapse` |
| **Secondary Sources** | `DWH_dbo.Dim_Country` (for CountryID resolution) |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
IP2Location Anonymous IP database (external)
  -> DWH_staging.IP2Location (HEAP, ROUND_ROBIN)
  -> DWH_dbo.SP_Dictionaries_Country_DL_To_Synapse (TRUNCATE + INSERT)
  -> DWH_dbo.Dim_CountryIPAnonymous (initial: 6 cols)
  -> UPDATE: JOIN DWH_dbo.Dim_Country ON Abbreviation = CountryCode -> sets CountryID
  -> DWH_dbo.Dim_CountryIPAnonymous (4.8M rows, fully loaded)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **rename** | Same value, different column name in DWH. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |
| **NULL-guard** | Value transformation: ISNULL(source_col, default) applied. |
| **UPDATE-patch** | Not in initial INSERT; added via a subsequent UPDATE pass. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| IPFrom | IP2Location (DWH_staging.IP2Location) | ip_from | rename | snake_case -> PascalCase. bigint integer. |
| IPTo | IP2Location (DWH_staging.IP2Location) | ip_to | rename | snake_case -> PascalCase. bigint integer. |
| ProxyType | IP2Location (DWH_staging.IP2Location) | proxy_type | rename | snake_case -> PascalCase. 3-char code. |
| CountryCode | IP2Location (DWH_staging.IP2Location) | country_code | NULL-guard + rename | `ISNULL(country_code, 'NA')` - NULL maps to 'NA' (Namibia's ISO code). |
| CountryName | IP2Location (DWH_staging.IP2Location) | country_name | rename | snake_case -> PascalCase. Full country name string. |
| UpdateDate | - | - | ETL-computed | GETDATE() on each reload. |
| CountryID | DWH_dbo.Dim_Country | CountryID | UPDATE-patch | Resolved by: `JOIN Dim_Country b ON b.Abbreviation = a.CountryCode`. NULL if no match. |

## Summary

| Category | Count |
|----------|-------|
| **Rename** | 4 |
| **NULL-guard + rename** | 1 |
| **ETL-computed** | 1 |
| **UPDATE-patch** | 1 |
| **Total** | 7 |
