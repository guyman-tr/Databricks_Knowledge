# Column Lineage: main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake` |
| **Object Type** | `EXTERNAL` |
| **Source** | (no source code snapshot — JOB-written table or fetch failed) |
| **Generated** | 2026-05-19 |

> No SQL/notebook source was cached for this object. The wiki for this object
> relies on `system.access.column_lineage` data cached under
> `_discovery/column_lineage/bronze_riskclassification_dbo_v_riskclassificationdatalake.json` for upstream resolution.

## Column Lineage

| # | Element | source_object | source_column | transform |
|---|---------|---------------|---------------|-----------|
| 1 | `RiskScore_Explanation` | `—` | `—` | `runtime_lineage` |
| 2 | `Regulation` | `—` | `—` | `runtime_lineage` |
| 3 | `RiskScoreName` | `—` | `—` | `runtime_lineage` |
| 4 | `GCID` | `—` | `—` | `runtime_lineage` |
| 5 | `CID` | `—` | `—` | `runtime_lineage` |
| 6 | `RegulationID` | `—` | `—` | `runtime_lineage` |
| 7 | `RiskScore` | `—` | `—` | `runtime_lineage` |
| 8 | `RiskScore_Value` | `—` | `—` | `runtime_lineage` |
| 9 | `BeginTime` | `—` | `—` | `runtime_lineage` |
| 10 | `EndTime` | `—` | `—` | `runtime_lineage` |
| 11 | `CountryofResidenceOnboarding_RiskScore` | `—` | `—` | `runtime_lineage` |
| 12 | `CountryofResidenceOnboarding_Value` | `—` | `—` | `runtime_lineage` |
| 13 | `CountryofResidenceExistingClients_RiskScore` | `—` | `—` | `runtime_lineage` |
| 14 | `CountryofResidenceExistingClients_Value` | `—` | `—` | `runtime_lineage` |
| 15 | `AgeofCustomer_RiskScore` | `—` | `—` | `runtime_lineage` |
| 16 | `AgeofCustomer_Value` | `—` | `—` | `runtime_lineage` |
| 17 | `AgeAlert_RiskScore` | `—` | `—` | `runtime_lineage` |
| 18 | `AgeAlert_Value` | `—` | `—` | `runtime_lineage` |
| 19 | `PEPCheck_RiskScore` | `—` | `—` | `runtime_lineage` |
| 20 | `PEPCheck_Value` | `—` | `—` | `runtime_lineage` |
| 21 | `MainSourceofIncome_RiskScore` | `—` | `—` | `runtime_lineage` |
| 22 | `MainSourceofIncome_Value` | `—` | `—` | `runtime_lineage` |
| 23 | `Occupation_RiskScore` | `—` | `—` | `runtime_lineage` |
| 24 | `Occupation_Value` | `—` | `—` | `runtime_lineage` |
| 25 | `SpecialScore_RiskScore` | `—` | `—` | `runtime_lineage` |
| 26 | `SpecialScore_Value` | `—` | `—` | `runtime_lineage` |
| 27 | `AnnualIncome_RiskScore` | `—` | `—` | `runtime_lineage` |
| 28 | `AnnualIncome_Value` | `—` | `—` | `runtime_lineage` |
| 29 | `TotalCashAndLiquidAssets_RiskScore` | `—` | `—` | `runtime_lineage` |
| 30 | `TotalCashAndLiquidAssets_Value` | `—` | `—` | `runtime_lineage` |
| 31 | `MoneyPlanToInvest_RiskScore` | `—` | `—` | `runtime_lineage` |
| 32 | `MoneyPlanToInvest_Value` | `—` | `—` | `runtime_lineage` |
| 33 | `HighRisk_RiskScore` | `—` | `—` | `runtime_lineage` |
| 34 | `HighRisk_Value` | `—` | `—` | `runtime_lineage` |
| 35 | `SectorMLTF_RiskScore` | `—` | `—` | `runtime_lineage` |
| 36 | `SectorMLTF_Value` | `—` | `—` | `runtime_lineage` |
| 37 | `NetDeposit_RiskScore` | `—` | `—` | `runtime_lineage` |
| 38 | `NetDeposit_Value` | `—` | `—` | `runtime_lineage` |
| 39 | `InstrumentsPlannedInvestment_RiskScore` | `—` | `—` | `runtime_lineage` |
| 40 | `InstrumentsPlannedInvestment_Value` | `—` | `—` | `runtime_lineage` |
| 41 | `FTD_RiskScore` | `—` | `—` | `runtime_lineage` |
| 42 | `FTD_Value` | `—` | `—` | `runtime_lineage` |
| 43 | `ScoreExpectedOriginFunds_RiskScore` | `—` | `—` | `runtime_lineage` |
| 44 | `ScoreExpectedOriginFunds_Value` | `—` | `—` | `runtime_lineage` |
| 45 | `ScoreExpectedDestinationPayments_RiskScore` | `—` | `—` | `runtime_lineage` |
| 46 | `ScoreExpectedDestinationPayments_Value` | `—` | `—` | `runtime_lineage` |
| 47 | `SectorHighRisk_RiskScore` | `—` | `—` | `runtime_lineage` |
| 48 | `SectorHighRisk_Value` | `—` | `—` | `runtime_lineage` |
| 49 | `Sector_ML_TF_RiskScore` | `—` | `—` | `runtime_lineage` |
| 50 | `Sector_ML_TF_Value` | `—` | `—` | `runtime_lineage` |
| 51 | `SectorHighCash_RiskScore` | `—` | `—` | `runtime_lineage` |
| 52 | `SectorHighCash_Value` | `—` | `—` | `runtime_lineage` |
| 53 | `EstablishmentApproved_RiskScore` | `—` | `—` | `runtime_lineage` |
| 54 | `EstablishmentApproved_Value` | `—` | `—` | `runtime_lineage` |
| 55 | `HighPublicProfile_RiskScore` | `—` | `—` | `runtime_lineage` |
| 56 | `HighPublicProfile_Value` | `—` | `—` | `runtime_lineage` |
| 57 | `DisclosureSubjected_RiskScore` | `—` | `—` | `runtime_lineage` |
| 58 | `DisclosureSubjected_Value` | `—` | `—` | `runtime_lineage` |
| 59 | `RegionSupervised_RiskScore` | `—` | `—` | `runtime_lineage` |
| 60 | `RegionSupervised_Value` | `—` | `—` | `runtime_lineage` |
| 61 | `JurisdictionNonCorrupt_RiskScore` | `—` | `—` | `runtime_lineage` |
| 62 | `JurisdictionNonCorrupt_Value` | `—` | `—` | `runtime_lineage` |
| 63 | `AML_CFT_Failure_RiskScore` | `—` | `—` | `runtime_lineage` |
| 64 | `AML_CFT_Failure_Value` | `—` | `—` | `runtime_lineage` |
| 65 | `BackgroundConsistent_RiskScore` | `—` | `—` | `runtime_lineage` |
| 66 | `BackgroundConsistent_Value` | `—` | `—` | `runtime_lineage` |
| 67 | `TransactionSuspicious_RiskScore` | `—` | `—` | `runtime_lineage` |
| 68 | `TransactionSuspicious_Value` | `—` | `—` | `runtime_lineage` |
| 69 | `IdentityEvidence_RiskScore` | `—` | `—` | `runtime_lineage` |
| 70 | `IdentityEvidence_Value` | `—` | `—` | `runtime_lineage` |
| 71 | `AvoidBusinessRelations_RiskScore` | `—` | `—` | `runtime_lineage` |
| 72 | `AvoidBusinessRelations_Value` | `—` | `—` | `runtime_lineage` |
| 73 | `OwnershipTransparent_RiskScore` | `—` | `—` | `runtime_lineage` |
| 74 | `OwnershipTransparent_Value` | `—` | `—` | `runtime_lineage` |
| 75 | `AssetHoldingVehicle_RiskScore` | `—` | `—` | `runtime_lineage` |
| 76 | `AssetHoldingVehicle_Value` | `—` | `—` | `runtime_lineage` |
| 77 | `TransactionsUnusual_RiskScore` | `—` | `—` | `runtime_lineage` |
| 78 | `TransactionsUnusual_Value` | `—` | `—` | `runtime_lineage` |
| 79 | `SecrecyUnreasonable_RiskScore` | `—` | `—` | `runtime_lineage` |
| 80 | `SecrecyUnreasonable_Value` | `—` | `—` | `runtime_lineage` |
| 81 | `NFTF_RiskScore` | `—` | `—` | `runtime_lineage` |
| 82 | `NFTF_Value` | `—` | `—` | `runtime_lineage` |
| 83 | `IdentityDoubts_RiskScore` | `—` | `—` | `runtime_lineage` |
| 84 | `IdentityDoubts_Value` | `—` | `—` | `runtime_lineage` |
| 85 | `ExpectedProductsUsed_RiskScore` | `—` | `—` | `runtime_lineage` |
| 86 | `ExpectedProductsUsed_Value` | `—` | `—` | `runtime_lineage` |
| 87 | `NonProfitOrgAbused_RiskScore` | `—` | `—` | `runtime_lineage` |
| 88 | `NonProfitOrgAbused_Value` | `—` | `—` | `runtime_lineage` |
| 89 | `CooperativeClient_RiskScore` | `—` | `—` | `runtime_lineage` |
| 90 | `CooperativeClient_Value` | `—` | `—` | `runtime_lineage` |
| 91 | `IdentityAnonymous_RiskScore` | `—` | `—` | `runtime_lineage` |
| 92 | `IdentityAnonymous_Value` | `—` | `—` | `runtime_lineage` |
| 93 | `TransactionComplexity_RiskScore` | `—` | `—` | `runtime_lineage` |
| 94 | `TransactionComplexity_Value` | `—` | `—` | `runtime_lineage` |
| 95 | `PaymentsThirdParty_RiskScore` | `—` | `—` | `runtime_lineage` |
| 96 | `PaymentsThirdParty_Value` | `—` | `—` | `runtime_lineage` |
| 97 | `PlaceofBirth_RiskScore` | `—` | `—` | `runtime_lineage` |
| 98 | `PlaceofBirth_Value` | `—` | `—` | `runtime_lineage` |
| 99 | `PreviousRisk` | `—` | `—` | `runtime_lineage` |
| 100 | `PreviousRiskUpdateDate` | `—` | `—` | `runtime_lineage` |
