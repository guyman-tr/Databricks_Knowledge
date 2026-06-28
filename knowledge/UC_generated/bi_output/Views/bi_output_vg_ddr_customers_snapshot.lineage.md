# Column Lineage: main.bi_output.bi_output_vg_ddr_customers_snapshot

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_ddr_customers_snapshot` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\bi_output_vg_ddr_customers_snapshot.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\bi_output_vg_ddr_customers_snapshot.json` (rows: 102, mismatches: 9) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` |
| **Generated** | 2026-06-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_AccountType.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_AccountStatus.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Language.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `main.bi_output.bi_output_vg_date` | JOIN / referenced | ✓ `knowledge\UC_generated\bi_output\Views\bi_output_vg_date.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Customer_Periodic_Status.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Customer_Daily_Status.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Language.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Manager.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_VerificationLevel.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_GuruStatus.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusReasons.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusSubReasons.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatus.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status   ←── primary upstream
  + main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status   (JOIN)
  + main.bi_output.bi_output_vg_date   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country   (JOIN)
        │
        ▼
main.bi_output.bi_output_vg_ddr_customers_snapshot   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `RealCID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | `RealCID` | `cast` | (Tier 2 — SP_DDR_Customer_Daily_Status) | cast to STRING — CAST(ddrc.RealCID AS STRING) AS RealCID |
| 2 | `GCID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `GCID` | `join_enriched` | (Tier 2 — via Fact_SnapshotCustomer) | fsc.GCID |
| 3 | `Date` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | `date` | `rename` | (Tier 2 — SP_DDR_Customer_Daily_Status) | ddrc.date AS Date |
| 4 | `DateID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | `DateID` | `passthrough` | (Tier 2 — SP_DDR_Customer_Daily_Status) | ddrc.DateID AS DateID |
| 5 | `PlayerLevelID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerLevelID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.PlayerLevelID |
| 6 | `ClubTier` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerLevel) | dpl.Name AS ClubTier |
| 7 | `RegulationID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `RegulationID` | `join_enriched` | (Tier 2 — via Fact_SnapshotCustomer) | fsc.RegulationID |
| 8 | `Regulation` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.Regulation) | dr.Name AS Regulation |
| 9 | `VerificationLevelID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `VerificationLevelID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.VerificationLevelID |
| 10 | `VerificationLevel` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel` | `Name` | `join_enriched` | (Tier 1 — upstream wiki, Dictionary.VerificationLevel) | dv.Name AS VerificationLevel |
| 11 | `CountryID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `CountryID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.CountryID |
| 12 | `Country` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `Name` | `join_enriched` | (Tier 1 - Dictionary.Country upstream wiki) | dc.Name AS Country |
| 13 | `Region` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `MarketingRegionManualName` | `join_enriched` | (Tier 3 - Ext_Dim_Country live data) | dc.MarketingRegionManualName AS Region |
| 14 | `AccountManagerID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `AccountManagerID` | `join_enriched` | (Tier 2 — via Fact_SnapshotCustomer) | fsc.AccountManagerID |
| 15 | `AccountManager` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` | `—` | `string_op` | — | CONCAT(dm.FirstName, ' ', dm.LastName) AS AccountManager |
| 16 | `LanguageID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `LanguageID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.LanguageID |
| 17 | `Language` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | `Name` | `join_enriched` | (Tier 1 — Dictionary.Language) | dl.Name AS Language |
| 18 | `CommunicationLanguageID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `CommunicationLanguageID` | `join_enriched` | (Tier 2 — via Fact_SnapshotCustomer) | fsc.CommunicationLanguageID |
| 19 | `CommunicationLanguage` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | `Name` | `join_enriched` | (Tier 1 — Dictionary.Language) | dcl.Name AS CommunicationLanguage |
| 20 | `AccountTypeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `AccountTypeID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.AccountTypeID |
| 21 | `AccountType` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.AccountType) | act.Name AS AccountType |
| 22 | `GuruStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `GuruStatusID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.GuruStatusID |
| 23 | `GuruStatusName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` | `GuruStatusName` | `join_enriched` | (Tier 1 — Dictionary.GuruStatus) | gs.GuruStatusName |
| 24 | `IsPI` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `—` | `case` | — | CASE WHEN fsc.GuruStatusID > 1 THEN 1 ELSE 0 END AS IsPI |
| 25 | `AccountStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `AccountStatusID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.AccountStatusID |
| 26 | `AccountStatusName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` | `AccountStatusName` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.AccountStatus) | ast.AccountStatusName |
| 27 | `PlayerStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerStatusID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.PlayerStatusID |
| 28 | `PlayerStatusName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.Name AS PlayerStatusName |
| 29 | `CanOpenPosition` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanOpenPosition` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanOpenPosition |
| 30 | `CanClosePosition` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanClosePosition` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanClosePosition |
| 31 | `CanEditPosition` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanEditPosition` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanEditPosition |
| 32 | `CanBeCopied` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanBeCopied` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanBeCopied |
| 33 | `CanDeposit` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanDeposit` | `join_enriched` | — | pst.CanDeposit |
| 34 | `CanRequestWithdraw` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanRequestWithdraw` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanRequestWithdraw |
| 35 | `PlayerStatusReasonID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerStatusReasonID` | `join_enriched` | — | fsc.PlayerStatusReasonID |
| 36 | `PlayerStatusReasonName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatusReasons) | psr.Name AS PlayerStatusReasonName |
| 37 | `PlayerStatusSubReasonID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerStatusSubReasonID` | `join_enriched` | — | fsc.PlayerStatusSubReasonID |
| 38 | `PlayerStatusSubReasonName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` | `PlayerStatusSubReasonName` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatusSubReasons) | pssr.PlayerStatusSubReasonName |
| 39 | `WeekNumberYear` | `main.bi_output.bi_output_vg_date` | `WeekNumberYear` | `join_enriched` | (Tier 1 — DDL) | dd.WeekNumberYear |
| 40 | `CalendarYearMonth` | `main.bi_output.bi_output_vg_date` | `CalendarYearMonth` | `join_enriched` | (Tier 2 — live sample) | dd.CalendarYearMonth |
| 41 | `CalendarQuarter` | `main.bi_output.bi_output_vg_date` | `CalendarQuarter` | `join_enriched` | (Tier 1 — DDL) | dd.CalendarQuarter |
| 42 | `CalendarYear` | `main.bi_output.bi_output_vg_date` | `CalendarYear` | `join_enriched` | (Tier 1 — DDL) | dd.CalendarYear |
| 43 | `IsLastDayWeek` | `main.bi_output.bi_output_vg_date` | `IsLastDayWeek` | `join_enriched` | (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`) | dd.IsLastDayWeek |
| 44 | `IsLastDayMonth` | `main.bi_output.bi_output_vg_date` | `IsLastDayMonth` | `join_enriched` | (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`) | dd.IsLastDayMonth |
| 45 | `IsLastDayQuarter` | `main.bi_output.bi_output_vg_date` | `IsLastDayQuarter` | `join_enriched` | (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`) | dd.IsLastDayQuarter |
| 46 | `IsLastDayYear` | `main.bi_output.bi_output_vg_date` | `IsLastDayYear` | `join_enriched` | (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`) | dd.IsLastDayYear |
| 47 | `CitizenshipCountryID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `CitizenshipCountryID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dcu.CitizenshipCountryID |
| 48 | `CitizenshipCountry` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `Name` | `join_enriched` | (Tier 1 - Dictionary.Country upstream wiki) | dcz.Name AS CitizenshipCountry |
| 49 | `AffiliateID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `AffiliateID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dcu.AffiliateID |
| 50 | `ClusterDetail` | `—` | `ClusterDetail` | `join_enriched` | — | cdl.ClusterDetail |
| 51 | `ClusterSF` | `—` | `ClusterSF` | `join_enriched` | — | cdl.ClusterSF |
| 52 | `IsLastCluster` | `—` | `IsLastCluster` | `join_enriched` | — | cdl.IsLastCluster |
| 53 | `IsFirstCluster` | `—` | `IsFirstCluster` | `join_enriched` | — | cdl.IsFirstCluster |
| 54 | `IsSFCluster` | `—` | `IsSFCluster` | `join_enriched` | — | cdl.IsSFCluster |
| 55 | `UpdateDateIDSF` | `—` | `UpdateDateIDSF` | `join_enriched` | — | cdl.UpdateDateIDSF |
| 56 | `ClusterDynamic` | `—` | `ClusterDynamic` | `join_enriched` | — | cdl.ClusterDynamic |
| 57 | `ActiveTraded` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | `ActiveTraded` | `passthrough` | (Tier 2 — Function_Population_Active_Traders) | ddrc.ActiveTraded |
| 58 | `BalanceOnlyAccount` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | `BalanceOnlyAccount` | `passthrough` | (Tier 2 — Function_Population_Balance_Only_Accounts) | ddrc.BalanceOnlyAccount |
| 59 | `Portfolio_Only` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | `Portfolio_Only` | `passthrough` | (Tier 2 — Function_Population_Portfolio_Only) | ddrc.Portfolio_Only |
| 60 | `AccountActive` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | `AccountActive` | `passthrough` | (Tier 2 — SP_DDR_Customer_Daily_Status) | ddrc.AccountActive |
| 61 | `AccountInActive` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | `AccountInActive` | `passthrough` | (Tier 2 — SP_DDR_Customer_Daily_Status) | ddrc.AccountInActive |
| 62 | `IsFunded` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | `IsFunded` | `passthrough` | (Tier 2 — Function_Population_Funded) | ddrc.IsFunded |
| 63 | `ActiveTraded_ThisWeek` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `ActiveTraded_ThisWeek` | `join_enriched` | (Tier 1 — Function_Population_Active_Traders) | ddps.ActiveTraded_ThisWeek |
| 64 | `ActiveTraded_ThisMonth` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `ActiveTraded_ThisMonth` | `join_enriched` | (Tier 1 — Function_Population_Active_Traders) | ddps.ActiveTraded_ThisMonth |
| 65 | `ActiveTraded_ThisQuarter` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `ActiveTraded_ThisQuarter` | `join_enriched` | (Tier 1 — Function_Population_Active_Traders) | ddps.ActiveTraded_ThisQuarter |
| 66 | `ActiveTraded_ThisYear` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `ActiveTraded_ThisYear` | `join_enriched` | (Tier 1 — Function_Population_Active_Traders) | ddps.ActiveTraded_ThisYear |
| 67 | `BalanceOnlyAccount_ThisWeek` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `BalanceOnlyAccount_ThisWeek` | `join_enriched` | (Tier 1 — Function_Population_Balance_Only_Accounts) | ddps.BalanceOnlyAccount_ThisWeek |
| 68 | `BalanceOnlyAccount_ThisMonth` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `BalanceOnlyAccount_ThisMonth` | `join_enriched` | (Tier 1 — Function_Population_Balance_Only_Accounts) | ddps.BalanceOnlyAccount_ThisMonth |
| 69 | `BalanceOnlyAccount_ThisQuarter` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `BalanceOnlyAccount_ThisQuarter` | `join_enriched` | (Tier 1 — Function_Population_Balance_Only_Accounts) | ddps.BalanceOnlyAccount_ThisQuarter |
| 70 | `BalanceOnlyAccount_ThisYear` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `BalanceOnlyAccount_ThisYear` | `join_enriched` | (Tier 4 — BI_DB_dbo.SP_DDR_Customer_Periodic_Status [UNVERIFIED]) | ddps.BalanceOnlyAccount_ThisYear |
| 71 | `Portfolio_Only_ThisWeek` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `Portfolio_Only_ThisWeek` | `join_enriched` | (Tier 1 — Function_Population_Portfolio_Only) | ddps.Portfolio_Only_ThisWeek |
| 72 | `Portfolio_Only_ThisMonth` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `Portfolio_Only_ThisMonth` | `join_enriched` | (Tier 1 — Function_Population_Portfolio_Only) | ddps.Portfolio_Only_ThisMonth |
| 73 | `Portfolio_Only_ThisQuarter` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `Portfolio_Only_ThisQuarter` | `join_enriched` | (Tier 1 — Function_Population_Portfolio_Only) | ddps.Portfolio_Only_ThisQuarter |
| 74 | `Portfolio_Only_ThisYear` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `Portfolio_Only_ThisYear` | `join_enriched` | (Tier 4 — BI_DB_dbo.SP_DDR_Customer_Periodic_Status [UNVERIFIED]) | ddps.Portfolio_Only_ThisYear |
| 75 | `IsFunded_ThisWeek` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `IsFunded_ThisWeek` | `join_enriched` | (Tier 1 — Function_Population_Funded) | ddps.IsFunded_ThisWeek |
| 76 | `IsFunded_ThisMonth` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `IsFunded_ThisMonth` | `join_enriched` | (Tier 1 — Function_Population_Funded) | ddps.IsFunded_ThisMonth |
| 77 | `IsFunded_ThisQuarter` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `IsFunded_ThisQuarter` | `join_enriched` | (Tier 1 — Function_Population_Funded) | ddps.IsFunded_ThisQuarter |
| 78 | `IsFunded_ThisYear` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `IsFunded_ThisYear` | `join_enriched` | (Tier 1 — Function_Population_Funded) | ddps.IsFunded_ThisYear |
| 79 | `RegulationID_ThisWeek` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `RegulationID_ThisWeek` | `join_enriched` | (Tier 2 — DWH_dbo.SP_Fact_SnapshotCustomer) | ddps.RegulationID_ThisWeek |
| 80 | `RegulationID_ThisMonth` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `RegulationID_ThisMonth` | `join_enriched` | (Tier 2 — DWH_dbo.SP_Fact_SnapshotCustomer) | ddps.RegulationID_ThisMonth |
| 81 | `RegulationID_ThisQuarter` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `RegulationID_ThisQuarter` | `join_enriched` | (Tier 2 — DWH_dbo.SP_Fact_SnapshotCustomer) | ddps.RegulationID_ThisQuarter |
| 82 | `RegulationID_ThisYear` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `RegulationID_ThisYear` | `join_enriched` | (Tier 2 — DWH_dbo.SP_Fact_SnapshotCustomer) | ddps.RegulationID_ThisYear |
| 83 | `CountryID_ThisWeek` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `CountryID_ThisWeek` | `join_enriched` | (Tier 2 — DWH_dbo.SP_Fact_SnapshotCustomer) | ddps.CountryID_ThisWeek |
| 84 | `CountryID_ThisMonth` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `CountryID_ThisMonth` | `join_enriched` | (Tier 2 — DWH_dbo.SP_Fact_SnapshotCustomer) | ddps.CountryID_ThisMonth |
| 85 | `CountryID_ThisQuarter` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `CountryID_ThisQuarter` | `join_enriched` | (Tier 2 — DWH_dbo.SP_Fact_SnapshotCustomer) | ddps.CountryID_ThisQuarter |
| 86 | `CountryID_ThisYear` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `CountryID_ThisYear` | `join_enriched` | (Tier 2 — DWH_dbo.SP_Fact_SnapshotCustomer) | ddps.CountryID_ThisYear |
| 87 | `IsCreditReportValidCB_ThisWeek` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `IsCreditReportValidCB_ThisWeek` | `join_enriched` | (Tier 2 — DWH_dbo.SP_Fact_SnapshotCustomer) | ddps.IsCreditReportValidCB_ThisWeek |
| 88 | `IsCreditReportValidCB_ThisMonth` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `IsCreditReportValidCB_ThisMonth` | `join_enriched` | (Tier 2 — DWH_dbo.SP_Fact_SnapshotCustomer) | ddps.IsCreditReportValidCB_ThisMonth |
| 89 | `IsCreditReportValidCB_ThisQuarter` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `IsCreditReportValidCB_ThisQuarter` | `join_enriched` | (Tier 2 — DWH_dbo.SP_Fact_SnapshotCustomer) | ddps.IsCreditReportValidCB_ThisQuarter |
| 90 | `IsCreditReportValidCB_ThisYear` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `IsCreditReportValidCB_ThisYear` | `join_enriched` | (Tier 2 — DWH_dbo.SP_Fact_SnapshotCustomer) | ddps.IsCreditReportValidCB_ThisYear |
| 91 | `IsValidCustomer_ThisWeek` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `IsValidCustomer_ThisWeek` | `join_enriched` | (Tier 2 — DWH_dbo.SP_Fact_SnapshotCustomer) | ddps.IsValidCustomer_ThisWeek |
| 92 | `IsValidCustomer_ThisMonth` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `IsValidCustomer_ThisMonth` | `join_enriched` | (Tier 2 — DWH_dbo.SP_Fact_SnapshotCustomer) | ddps.IsValidCustomer_ThisMonth |
| 93 | `IsValidCustomer_ThisQuarter` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `IsValidCustomer_ThisQuarter` | `join_enriched` | (Tier 2 — DWH_dbo.SP_Fact_SnapshotCustomer) | ddps.IsValidCustomer_ThisQuarter |
| 94 | `IsValidCustomer_ThisYear` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `IsValidCustomer_ThisYear` | `join_enriched` | (Tier 2 — DWH_dbo.SP_Fact_SnapshotCustomer) | ddps.IsValidCustomer_ThisYear |
| 95 | `MarketingRegion_ThisWeek` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `MarketingRegion_ThisWeek` | `join_enriched` | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) | ddps.MarketingRegion_ThisWeek |
| 96 | `MarketingRegion_ThisMonth` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `MarketingRegion_ThisMonth` | `join_enriched` | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) | ddps.MarketingRegion_ThisMonth |
| 97 | `MarketingRegion_ThisQuarter` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `MarketingRegion_ThisQuarter` | `join_enriched` | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) | ddps.MarketingRegion_ThisQuarter |
| 98 | `MarketingRegion_ThisYear` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `MarketingRegion_ThisYear` | `join_enriched` | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) | ddps.MarketingRegion_ThisYear |
| 99 | `ClubTier_ThisWeek` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `PlayerLevelID_ThisWeek` | `join_enriched` | (Tier 2 — DWH_dbo.SP_Fact_SnapshotCustomer) | ddps.PlayerLevelID_ThisWeek AS ClubTier_ThisWeek |
| 100 | `ClubTier_ThisMonth` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `PlayerLevelID_ThisMonth` | `join_enriched` | (Tier 2 — DWH_dbo.SP_Fact_SnapshotCustomer) | ddps.PlayerLevelID_ThisMonth AS ClubTier_ThisMonth |
| 101 | `ClubTier_ThisQuarter` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `PlayerLevelID_ThisQuarter` | `join_enriched` | (Tier 2 — DWH_dbo.SP_Fact_SnapshotCustomer) | ddps.PlayerLevelID_ThisQuarter AS ClubTier_ThisQuarter |
| 102 | `ClubTier_ThisYear` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `PlayerLevelID_ThisYear` | `join_enriched` | (Tier 2 — DWH_dbo.SP_Fact_SnapshotCustomer) | ddps.PlayerLevelID_ThisYear AS ClubTier_ThisYear |

