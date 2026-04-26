# BI_DB_dbo.BI_DB_Corporates_SummaryReport — Column Lineage

**Generated**: 2026-04-21 | **Writer SP**: SP_CorporatesSummaryReport | **Batch**: 20

## Summary

Daily TRUNCATE+INSERT snapshot of eToro corporate and SMSF account holders (AccountTypeID IN 2, 14).
Sources: DWH_dbo.Fact_SnapshotCustomer (population filter), DWH_dbo.Dim_Customer (current attributes),
DWH_dbo.V_Liabilities (current financial position), BI_DB_dbo.BI_DB_AllDeposits (total deposits).

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | GCID | DWH_dbo.Fact_SnapshotCustomer | GCID | Passthrough — fsc.GCID. Population filtered by AccountTypeID IN (2,14). | Tier 1 — Customer.CustomerStatic |
| 2 | RealCID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Passthrough — fsc.RealCID. JOIN key to Dim_Customer in #details step. | Tier 1 — Customer.CustomerStatic |
| 3 | ApprovedDateTime | DWH_dbo.Dim_Range → DWH_dbo.Dim_Date | FullDate | MIN(dd.FullDate) — earliest full date of the DateRange covering the first corporate/SMSF snapshot. Proxy for account approval date. | Tier 2 — SP_CorporatesSummaryReport |
| 4 | PlayerStatus | DWH_dbo.Dim_Customer → DWH_dbo.Dim_PlayerStatus | Name | dps.Name AS PlayerStatus — current player status name via LEFT JOIN Dim_Customer.PlayerStatusID = Dim_PlayerStatus.PlayerStatusID. | Tier 2 — SP_CorporatesSummaryReport |
| 5 | PlayerLevel | DWH_dbo.Dim_Customer → DWH_dbo.Dim_PlayerLevel | Name | dpl.Name AS PlayerLevel — current club tier via LEFT JOIN Dim_Customer.PlayerLevelID = Dim_PlayerLevel.PlayerLevelID. | Tier 2 — SP_CorporatesSummaryReport |
| 6 | Country | DWH_dbo.Dim_Country | Name | dc1.Name AS Country — full country name via LEFT JOIN Dim_Customer.CountryID = Dim_Country.CountryID. | Tier 1 — Dictionary.Country |
| 7 | Region | DWH_dbo.Dim_Country | Region | dc1.Region AS Region — marketing region label from Dim_Country (sourced from etoro.Dictionary.MarketingRegion.Name). | Tier 2 — SP_Dictionaries_Country_DL_To_Synapse |
| 8 | Balance | DWH_dbo.V_Liabilities | Credit | ISNULL(vl.Credit, 0) — credit balance from V_Liabilities for vl.DateID = @EndDateID (yesterday). | Tier 2 — SP_CorporatesSummaryReport |
| 9 | TotalEquity | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | ISNULL(vl.Liabilities + vl.ActualNWA, 0) — total equity = liabilities + actual net worth at @EndDateID. | Tier 2 — SP_CorporatesSummaryReport |
| 10 | TotalDeposits | BI_DB_dbo.BI_DB_AllDeposits | [Amount in $] | ISNULL(SUM(bdad.[Amount in $]), 0) WHERE bdad.PaymentStatus = 'Approved' — cumulative approved deposits per customer. | Tier 2 — SP_CorporatesSummaryReport |
| 11 | AccountType | DWH_dbo.Dim_Customer → DWH_dbo.Dim_AccountType | Name | aty.Name AS AccountType — CURRENT account type name via JOIN Dim_Customer.AccountTypeID = Dim_AccountType.AccountTypeID. May differ from original population filter (IN 2,14) if account type changed. | Tier 2 — SP_CorporatesSummaryReport |
| 12 | UpdateDate | — | — | GETDATE() at ETL execution time (TRUNCATE+INSERT daily). | Tier 2 — SP_CorporatesSummaryReport |

## ETL Pipeline

```
etoro.Customer.CustomerStatic + etoro.Dictionary.AccountType
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_dbo.Fact_SnapshotCustomer (AccountTypeID IN 2,14)
DWH_dbo.Dim_Customer + Dim_PlayerStatus + Dim_PlayerLevel + Dim_Country + Dim_AccountType
DWH_dbo.V_Liabilities (@EndDateID = yesterday)
BI_DB_dbo.BI_DB_AllDeposits (PaymentStatus='Approved')
  |-- SP_CorporatesSummaryReport (TRUNCATE+INSERT daily) ---|
  v
BI_DB_dbo.BI_DB_Corporates_SummaryReport (4,636 rows, 2011-present)
  |-- UC Target: _Not_Migrated ---|
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 3 | GCID, RealCID, Country |
| Tier 2 | 9 | ApprovedDateTime, PlayerStatus, PlayerLevel, Region, Balance, TotalEquity, TotalDeposits, AccountType, UpdateDate |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |
