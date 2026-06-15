# Column Lineage: main.de_output.vw_risk_classification_history_complete

| Property | Value |
|----------|-------|
| **UC Object** | `main.de_output.vw_risk_classification_history_complete` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\de_output\_discovery\source_code\vw_risk_classification_history_complete.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\de_output\_discovery\column_lineage\vw_risk_classification_history_complete.json` (rows: 96, mismatches: 93) |
| **Primary upstream** | `main.de_output.de_output_risk_classification_history` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.de_output.de_output_risk_classification_history` | Primary (FROM) | ✗ `knowledge/UC_generated/de_output/<Tables|Views>/de_output_risk_classification_history.md` |
| `main.de_output.de_output_risk_classification_history` | Primary (FROM) | ✗ `knowledge/UC_generated/de_output/<Tables|Views>/de_output_risk_classification_history.md` |
| `main.de_output.de_output_risk_classification` | JOIN / referenced | ✗ `knowledge/UC_generated/de_output/<Tables|Views>/de_output_risk_classification.md` |

## Lineage Chain

```
main.de_output.de_output_risk_classification_history   ←── primary upstream
  + main.de_output.de_output_risk_classification   (JOIN)
        │
        ▼
main.de_output.vw_risk_classification_history_complete   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `BeginTime` | `main.de_output.de_output_risk_classification_history` | `BeginTime` | `passthrough` | — | BeginTime |
| 2 | `EndTime` | `main.de_output.de_output_risk_classification_history` | `EndTime` | `passthrough` | — | EndTime |
| 3 | `GCID` | `main.de_output.de_output_risk_classification_history` | `GCID` | `passthrough` | — | GCID |
| 4 | `CID` | `main.de_output.de_output_risk_classification_history` | `CID` | `passthrough` | — | CID |
| 5 | `RegulationID` | `main.de_output.de_output_risk_classification_history` | `RegulationID` | `passthrough` | — | RegulationID |
| 6 | `Regulation` | `main.de_output.de_output_risk_classification_history` | `Regulation` | `passthrough` | — | Regulation |
| 7 | `CountryofResidence_Onboarding_RiskScore` | `main.de_output.de_output_risk_classification_history` | `CountryofResidence_Onboarding_RiskScore` | `passthrough` | — | CountryofResidence_Onboarding_RiskScore |
| 8 | `CountryofResidence_Onboarding_Value` | `main.de_output.de_output_risk_classification_history` | `CountryofResidence_Onboarding_Value` | `passthrough` | — | CountryofResidence_Onboarding_Value |
| 9 | `CountryofResidence_Existingclients_RiskScore` | `main.de_output.de_output_risk_classification_history` | `CountryofResidence_Existingclients_RiskScore` | `passthrough` | — | CountryofResidence_Existingclients_RiskScore |
| 10 | `CountryofResidence_Existingclients_Value` | `main.de_output.de_output_risk_classification_history` | `CountryofResidence_Existingclients_Value` | `passthrough` | — | CountryofResidence_Existingclients_Value |
| 11 | `Ageofcustomer_RiskScore` | `main.de_output.de_output_risk_classification_history` | `Ageofcustomer_RiskScore` | `passthrough` | — | Ageofcustomer_RiskScore |
| 12 | `Ageofcustomer_Value` | `main.de_output.de_output_risk_classification_history` | `Ageofcustomer_Value` | `passthrough` | — | Ageofcustomer_Value |
| 13 | `AgeAlert_RiskScore` | `main.de_output.de_output_risk_classification_history` | `AgeAlert_RiskScore` | `passthrough` | — | AgeAlert_RiskScore |
| 14 | `AgeAlert_Value` | `main.de_output.de_output_risk_classification_history` | `AgeAlert_Value` | `passthrough` | — | AgeAlert_Value |
| 15 | `ScreeningStatus_RiskScore` | `main.de_output.de_output_risk_classification_history` | `ScreeningStatus_RiskScore` | `passthrough` | — | ScreeningStatus_RiskScore |
| 16 | `ScreeningStatus_Value` | `main.de_output.de_output_risk_classification_history` | `ScreeningStatus_Value` | `passthrough` | — | ScreeningStatus_Value |
| 17 | `MainSourceofIncome_RiskScore` | `main.de_output.de_output_risk_classification_history` | `MainSourceofIncome_RiskScore` | `passthrough` | — | MainSourceofIncome_RiskScore |
| 18 | `MainSourceofIncome_Value` | `main.de_output.de_output_risk_classification_history` | `MainSourceofIncome_Value` | `passthrough` | — | MainSourceofIncome_Value |
| 19 | `Occupation_RiskScore` | `main.de_output.de_output_risk_classification_history` | `Occupation_RiskScore` | `passthrough` | — | Occupation_RiskScore |
| 20 | `Occupation_Value` | `main.de_output.de_output_risk_classification_history` | `Occupation_Value` | `passthrough` | — | Occupation_Value |
| 21 | `SpecialScore_RiskScore` | `main.de_output.de_output_risk_classification_history` | `SpecialScore_RiskScore` | `passthrough` | — | SpecialScore_RiskScore |
| 22 | `SpecialScore_Value` | `main.de_output.de_output_risk_classification_history` | `SpecialScore_Value` | `passthrough` | — | SpecialScore_Value |
| 23 | `AnnualIncome_RiskScore` | `main.de_output.de_output_risk_classification_history` | `AnnualIncome_RiskScore` | `passthrough` | — | AnnualIncome_RiskScore |
| 24 | `AnnualIncome_Value` | `main.de_output.de_output_risk_classification_history` | `AnnualIncome_Value` | `passthrough` | — | AnnualIncome_Value |
| 25 | `TotalCashAndLiquidAssets_RiskScore` | `main.de_output.de_output_risk_classification_history` | `TotalCashAndLiquidAssets_RiskScore` | `passthrough` | — | TotalCashAndLiquidAssets_RiskScore |
| 26 | `TotalCashAndLiquidAssets_Value` | `main.de_output.de_output_risk_classification_history` | `TotalCashAndLiquidAssets_Value` | `passthrough` | — | TotalCashAndLiquidAssets_Value |
| 27 | `MoneyplanToinvest_RiskScore` | `main.de_output.de_output_risk_classification_history` | `MoneyplanToinvest_RiskScore` | `passthrough` | — | MoneyplanToinvest_RiskScore |
| 28 | `MoneyplanToinvest_Value` | `main.de_output.de_output_risk_classification_history` | `MoneyplanToinvest_Value` | `passthrough` | — | MoneyplanToinvest_Value |
| 29 | `HighRisk_RiskScore` | `main.de_output.de_output_risk_classification_history` | `HighRisk_RiskScore` | `passthrough` | — | HighRisk_RiskScore |
| 30 | `HighRisk_Value` | `main.de_output.de_output_risk_classification_history` | `HighRisk_Value` | `passthrough` | — | HighRisk_Value |
| 31 | `SectorMLTF_RiskScore` | `main.de_output.de_output_risk_classification_history` | `SectorMLTF_RiskScore` | `passthrough` | — | SectorMLTF_RiskScore |
| 32 | `SectorMLTF_Value` | `main.de_output.de_output_risk_classification_history` | `SectorMLTF_Value` | `passthrough` | — | SectorMLTF_Value |
| 33 | `NetDeposit_RiskScore` | `main.de_output.de_output_risk_classification_history` | `NetDeposit_RiskScore` | `passthrough` | — | NetDeposit_RiskScore |
| 34 | `NetDeposit_Value` | `main.de_output.de_output_risk_classification_history` | `NetDeposit_Value` | `passthrough` | — | NetDeposit_Value |
| 35 | `FTD_RiskScore` | `main.de_output.de_output_risk_classification_history` | `FTD_RiskScore` | `passthrough` | — | FTD_RiskScore |
| 36 | `FTD_Value` | `main.de_output.de_output_risk_classification_history` | `FTD_Value` | `passthrough` | — | FTD_Value |
| 37 | `ScoreExpectedOriginFunds_RiskScore` | `main.de_output.de_output_risk_classification_history` | `ScoreExpectedOriginFunds_RiskScore` | `passthrough` | — | ScoreExpectedOriginFunds_RiskScore |
| 38 | `ScoreExpectedOriginFunds_Value` | `main.de_output.de_output_risk_classification_history` | `ScoreExpectedOriginFunds_Value` | `passthrough` | — | ScoreExpectedOriginFunds_Value |
| 39 | `ScoreExpectedDestinationPayments_RiskScore` | `main.de_output.de_output_risk_classification_history` | `ScoreExpectedDestinationPayments_RiskScore` | `passthrough` | — | ScoreExpectedDestinationPayments_RiskScore |
| 40 | `ScoreExpectedDestinationPayments_Value` | `main.de_output.de_output_risk_classification_history` | `ScoreExpectedDestinationPayments_Value` | `passthrough` | — | ScoreExpectedDestinationPayments_Value |
| 41 | `SectorHighRisk_RiskScore` | `main.de_output.de_output_risk_classification_history` | `SectorHighRisk_RiskScore` | `passthrough` | — | SectorHighRisk_RiskScore |
| 42 | `SectorHighRisk_Value` | `main.de_output.de_output_risk_classification_history` | `SectorHighRisk_Value` | `passthrough` | — | SectorHighRisk_Value |
| 43 | `Sector_ML_TF_RiskScore` | `main.de_output.de_output_risk_classification_history` | `Sector_ML_TF_RiskScore` | `passthrough` | — | Sector_ML_TF_RiskScore |
| 44 | `Sector_ML_TF_Value` | `main.de_output.de_output_risk_classification_history` | `Sector_ML_TF_Value` | `passthrough` | — | Sector_ML_TF_Value |
| 45 | `SectorHighCash_RiskScore` | `main.de_output.de_output_risk_classification_history` | `SectorHighCash_RiskScore` | `passthrough` | — | SectorHighCash_RiskScore |
| 46 | `SectorHighCash_Value` | `main.de_output.de_output_risk_classification_history` | `SectorHighCash_Value` | `passthrough` | — | SectorHighCash_Value |
| 47 | `EstablishmentApproved_RiskScore` | `main.de_output.de_output_risk_classification_history` | `EstablishmentApproved_RiskScore` | `passthrough` | — | EstablishmentApproved_RiskScore |
| 48 | `EstablishmentApproved_Value` | `main.de_output.de_output_risk_classification_history` | `EstablishmentApproved_Value` | `passthrough` | — | EstablishmentApproved_Value |
| 49 | `HighPublicProfile_RiskScore` | `main.de_output.de_output_risk_classification_history` | `HighPublicProfile_RiskScore` | `passthrough` | — | HighPublicProfile_RiskScore |
| 50 | `HighPublicProfile_Value` | `main.de_output.de_output_risk_classification_history` | `HighPublicProfile_Value` | `passthrough` | — | HighPublicProfile_Value |
| 51 | `DisclosureSubjected_RiskScore` | `main.de_output.de_output_risk_classification_history` | `DisclosureSubjected_RiskScore` | `passthrough` | — | DisclosureSubjected_RiskScore |
| 52 | `DisclosureSubjected_Value` | `main.de_output.de_output_risk_classification_history` | `DisclosureSubjected_Value` | `passthrough` | — | DisclosureSubjected_Value |
| 53 | `RegionSupervised_RiskScore` | `main.de_output.de_output_risk_classification_history` | `RegionSupervised_RiskScore` | `passthrough` | — | RegionSupervised_RiskScore |
| 54 | `RegionSupervised_Value` | `main.de_output.de_output_risk_classification_history` | `RegionSupervised_Value` | `passthrough` | — | RegionSupervised_Value |
| 55 | `JurisdictionNonCorrupt_RiskScore` | `main.de_output.de_output_risk_classification_history` | `JurisdictionNonCorrupt_RiskScore` | `passthrough` | — | JurisdictionNonCorrupt_RiskScore |
| 56 | `JurisdictionNonCorrupt_Value` | `main.de_output.de_output_risk_classification_history` | `JurisdictionNonCorrupt_Value` | `passthrough` | — | JurisdictionNonCorrupt_Value |
| 57 | `AML_CFT_Failure_RiskScore` | `main.de_output.de_output_risk_classification_history` | `AML_CFT_Failure_RiskScore` | `passthrough` | — | AML_CFT_Failure_RiskScore |
| 58 | `AML_CFT_Failure_Value` | `main.de_output.de_output_risk_classification_history` | `AML_CFT_Failure_Value` | `passthrough` | — | AML_CFT_Failure_Value |
| 59 | `BackgroundConsistent_RiskScore` | `main.de_output.de_output_risk_classification_history` | `BackgroundConsistent_RiskScore` | `passthrough` | — | BackgroundConsistent_RiskScore |
| 60 | `BackgroundConsistent_Value` | `main.de_output.de_output_risk_classification_history` | `BackgroundConsistent_Value` | `passthrough` | — | BackgroundConsistent_Value |
| 61 | `TransactionSuspicious_RiskScore` | `main.de_output.de_output_risk_classification_history` | `TransactionSuspicious_RiskScore` | `passthrough` | — | TransactionSuspicious_RiskScore |
| 62 | `TransactionSuspicious_Value` | `main.de_output.de_output_risk_classification_history` | `TransactionSuspicious_Value` | `passthrough` | — | TransactionSuspicious_Value |
| 63 | `IdentityEvidence_RiskScore` | `main.de_output.de_output_risk_classification_history` | `IdentityEvidence_RiskScore` | `passthrough` | — | IdentityEvidence_RiskScore |
| 64 | `IdentityEvidence_Value` | `main.de_output.de_output_risk_classification_history` | `IdentityEvidence_Value` | `passthrough` | — | IdentityEvidence_Value |
| 65 | `AvoidBusinessRelations_RiskScore` | `main.de_output.de_output_risk_classification_history` | `AvoidBusinessRelations_RiskScore` | `passthrough` | — | AvoidBusinessRelations_RiskScore |
| 66 | `AvoidBusinessRelations_Value` | `main.de_output.de_output_risk_classification_history` | `AvoidBusinessRelations_Value` | `passthrough` | — | AvoidBusinessRelations_Value |
| 67 | `OwnershipTransparent_RiskScore` | `main.de_output.de_output_risk_classification_history` | `OwnershipTransparent_RiskScore` | `passthrough` | — | OwnershipTransparent_RiskScore |
| 68 | `OwnershipTransparent_Value` | `main.de_output.de_output_risk_classification_history` | `OwnershipTransparent_Value` | `passthrough` | — | OwnershipTransparent_Value |
| 69 | `AssetHoldingVehicle_RiskScore` | `main.de_output.de_output_risk_classification_history` | `AssetHoldingVehicle_RiskScore` | `passthrough` | — | AssetHoldingVehicle_RiskScore |
| 70 | `AssetHoldingVehicle_Value` | `main.de_output.de_output_risk_classification_history` | `AssetHoldingVehicle_Value` | `passthrough` | — | AssetHoldingVehicle_Value |
| 71 | `TransactionsUnusual_RiskScore` | `main.de_output.de_output_risk_classification_history` | `TransactionsUnusual_RiskScore` | `passthrough` | — | TransactionsUnusual_RiskScore |
| 72 | `TransactionsUnusual_Value` | `main.de_output.de_output_risk_classification_history` | `TransactionsUnusual_Value` | `passthrough` | — | TransactionsUnusual_Value |
| 73 | `SecrecyUnreasonable_RiskScore` | `main.de_output.de_output_risk_classification_history` | `SecrecyUnreasonable_RiskScore` | `passthrough` | — | SecrecyUnreasonable_RiskScore |
| 74 | `SecrecyUnreasonable_Value` | `main.de_output.de_output_risk_classification_history` | `SecrecyUnreasonable_Value` | `passthrough` | — | SecrecyUnreasonable_Value |
| 75 | `NFTF_RiskScore` | `main.de_output.de_output_risk_classification_history` | `NFTF_RiskScore` | `passthrough` | — | NFTF_RiskScore |
| 76 | `NFTF_Value` | `main.de_output.de_output_risk_classification_history` | `NFTF_Value` | `passthrough` | — | NFTF_Value |
| 77 | `IdentityDoubts_RiskScore` | `main.de_output.de_output_risk_classification_history` | `IdentityDoubts_RiskScore` | `passthrough` | — | IdentityDoubts_RiskScore |
| 78 | `IdentityDoubts_Value` | `main.de_output.de_output_risk_classification_history` | `IdentityDoubts_Value` | `passthrough` | — | IdentityDoubts_Value |
| 79 | `ExpectedProductsUsed_RiskScore` | `main.de_output.de_output_risk_classification_history` | `ExpectedProductsUsed_RiskScore` | `passthrough` | — | ExpectedProductsUsed_RiskScore |
| 80 | `ExpectedProductsUsed_Value` | `main.de_output.de_output_risk_classification_history` | `ExpectedProductsUsed_Value` | `passthrough` | — | ExpectedProductsUsed_Value |
| 81 | `NonProfitOrgAbused_RiskScore` | `main.de_output.de_output_risk_classification_history` | `NonProfitOrgAbused_RiskScore` | `passthrough` | — | NonProfitOrgAbused_RiskScore |
| 82 | `NonProfitOrgAbused_Value` | `main.de_output.de_output_risk_classification_history` | `NonProfitOrgAbused_Value` | `passthrough` | — | NonProfitOrgAbused_Value |
| 83 | `CooperativeClient_RiskScore` | `main.de_output.de_output_risk_classification_history` | `CooperativeClient_RiskScore` | `passthrough` | — | CooperativeClient_RiskScore |
| 84 | `CooperativeClient_Value` | `main.de_output.de_output_risk_classification_history` | `CooperativeClient_Value` | `passthrough` | — | CooperativeClient_Value |
| 85 | `IdentityAnonymous_RiskScore` | `main.de_output.de_output_risk_classification_history` | `IdentityAnonymous_RiskScore` | `passthrough` | — | IdentityAnonymous_RiskScore |
| 86 | `IdentityAnonymous_Value` | `main.de_output.de_output_risk_classification_history` | `IdentityAnonymous_Value` | `passthrough` | — | IdentityAnonymous_Value |
| 87 | `TransactionComplexity_RiskScore` | `main.de_output.de_output_risk_classification_history` | `TransactionComplexity_RiskScore` | `passthrough` | — | TransactionComplexity_RiskScore |
| 88 | `TransactionComplexity_Value` | `main.de_output.de_output_risk_classification_history` | `TransactionComplexity_Value` | `passthrough` | — | TransactionComplexity_Value |
| 89 | `PaymentsThirdParty_RiskScore` | `main.de_output.de_output_risk_classification_history` | `PaymentsThirdParty_RiskScore` | `passthrough` | — | PaymentsThirdParty_RiskScore |
| 90 | `PaymentsThirdParty_Value` | `main.de_output.de_output_risk_classification_history` | `PaymentsThirdParty_Value` | `passthrough` | — | PaymentsThirdParty_Value |
| 91 | `Finalscore_RiskScore` | `main.de_output.de_output_risk_classification_history` | `Finalscore_RiskScore` | `passthrough` | — | Finalscore_RiskScore |
| 92 | `Finalscore_Value` | `main.de_output.de_output_risk_classification_history` | `Finalscore_Value` | `passthrough` | — | Finalscore_Value |
| 93 | `RiskScore_Explanation` | `main.de_output.de_output_risk_classification_history` | `RiskScore_Explanation` | `passthrough` | — | RiskScore_Explanation |
| 94 | `RiskScoreName` | `main.de_output.de_output_risk_classification_history` | `RiskScoreName` | `passthrough` | — | RiskScoreName |
| 95 | `SourceDate` | `main.de_output.de_output_risk_classification_history` | `SourceDate` | `passthrough` | — | SourceDate |
| 96 | `IsLastUpdate` | `main.de_output.de_output_risk_classification_history` | `IsLastUpdate` | `passthrough` | — | IsLastUpdate |

## Cross-check vs system.access.column_lineage

- Total target columns: **96**
- OK: **3**, WARN: **93**, ERROR: **0**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `BeginTime` | `main.de_output.de_output_risk_classification_history.begintime` | `main.de_output.de_output_risk_classification.update_datetime`, `main.de_output.de_output_risk_classification_history.begintime` | WARN |
| `GCID` | `main.de_output.de_output_risk_classification_history.gcid` | `main.de_output.de_output_risk_classification.gcid`, `main.de_output.de_output_risk_classification_history.gcid` | WARN |
| `CID` | `main.de_output.de_output_risk_classification_history.cid` | `main.de_output.de_output_risk_classification.cid`, `main.de_output.de_output_risk_classification_history.cid` | WARN |
| `RegulationID` | `main.de_output.de_output_risk_classification_history.regulationid` | `main.de_output.de_output_risk_classification.regulationid`, `main.de_output.de_output_risk_classification_history.regulationid` | WARN |
| `Regulation` | `main.de_output.de_output_risk_classification_history.regulation` | `main.de_output.de_output_risk_classification.regulation`, `main.de_output.de_output_risk_classification_history.regulation` | WARN |
| `CountryofResidence_Onboarding_RiskScore` | `main.de_output.de_output_risk_classification_history.countryofresidence_onboarding_riskscore` | `main.de_output.de_output_risk_classification.countryofresidence_onboarding_riskscore`, `main.de_output.de_output_risk_classification_history.countryofresidence_onboarding_riskscore` | WARN |
| `CountryofResidence_Onboarding_Value` | `main.de_output.de_output_risk_classification_history.countryofresidence_onboarding_value` | `main.de_output.de_output_risk_classification.countryofresidence_onboarding_value`, `main.de_output.de_output_risk_classification_history.countryofresidence_onboarding_value` | WARN |
| `CountryofResidence_Existingclients_RiskScore` | `main.de_output.de_output_risk_classification_history.countryofresidence_existingclients_riskscore` | `main.de_output.de_output_risk_classification.countryofresidence_existingclients_riskscore`, `main.de_output.de_output_risk_classification_history.countryofresidence_existingclients_riskscore` | WARN |
| `CountryofResidence_Existingclients_Value` | `main.de_output.de_output_risk_classification_history.countryofresidence_existingclients_value` | `main.de_output.de_output_risk_classification.countryofresidence_existingclients_value`, `main.de_output.de_output_risk_classification_history.countryofresidence_existingclients_value` | WARN |
| `Ageofcustomer_RiskScore` | `main.de_output.de_output_risk_classification_history.ageofcustomer_riskscore` | `main.de_output.de_output_risk_classification.ageofcustomer_riskscore`, `main.de_output.de_output_risk_classification_history.ageofcustomer_riskscore` | WARN |
| `Ageofcustomer_Value` | `main.de_output.de_output_risk_classification_history.ageofcustomer_value` | `main.de_output.de_output_risk_classification.ageofcustomer_value`, `main.de_output.de_output_risk_classification_history.ageofcustomer_value` | WARN |
| `AgeAlert_RiskScore` | `main.de_output.de_output_risk_classification_history.agealert_riskscore` | `main.de_output.de_output_risk_classification.agealert_riskscore`, `main.de_output.de_output_risk_classification_history.agealert_riskscore` | WARN |
| `AgeAlert_Value` | `main.de_output.de_output_risk_classification_history.agealert_value` | `main.de_output.de_output_risk_classification.agealert_value`, `main.de_output.de_output_risk_classification_history.agealert_value` | WARN |
| `ScreeningStatus_RiskScore` | `main.de_output.de_output_risk_classification_history.screeningstatus_riskscore` | `main.de_output.de_output_risk_classification.screeningstatus_riskscore`, `main.de_output.de_output_risk_classification_history.screeningstatus_riskscore` | WARN |
| `ScreeningStatus_Value` | `main.de_output.de_output_risk_classification_history.screeningstatus_value` | `main.de_output.de_output_risk_classification.screeningstatus_value`, `main.de_output.de_output_risk_classification_history.screeningstatus_value` | WARN |
| `MainSourceofIncome_RiskScore` | `main.de_output.de_output_risk_classification_history.mainsourceofincome_riskscore` | `main.de_output.de_output_risk_classification.mainsourceofincome_riskscore`, `main.de_output.de_output_risk_classification_history.mainsourceofincome_riskscore` | WARN |
| `MainSourceofIncome_Value` | `main.de_output.de_output_risk_classification_history.mainsourceofincome_value` | `main.de_output.de_output_risk_classification.mainsourceofincome_value`, `main.de_output.de_output_risk_classification_history.mainsourceofincome_value` | WARN |
| `Occupation_RiskScore` | `main.de_output.de_output_risk_classification_history.occupation_riskscore` | `main.de_output.de_output_risk_classification.occupation_riskscore`, `main.de_output.de_output_risk_classification_history.occupation_riskscore` | WARN |
| `Occupation_Value` | `main.de_output.de_output_risk_classification_history.occupation_value` | `main.de_output.de_output_risk_classification.occupation_value`, `main.de_output.de_output_risk_classification_history.occupation_value` | WARN |
| `SpecialScore_RiskScore` | `main.de_output.de_output_risk_classification_history.specialscore_riskscore` | `main.de_output.de_output_risk_classification.specialscore_riskscore`, `main.de_output.de_output_risk_classification_history.specialscore_riskscore` | WARN |
| `SpecialScore_Value` | `main.de_output.de_output_risk_classification_history.specialscore_value` | `main.de_output.de_output_risk_classification.specialscore_value`, `main.de_output.de_output_risk_classification_history.specialscore_value` | WARN |
| `AnnualIncome_RiskScore` | `main.de_output.de_output_risk_classification_history.annualincome_riskscore` | `main.de_output.de_output_risk_classification.annualincome_riskscore`, `main.de_output.de_output_risk_classification_history.annualincome_riskscore` | WARN |
| `AnnualIncome_Value` | `main.de_output.de_output_risk_classification_history.annualincome_value` | `main.de_output.de_output_risk_classification.annualincome_value`, `main.de_output.de_output_risk_classification_history.annualincome_value` | WARN |
| `TotalCashAndLiquidAssets_RiskScore` | `main.de_output.de_output_risk_classification_history.totalcashandliquidassets_riskscore` | `main.de_output.de_output_risk_classification.totalcashandliquidassets_riskscore`, `main.de_output.de_output_risk_classification_history.totalcashandliquidassets_riskscore` | WARN |
| `TotalCashAndLiquidAssets_Value` | `main.de_output.de_output_risk_classification_history.totalcashandliquidassets_value` | `main.de_output.de_output_risk_classification.totalcashandliquidassets_value`, `main.de_output.de_output_risk_classification_history.totalcashandliquidassets_value` | WARN |
| `MoneyplanToinvest_RiskScore` | `main.de_output.de_output_risk_classification_history.moneyplantoinvest_riskscore` | `main.de_output.de_output_risk_classification.moneyplantoinvest_riskscore`, `main.de_output.de_output_risk_classification_history.moneyplantoinvest_riskscore` | WARN |
| `MoneyplanToinvest_Value` | `main.de_output.de_output_risk_classification_history.moneyplantoinvest_value` | `main.de_output.de_output_risk_classification.moneyplantoinvest_value`, `main.de_output.de_output_risk_classification_history.moneyplantoinvest_value` | WARN |
| `HighRisk_RiskScore` | `main.de_output.de_output_risk_classification_history.highrisk_riskscore` | `main.de_output.de_output_risk_classification.highrisk_riskscore`, `main.de_output.de_output_risk_classification_history.highrisk_riskscore` | WARN |
| `HighRisk_Value` | `main.de_output.de_output_risk_classification_history.highrisk_value` | `main.de_output.de_output_risk_classification.highrisk_value`, `main.de_output.de_output_risk_classification_history.highrisk_value` | WARN |
| `SectorMLTF_RiskScore` | `main.de_output.de_output_risk_classification_history.sectormltf_riskscore` | `main.de_output.de_output_risk_classification.sectormltf_riskscore`, `main.de_output.de_output_risk_classification_history.sectormltf_riskscore` | WARN |
| `SectorMLTF_Value` | `main.de_output.de_output_risk_classification_history.sectormltf_value` | `main.de_output.de_output_risk_classification.sectormltf_value`, `main.de_output.de_output_risk_classification_history.sectormltf_value` | WARN |
| `NetDeposit_RiskScore` | `main.de_output.de_output_risk_classification_history.netdeposit_riskscore` | `main.de_output.de_output_risk_classification.netdeposit_riskscore`, `main.de_output.de_output_risk_classification_history.netdeposit_riskscore` | WARN |
| `NetDeposit_Value` | `main.de_output.de_output_risk_classification_history.netdeposit_value` | `main.de_output.de_output_risk_classification.netdeposit_value`, `main.de_output.de_output_risk_classification_history.netdeposit_value` | WARN |
| `FTD_RiskScore` | `main.de_output.de_output_risk_classification_history.ftd_riskscore` | `main.de_output.de_output_risk_classification.ftd_riskscore`, `main.de_output.de_output_risk_classification_history.ftd_riskscore` | WARN |
| `FTD_Value` | `main.de_output.de_output_risk_classification_history.ftd_value` | `main.de_output.de_output_risk_classification.ftd_value`, `main.de_output.de_output_risk_classification_history.ftd_value` | WARN |
| `ScoreExpectedOriginFunds_RiskScore` | `main.de_output.de_output_risk_classification_history.scoreexpectedoriginfunds_riskscore` | `main.de_output.de_output_risk_classification.scoreexpectedoriginfunds_riskscore`, `main.de_output.de_output_risk_classification_history.scoreexpectedoriginfunds_riskscore` | WARN |
| `ScoreExpectedOriginFunds_Value` | `main.de_output.de_output_risk_classification_history.scoreexpectedoriginfunds_value` | `main.de_output.de_output_risk_classification.scoreexpectedoriginfunds_value`, `main.de_output.de_output_risk_classification_history.scoreexpectedoriginfunds_value` | WARN |
| `ScoreExpectedDestinationPayments_RiskScore` | `main.de_output.de_output_risk_classification_history.scoreexpecteddestinationpayments_riskscore` | `main.de_output.de_output_risk_classification.scoreexpecteddestinationpayments_riskscore`, `main.de_output.de_output_risk_classification_history.scoreexpecteddestinationpayments_riskscore` | WARN |
| `ScoreExpectedDestinationPayments_Value` | `main.de_output.de_output_risk_classification_history.scoreexpecteddestinationpayments_value` | `main.de_output.de_output_risk_classification.scoreexpecteddestinationpayments_value`, `main.de_output.de_output_risk_classification_history.scoreexpecteddestinationpayments_value` | WARN |
| `SectorHighRisk_RiskScore` | `main.de_output.de_output_risk_classification_history.sectorhighrisk_riskscore` | `main.de_output.de_output_risk_classification.sectorhighrisk_riskscore`, `main.de_output.de_output_risk_classification_history.sectorhighrisk_riskscore` | WARN |

## Lost / added columns

- Computed/added columns vs primary: **0**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN main.de_output.de_output_risk_classification_history AS h ON r.CID = h.CID
