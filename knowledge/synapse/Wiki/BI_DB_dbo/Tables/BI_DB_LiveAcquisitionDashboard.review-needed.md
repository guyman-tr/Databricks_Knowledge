# Review Sidecar — BI_DB_dbo.BI_DB_LiveAcquisitionDashboard

## Auto-Generated Verification

| Check | Status | Notes |
|-------|--------|-------|
| Column count matches DDL | ✅ | 22 columns in DDL, 22 in wiki |
| All columns have tier suffix | ✅ | T1=9, T2=7, T3=4, Propagation=1 |
| Writer SP confirmed | ✅ | SP_H_LiveAcquisitionDashboard — OpsDB P0 Hourly |
| ETL pattern documented | ✅ | TRUNCATE + INSERT (hourly full refresh) |
| KPI values confirmed via live data | ✅ | Registration (1,358,954) + FTDs (124,852) — MCP query verified |
| RegToFTDBuckets values confirmed from SP code | ✅ | SameDay/1 Day/2Days/Same Week/Same Month/OldReg — read from SP |
| T1 upstream source found | ✅ | etoro.Customer.Customer (DB_Schema repo) + etoro.Billing.Deposit |
| Sample data reviewed | ✅ | 1,483,806 rows; rolling 92 days; top countries: UK, France, Germany |

## T1 Fidelity Table

| BI_DB Column | T1 Source | T1 Wiki |
|-------------|-----------|---------|
| CID | etoro.Customer.Customer.CID | DB_Schema/etoro/Wiki/Customer/Views/Customer.Customer.md |
| Date (Registration path) | etoro.Customer.Customer.Registered | same |
| Date (FTDs path) | etoro.Billing.Deposit.ModificationDate | DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md |
| CountryID | etoro.Customer.Customer.CountryID | DB_Schema/etoro/Wiki/Customer/Views/Customer.Customer.md |
| Country | etoro.Dictionary.Country.Name | (via Dim_Country) |
| FTDA | etoro.Billing.Deposit.Amount × ExchangeRate | DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md |
| SerialID | etoro.Customer.Customer.SerialID | DB_Schema/etoro/Wiki/Customer/Views/Customer.Customer.md |
| SubSerialID | etoro.Customer.Customer.SubSerialID | same |
| DownloadID | etoro.Customer.Customer.DownloadID | same |
| FunnelName / FunnelFromName | etoro.Customer.Customer.FunnelID/FunnelFromID → Dim_Funnel | same |

**T1 coverage**: 9 / 21 business columns = 42.9%

## Items for Human Review

| # | Column / Section | Confidence | Question |
|---|-----------------|------------|----------|
| 1 | SP_H_LiveAcquisitionDashboard_New | High | OpsDB also shows this SP writing to BI_DB_LiveAcquisitionDashboard (P0 Hourly). SSDT code is a complete stub (`PRINT 'Hello World'` only). Confirm this SP is decommissioned or not yet activated. If it becomes active, the ETL documentation needs full update. |
| 2 | SP_TanganyEOD_Recon → BI_DB_LiveAcquisitionDashboard | High | OpsDB metadata shows SP_TanganyEOD_Recon as a writer to this table. No such code found in SSDT. Likely an OpsDB metadata error (Tangany recon SP writing to live acquisition dashboard is not logical). Confirm this dependency can be dismissed. |
| 3 | CountryID=250 exclusion | Medium | Filter `CountryID ≠ 250` is applied. Wiki does not name which country this is. Confirm via `SELECT Name FROM [DWH_dbo].[Dim_Country] WHERE CountryID = 250` and add clarification to the population filter note. |
| 4 | Dim_Customer JOIN (historical Registration path) | Medium | Historical Registration rows use `LEFT JOIN DWH_dbo.Dim_Customer dc ON dc.RealCID = b.CID WHERE dc.RegisteredReal ≤ @MinDate+1`. Customers absent from Dim_Customer will have NULL FunnelID/CountryID/RegionID, causing NULL FunnelName, CountryID, Region, Country, State for those rows. Confirm expected coverage gap magnitude. |
| 5 | RegToFTD column type | Low | DDL declares `RegToFTD varchar(100)` but the SP assigns `DATEDIFF(DAY, Registered, Date)` (an INT). This is an implicit INT→varchar cast. No data quality issue observed in samples, but worth noting for consumers who rely on numeric comparisons without explicit CAST. |
| 6 | @MinDate anchor freshness | Low | @MinDate = MAX(CAST(Date AS DATE)) FROM BI_DB_LiveAcquisitionDashboard_Daily. If the Daily table is not refreshed for extended periods (e.g., holiday pipeline pause), @MinDate becomes stale and the live hourly feed covers a wider gap than 1 day. Confirm operational monitoring is in place for this edge case. |

## Reviewer Corrections

*(Empty — awaiting human review)*

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 9 | CID, Date, CountryID, Country, FTDA, SerialID, SubSerialID, DownloadID, FunnelName/FunnelFromName |
| Tier 2 | 7 | AffiliatesGroupsName, Contact, Channel, SubChannel, Fast, Fast24H, KPI, RegToFTDBuckets, RegToFTD |
| Tier 3 | 4 | Region, State (no upstream DWH wiki available for Dim_Country, Dim_State_and_Province) |
| Propagation | 1 | UpdateDate |
