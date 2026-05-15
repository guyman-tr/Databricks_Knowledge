# Column Lineage: BI_DB_dbo.BI_DB_CIDFirstDates_metric_view

| Property | Value |
|----------|-------|
| **Synapse View** | `BI_DB_dbo.BI_DB_CIDFirstDates_metric_view` (Synapse MCP pool used for batch did not expose this object; grounding uses UC `DESCRIBE` + `BI_DB_CIDFirstDates` wiki) |
| **UC Target (roster)** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_metric_view` |
| **UC verified alternate** | `main.pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_metric_view` (Databricks METRIC_VIEW; see `BI_DB_CIDFirstDates.deploy-report.md`) |
| **Generated** | 2026-05-14 |

## Source Objects

| Source Object | Role |
|---------------|------|
| `BI_DB_dbo.BI_DB_CIDFirstDates` | Narrow grain for first-dates/equity snapshots (CID, Club, Credit, equity, deposits) |
| `DWH_dbo.Dim_Customer` | Username PII linkage as documented in CIDFirstDates ETL |

## Column Lineage

| View Column | Source Table | Source Column | Transform |
|-------------|--------------|---------------|-----------|
| CustomerID | `BI_DB_CIDFirstDates` | `CID` | rename / semantic alias (`CustomerID` in UC METRIC_VIEW) |
| UserName | `Dim_Customer` | `UserName` | passthrough via CIDFirstDates ETL joins (Tier path per `BI_DB_CIDFirstDates` / Dim_Customer) |
| ClubName | `BI_DB_CIDFirstDates` | `Club` | rename (`ClubName` presentation name in METRIC_VIEW) |
| registered date | `BI_DB_CIDFirstDates` | `registered` | rename (quoted identifier with embedded space in UC catalog) |
| Total Credit | `BI_DB_CIDFirstDates` | `Credit` | measure projection; semantics `Credit = ISNULL(V_Liabilities.Credit, 0)` per `SP_CIDFirstDates` (see `BI_DB_CIDFirstDates.md` §2.6) |
| Total Realized Equity | `BI_DB_CIDFirstDates` | `RealizedEquity` | measure projection; `RealizedEquity = ISNULL(V_Liabilities.RealizedEquity, 0)` per same section |
| Last Deposit Amount | `BI_DB_CIDFirstDates` | `LastDepositAmount` | passthrough metric from Fact_BillingDeposit lineage in `SP_CIDFirstDates` |
