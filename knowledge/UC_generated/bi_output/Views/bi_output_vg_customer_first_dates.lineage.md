# Column Lineage: main.bi_output.bi_output_vg_customer_first_dates

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_customer_first_dates` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\bi_output_vg_customer_first_dates.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\bi_output_vg_customer_first_dates.json` (rows: 67, mismatches: 24) |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_AccountType.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_AccountStatus.md` |
| `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_ClubChangeLogProduct.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Customer_Daily_Status.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Language.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Date.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Date.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Language.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Manager.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_VerificationLevel.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Customer_Daily_Status.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_GuruStatus.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusReasons.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusSubReasons.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatus.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   ←── primary upstream
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
  + main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country   (JOIN)
  + main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date   (JOIN)
  + main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct   (JOIN)
  + main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status   (JOIN)
        │
        ▼
main.bi_output.bi_output_vg_customer_first_dates   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `RealCID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `RealCID` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | fsc.RealCID |
| 2 | `GCID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `GCID` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | fsc.GCID |
| 3 | `RegistrationDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `—` | `unknown` | — | TO_DATE(fsc.RegisteredReal) AS RegistrationDate |
| 4 | `VerificationLevel1Date` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `VerificationLevel1Date` | `join_enriched` | — | cdf.VerificationLevel1Date |
| 5 | `VerificationLevel2Date` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `VerificationLevel2Date` | `join_enriched` | — | cdf.VerificationLevel2Date |
| 6 | `VerificationLevel3Date` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `VerificationLevel3Date` | `join_enriched` | — | cdf.VerificationLevel3Date |
| 7 | `EmailVerifiedDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `EmailVerifiedDate` | `join_enriched` | — | cdf.EmailVerifiedDate |
| 8 | `VerificationLevelID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `VerificationLevelID` | `passthrough` | (Tier 1 — BackOffice.Customer) | fsc.VerificationLevelID |
| 9 | `Channel` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `Channel` | `join_enriched` | — | cdf.Channel |
| 10 | `SubChannel` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `SubChannel` | `join_enriched` | — | cdf.SubChannel |
| 11 | `Global_FTD_Date` | `—` | `Global_FTD_Date` | `join_enriched` | — | dsf.Global_FTD_Date |
| 12 | `Global_FTDA` | `—` | `Global_FTDA` | `join_enriched` | — | dsf.Global_FTDA |
| 13 | `IBAN_FTD_Date` | `—` | `IBAN_FTD_Date` | `join_enriched` | — | dsf.IBAN_FTD_Date |
| 14 | `IBAN_FTDA` | `—` | `IBAN_FTDA` | `join_enriched` | — | dsf.IBAN_FTDA |
| 15 | `TP_FTD_Date` | `—` | `TP_FTD_Date` | `join_enriched` | — | dsf.TP_FTD_Date |
| 16 | `TP_FTDA` | `—` | `TP_FTDA` | `join_enriched` | — | dsf.TP_FTDA |
| 17 | `Options_FTD_Date` | `—` | `Options_FTD_Date` | `join_enriched` | — | dsf.Options_FTD_Date |
| 18 | `Options_FTDA` | `—` | `Options_FTDA` | `join_enriched` | — | dsf.Options_FTDA |
| 19 | `FirstActionType` | `—` | `FirstActionType` | `join_enriched` | — | dsf.FirstActionType |
| 20 | `FirstActionDate` | `—` | `FirstActionDate` | `join_enriched` | — | dsf.FirstActionDate |
| 21 | `FirstIOBTime` | `—` | `FirstIOBTime` | `join_enriched` | — | dsf.FirstIOBTime |
| 22 | `FirstTimeFunded` | `—` | `FirstTimeFunded` | `join_enriched` | — | dsf.FirstTimeFunded |
| 23 | `FirstFundedDate` | `—` | `FirstFundedDate` | `join_enriched` | — | dsf.FirstFundedDate |
| 24 | `IsFunded` | `—` | `IsFunded` | `join_enriched` | — | dsf.IsFunded |
| 25 | `FirstClub` | `—` | `currentclub` | `join_enriched` | — | fc.currentclub AS FirstClub |
| 26 | `FirstTimeClubDate` | `—` | `date` | `join_enriched` | — | fc.date AS FirstTimeClubDate |
| 27 | `PlayerLevelID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `PlayerLevelID` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | fsc.PlayerLevelID |
| 28 | `ClubTier` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerLevel) | dpl.Name AS ClubTier |
| 29 | `RegulationID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `RegulationID` | `passthrough` | (Tier 1 — BackOffice.Customer) | fsc.RegulationID |
| 30 | `Regulation` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.Regulation) | dr.Name AS Regulation |
| 31 | `VerificationLevel` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel` | `Name` | `join_enriched` | (Tier 1 — upstream wiki, Dictionary.VerificationLevel) | dv.Name AS VerificationLevel |
| 32 | `CountryID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `CountryID` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | fsc.CountryID |
| 33 | `Country` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `Name` | `join_enriched` | (Tier 1 - Dictionary.Country upstream wiki) | dc.Name AS Country |
| 34 | `Region` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `MarketingRegionManualName` | `join_enriched` | (Tier 3 - Ext_Dim_Country live data) | dc.MarketingRegionManualName AS Region |
| 35 | `AccountManagerID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `AccountManagerID` | `passthrough` | (Tier 1 — BackOffice.Customer) | fsc.AccountManagerID |
| 36 | `AccountManager` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` | `—` | `string_op` | — | CONCAT_WS(dm.FirstName, '', dm.LastName) AS AccountManager |
| 37 | `LanguageID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `LanguageID` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | fsc.LanguageID |
| 38 | `Language` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | `Name` | `join_enriched` | (Tier 1 — Dictionary.Language) | dl.Name AS Language |
| 39 | `CommunicationLanguageID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `CommunicationLanguageID` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | fsc.CommunicationLanguageID |
| 40 | `CommunicationLanguage` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | `Name` | `join_enriched` | (Tier 1 — Dictionary.Language) | dcl.Name AS CommunicationLanguage |
| 41 | `AccountTypeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `AccountTypeID` | `passthrough` | (Tier 1 — BackOffice.Customer) | fsc.AccountTypeID |
| 42 | `AccountType` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.AccountType) | act.Name AS AccountType |
| 43 | `GuruStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `GuruStatusID` | `passthrough` | (Tier 1 — BackOffice.Customer) | fsc.GuruStatusID |
| 44 | `GuruStatusName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` | `GuruStatusName` | `join_enriched` | (Tier 1 — Dictionary.GuruStatus) | gs.GuruStatusName |
| 45 | `IsPI` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `—` | `case` | — | CASE WHEN fsc.GuruStatusID > 1 THEN 1 ELSE 0 END AS IsPI |
| 46 | `AccountStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `AccountStatusID` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | fsc.AccountStatusID |
| 47 | `AccountStatusName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` | `AccountStatusName` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.AccountStatus) | ast.AccountStatusName |
| 48 | `PlayerStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `PlayerStatusID` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | fsc.PlayerStatusID |
| 49 | `PlayerStatusName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.Name AS PlayerStatusName |
| 50 | `CanOpenPosition` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanOpenPosition` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanOpenPosition |
| 51 | `CanClosePosition` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanClosePosition` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanClosePosition |
| 52 | `CanEditPosition` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanEditPosition` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanEditPosition |
| 53 | `CanBeCopied` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanBeCopied` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanBeCopied |
| 54 | `CanDeposit` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanDeposit` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanDeposit |
| 55 | `CanRequestWithdraw` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanRequestWithdraw` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanRequestWithdraw |
| 56 | `PlayerStatusReasonID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `PlayerStatusReasonID` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | fsc.PlayerStatusReasonID |
| 57 | `PlayerStatusReasonName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatusReasons) | psr.Name AS PlayerStatusReasonName |
| 58 | `PlayerStatusSubReasonID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `PlayerStatusSubReasonID` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | fsc.PlayerStatusSubReasonID |
| 59 | `PlayerStatusSubReasonName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` | `PlayerStatusSubReasonName` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatusSubReasons) | pssr.PlayerStatusSubReasonName |
| 60 | `ActiveTraded` | `—` | `ActiveTraded` | `join_enriched` | — | dsf.ActiveTraded |
| 61 | `BalanceOnlyAccount` | `—` | `BalanceOnlyAccount` | `join_enriched` | — | dsf.BalanceOnlyAccount |
| 62 | `Portfolio_Only` | `—` | `Portfolio_Only` | `join_enriched` | — | dsf.Portfolio_Only |
| 63 | `AccountActive` | `—` | `AccountActive` | `join_enriched` | — | dsf.AccountActive |
| 64 | `AccountInActive` | `—` | `AccountInActive` | `join_enriched` | — | dsf.AccountInActive |
| 65 | `CitizenshipCountryID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `CitizenshipCountryID` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | fsc.CitizenshipCountryID |
| 66 | `CitizenshipCountry` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `Name` | `join_enriched` | (Tier 1 - Dictionary.Country upstream wiki) | dcz.Name AS CitizenshipCountry |
| 67 | `AffiliateID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `AffiliateID` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | fsc.AffiliateID |

## Cross-check vs system.access.column_lineage

- Total target columns: **67**
- OK: **43**, WARN: **0**, ERROR: **24**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `RegistrationDate` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.registeredreal` | ERROR |
| `Global_FTD_Date` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status.global_ftd_date` | ERROR |
| `Global_FTDA` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status.global_ftda` | ERROR |
| `IBAN_FTD_Date` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status.iban_ftd_date` | ERROR |
| `IBAN_FTDA` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status.iban_ftda` | ERROR |
| `TP_FTD_Date` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status.tp_ftd_date` | ERROR |
| `TP_FTDA` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status.tp_ftda` | ERROR |
| `Options_FTD_Date` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status.options_ftd_date` | ERROR |
| `Options_FTDA` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status.options_ftda` | ERROR |
| `FirstActionType` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status.firstactiontype` | ERROR |
| `FirstActionDate` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date.fulldate` | ERROR |
| `FirstIOBTime` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status.firstiobtime` | ERROR |
| `FirstTimeFunded` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status.firsttimefunded` | ERROR |
| `FirstFundedDate` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date.fulldate` | ERROR |
| `IsFunded` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status.isfunded` | ERROR |
| `FirstClub` | — | `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct.currentclub` | ERROR |
| `FirstTimeClubDate` | — | `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct.date` | ERROR |
| `AccountManager` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager.firstname`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager.lastname` | ERROR |
| `IsPI` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.gurustatusid` | ERROR |
| `ActiveTraded` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status.activetraded` | ERROR |
| `BalanceOnlyAccount` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status.balanceonlyaccount` | ERROR |
| `Portfolio_Only` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status.portfolio_only` | ERROR |
| `AccountActive` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status.accountactive` | ERROR |
| `AccountInActive` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status.accountinactive` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **48**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **1**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel AS dpl ON fsc.PlayerLevelID = dpl.PlayerLevelID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager AS dm ON fsc.AccountManagerID = dm.ManagerID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation AS dr ON fsc.RegulationID = dr.ID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country AS dc ON fsc.CountryID = dc.CountryID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language AS dl ON fsc.LanguageID = dl.LanguageID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel AS dv ON fsc.VerificationLevelID = dv.ID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus AS gs ON fsc.GuruStatusID = gs.GuruStatusID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus AS ast ON fsc.AccountStatusID = ast.AccountStatusID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype AS act ON fsc.AccountTypeID = act.AccountTypeID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus AS pst ON fsc.PlayerStatusID = pst.PlayerStatusID
