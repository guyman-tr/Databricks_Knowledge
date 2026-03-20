# Column Lineage: DWH_dbo.Dim_CountryIP

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_CountryIP` |
| **UC Target** | _Pending - resolved during write-objects_ |
| **Primary Source** | `etoro.Dictionary.CountryIP` (etoro) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.CountryIP
  -> [Generic Pipeline]
  -> DWH_staging.etoro_Dictionary_CountryIP (HEAP, ROUND_ROBIN)
  -> DWH_dbo.SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, GETDATE() for UpdateDate)
  -> DWH_dbo.Dim_CountryIP (6.8M rows)
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
| CountryID | etoro.Dictionary.CountryIP | CountryID | passthrough | Country owning the IP range. |
| IPFrom | etoro.Dictionary.CountryIP | IPFrom | passthrough | Start of IP range as bigint integer. |
| IPTo | etoro.Dictionary.CountryIP | IPTo | passthrough | End of IP range as bigint integer. |
| RegionID | etoro.Dictionary.CountryIP | RegionID | passthrough | Sub-national region. NULL when not available. |
| UpdateDate | - | - | ETL-computed | GETDATE() on each reload. |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 4 |
| **ETL-computed** | 1 |
| **Total** | 5 |
