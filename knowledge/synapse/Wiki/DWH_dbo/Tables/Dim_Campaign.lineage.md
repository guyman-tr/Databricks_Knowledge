# Column Lineage: DWH_dbo.Dim_Campaign

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_Campaign` |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **Primary Source** | `BackOffice.Campaign` (`etoro`) -- LOAD DISABLED |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-18 |

## Lineage Chain

```
etoro.BackOffice.Campaign (etoroDB-REAL, 11,080 rows)
  |
  v [Generic Pipeline - daily, Override, 1440 min, parquet]
Bronze/etoro/BackOffice/Campaign/
  |
  v [staging]
DWH_staging.etoro_BackOffice_Campaign (POPULATED but not read by SP)
  |
  x [SP_Dictionaries_DL_To_Synapse - INSERT COMMENTED OUT]
  |
  v [TRUNCATE + ID=0 placeholder only]
DWH_dbo.Dim_Campaign (1 row - ID=0 placeholder only)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **disabled** | Column was in the intended INSERT but that INSERT is commented out. Staging has data; DWH does not. |
| **ETL-computed** | Derived/calculated by ETL SP. |
| **excluded** | Column in production source not in the DWH INSERT (even in the commented-out version). |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| CampaignID | BackOffice.Campaign | CampaignID | disabled | INSERT commented out in SP; only ID=0 from hardcoded placeholder |
| CampaignGroupID | BackOffice.Campaign | CampaignGroupID | disabled | INSERT commented out |
| Code | BackOffice.Campaign | Code | disabled | INSERT commented out; 'N/A' from hardcoded placeholder |
| MaxNumberOfUsers | BackOffice.Campaign | MaxNumberOfUsers | disabled | INSERT commented out; 0 from placeholder |
| StartDate | BackOffice.Campaign | StartDate | disabled | INSERT commented out; '1900-01-01' from placeholder |
| EndDate | BackOffice.Campaign | EndDate | disabled | INSERT commented out; '1900-01-01' from placeholder |
| MaxBonusAmount | BackOffice.Campaign | MaxBonusAmount | disabled | INSERT commented out; 0 from placeholder |
| IsActive | BackOffice.Campaign | IsActive | disabled | INSERT commented out; 0 from placeholder |
| ParticipatedUsers | BackOffice.Campaign | ParticipatedUsers | disabled | INSERT commented out; 0 from placeholder; MASKED in DWH DDL |
| Description | BackOffice.Campaign | Description | disabled | INSERT commented out; NULL from placeholder; MASKED in DWH DDL |
| InsertDate | - | - | ETL-computed | @ddate (CAST(GETDATE() AS DATE)) for ID=0 placeholder -- date at midnight |
| UpdateDate | - | - | ETL-computed | @ddate (CAST(GETDATE() AS DATE)) for ID=0 placeholder -- date at midnight |
| *(not in DWH)* | BackOffice.Campaign | StartJobID | excluded | SQL Agent binary job ID - not in DWH DDL |
| *(not in DWH)* | BackOffice.Campaign | EndJobID | excluded | SQL Agent binary job ID - not in DWH DDL |
| *(not in DWH)* | BackOffice.Campaign | ExtendedCampaignProperties | excluded | XML column - not in DWH DDL |
| *(not in DWH)* | BackOffice.Campaign | CreatedOn | excluded | Not in DWH DDL |
| *(not in DWH)* | BackOffice.Campaign | CreatedBy | excluded | Not in DWH DDL |
| *(not in DWH)* | BackOffice.Campaign | CurrentBonusAmount | excluded | Not in DWH DDL |

## Summary

| Category | Count |
|----------|-------|
| **Disabled (INSERT commented out)** | 10 |
| **ETL-computed (placeholder only)** | 2 |
| **Excluded from DWH DDL** | 6 |
| **Total (DWH columns)** | 12 |
