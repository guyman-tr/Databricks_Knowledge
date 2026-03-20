# Column Lineage: DWH_dbo.Dim_State_and_Province

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_State_and_Province` |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **Primary Source** | `Dictionary.RegionByIP` + `Dictionary.RegionName` (`etoro`) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.RegionByIP (etoroDB-REAL, 4,206 rows)
  + etoro.Dictionary.RegionName (full geographic names)
  |
  v [INNER JOIN: rei.Name = ren.ShortName AND rei.CountryID = ren.CountryID]
  |
  v [Generic Pipeline — daily, Override, parquet]
DWH_staging.etoro_Dictionary_RegionByIP + DWH_staging.etoro_Dictionary_RegionName
  |
  v [SP_Dictionaries_DL_To_Synapse — TRUNCATE + INSERT (joined result)]
DWH_dbo.Dim_State_and_Province (181 rows)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is from source. |
| **ETL-computed** | Derived/calculated by ETL SP. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| RegionByIP_ID | Dictionary.RegionByIP | RegionByIP_ID | passthrough | LEFT side of join (rei); 181 rows have matching RegionName |
| CountryID | Dictionary.RegionName | CountryID | passthrough | RIGHT side of join (ren) |
| ShortName | Dictionary.RegionName | ShortName | passthrough | Also the JOIN condition key (equals rei.Name) |
| Name | Dictionary.RegionName | Name | passthrough | Full geographic label (state/province/territory) |
| UpdateDate | — | — | ETL-computed | GETDATE() at SP execution time |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 4 |
| **ETL-computed** | 1 |
| **Total** | 5 |
