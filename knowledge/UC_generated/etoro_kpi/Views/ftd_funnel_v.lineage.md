# Column Lineage: main.etoro_kpi.ftd_funnel_v

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.ftd_funnel_v` |
| **Object Type** | `MATERIALIZED_VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\ftd_funnel_v.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\ftd_funnel_v.json` (rows: 59, mismatches: 20) |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.general.bronze_etoro_dictionary_country` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Country.md` |
| `main.bi_dealing.bi_output_dealing_cidage_data` | JOIN / referenced | ✗ `knowledge/UC_generated/bi_dealing/<Tables|Views>/bi_output_dealing_cidage_data.md` |
| `main.general.bronze_etoro_customer_customer_masked` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Views/Customer.Customer.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.general.bronze_etoro_dictionary_playerstatus` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PlayerStatus.md` |
| `main.etoro_kpi.customer_exclude_list` | JOIN / referenced | ✗ `knowledge/UC_generated/etoro_kpi/<Tables|Views>/customer_exclude_list.md` |
| `main.bi_db.bronze_moneybusdb_dictionary_accounttypes` | JOIN / referenced | ✓ `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.AccountTypes.md` |
| `main.etoro_kpi.ftd_click_v` | JOIN / referenced | ✗ `knowledge/UC_generated/etoro_kpi/<Tables|Views>/ftd_click_v.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Operations_Onboarding_Flow_UserKPIs.md` |
| `main.etoro_kpi.ftd_funnel_kyc` | JOIN / referenced | ✗ `knowledge/UC_generated/etoro_kpi/<Tables|Views>/ftd_funnel_kyc.md` |
| `main.general.bronze_etoro_dictionary_platform` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Platform.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   ←── primary upstream
  + main.general.bronze_etoro_customer_customer_masked   (JOIN)
  + main.general.bronze_etoro_dictionary_platform   (JOIN)
  + main.general.bronze_etoro_dictionary_country   (JOIN)
  + main.bi_dealing.bi_output_dealing_cidage_data   (JOIN)
  + main.general.bronze_etoro_dictionary_playerstatus   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation   (JOIN)
  + main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked   (JOIN)
  + main.etoro_kpi.ftd_funnel_kyc   (JOIN)
  + main.etoro_kpi.customer_exclude_list   (JOIN)
  + main.etoro_kpi.ftd_click_v   (JOIN)
  + main.bi_db.bronze_moneybusdb_dictionary_accounttypes   (JOIN)
  + main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis   (JOIN)
        │
        ▼
main.etoro_kpi.ftd_funnel_v   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `GCID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `GCID` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | dc.GCID |
| 2 | `CID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `RealCID` | `rename` | (Tier 1 — Customer.CustomerStatic) | dc.RealCID AS CID |
| 3 | `Regulation` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.Regulation) | reg_1.Name AS Regulation /* User Dimensions */ |
| 4 | `DesignatedRegulation` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.Regulation) | reg_2.Name AS DesignatedRegulation |
| 5 | `Club` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `Club` | `join_enriched` | — | cfd.Club |
| 6 | `Country` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `Country` | `join_enriched` | — | cfd.Country AS Country |
| 7 | `MarketingRegion` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `NewMarketingRegion` | `join_enriched` | — | cfd.NewMarketingRegion AS MarketingRegion |
| 8 | `CustomerAge` | `main.bi_dealing.bi_output_dealing_cidage_data` | `Age` | `join_enriched` | — | ca.Age AS CustomerAge |
| 9 | `IsPopularInvestor` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `—` | `case` | — | CASE WHEN dc.GuruStatusID IN (2, 3, 4, 5, 6) THEN TRUE ELSE FALSE END AS IsPopularInvestor |
| 10 | `PlayerStatus` | `main.general.bronze_etoro_dictionary_playerstatus` | `Name` | `join_enriched` | — | dps.Name AS PlayerStatus /* User Dimensions: Player Status */ |
| 11 | `Channel` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `Channel` | `join_enriched` | — | cfd.Channel /* User Acquisition Info */ |
| 12 | `SubChannel` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `SubChannel` | `join_enriched` | — | cfd.SubChannel |
| 13 | `BannerID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `BannerID` | `join_enriched` | — | cfd.BannerID |
| 14 | `SerialID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `SerialID` | `join_enriched` | — | cfd.SerialID |
| 15 | `Language` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `Language` | `join_enriched` | — | cfd.Language |
| 16 | `CurrentVerificationLevel` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `VerificationLevelID` | `rename` | (Tier 1 — BackOffice.Customer) | dc.VerificationLevelID AS CurrentVerificationLevel /* User Dates & FTD Amount */ |
| 17 | `Registration_Date` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `RegisteredReal` | `cast` | (Tier 1 — Customer.CustomerStatic) | cast to DATE — CAST(dc.RegisteredReal AS DATE) AS Registration_Date /* Registration */ |
| 18 | `Registration_Time` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `—` | `unknown` | — | DATE_FORMAT(dc.RegisteredReal, 'HH:mm:ss') AS Registration_Time |
| 19 | `VerificationLevel1_Date` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis / main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `—` | `unknown` | — | CAST(COALESCE(kpi.DateTime_VL1, cfd.VerificationLevel1Date) AS DATE) AS VerificationLevel1_Date /* Verification Level 1 */ |
| 20 | `VerificationLevel1_Time` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis / main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `—` | `unknown` | — | DATE_FORMAT(COALESCE(kpi.DateTime_VL1, cfd.VerificationLevel1Date), 'HH:mm:ss') AS VerificationLevel1_Time |
| 21 | `VerificationLevel2_Date` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis / main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `—` | `unknown` | — | CAST(COALESCE(kpi.DateTime_VL2, cfd.VerificationLevel2Date) AS DATE) AS VerificationLevel2_Date /* Verification Level 2 */ |
| 22 | `VerificationLevel2_Time` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis / main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `—` | `unknown` | — | DATE_FORMAT(COALESCE(kpi.DateTime_VL2, cfd.VerificationLevel2Date), 'HH:mm:ss') AS VerificationLevel2_Time |
| 23 | `VerificationLevel3_Date` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis / main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `—` | `unknown` | — | CAST(COALESCE(kpi.DateTime_VL3, cfd.VerificationLevel3Date) AS DATE) AS VerificationLevel3_Date /* Verification Level 3 */ |
| 24 | `VerificationLevel3_Time` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis / main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `—` | `unknown` | — | DATE_FORMAT(COALESCE(kpi.DateTime_VL3, cfd.VerificationLevel3Date), 'HH:mm:ss') AS VerificationLevel3_Time |
| 25 | `FirstTimeDeposit_Date` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `—` | `case` | — | CASE WHEN dc.FirstDepositDate = '1900-01-01T00:00:00.000+00:00' THEN NULL ELSE CAST(dc.FirstDepositDate AS DATE) END AS FirstTimeDeposit_Dat |
| 26 | `FirstTimeDeposit_Time` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `—` | `case` | — | CASE WHEN dc.FirstDepositDate = '1900-01-01T00:00:00.000+00:00' THEN NULL ELSE DATE_FORMAT(dc.FirstDepositDate, 'HH:mm:ss') END AS FirstTime |
| 27 | `FirstTimeDepositAmountUSD` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `FirstDepositAmount` | `rename` | (Tier 2 — SP_Dim_Customer) | dc.FirstDepositAmount AS FirstTimeDepositAmountUSD |
| 28 | `FundingType` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstDepositFundingType` | `join_enriched` | — | cfd.FirstDepositFundingType AS FundingType |
| 29 | `KYCFlow` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis` | `KYCFlow` | `join_enriched` | (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) | kpi.KYCFlow /* Onboarding Details */ |
| 30 | `UserScreening_Status` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis` | `US_ScreeningStatus` | `join_enriched` | (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) | kpi.US_ScreeningStatus AS UserScreening_Status /* User Screening */ |
| 31 | `UserScreening_StartTime` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis` | `US_StartTime` | `join_enriched` | (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) | kpi.US_StartTime AS UserScreening_StartTime |
| 32 | `UserScreening_EndTime` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis` | `US_EndTime` | `join_enriched` | (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) | kpi.US_EndTime AS UserScreening_EndTime |
| 33 | `ElectronicVerification_IsCountryEligible` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis` | `—` | `case` | — | CASE WHEN kpi.EV_IsCountryEligible = 1 THEN TRUE ELSE FALSE END AS ElectronicVerification_IsCountryEligible /* Electronic Verification */ |
| 34 | `ElectronicVerification_MatchStatusDateTime` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis` | `EV_MatchStatusDateTime` | `join_enriched` | (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) | kpi.EV_MatchStatusDateTime AS ElectronicVerification_MatchStatusDateTime |
| 35 | `ElectronicVerification_MatchStatus` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis` | `EV_MatchStatus` | `join_enriched` | (Tier 2 — SP_Dictionaries_DL_To_Synapse) | kpi.EV_MatchStatus AS ElectronicVerification_MatchStatus |
| 36 | `VD_HasDocuments` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis` | `—` | `case` | — | CASE WHEN kpi.VD_HasDocuments = 1 THEN 'Yes' WHEN kpi.VD_HasDocuments = 0 THEN 'No' ELSE 'No Indication' END AS VD_HasDocuments /* Proof of  |
| 37 | `ProofOfIdentity_IsApproved` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis` | `—` | `case` | — | CASE WHEN kpi.POI_IsApproved = 1 THEN 'Yes' WHEN kpi.POI_IsApproved = 0 THEN 'No' ELSE 'No Indication' END AS ProofOfIdentity_IsApproved |
| 38 | `ProofOfIdentity_UploadDateTime` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis` | `POI_UploadDateTime` | `join_enriched` | (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) | kpi.POI_UploadDateTime AS ProofOfIdentity_UploadDateTime |
| 39 | `ProofOfIdentity_ResponseDateTime` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis` | `POI_ResponseDateTime` | `join_enriched` | (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) | kpi.POI_ResponseDateTime AS ProofOfIdentity_ResponseDateTime |
| 40 | `ProofOfAddress_IsApproved` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis` | `—` | `case` | — | CASE WHEN kpi.POA_IsApproved = 1 THEN 'Yes' WHEN kpi.POA_IsApproved = 0 THEN 'No' ELSE 'No Indication' END AS ProofOfAddress_IsApproved /* P |
| 41 | `ProofOfAddress_UploadDateTime` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis` | `POA_UploadDateTime` | `join_enriched` | (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) | kpi.POA_UploadDateTime AS ProofOfAddress_UploadDateTime |
| 42 | `ProofOfAddress_ResponseDateTime` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis` | `POA_ResponseDateTime` | `join_enriched` | (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) | kpi.POA_ResponseDateTime AS ProofOfAddress_ResponseDateTime |
| 43 | `IsEmailVerified` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis` | `—` | `case` | — | CASE WHEN kpi.EmailVerification = 1 THEN 'Yes' WHEN kpi.EmailVerification = 0 THEN 'No' ELSE 'No Indication' END AS IsEmailVerified /* Email |
| 44 | `IsPhoneVerified` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `—` | `case` | — | CASE WHEN dc.IsPhoneVerified = TRUE THEN 'Yes' WHEN dc.IsPhoneVerified = FALSE THEN 'No' ELSE 'No Indication' END AS IsPhoneVerified /* Phon |
| 45 | `PhoneVerificationDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `PhoneVerificationDate` | `passthrough` | (Tier 2 — SP_Dim_Customer) | dc.PhoneVerificationDate |
| 46 | `IsExcludeUser` | `main.etoro_kpi.customer_exclude_list` | `—` | `case` | — | CASE WHEN NOT exl.GCID IS NULL THEN TRUE ELSE FALSE END AS IsExcludeUser |
| 47 | `ExcludeReason` | `main.etoro_kpi.customer_exclude_list` | `excludeReason` | `join_enriched` | — | exl.excludeReason AS ExcludeReason |
| 48 | `First_KYC_Answer_Input_DateTime` | `main.etoro_kpi.ftd_funnel_kyc` | `First_KYC_Answer` | `join_enriched` | — | kyc.First_KYC_Answer AS First_KYC_Answer_Input_DateTime /* KYC */ |
| 49 | `Last_KYC_Answer_Input_DateTime` | `main.etoro_kpi.ftd_funnel_kyc` | `Last_KYC_Answer` | `join_enriched` | — | kyc.Last_KYC_Answer AS Last_KYC_Answer_Input_DateTime |
| 50 | `Initial_DepositClick_Date` | `main.etoro_kpi.ftd_click_v` | `initial_deposit_clicks_combined` | `cast` | — | cast to DATE — CAST(ftdc.initial_deposit_clicks_combined AS DATE) AS Initial_DepositClick_Date /* Mixpanel Deposit Clicks */ |
| 51 | `Initial_DepositClick_Time` | `main.etoro_kpi.ftd_click_v` | `—` | `unknown` | — | DATE_FORMAT(ftdc.initial_deposit_clicks_combined, 'HH:mm:ss') AS Initial_DepositClick_Time |
| 52 | `Initial_DepositClick_Type` | `main.etoro_kpi.ftd_click_v` | `initial_deposit_click_type` | `join_enriched` | — | ftdc.initial_deposit_click_type AS Initial_DepositClick_Type |
| 53 | `Final_DepositClick_Date` | `main.etoro_kpi.ftd_click_v` | `final_deposit_click` | `cast` | — | cast to DATE — CAST(ftdc.final_deposit_click AS DATE) AS Final_DepositClick_Date |
| 54 | `Final_DepositClick_Time` | `main.etoro_kpi.ftd_click_v` | `—` | `unknown` | — | DATE_FORMAT(ftdc.final_deposit_click, 'HH:mm:ss') AS Final_DepositClick_Time |
| 55 | `RegistrationPlatform` | `main.general.bronze_etoro_dictionary_platform` | `Platform` | `join_enriched` | — | p.Platform AS RegistrationPlatform /* Reg Platform */ |
| 56 | `FirstPosOpenDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstPosOpenDate` | `cast` | — | cast to DATE — CAST(cfd.FirstPosOpenDate AS DATE) AS FirstPosOpenDate |
| 57 | `FirstPosOpenTime` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `—` | `unknown` | — | DATE_FORMAT(cfd.FirstPosOpenDate, 'HH:mm:ss') AS FirstPosOpenTime |
| 58 | `FTDPlatformID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `FTDPlatformID` | `passthrough` | (Tier 2 — SP_Dim_Customer) | dc.FTDPlatformID |
| 59 | `FTDPlatform` | `main.bi_db.bronze_moneybusdb_dictionary_accounttypes` | `Name` | `join_enriched` | — | ftd_plt.Name AS FTDPlatform |

## Cross-check vs system.access.column_lineage

- Total target columns: **59**
- OK: **39**, WARN: **0**, ERROR: **20**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `IsPopularInvestor` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.gurustatusid` | ERROR |
| `Registration_Time` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.registeredreal` | ERROR |
| `VerificationLevel1_Date` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked.verificationlevel1date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis.datetime_vl1` | ERROR |
| `VerificationLevel1_Time` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked.verificationlevel1date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis.datetime_vl1` | ERROR |
| `VerificationLevel2_Date` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked.verificationlevel2date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis.datetime_vl2` | ERROR |
| `VerificationLevel2_Time` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked.verificationlevel2date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis.datetime_vl2` | ERROR |
| `VerificationLevel3_Date` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked.verificationlevel3date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis.datetime_vl3` | ERROR |
| `VerificationLevel3_Time` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked.verificationlevel3date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis.datetime_vl3` | ERROR |
| `FirstTimeDeposit_Date` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.firstdepositdate` | ERROR |
| `FirstTimeDeposit_Time` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.firstdepositdate` | ERROR |
| `ElectronicVerification_IsCountryEligible` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis.ev_iscountryeligible` | ERROR |
| `VD_HasDocuments` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis.vd_hasdocuments` | ERROR |
| `ProofOfIdentity_IsApproved` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis.poi_isapproved` | ERROR |
| `ProofOfAddress_IsApproved` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis.poa_isapproved` | ERROR |
| `IsEmailVerified` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis.emailverification` | ERROR |
| `IsPhoneVerified` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.isphoneverified` | ERROR |
| `IsExcludeUser` | — | `main.etoro_kpi.customer_exclude_list.gcid` | ERROR |
| `Initial_DepositClick_Time` | — | `main.etoro_kpi.ftd_click_v.initial_deposit_clicks_combined` | ERROR |
| `Final_DepositClick_Time` | — | `main.etoro_kpi.ftd_click_v.final_deposit_click` | ERROR |
| `FirstPosOpenTime` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked.firstposopendate` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **39**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **10**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN main.general.bronze_etoro_customer_customer_masked AS cc ON (dc.RealCID = cc.CID)
- `LEFT JOIN` — LEFT JOIN main.general.bronze_etoro_dictionary_platform AS p ON (cc.PlatformID = p.Id)
- `INNER INNER` — INNER JOIN main.general.bronze_etoro_dictionary_country AS c ON (dc.CountryID = c.CountryID)
- `LEFT JOIN` — LEFT JOIN bi_dealing.bi_output_dealing_cidage_data AS ca ON (ca.RealCID = dc.RealCID)
- `LEFT JOIN` — LEFT JOIN main.general.bronze_etoro_dictionary_playerstatus AS dps ON dc.PlayerStatusID = dps.PlayerStatusID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation AS reg_1 ON dc.RegulationID = reg_1.DWHRegulationID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation AS reg_2 ON dc.DesignatedRegulationID = reg_2.DWHRegulationID
- `LEFT JOIN` — LEFT JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked AS cfd ON dc.RealCID = cfd.CID
- `LEFT JOIN` — LEFT JOIN (SELECT * FROM (SELECT kpi.*, ROW_NUMBER() OVER (PARTITION BY kpi.CID ORDER BY kpi.CID) AS rn FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis AS kpi) AS t WHERE rn = 1) AS kpi ON dc.RealCID 
- `LEFT JOIN` — LEFT JOIN main.etoro_kpi.ftd_funnel_kyc AS kyc ON dc.GCID = kyc.GCID
