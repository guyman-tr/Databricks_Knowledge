# Column Lineage: BI_DB_dbo.BI_DB_ASIC_CreditLine_At_transfer

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_ASIC_CreditLine_At_transfer` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Source** | `DWH_dbo.Fact_RegulationTransfer` (regulation change events) |
| **ETL SP** | `SP_ASIC_CreditLine_At_transfer` |
| **Secondary Sources** | `DWH_dbo.Dim_Regulation` (×2, name lookups), `BI_DB_dbo.BI_DB_Daily_CreditLine` (credit line snapshot) |
| **Generated** | 2026-03-28 |

## Lineage Chain

```
DWH_dbo.Fact_RegulationTransfer (regulation change events, from etoro.History.BackOfficeCustomer)
    │
    ├── JOIN DWH_dbo.Dim_Regulation dr  ON dr.DWHRegulationID = frt.FromRegulationID
    ├── JOIN DWH_dbo.Dim_Regulation dr1 ON dr1.DWHRegulationID = frt.ToRegulationID
    ├── LEFT JOIN BI_DB_dbo.BI_DB_Daily_CreditLine cl ON frt.DateID = cl.DateID AND cl.RealCID = frt.CID
    │
    └── SP_ASIC_CreditLine_At_transfer @Date
        ├── CTAS #cl (WHERE frt.ToRegulationID IN (4,10) — ASIC + ASIC & GAML only)
        ├── DELETE WHERE DateID = @DateID
        └── INSERT → BI_DB_dbo.BI_DB_ASIC_CreditLine_At_transfer
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **join-enriched** | Joined from a secondary source table during ETL. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| FromRegulation | DWH_dbo.Dim_Regulation (dr) | Name | join-enriched | `dr.Name` via `Fact_RegulationTransfer.FromRegulationID = dr.DWHRegulationID` | Regulation the customer was under BEFORE transfer |
| ToRegulation | DWH_dbo.Dim_Regulation (dr1) | Name | join-enriched | `dr1.Name` via `Fact_RegulationTransfer.ToRegulationID = dr1.DWHRegulationID` | Filtered to ToRegulationID IN (4,10) = ASIC, ASIC & GAML |
| CID | DWH_dbo.Fact_RegulationTransfer | CID | passthrough | Direct: `frt.CID` | Customer Real account ID |
| TotalCLAmount | BI_DB_dbo.BI_DB_Daily_CreditLine | TotalCLAmount | join-enriched | `cl.TotalCLAmount` via LEFT JOIN on `frt.DateID = cl.DateID AND cl.RealCID = frt.CID` | NULL when customer had no credit line at transfer date (99.94% NULL) |
| DateID | DWH_dbo.Fact_RegulationTransfer | DateID | passthrough | Direct: `frt.DateID` | YYYYMMDD integer, filtered to @DateID |
| DateOccurred | — | — | ETL-computed | `@Date` SP parameter cast as date | Business date of the regulation transfer |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL execution timestamp |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 |
| **Join-enriched** | 3 |
| **ETL-computed** | 2 |
| **Total** | 7 |
