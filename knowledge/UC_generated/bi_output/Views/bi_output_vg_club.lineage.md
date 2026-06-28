# Column Lineage: main.bi_output.bi_output_vg_club

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_club` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\bi_output_vg_club.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\bi_output_vg_club.json` (rows: 69, mismatches: 3) |
| **Primary upstream** | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity` |
| **Generated** | 2026-06-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_AccountType.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_AccountStatus.md` |
| `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity` | Primary (FROM) | ✗ `(no wiki found)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Language.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `main.bi_output.bi_output_vg_date` | JOIN / referenced | ✓ `knowledge\UC_generated\bi_output\Views\bi_output_vg_date.md` |
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
main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   (JOIN)
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
main.bi_output.bi_output_vg_club   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `Date` | `main.bi_output.bi_output_vg_date` | `Date` | `join_enriched` | (Tier 1 — DDL) | dd.Date |
| 2 | `DateID` | `main.bi_output.bi_output_vg_date` | `DateID` | `join_enriched` | (Tier 1 — DDL + SP_PopulateDimDate) | dd.DateID |
| 3 | `CalendarYearMonth` | `main.bi_output.bi_output_vg_date` | `CalendarYearMonth` | `join_enriched` | (Tier 2 — live sample) | dd.CalendarYearMonth |
| 4 | `CalendarQuarter` | `main.bi_output.bi_output_vg_date` | `CalendarQuarter` | `join_enriched` | (Tier 1 — DDL) | dd.CalendarQuarter |
| 5 | `CalendarYear` | `main.bi_output.bi_output_vg_date` | `CalendarYear` | `join_enriched` | (Tier 1 — DDL) | dd.CalendarYear |
| 6 | `RealCID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `RealCID` | `cast` | (Tier 1 — Customer.CustomerStatic) | cast to STRING — CAST(dc1.RealCID AS STRING) AS RealCID |
| 7 | `PLChangeType` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity` | `PLChangeType` | `passthrough` | — | clb.PLChangeType |
| 8 | `PLChangeTypeDate` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity` | `PLChangeTypeDate` | `passthrough` | — | clb.PLChangeTypeDate |
| 9 | `IsUpgrade` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity` | `IsUpgrade` | `passthrough` | — | clb.IsUpgrade |
| 10 | `IsDowngrade` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity` | `IsDowngrade` | `passthrough` | — | clb.IsDowngrade |
| 11 | `IsFTC` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity` | `IsFTC` | `passthrough` | — | clb.IsFTC |
| 12 | `CurrentTier` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity` | `CurrentTier` | `passthrough` | — | clb.CurrentTier |
| 13 | `LastTier` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity` | `LastTier` | `passthrough` | — | clb.LastTier |
| 14 | `MaxTier` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity` | `MaxTier` | `passthrough` | — | clb.MaxTier |
| 15 | `FTDDate` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity` | `FTDDate` | `passthrough` | — | clb.FTDDate |
| 16 | `FTCDate` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity` | `FTCDate` | `passthrough` | — | clb.FTCDate |
| 17 | `IsFTC_Status` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity` | `IsFTC_Status` | `passthrough` | — | clb.IsFTC_Status |
| 18 | `DaysTillFTC` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity` | `DaysTillFTC` | `passthrough` | — | clb.DaysTillFTC |
| 19 | `DaysFromFTD` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity` | `DaysFromFTD` | `passthrough` | — | clb.DaysFromFTD |
| 20 | `DaysInClub` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity` | `DaysInClub` | `passthrough` | — | clb.DaysInClub |
| 21 | `DaysInCurrentClub` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity` | `DaysInCurrentClub` | `passthrough` | — | clb.DaysInCurrentClub |
| 22 | `AmountForUpgrade` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity` | `AmountForUpgrade` | `passthrough` | — | clb.AmountForUpgrade |
| 23 | `IsOptInIOB` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity` | `IsOptInIOB` | `passthrough` | — | clb.IsOptInIOB |
| 24 | `IOB_Date` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity` | `IOB_Date` | `passthrough` | — | clb.IOB_Date |
| 25 | `UpdateDate` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity` | `UpdateDate` | `passthrough` | — | clb.UpdateDate |
| 26 | `GCID_Club` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity` | `GCID_Club` | `passthrough` | — | clb.GCID_Club |
| 27 | `TotalEquityClub` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity` | `TotalEquityClub` | `passthrough` | — | clb.TotalEquityClub |
| 28 | `WealthFrance` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity` | `WealthFrance` | `passthrough` | — | clb.WealthFrance |
| 29 | `MoneyBalance` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity` | `MoneyBalance` | `passthrough` | — | clb.MoneyBalance |
| 30 | `RealizedEquity` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity` | `RealizedEquity` | `passthrough` | — | clb.RealizedEquity |
| 31 | `MoneyFarmBalance` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity` | `MoneyFarmBalance` | `passthrough` | — | clb.MoneyFarmBalance |
| 32 | `PlayerLevelID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerLevelID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.PlayerLevelID |
| 33 | `ClubTier` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerLevel) | dpl.Name AS ClubTier |
| 34 | `RegulationID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `RegulationID` | `join_enriched` | (Tier 2 — via Fact_SnapshotCustomer) | fsc.RegulationID |
| 35 | `Regulation` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.Regulation) | dr.Name AS Regulation |
| 36 | `VerificationLevelID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `VerificationLevelID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.VerificationLevelID |
| 37 | `VerificationLevel` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel` | `Name` | `join_enriched` | (Tier 1 — upstream wiki, Dictionary.VerificationLevel) | dv.Name AS VerificationLevel |
| 38 | `CountryID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `CountryID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.CountryID |
| 39 | `Country` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `Name` | `join_enriched` | (Tier 1 - Dictionary.Country upstream wiki) | dc.Name AS Country |
| 40 | `Region` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `MarketingRegionManualName` | `join_enriched` | (Tier 3 - Ext_Dim_Country live data) | dc.MarketingRegionManualName AS Region |
| 41 | `AccountManagerID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `AccountManagerID` | `join_enriched` | (Tier 2 — via Fact_SnapshotCustomer) | fsc.AccountManagerID |
| 42 | `AccountManager` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` | `—` | `string_op` | — | CONCAT_WS(dm.FirstName, '', dm.LastName) AS AccountManager |
| 43 | `LanguageID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `LanguageID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.LanguageID |
| 44 | `Language` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | `Name` | `join_enriched` | (Tier 1 — Dictionary.Language) | dl.Name AS Language |
| 45 | `CommunicationLanguageID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `CommunicationLanguageID` | `join_enriched` | (Tier 2 — via Fact_SnapshotCustomer) | fsc.CommunicationLanguageID |
| 46 | `CommunicationLanguage` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | `Name` | `join_enriched` | (Tier 1 — Dictionary.Language) | dcl.Name AS CommunicationLanguage |
| 47 | `AccountTypeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `AccountTypeID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.AccountTypeID |
| 48 | `AccountType` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.AccountType) | act.Name AS AccountType |
| 49 | `GuruStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `GuruStatusID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.GuruStatusID |
| 50 | `GuruStatusName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` | `GuruStatusName` | `join_enriched` | (Tier 1 — Dictionary.GuruStatus) | gs.GuruStatusName |
| 51 | `IsPI` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `—` | `case` | — | CASE WHEN fsc.GuruStatusID > 1 THEN 1 ELSE 0 END AS IsPI |
| 52 | `IsPro` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `—` | `case` | — | CASE WHEN fsc.MifidCategorizationID IN (2, 3) THEN 1 ELSE 0 END AS IsPro |
| 53 | `AccountStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `AccountStatusID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.AccountStatusID |
| 54 | `AccountStatusName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` | `AccountStatusName` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.AccountStatus) | ast.AccountStatusName |
| 55 | `PlayerStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerStatusID` | `join_enriched` | (Tier 2 — inherited from Fact_SnapshotCustomer wiki) | fsc.PlayerStatusID |
| 56 | `PlayerStatusName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.Name AS PlayerStatusName |
| 57 | `CanOpenPosition` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanOpenPosition` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanOpenPosition |
| 58 | `CanClosePosition` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanClosePosition` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanClosePosition |
| 59 | `CanEditPosition` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanEditPosition` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanEditPosition |
| 60 | `CanBeCopied` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanBeCopied` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanBeCopied |
| 61 | `CanDeposit` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanDeposit` | `join_enriched` | — | pst.CanDeposit |
| 62 | `CanRequestWithdraw` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanRequestWithdraw` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanRequestWithdraw |
| 63 | `PlayerStatusReasonID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerStatusReasonID` | `join_enriched` | — | fsc.PlayerStatusReasonID |
| 64 | `PlayerStatusReasonName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatusReasons) | psr.Name AS PlayerStatusReasonName |
| 65 | `PlayerStatusSubReasonID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerStatusSubReasonID` | `join_enriched` | — | fsc.PlayerStatusSubReasonID |
| 66 | `PlayerStatusSubReasonName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` | `PlayerStatusSubReasonName` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatusSubReasons) | pssr.PlayerStatusSubReasonName |
| 67 | `CitizenshipCountryID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `CitizenshipCountryID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dcu.CitizenshipCountryID |
| 68 | `CitizenshipCountry` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `Name` | `join_enriched` | (Tier 1 - Dictionary.Country upstream wiki) | dcz.Name AS CitizenshipCountry |
| 69 | `AffiliateID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `AffiliateID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dcu.AffiliateID |

## Cross-check vs system.access.column_lineage

- Total target columns: **69**
- OK: **66**, WARN: **0**, ERROR: **3**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `AccountManager` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager.firstname`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager.lastname` | ERROR |
| `IsPI` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked.gurustatusid` | ERROR |
| `IsPro` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked.mifidcategorizationid` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **42**

## Joins (detected)

- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS dc1 ON clb.CID = dc1.RealCID
- `INNER INNER` — INNER JOIN main.bi_output.bi_output_vg_date AS dd ON CAST(DATE_FORMAT(clb.Date, 'yyyyMMdd') AS INT) = dd.DateID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked AS fsc ON fsc.RealCID = clb.CID AND fsc.FromDateID <= CAST(DATE_FORMAT(clb.Date, 'yyyyMMdd') AS INT) AND fsc.ToDateID >= CAST(DATE_FORMAT(clb.Date, 'yy
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS dcu ON fsc.RealCID = dcu.RealCID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel AS dpl ON fsc.PlayerLevelID = dpl.PlayerLevelID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager AS dm ON fsc.AccountManagerID = dm.ManagerID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation AS dr ON fsc.RegulationID = dr.ID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country AS dc ON fsc.CountryID = dc.CountryID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language AS dl ON fsc.LanguageID = dl.LanguageID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel AS dv ON fsc.VerificationLevelID = dv.ID
