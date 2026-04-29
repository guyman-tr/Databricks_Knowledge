# BI_DB_dbo.BI_DB_Revenue14DaysToBigQuery — Column Lineage

## Source Objects

| Source | Schema | Role |
|--------|--------|------|
| Dim_Customer | DWH_dbo | First deposit date + customer ID (filtered by IsValidCustomer=1) |
| BI_DB_CID_BalanceDays | BI_DB_dbo | 14-day cumulative revenue metric |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| FirstDepositeDate | DWH_dbo.Dim_Customer | FirstDepositDate | Passthrough (note: target column has typo — "Deposite" vs "Deposit") |
| CID | DWH_dbo.Dim_Customer | RealCID | Rename (RealCID → CID) |
| Revenue | BI_DB_dbo.BI_DB_CID_BalanceDays | Revenue14days | Rename (Revenue14days → Revenue) |
| UpdateDate | — | GETDATE() | ETL timestamp |

## ETL Pattern

- **SP**: BI_DB_dbo.SP_Revenue14DaysToBigQuery
- **Schedule**: Daily (SB_Daily, Priority 0)
- **Load**: DELETE rows where FirstDepositeDate = @date-14, then INSERT new rows for that cohort date
- **Filter**: Only customers with IsValidCustomer=1 and FirstDepositDate exactly 14 days before run date