## Cross-check vs system.access.column_lineage

- Total target columns: **102**
- OK: **93**, WARN: **0**, ERROR: **9**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `AccountManager` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager.firstname`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager.lastname` | ERROR |
| `IsPI` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked.gurustatusid` | ERROR |
| `ClusterDetail` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster.clusterdetail` | ERROR |
| `ClusterSF` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster.clustersf` | ERROR |
| `IsLastCluster` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster.islastcluster` | ERROR |
| `IsFirstCluster` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster.isfirstcluster` | ERROR |
| `IsSFCluster` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster.issfcluster` | ERROR |
| `UpdateDateIDSF` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster.updatedateidsf` | ERROR |
| `ClusterDynamic` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster.clusterdynamic` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **92**

## Joins (detected)

- `INNER JOIN` — JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status AS ddps ON ddrc.RealCID = ddps.RealCID AND ddrc.DateID = ddps.DateID AND ddrc.etr_ymd = ddps.etr_ymd
- `INNER INNER` — INNER JOIN main.bi_output.bi_output_vg_date AS dd ON dd.DateID = ddrc.DateID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked AS fsc ON ddrc.DateID BETWEEN fsc.FromDateID AND fsc.ToDateID AND ddrc.RealCID = fsc.RealCID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS dcu ON ddrc.RealCID = dcu.RealCID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel AS dpl ON fsc.PlayerLevelID = dpl.PlayerLevelID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager AS dm ON fsc.AccountManagerID = dm.ManagerID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation AS dr ON fsc.RegulationID = dr.ID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country AS dc ON fsc.CountryID = dc.CountryID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language AS dl ON fsc.LanguageID = dl.LanguageID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel AS dv ON fsc.VerificationLevelID = dv.ID
