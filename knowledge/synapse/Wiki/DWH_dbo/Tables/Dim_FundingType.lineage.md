# Column Lineage: DWH_dbo.Dim_FundingType

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_FundingType` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` |
| **Primary Source** | `etoro.Dictionary.FundingType` (`etoroDB-REAL`) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None (N/A row = hardcoded VALUES) |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.FundingType (etoroDB-REAL)
    |
    v
[Generic Pipeline - Bronze/etoro/Dictionary/FundingType/]
    |
    v
DWH_staging.etoro_Dictionary_FundingType
    |
    v
SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, ~line 672)
  - Adds: DWHFundingTypeID = FundingTypeID, StatusID = 1, UpdateDate/InsertDate = GETDATE()
    |
    v
DWH_dbo.Dim_FundingType (rows 1-44)

THEN:
SP_Dictionaries_DL_To_Synapse (VALUES INSERT, ~line 1475)
  - Hardcoded: FundingTypeID=0, Name='N/A', all flags=0, StatusID=1
    |
    v
DWH_dbo.Dim_FundingType (row 0 - N/A sentinel added)
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
| FundingTypeID | etoro.Dictionary.FundingType | FundingTypeID | passthrough | smallint. N/A row (ID=0) is hardcoded. |
| Name | etoro.Dictionary.FundingType | Name | passthrough | varchar(50). Not renamed (kept as Name). |
| IsNewStyle | etoro.Dictionary.FundingType | IsNewStyle | passthrough | bit. |
| IsSingleFunding | etoro.Dictionary.FundingType | IsSingleFunding | passthrough | bit. |
| IsCashoutActive | etoro.Dictionary.FundingType | IsCashoutActive | passthrough | bit. |
| DWHFundingTypeID | etoro.Dictionary.FundingType | FundingTypeID | ETL-computed | `[FundingTypeID] as [DWHFundingTypeID]` - alias of FundingTypeID. Currently identical to source. |
| StatusID | - | - | ETL-computed | Hardcoded value 1 for all rows. |
| UpdateDate | - | - | ETL-computed | GETDATE() (@ddate variable) at SP execution time. |
| InsertDate | - | - | ETL-computed | GETDATE() (@ddate variable) - same value as UpdateDate per run. |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 5 |
| **ETL-computed** | 4 |
| **Total** | 9 |
