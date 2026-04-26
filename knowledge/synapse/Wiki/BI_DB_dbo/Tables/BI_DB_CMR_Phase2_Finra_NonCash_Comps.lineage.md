# Column Lineage — BI_DB_dbo.BI_DB_CMR_Phase2_Finra_NonCash_Comps

**Generated**: 2026-04-23 | **Writer SP**: SP_CMR_Phase2_Finra_NonCash_Comps | **Batch**: 60

## Source Chain

```
DWH_dbo.Fact_CustomerAction (ActionTypeID=36, CompensationReasonID IN known set, DateID=@dateID)
  +-- DWH_dbo.Fact_SnapshotCustomer (RegulationID=8 filter: FinCEN+FINRA)
  |     JOIN on RealCID + DateRangeID via Dim_Range
  +-- DWH_dbo.Dim_Range (DateRangeID → FromDateID/ToDateID range filter)
  +-- DWH_dbo.Dim_CompensationReason (CompensationReasonID → Name)
  |-- SP_CMR_Phase2_Finra_NonCash_Comps (@date, DELETE+INSERT, CID-grain)
  v
BI_DB_dbo.BI_DB_CMR_Phase2_Finra_NonCash_Comps
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | RealCID | Fact_CustomerAction → Customer.CustomerStatic | RealCID | Passthrough. Tier 1 from upstream (Fact_CustomerAction inherits from Customer.CustomerStatic). | Tier 1 |
| 2 | DateID | Fact_CustomerAction | DateID | Passthrough (= @dateID filter). ETL-computed from Occurred in FCA. | Tier 2 |
| 3 | Date | Fact_CustomerAction | Occurred | CAST(Occurred AS DATE) — derives calendar date from the event timestamp. Tier 2 transformation in SP. | Tier 2 |
| 4 | CompensationReason | Dim_CompensationReason → BackOffice.CompensationReason | Name | Resolved via JOIN on CompensationReasonID. Passthrough of Dim_CompensationReason.Name. Tier 1 from BackOffice.CompensationReason. | Tier 1 |
| 5 | Amount | Fact_CustomerAction | Amount | SUM(Amount) grouped by RealCID, DateID, CompensationReason — aggregate monetary value of non-cash corporate action (ActionTypeID=36). | Tier 2 |
| 6 | UpdateDate | ETL | GETDATE() | Stamped at INSERT time via GETDATE(). | Propagation |

## Filters Applied in SP

| Filter | Value | Purpose |
|--------|-------|---------|
| ActionTypeID | = 36 | Compensation events only |
| CompensationReasonID | IN (45,60,62,63,64,65,66,67,68,69,70,71,72,75,76,78,79,81,82,83,84,85,86,87,88,89,92) | Apex corporate action reasons |
| RegulationID (via SnapshotCustomer) | = 8 | FinCEN+FINRA (US FINRA) regulated customers |
| DateID | = @dateID | Single-day processing |

## UC External Lineage

UC Target: `_Not_Migrated`

*No UC lineage entries — table not migrated to Unity Catalog.*
