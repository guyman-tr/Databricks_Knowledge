# Column Lineage: main.etoro_kpi.vg_customer_daily_snapshot

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.vg_customer_daily_snapshot` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\vg_customer_daily_snapshot.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\vg_customer_daily_snapshot.json` (rows: 62, mismatches: 3) |
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
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Customer_Daily_Status.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusReasons.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusSubReasons.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatus.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date   ←── primary upstream
  + main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked   (JOIN)
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
main.etoro_kpi.vg_customer_daily_snapshot   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `DateID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `DateKey` | `rename` | (Tier 1 — DDL + SP_PopulateDimDate) | dd.DateKey AS DateID |
| 2 | `Date` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `FullDate` | `rename` | (Tier 1 — DDL) | dd.FullDate AS Date |
| 3 | `MonthNumberOfYear` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `MonthNumberOfYear` | `passthrough` | (Tier 1 — DDL) | dd.MonthNumberOfYear |
| 4 | `ISOYearAndWeekNumber` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `ISOYearAndWeekNumber` | `passthrough` | (Tier 2 — live sample) | dd.ISOYearAndWeekNumber |
| 5 | `DayNumberOfWeek_Sun_Start` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `DayNumberOfWeek_Sun_Start` | `passthrough` | (Tier 1 — SP) | dd.DayNumberOfWeek_Sun_Start |
| 6 | `MonthName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `MonthName` | `passthrough` | (Tier 2 — live sample) | dd.MonthName |
| 7 | `MonthNameAbbreviation` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `MonthNameAbbreviation` | `passthrough` | (Tier 1 — DDL) | dd.MonthNameAbbreviation |
| 8 | `DayName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `DayName` | `passthrough` | (Tier 1 — DDL) | dd.DayName |
| 9 | `DayNameAbbreviation` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `DayNameAbbreviation` | `passthrough` | (Tier 1 — DDL) | dd.DayNameAbbreviation |
| 10 | `CalendarYear` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `CalendarYear` | `passthrough` | (Tier 1 — DDL) | dd.CalendarYear |
| 11 | `CalendarYearMonth` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `CalendarYearMonth` | `passthrough` | (Tier 2 — live sample) | dd.CalendarYearMonth |
| 12 | `CalendarYearQtr` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `CalendarYearQtr` | `passthrough` | (Tier 3 — name-inferred) | dd.CalendarYearQtr |
| 13 | `IsLastDayOfMonth` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `IsLastDayOfMonth` | `passthrough` | (Tier 2 — live sample) | dd.IsLastDayOfMonth |
| 14 | `IsWeekday` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `IsWeekday` | `passthrough` | (Tier 2 — live sample) | dd.IsWeekday |
| 15 | `IsWeekend` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `IsWeekend` | `passthrough` | (Tier 1 — DDL) | dd.IsWeekend |
| 16 | `RealCID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | `RealCID` | `join_enriched` | (Tier 2 — SP_DDR_Customer_Daily_Status) | dps.RealCID |
| 17 | `IsFunded` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | `IsFunded` | `join_enriched` | (Tier 2 — Function_Population_Funded) | dps.IsFunded |
| 18 | `ActiveTraded` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | `ActiveTraded` | `join_enriched` | (Tier 2 — Function_Population_Active_Traders) | dps.ActiveTraded |
| 19 | `Portfolio_Only` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | `Portfolio_Only` | `join_enriched` | (Tier 2 — Function_Population_Portfolio_Only) | dps.Portfolio_Only |
| 20 | `BalanceOnlyAccount` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | `BalanceOnlyAccount` | `join_enriched` | (Tier 2 — Function_Population_Balance_Only_Accounts) | dps.BalanceOnlyAccount |
| 21 | `GlobalDeposited` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | `GlobalDeposited` | `join_enriched` | (Tier 2 — SP_DDR_Customer_Daily_Status) | dps.GlobalDeposited |
| 22 | `GlobalRedeposited` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | `GlobalRedeposited` | `join_enriched` | (Tier 2 — SP_DDR_Customer_Daily_Status) | dps.GlobalRedeposited |
| 23 | `GlobalCashedOut` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | `GlobalCashedOut` | `join_enriched` | (Tier 2 — SP_DDR_Customer_Daily_Status) | dps.GlobalCashedOut |
| 24 | `Redeemed` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | `Redeemed` | `join_enriched` | (Tier 2 — SP_DDR_Customer_Daily_Status) | dps.Redeemed |
| 25 | `RegulationID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `RegulationID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.RegulationID |
| 26 | `PlayerLevelID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerLevelID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.PlayerLevelID |
| 27 | `CountryID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `CountryID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.CountryID |
| 28 | `MifidCategorizationID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `MifidCategorizationID` | `join_enriched` | — | fsc.MifidCategorizationID |
| 29 | `IsValidCustomer` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `IsValidCustomer` | `join_enriched` | — | fsc.IsValidCustomer |
| 30 | `IsCreditReportValidCB` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `IsCreditReportValidCB` | `join_enriched` | — | fsc.IsCreditReportValidCB |
| 31 | `Region` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `MarketingRegionManualName` | `join_enriched` | (Tier 3 - Ext_Dim_Country live data) | dc.MarketingRegionManualName AS Region |
| 32 | `Regulation` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.Regulation) | dr1.Name AS Regulation |
| 33 | `Country` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `Name` | `join_enriched` | (Tier 1 - Dictionary.Country upstream wiki) | dc.Name AS Country |
| 34 | `ClubTier` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerLevel) | dpl.Name AS ClubTier |
| 35 | `MifidCategory` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization` | `Name` | `join_enriched` | (Tier 1 — Dictionary.MifidCategorization) | dmc.Name AS MifidCategory |
| 36 | `MifidType` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization` | `—` | `case` | — | CASE WHEN dmc.MifidCategorizationID IN (2, 3) THEN 'Professional' ELSE 'Retail' END AS MifidType |
| 37 | `CitizenshipCountry` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `Name` | `join_enriched` | (Tier 1 - Dictionary.Country upstream wiki) | dc2.Name AS CitizenshipCountry |
| 38 | `GuruStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `GuruStatusID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.GuruStatusID |
| 39 | `GuruStatusName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` | `GuruStatusName` | `join_enriched` | (Tier 1 — Dictionary.GuruStatus) | dgs.GuruStatusName |
| 40 | `IsPI` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `—` | `case` | — | CASE WHEN fsc.GuruStatusID > 1 THEN 1 ELSE 0 END AS IsPI |
| 41 | `AccountStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `AccountStatusID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.AccountStatusID |
| 42 | `AccountStatusName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` | `AccountStatusName` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.AccountStatus) | ast.AccountStatusName |
| 43 | `PlayerStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerStatusID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.PlayerStatusID |
| 44 | `PlayerStatusName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.Name AS PlayerStatusName |
| 45 | `CanOpenPosition` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanOpenPosition` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanOpenPosition |
| 46 | `CanClosePosition` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanClosePosition` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanClosePosition |
| 47 | `CanEditPosition` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanEditPosition` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanEditPosition |
| 48 | `CanBeCopied` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanBeCopied` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanBeCopied |
| 49 | `CanDeposit` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanDeposit` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanDeposit |
| 50 | `CanRequestWithdraw` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanRequestWithdraw` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanRequestWithdraw |
| 51 | `PlayerStatusReasonID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerStatusReasonID` | `join_enriched` | — | fsc.PlayerStatusReasonID |
| 52 | `PlayerStatusReasonName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatusReasons) | psr.Name AS PlayerStatusReasonName |
| 53 | `PlayerStatusSubReasonID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerStatusSubReasonID` | `join_enriched` | — | fsc.PlayerStatusSubReasonID |
| 54 | `PlayerStatusSubReasonName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` | `PlayerStatusSubReasonName` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatusSubReasons) | pssr.PlayerStatusSubReasonName |
| 55 | `AccountManagerID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `AccountManagerID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.AccountManagerID |
| 56 | `AccountManager` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` | `—` | `string_op` | — | CONCAT(dm.FirstName, ' ', dm.LastName) AS AccountManager |
| 57 | `LanguageID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `LanguageID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.LanguageID |
| 58 | `Language` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | `Name` | `join_enriched` | (Tier 1 — Dictionary.Language) | dl.Name AS Language |
| 59 | `CommunicationLanguageID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `CommunicationLanguageID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.CommunicationLanguageID |
| 60 | `CommunicationLanguage` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | `Name` | `join_enriched` | (Tier 1 — Dictionary.Language) | dcl.Name AS CommunicationLanguage |
| 61 | `AccountTypeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `AccountTypeID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.AccountTypeID |
| 62 | `AccountType` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.AccountType) | act.Name AS AccountType |

