# BI_DB_dbo.BI_DB_Depositors_By_Managers — Column Lineage

## Lineage Metadata

| Property | Value |
|----------|-------|
| **Target Table** | BI_DB_dbo.BI_DB_Depositors_By_Managers |
| **Writer SP** | BI_DB_dbo.SP_NewBonusReport (end-of-month section) |
| **Primary Sources** | DWH_dbo.Fact_SnapshotCustomer (customer-manager assignments), DWH_dbo.Fact_CustomerAction (deposits), DWH_dbo.Dim_Manager |
| **Load Pattern** | End-of-month only (IF EOMONTH(@dd) = @dd) — DELETE month + INSERT aggregation |
| **Generated** | 2026-04-26 |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|---------------|-----------|------|
| 1 | Manager | DWH_dbo.Dim_Manager | FirstName + LastName | Concatenated name | Tier 2 |
| 2 | Month | SP computation | @dd | DATEADD(MONTH, DATEDIFF(MONTH, 0, @dd), 0) → 1st of month | Tier 2 |
| 3 | NoOfCustomers | DWH_dbo.Fact_SnapshotCustomer | COUNT(RealCID) | Count of managed customers at month start | Tier 2 |
| 4 | Depositors | DWH_dbo.Fact_CustomerAction | SUM(IsDepositor) | Count of managed customers who deposited (ActionTypeID=7) during the month | Tier 2 |
| 5 | UpdateDate | SP computation | GETDATE() | ETL timestamp | Tier 5 |
| 6 | ManagerID | DWH_dbo.Dim_Manager | ManagerID | Passthrough | Tier 2 |

## Source Objects

| Source Object | Type | Purpose |
|--------------|------|---------|
| DWH_dbo.Fact_SnapshotCustomer | Fact Table | Customer-manager assignments via DateRangeID |
| DWH_dbo.Dim_Manager | Dimension | Manager name, excludes IDs 0,342,787,283,887 |
| DWH_dbo.Dim_Range | Dimension | Date range resolution for snapshot |
| DWH_dbo.Fact_CustomerAction | Fact Table | Deposit events (ActionTypeID=7) during the month |
| BI_DB_dbo.BI_DB_CIDFirstDates | Table | Customer country/region/channel metadata |
