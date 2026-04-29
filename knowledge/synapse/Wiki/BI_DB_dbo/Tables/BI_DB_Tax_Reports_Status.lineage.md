# BI_DB_dbo.BI_DB_Tax_Reports_Status — Column Lineage

## Source Objects

| Source | Schema | Role | Join Condition |
|--------|--------|------|----------------|
| External_FinanceReports_Reports_Report | BI_DB_dbo (External) | Primary tax report request data | Main driver |
| DWH_dbo.Dim_Country | DWH_dbo | Country name lookup | t.CountryID = dc.CountryID |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| Date | (SP parameter) | @Date | SP input parameter, set by OpsDB scheduler |
| Country | DWH_dbo.Dim_Country | Name | Dim-lookup passthrough |
| ReportStatus | FinanceReports.Reports.Report | ReportStatusID | CASE: 5,6→'Completed', 7→'Failed', else→'Pending' |
| TaxYear | FinanceReports.Reports.Report | FromUtc, TillUtc | CASE: same year→'YYYY', cross-year→'YYYY/YYYY' |
| FromUtc | FinanceReports.Reports.Report | FromUtc | Passthrough (filtered for valid tax year ranges) |
| TillUtc | FinanceReports.Reports.Report | TillUtc | Passthrough (filtered for valid tax year ranges) |
| Report_Count | FinanceReports.Reports.Report | RequestID | COUNT(RequestID) aggregation |
| UpdateDate | (ETL) | GETDATE() | ETL metadata timestamp |

## Production Source Chain

```
FinanceReports.Reports.Report (tax report request records)
  |-- Generic Pipeline (Bronze export) --|
  v
BI_DB_dbo.External_FinanceReports_Reports_Report (External table)
  + DWH_dbo.Dim_Country (CountryID→Name)
  |-- SP_TaxReports @Date --|
  |-- Filter: valid tax year date ranges (country-specific fiscal years) --|
  |-- Aggregate: COUNT(RequestID) GROUP BY Country, Status, TaxYear, dates --|
  |-- DELETE+INSERT by @Date --|
  v
BI_DB_dbo.BI_DB_Tax_Reports_Status (121K rows)
```
