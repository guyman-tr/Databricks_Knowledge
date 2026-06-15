# Column Lineage: main.etoro_kpi.vg_customer_monthly_snapshot

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.vg_customer_monthly_snapshot` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\vg_customer_monthly_snapshot.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\vg_customer_monthly_snapshot.json` (rows: 63, mismatches: 4) |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_AccountType.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_AccountStatus.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Language.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Date.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_GuruStatus.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Language.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Manager.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_MifidCategorization.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Customer_Periodic_Status.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusReasons.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusSubReasons.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatus.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date   ←── primary upstream
  + main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager   (JOIN)
        │
        ▼
main.etoro_kpi.vg_customer_monthly_snapshot   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `DateID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `DateKey` | `rename` | (Tier 1 — DDL + SP_PopulateDimDate) | dd.DateKey AS DateID |
| 2 | `MonthStartDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `—` | `unknown` | — | TRUNC(dd.FullDate, 'MM') AS MonthStartDate |
| 3 | `MonthEndDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `FullDate` | `rename` | (Tier 1 — DDL) | dd.FullDate AS MonthEndDate |
| 4 | `MonthNumberOfYear` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `MonthNumberOfYear` | `passthrough` | (Tier 1 — DDL) | dd.MonthNumberOfYear |
| 5 | `ISOYearAndWeekNumber` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `ISOYearAndWeekNumber` | `passthrough` | (Tier 2 — live sample) | dd.ISOYearAndWeekNumber |
| 6 | `DayNumberOfWeek_Sun_Start` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `DayNumberOfWeek_Sun_Start` | `passthrough` | (Tier 1 — SP) | dd.DayNumberOfWeek_Sun_Start |
| 7 | `MonthName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `MonthName` | `passthrough` | (Tier 2 — live sample) | dd.MonthName |
| 8 | `MonthNameAbbreviation` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `MonthNameAbbreviation` | `passthrough` | (Tier 1 — DDL) | dd.MonthNameAbbreviation |
| 9 | `DayName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `DayName` | `passthrough` | (Tier 1 — DDL) | dd.DayName |
| 10 | `DayNameAbbreviation` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `DayNameAbbreviation` | `passthrough` | (Tier 1 — DDL) | dd.DayNameAbbreviation |
| 11 | `CalendarYear` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `CalendarYear` | `passthrough` | (Tier 1 — DDL) | dd.CalendarYear |
| 12 | `CalendarYearMonth` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `CalendarYearMonth` | `passthrough` | (Tier 2 — live sample) | dd.CalendarYearMonth |
| 13 | `CalendarYearQtr` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `CalendarYearQtr` | `passthrough` | (Tier 3 — name-inferred) | dd.CalendarYearQtr |
| 14 | `IsLastDayOfMonth` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `IsLastDayOfMonth` | `passthrough` | (Tier 2 — live sample) | dd.IsLastDayOfMonth |
| 15 | `IsWeekday` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `IsWeekday` | `passthrough` | (Tier 2 — live sample) | dd.IsWeekday |
| 16 | `IsWeekend` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `IsWeekend` | `passthrough` | (Tier 1 — DDL) | dd.IsWeekend |
| 17 | `RealCID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `RealCID` | `join_enriched` | (Tier 2 — BI_DB_dbo.SP_DDR_Customer_Periodic_Status) | dps.RealCID |
| 18 | `IsFunded_ThisMonth` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `IsFunded_ThisMonth` | `join_enriched` | (Tier 1 — Function_Population_Funded) | dps.IsFunded_ThisMonth |
| 19 | `ActiveTraded_ThisMonth` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `ActiveTraded_ThisMonth` | `join_enriched` | (Tier 1 — Function_Population_Active_Traders) | dps.ActiveTraded_ThisMonth |
| 20 | `Portfolio_Only_ThisMonth` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `Portfolio_Only_ThisMonth` | `join_enriched` | (Tier 1 — Function_Population_Portfolio_Only) | dps.Portfolio_Only_ThisMonth |
| 21 | `BalanceOnlyAccount_ThisMonth` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `BalanceOnlyAccount_ThisMonth` | `join_enriched` | (Tier 1 — Function_Population_Balance_Only_Accounts) | dps.BalanceOnlyAccount_ThisMonth |
| 22 | `GlobalDeposited_ThisMonth` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `GlobalDeposited_ThisMonth` | `join_enriched` | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) | dps.GlobalDeposited_ThisMonth |
| 23 | `GlobalRedeposited_ThisMonth` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `GlobalRedeposited_ThisMonth` | `join_enriched` | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) | dps.GlobalRedeposited_ThisMonth |
| 24 | `GlobalCashedOut_ThisMonth` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `GlobalCashedOut_ThisMonth` | `join_enriched` | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) | dps.GlobalCashedOut_ThisMonth |
| 25 | `Redeemed_ThisMonth` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | `Redeemed_ThisMonth` | `join_enriched` | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) | dps.Redeemed_ThisMonth |
| 26 | `RegulationID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `RegulationID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.RegulationID |
| 27 | `PlayerLevelID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerLevelID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.PlayerLevelID |
| 28 | `CountryID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `CountryID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.CountryID |
| 29 | `MifidCategorizationID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `MifidCategorizationID` | `join_enriched` | — | fsc.MifidCategorizationID |
| 30 | `IsValidCustomer` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `IsValidCustomer` | `join_enriched` | — | fsc.IsValidCustomer |
| 31 | `IsCreditReportValidCB` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `IsCreditReportValidCB` | `join_enriched` | — | fsc.IsCreditReportValidCB |
| 32 | `Region` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `MarketingRegionManualName` | `join_enriched` | (Tier 3 - Ext_Dim_Country live data) | dc.MarketingRegionManualName AS Region |
| 33 | `Regulation` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.Regulation) | dr1.Name AS Regulation |
| 34 | `Country` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `Name` | `join_enriched` | (Tier 1 - Dictionary.Country upstream wiki) | dc.Name AS Country |
| 35 | `ClubTier` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerLevel) | dpl.Name AS ClubTier |
| 36 | `MifidCategory` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization` | `Name` | `join_enriched` | (Tier 1 — Dictionary.MifidCategorization) | dmc.Name AS MifidCategory |
| 37 | `MifidType` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization` | `—` | `case` | — | CASE WHEN dmc.MifidCategorizationID IN (2, 3) THEN 'Professional' ELSE 'Retail' END AS MifidType |
| 38 | `CitizenshipCountry` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `Name` | `join_enriched` | (Tier 1 - Dictionary.Country upstream wiki) | dc2.Name AS CitizenshipCountry /*     cdl.ClusterDetail,     cdl.ClusterSF,     cdl.IsLastCluster,     cdl.IsFirstCluster,     cdl.IsSFClust |
| 39 | `GuruStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `GuruStatusID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.GuruStatusID |
| 40 | `GuruStatusName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` | `GuruStatusName` | `join_enriched` | (Tier 1 — Dictionary.GuruStatus) | dgs.GuruStatusName |
| 41 | `IsPI` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `—` | `case` | — | CASE WHEN fsc.GuruStatusID > 1 THEN 1 ELSE 0 END AS IsPI |
| 42 | `AccountStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `AccountStatusID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.AccountStatusID |
| 43 | `AccountStatusName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` | `AccountStatusName` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.AccountStatus) | ast.AccountStatusName |
| 44 | `PlayerStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerStatusID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.PlayerStatusID |
| 45 | `PlayerStatusName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.Name AS PlayerStatusName |
| 46 | `CanOpenPosition` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanOpenPosition` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanOpenPosition |
| 47 | `CanClosePosition` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanClosePosition` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanClosePosition |
| 48 | `CanEditPosition` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanEditPosition` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanEditPosition |
| 49 | `CanBeCopied` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanBeCopied` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanBeCopied |
| 50 | `CanDeposit` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanDeposit` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanDeposit |
| 51 | `CanRequestWithdraw` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanRequestWithdraw` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanRequestWithdraw |
| 52 | `PlayerStatusReasonID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerStatusReasonID` | `join_enriched` | — | fsc.PlayerStatusReasonID |
| 53 | `PlayerStatusReasonName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatusReasons) | psr.Name AS PlayerStatusReasonName |
| 54 | `PlayerStatusSubReasonID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerStatusSubReasonID` | `join_enriched` | — | fsc.PlayerStatusSubReasonID |
| 55 | `PlayerStatusSubReasonName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` | `PlayerStatusSubReasonName` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatusSubReasons) | pssr.PlayerStatusSubReasonName |
| 56 | `AccountManagerID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `AccountManagerID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.AccountManagerID |
| 57 | `AccountManager` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` | `—` | `string_op` | — | CONCAT(dm.FirstName, ' ', dm.LastName) AS AccountManager |
| 58 | `LanguageID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `LanguageID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.LanguageID |
| 59 | `Language` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | `Name` | `join_enriched` | (Tier 1 — Dictionary.Language) | dl.Name AS Language |
| 60 | `CommunicationLanguageID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `CommunicationLanguageID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.CommunicationLanguageID |
| 61 | `CommunicationLanguage` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | `Name` | `join_enriched` | (Tier 1 — Dictionary.Language) | dcl.Name AS CommunicationLanguage |
| 62 | `AccountTypeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `AccountTypeID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.AccountTypeID |
| 63 | `AccountType` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.AccountType) | act.Name AS AccountType |

## Cross-check vs system.access.column_lineage

- Total target columns: **63**
- OK: **59**, WARN: **0**, ERROR: **4**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `MonthStartDate` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date.fulldate` | ERROR |
| `MifidType` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization.mifidcategorizationid` | ERROR |
| `IsPI` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked.gurustatusid` | ERROR |
| `AccountManager` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager.firstname`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager.lastname` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **46**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **1**

## Joins (detected)

- `INNER JOIN` — JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status AS dps ON dd.DateKey = dps.DateID
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked AS fsc ON dps.RealCID = fsc.RealCID
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range AS dr ON fsc.DateRangeID = dr.DateRangeID AND dd.DateKey BETWEEN dr.FromDateID AND dr.ToDateID
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country AS dc ON fsc.CountryID = dc.CountryID
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel AS dpl ON fsc.PlayerLevelID = dpl.PlayerLevelID
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization AS dmc ON fsc.MifidCategorizationID = dmc.MifidCategorizationID
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation AS dr1 ON fsc.RegulationID = dr1.DWHRegulationID
- `INNER JOIN` — /*
LEFT JOIN (
    SELECT
      dd1.DateKey AS DateID,
      dcl.CID AS RealCID,
      dcl.ClusterDetail,
      dcl.ClusterSF,
      dcl.IsLastCluster,
      dcl.IsFirstCluster,
      dcl.IsSFCluster,
      dcl.UpdateDateIDSF,
      dcl.Clu
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country AS dc2 ON dc1.CitizenshipCountryID = dc2.CountryID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus AS dgs ON fsc.GuruStatusID = dgs.GuruStatusID
