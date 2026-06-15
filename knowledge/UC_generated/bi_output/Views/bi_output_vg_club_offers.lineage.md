# Column Lineage: main.bi_output.bi_output_vg_club_offers

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_club_offers` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\bi_output_vg_club_offers.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\bi_output_vg_club_offers.json` (rows: 64, mismatches: 3) |
| **Primary upstream** | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_AccountType.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_AccountStatus.md` |
| `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` | Primary (FROM) | ✗ `(no wiki found)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Language.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Language.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Manager.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_VerificationLevel.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_GuruStatus.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusReasons.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusSubReasons.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatus.md` |

## Lineage Chain

```
main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   (JOIN)
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
main.bi_output.bi_output_vg_club_offers   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `RealCID` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` | `RealCID` | `cast` | — | cast to STRING — CAST(clb.RealCID AS STRING) AS RealCID |
| 2 | `OfferID` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` | `OfferID` | `passthrough` | — | clb.OfferID |
| 3 | `OfferName` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` | `OfferName` | `passthrough` | — | clb.OfferName |
| 4 | `Inventorytype` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` | `Inventorytype` | `passthrough` | — | clb.Inventorytype |
| 5 | `DeliveryMethod` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` | `DeliveryMethod` | `passthrough` | — | clb.DeliveryMethod |
| 6 | `Type` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` | `Type` | `passthrough` | — | clb.Type |
| 7 | `SubType` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` | `SubType` | `passthrough` | — | clb.SubType |
| 8 | `Category` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` | `Category` | `passthrough` | — | clb.Category |
| 9 | `StartDate` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` | `StartDate` | `passthrough` | — | clb.StartDate |
| 10 | `IsEligble` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` | `IsEligble` | `passthrough` | — | clb.IsEligble |
| 11 | `HasOffer` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` | `HasOffer` | `passthrough` | — | clb.HasOffer |
| 12 | `CountryCriteria` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` | `CountryCriteria` | `passthrough` | — | clb.CountryCriteria |
| 13 | `RegulationCriteria` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` | `RegulationCriteria` | `passthrough` | — | clb.RegulationCriteria |
| 14 | `ClubCriteria` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` | `ClubCriteria` | `passthrough` | — | clb.ClubCriteria |
| 15 | `LanguageCriteria` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` | `LanguageCriteria` | `passthrough` | — | clb.LanguageCriteria |
| 16 | `ExcludeCountryCriteria` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` | `ExcludeCountryCriteria` | `passthrough` | — | clb.ExcludeCountryCriteria |
| 17 | `ActivationDate` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` | `ActivationDate` | `passthrough` | — | clb.ActivationDate |
| 18 | `CancellationDate` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` | `CancellationDate` | `passthrough` | — | clb.CancellationDate |
| 19 | `CancellationReason` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` | `CancellationReason` | `passthrough` | — | clb.CancellationReason |
| 20 | `ToBeCancelled` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` | `ToBeCancelled` | `passthrough` | — | clb.ToBeCancelled |
| 21 | `SendCouponDate` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` | `SendCouponDate` | `passthrough` | — | clb.SendCouponDate |
| 22 | `AssetStatus` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` | `AssetStatus` | `passthrough` | — | clb.AssetStatus |
| 23 | `ClaimedDate` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` | `ClaimedDate` | `passthrough` | — | clb.ClaimedDate |
| 24 | `IsEligbleOnRequest` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` | `IsEligbleOnRequest` | `passthrough` | — | clb.IsEligbleOnRequest |
| 25 | `RequestedBy` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` | `RequestedBy` | `passthrough` | — | clb.RequestedBy |
| 26 | `Active` | `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` | `Active` | `passthrough` | — | clb.Active |
| 27 | `PlayerLevelID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `PlayerLevelID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dc1.PlayerLevelID |
| 28 | `ClubTier` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerLevel) | dpl.Name AS ClubTier |
| 29 | `RegulationID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `RegulationID` | `join_enriched` | (Tier 1 — BackOffice.Customer) | dc1.RegulationID |
| 30 | `Regulation` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.Regulation) | dr.Name AS Regulation |
| 31 | `VerificationLevelID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `VerificationLevelID` | `join_enriched` | (Tier 1 — BackOffice.Customer) | dc1.VerificationLevelID |
| 32 | `VerificationLevel` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel` | `Name` | `join_enriched` | (Tier 1 — upstream wiki, Dictionary.VerificationLevel) | dv.Name AS VerificationLevel |
| 33 | `CountryID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `CountryID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dc1.CountryID |
| 34 | `Country` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `Name` | `join_enriched` | (Tier 1 - Dictionary.Country upstream wiki) | dc.Name AS Country |
| 35 | `Region` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `MarketingRegionManualName` | `join_enriched` | (Tier 3 - Ext_Dim_Country live data) | dc.MarketingRegionManualName AS Region |
| 36 | `AccountManagerID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `AccountManagerID` | `join_enriched` | (Tier 1 — BackOffice.Customer) | dc1.AccountManagerID |
| 37 | `AccountManager` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` | `—` | `string_op` | — | CONCAT_WS(dm.FirstName, '', dm.LastName) AS AccountManager |
| 38 | `LanguageID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `LanguageID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dc1.LanguageID |
| 39 | `Language` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | `Name` | `join_enriched` | (Tier 1 — Dictionary.Language) | dl.Name AS Language |
| 40 | `CommunicationLanguageID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `CommunicationLanguageID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dc1.CommunicationLanguageID |
| 41 | `CommunicationLanguage` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | `Name` | `join_enriched` | (Tier 1 — Dictionary.Language) | dcl.Name AS CommunicationLanguage |
| 42 | `AccountTypeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `AccountTypeID` | `join_enriched` | (Tier 1 — BackOffice.Customer) | dc1.AccountTypeID |
| 43 | `AccountType` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.AccountType) | act.Name AS AccountType |
| 44 | `GuruStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `GuruStatusID` | `join_enriched` | (Tier 1 — BackOffice.Customer) | dc1.GuruStatusID |
| 45 | `GuruStatusName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` | `GuruStatusName` | `join_enriched` | (Tier 1 — Dictionary.GuruStatus) | gs.GuruStatusName |
| 46 | `IsPI` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `—` | `case` | — | CASE WHEN dc1.GuruStatusID > 1 THEN 1 ELSE 0 END AS IsPI |
| 47 | `IsPro` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `—` | `case` | — | CASE WHEN dc1.MifidCategorizationID IN (2, 3) THEN 1 ELSE 0 END AS IsPro |
| 48 | `AccountStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `AccountStatusID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dc1.AccountStatusID |
| 49 | `AccountStatusName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` | `AccountStatusName` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.AccountStatus) | ast.AccountStatusName |
| 50 | `PlayerStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `PlayerStatusID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dc1.PlayerStatusID |
| 51 | `PlayerStatusName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.Name AS PlayerStatusName |
| 52 | `CanOpenPosition` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanOpenPosition` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanOpenPosition |
| 53 | `CanClosePosition` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanClosePosition` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanClosePosition |
| 54 | `CanEditPosition` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanEditPosition` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanEditPosition |
| 55 | `CanBeCopied` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanBeCopied` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanBeCopied |
| 56 | `CanDeposit` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanDeposit` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanDeposit |
| 57 | `CanRequestWithdraw` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanRequestWithdraw` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanRequestWithdraw |
| 58 | `PlayerStatusReasonID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `PlayerStatusReasonID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dc1.PlayerStatusReasonID |
| 59 | `PlayerStatusReasonName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatusReasons) | psr.Name AS PlayerStatusReasonName |
| 60 | `PlayerStatusSubReasonID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `PlayerStatusSubReasonID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dc1.PlayerStatusSubReasonID |
| 61 | `PlayerStatusSubReasonName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` | `PlayerStatusSubReasonName` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatusSubReasons) | pssr.PlayerStatusSubReasonName |
| 62 | `CitizenshipCountryID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `CitizenshipCountryID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dcu.CitizenshipCountryID |
| 63 | `CitizenshipCountry` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `Name` | `join_enriched` | (Tier 1 - Dictionary.Country upstream wiki) | dcz.Name AS CitizenshipCountry |
| 64 | `AffiliateID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `AffiliateID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dcu.AffiliateID |

## Cross-check vs system.access.column_lineage

- Total target columns: **64**
- OK: **61**, WARN: **0**, ERROR: **3**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `AccountManager` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager.firstname`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager.lastname` | ERROR |
| `IsPI` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.gurustatusid` | ERROR |
| `IsPro` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.mifidcategorizationid` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **37**

## Joins (detected)

- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS dc1 ON clb.RealCID = dc1.RealCID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS dcu ON dc1.RealCID = dcu.RealCID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel AS dpl ON dc1.PlayerLevelID = dpl.PlayerLevelID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager AS dm ON dc1.AccountManagerID = dm.ManagerID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation AS dr ON dc1.RegulationID = dr.ID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country AS dc ON dc1.CountryID = dc.CountryID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language AS dl ON dc1.LanguageID = dl.LanguageID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel AS dv ON dc1.VerificationLevelID = dv.ID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus AS gs ON dc1.GuruStatusID = gs.GuruStatusID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus AS ast ON dc1.AccountStatusID = ast.AccountStatusID