## Cross-check vs system.access.column_lineage

- Total target columns: **62**
- OK: **59**, WARN: **0**, ERROR: **3**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `MifidType` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization.mifidcategorizationid` | ERROR |
| `IsPI` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked.gurustatusid` | ERROR |
| `AccountManager` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager.firstname`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager.lastname` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **46**

## Joins (detected)

- `INNER JOIN` — JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status AS dps ON dd.DateKey = dps.DateID
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked AS fsc ON dps.RealCID = fsc.RealCID AND dd.DateKey BETWEEN fsc.FromDateID AND fsc.ToDateID /* OPTIMIZED: Using fact table directly instead of dim_range join
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country AS dc ON fsc.CountryID = dc.CountryID
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel AS dpl ON fsc.PlayerLevelID = dpl.PlayerLevelID
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization AS dmc ON fsc.MifidCategorizationID = dmc.MifidCategorizationID
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation AS dr1 ON fsc.RegulationID = dr1.DWHRegulationID
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS dc1 ON fsc.RealCID = dc1.RealCID
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country AS dc2 ON dc1.CitizenshipCountryID = dc2.CountryID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus AS dgs ON fsc.GuruStatusID = dgs.GuruStatusID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus AS ast ON fsc.AccountStatusID = ast.AccountStatusID
