# Column Lineage: main.de_output.de_output_risk_classification_history_cysec

| Property | Value |
|----------|-------|
| **UC Object** | `main.de_output.de_output_risk_classification_history_cysec` |
| **Object Type** | `EXTERNAL` |
| **Source** | (no source code snapshot — JOB-written table or fetch failed) |
| **Generated** | 2026-05-19 |

> No SQL/notebook source was cached for this object. The wiki for this object
> relies on `system.access.column_lineage` data cached under
> `_discovery/column_lineage/de_output_risk_classification_history_cysec.json` for upstream resolution.

## Column Lineage

| # | Element | source_object | source_column | transform |
|---|---------|---------------|---------------|-----------|
| 1 | `BeginTime` | `—` | `—` | `runtime_lineage` |
| 2 | `EndTime` | `—` | `—` | `runtime_lineage` |
| 3 | `GCID` | `—` | `—` | `runtime_lineage` |
| 4 | `CID` | `—` | `—` | `runtime_lineage` |
| 5 | `RegulationID` | `—` | `—` | `runtime_lineage` |
| 6 | `Regulation` | `—` | `—` | `runtime_lineage` |
| 7 | `CountryofResidence_Onboarding_RiskScore` | `—` | `—` | `runtime_lineage` |
| 8 | `CountryofResidence_Onboarding_Value` | `—` | `—` | `runtime_lineage` |
| 9 | `CountryofResidence_Existingclients_RiskScore` | `—` | `—` | `runtime_lineage` |
| 10 | `CountryofResidence_Existingclients_Value` | `—` | `—` | `runtime_lineage` |
| 11 | `Ageofcustomer_RiskScore` | `—` | `—` | `runtime_lineage` |
| 12 | `Ageofcustomer_Value` | `—` | `—` | `runtime_lineage` |
| 13 | `AgeAlert_RiskScore` | `—` | `—` | `runtime_lineage` |
| 14 | `AgeAlert_Value` | `—` | `—` | `runtime_lineage` |
| 15 | `ScreeningStatus_RiskScore` | `—` | `—` | `runtime_lineage` |
| 16 | `ScreeningStatus_Value` | `—` | `—` | `runtime_lineage` |
| 17 | `MainSourceofIncome_RiskScore` | `—` | `—` | `runtime_lineage` |
| 18 | `MainSourceofIncome_Value` | `—` | `—` | `runtime_lineage` |
| 19 | `Occupation_RiskScore` | `—` | `—` | `runtime_lineage` |
| 20 | `Occupation_Value` | `—` | `—` | `runtime_lineage` |
| 21 | `SpecialScore_RiskScore` | `—` | `—` | `runtime_lineage` |
| 22 | `SpecialScore_Value` | `—` | `—` | `runtime_lineage` |
| 23 | `AnnualIncome_RiskScore` | `—` | `—` | `runtime_lineage` |
| 24 | `AnnualIncome_Value` | `—` | `—` | `runtime_lineage` |
| 25 | `TotalCashAndLiquidAssets_RiskScore` | `—` | `—` | `runtime_lineage` |
| 26 | `TotalCashAndLiquidAssets_Value` | `—` | `—` | `runtime_lineage` |
| 27 | `MoneyplanToinvest_RiskScore` | `—` | `—` | `runtime_lineage` |
| 28 | `MoneyplanToinvest_Value` | `—` | `—` | `runtime_lineage` |
| 29 | `HighRisk_RiskScore` | `—` | `—` | `runtime_lineage` |
| 30 | `HighRisk_Value` | `—` | `—` | `runtime_lineage` |
| 31 | `SectorMLTF_RiskScore` | `—` | `—` | `runtime_lineage` |
| 32 | `SectorMLTF_Value` | `—` | `—` | `runtime_lineage` |
| 33 | `NetDeposit_RiskScore` | `—` | `—` | `runtime_lineage` |
| 34 | `NetDeposit_Value` | `—` | `—` | `runtime_lineage` |
| 35 | `FTD_RiskScore` | `—` | `—` | `runtime_lineage` |
| 36 | `FTD_Value` | `—` | `—` | `runtime_lineage` |
| 37 | `ScoreExpectedOriginFunds_RiskScore` | `—` | `—` | `runtime_lineage` |
| 38 | `ScoreExpectedOriginFunds_Value` | `—` | `—` | `runtime_lineage` |
| 39 | `ScoreExpectedDestinationPayments_RiskScore` | `—` | `—` | `runtime_lineage` |
| 40 | `ScoreExpectedDestinationPayments_Value` | `—` | `—` | `runtime_lineage` |
| 41 | `SectorHighRisk_RiskScore` | `—` | `—` | `runtime_lineage` |
| 42 | `SectorHighRisk_Value` | `—` | `—` | `runtime_lineage` |
| 43 | `Sector_ML_TF_RiskScore` | `—` | `—` | `runtime_lineage` |
| 44 | `Sector_ML_TF_Value` | `—` | `—` | `runtime_lineage` |
| 45 | `SectorHighCash_RiskScore` | `—` | `—` | `runtime_lineage` |
| 46 | `SectorHighCash_Value` | `—` | `—` | `runtime_lineage` |
| 47 | `EstablishmentApproved_RiskScore` | `—` | `—` | `runtime_lineage` |
| 48 | `EstablishmentApproved_Value` | `—` | `—` | `runtime_lineage` |
| 49 | `HighPublicProfile_RiskScore` | `—` | `—` | `runtime_lineage` |
| 50 | `HighPublicProfile_Value` | `—` | `—` | `runtime_lineage` |
| 51 | `DisclosureSubjected_RiskScore` | `—` | `—` | `runtime_lineage` |
| 52 | `DisclosureSubjected_Value` | `—` | `—` | `runtime_lineage` |
| 53 | `RegionSupervised_RiskScore` | `—` | `—` | `runtime_lineage` |
| 54 | `RegionSupervised_Value` | `—` | `—` | `runtime_lineage` |
| 55 | `JurisdictionNonCorrupt_RiskScore` | `—` | `—` | `runtime_lineage` |
| 56 | `JurisdictionNonCorrupt_Value` | `—` | `—` | `runtime_lineage` |
| 57 | `AML_CFT_Failure_RiskScore` | `—` | `—` | `runtime_lineage` |
| 58 | `AML_CFT_Failure_Value` | `—` | `—` | `runtime_lineage` |
| 59 | `BackgroundConsistent_RiskScore` | `—` | `—` | `runtime_lineage` |
| 60 | `BackgroundConsistent_Value` | `—` | `—` | `runtime_lineage` |
| 61 | `TransactionSuspicious_RiskScore` | `—` | `—` | `runtime_lineage` |
| 62 | `TransactionSuspicious_Value` | `—` | `—` | `runtime_lineage` |
| 63 | `IdentityEvidence_RiskScore` | `—` | `—` | `runtime_lineage` |
| 64 | `IdentityEvidence_Value` | `—` | `—` | `runtime_lineage` |
| 65 | `AvoidBusinessRelations_RiskScore` | `—` | `—` | `runtime_lineage` |
| 66 | `AvoidBusinessRelations_Value` | `—` | `—` | `runtime_lineage` |
| 67 | `OwnershipTransparent_RiskScore` | `—` | `—` | `runtime_lineage` |
| 68 | `OwnershipTransparent_Value` | `—` | `—` | `runtime_lineage` |
| 69 | `AssetHoldingVehicle_RiskScore` | `—` | `—` | `runtime_lineage` |
| 70 | `AssetHoldingVehicle_Value` | `—` | `—` | `runtime_lineage` |
| 71 | `TransactionsUnusual_RiskScore` | `—` | `—` | `runtime_lineage` |
| 72 | `TransactionsUnusual_Value` | `—` | `—` | `runtime_lineage` |
| 73 | `SecrecyUnreasonable_RiskScore` | `—` | `—` | `runtime_lineage` |
| 74 | `SecrecyUnreasonable_Value` | `—` | `—` | `runtime_lineage` |
| 75 | `NFTF_RiskScore` | `—` | `—` | `runtime_lineage` |
| 76 | `NFTF_Value` | `—` | `—` | `runtime_lineage` |
| 77 | `IdentityDoubts_RiskScore` | `—` | `—` | `runtime_lineage` |
| 78 | `IdentityDoubts_Value` | `—` | `—` | `runtime_lineage` |
| 79 | `ExpectedProductsUsed_RiskScore` | `—` | `—` | `runtime_lineage` |
| 80 | `ExpectedProductsUsed_Value` | `—` | `—` | `runtime_lineage` |
| 81 | `NonProfitOrgAbused_RiskScore` | `—` | `—` | `runtime_lineage` |
| 82 | `NonProfitOrgAbused_Value` | `—` | `—` | `runtime_lineage` |
| 83 | `CooperativeClient_RiskScore` | `—` | `—` | `runtime_lineage` |
| 84 | `CooperativeClient_Value` | `—` | `—` | `runtime_lineage` |
| 85 | `IdentityAnonymous_RiskScore` | `—` | `—` | `runtime_lineage` |
| 86 | `IdentityAnonymous_Value` | `—` | `—` | `runtime_lineage` |
| 87 | `TransactionComplexity_RiskScore` | `—` | `—` | `runtime_lineage` |
| 88 | `TransactionComplexity_Value` | `—` | `—` | `runtime_lineage` |
| 89 | `PaymentsThirdParty_RiskScore` | `—` | `—` | `runtime_lineage` |
| 90 | `PaymentsThirdParty_Value` | `—` | `—` | `runtime_lineage` |
| 91 | `Finalscore_RiskScore` | `—` | `—` | `runtime_lineage` |
| 92 | `Finalscore_Value` | `—` | `—` | `runtime_lineage` |
| 93 | `RiskScore_Explanation` | `—` | `—` | `runtime_lineage` |
| 94 | `RiskScoreName` | `—` | `—` | `runtime_lineage` |
| 95 | `SourceDate` | `—` | `—` | `runtime_lineage` |
| 96 | `IsLastUpdate` | `—` | `—` | `runtime_lineage` |
