# BI_DB_dbo.BI_DB_Compensation_Activity_Data_CompensationReason — Column Lineage

> Generated: 2026-04-23 | Batch 71

## Object Metadata

| Property | Value |
|----------|-------|
| Schema | BI_DB_dbo |
| Object Type | Table |
| Writer SP | SP_Compensation_Activity_Data |
| Load Pattern | TRUNCATE + INSERT (previous-month full refresh) |
| Population | FCA-regulated customers (RegulationID=2, IsValidCustomer=1) with CompensationReasonID IN (3,26,125,126,127,128) |

## ETL Pipeline

```
DWH_dbo.Fact_CustomerAction (ActionType = compensation, FCA filter)
  + DWH_dbo.Dim_Customer (RegulationID=2, IsValidCustomer=1 filter)
  + DWH_dbo.Dim_CompensationReason (Name → CompensationReason)
    |-- SP_Compensation_Activity_Data (previous month window) TRUNCATE+INSERT ---|
    v
BI_DB_dbo.BI_DB_Compensation_Activity_Data_CompensationReason (916 rows, March 2026)
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | RealCID | DWH_dbo.Fact_CustomerAction | RealCID | Passthrough | Tier 1 — Customer.CustomerStatic |
| 2 | Date | DWH_dbo.Fact_CustomerAction | Occurred | Rename | Tier 2 — Fact_CustomerAction wiki |
| 3 | Amount | DWH_dbo.Fact_CustomerAction | Amount | Passthrough (compensation events only) | Tier 2 — Fact_CustomerAction wiki |
| 4 | CompensationReason | DWH_dbo.Dim_CompensationReason | Name | JOIN on CompensationReasonID IN (3,26,125,126,127,128) | Tier 1 — Dim_CompensationReason wiki |
| 5 | UpdateDate | ETL | GETDATE() | Runtime timestamp | Propagation |
