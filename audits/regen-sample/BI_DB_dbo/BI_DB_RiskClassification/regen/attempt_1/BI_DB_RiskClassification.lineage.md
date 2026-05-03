# Column Lineage: BI_DB_dbo.BI_DB_RiskClassification

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_RiskClassification` |
| **UC Target** | `bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake` |
| **Primary Source** | `RiskClassification.dbo.V_RiskClassificationDataLake` (risk-fg-RiskClassification) |
| **ETL SP** | None (Generic Pipeline direct load) |
| **Secondary Sources** | None |
| **Generated** | 2026-04-30 |

## Source Objects

| # | Source Object | Source Type | Relationship | Description |
|---|-------------|------------|-------------|-------------|
| 1 | RiskClassification.dbo.V_RiskClassificationDataLake | Production view | Primary source | External risk classification view exported via Generic Pipeline |
| 2 | BI_DB_Migration.BI_DB_RiskClassification | Migration staging | Historical | Migration staging table (Sep 2024 schema migration) |

## Lineage Chain

```
RiskClassification.dbo.V_RiskClassificationDataLake (risk-fg-RiskClassification)
  -> Generic Pipeline (weekly, Override, parquet)
  -> Bronze/RiskClassification/dbo/V_RiskClassificationDataLake/
  -> BI_DB_dbo.BI_DB_RiskClassification (4.9M rows)
  -> bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake (UC)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is from source view. Same name, same value. |
| **unknown** | Source column mapping unknown (no SP code, no upstream wiki). |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| RiskScore_Explanation | V_RiskClassificationDataLake | RiskScore_Explanation | passthrough | Comma-separated list of contributing risk factors |
| Regulation | V_RiskClassificationDataLake | Regulation | passthrough | Regulatory body name |
| RiskScoreName | V_RiskClassificationDataLake | RiskScoreName | passthrough | Overall risk level label |
| GCID | V_RiskClassificationDataLake | GCID | passthrough | Global customer identifier |
| CID | V_RiskClassificationDataLake | CID | passthrough | Customer identifier |
| RegulationID | V_RiskClassificationDataLake | RegulationID | passthrough | Regulation FK |
| RiskScore | V_RiskClassificationDataLake | RiskScore | passthrough | Overall composite risk score |
| RiskScore_Value | V_RiskClassificationDataLake | RiskScore_Value | passthrough | Score formula expression |
| BeginTime | V_RiskClassificationDataLake | BeginTime | passthrough | SCD validity start |
| EndTime | V_RiskClassificationDataLake | EndTime | passthrough | SCD validity end |
| Country of Residence, Onboarding_RiskScore | V_RiskClassificationDataLake | Country of Residence, Onboarding_RiskScore | passthrough | Risk factor score |
| Country of Residence, Onboarding_Value | V_RiskClassificationDataLake | Country of Residence, Onboarding_Value | passthrough | Risk factor value |
| Country of Residence, Existing clients_RiskScore | V_RiskClassificationDataLake | Country of Residence, Existing clients_RiskScore | passthrough | Risk factor score |
| Country of Residence, Existing clients_Value | V_RiskClassificationDataLake | Country of Residence, Existing clients_Value | passthrough | Risk factor value |
| Age of customer_RiskScore | V_RiskClassificationDataLake | Age of customer_RiskScore | passthrough | Risk factor score |
| Age of customer_Value | V_RiskClassificationDataLake | Age of customer_Value | passthrough | Risk factor value |
| Age Alert_RiskScore | V_RiskClassificationDataLake | Age Alert_RiskScore | passthrough | Risk factor score |
| Age Alert_Value | V_RiskClassificationDataLake | Age Alert_Value | passthrough | Risk factor value |
| PEP Check_RiskScore | V_RiskClassificationDataLake | PEP Check_RiskScore | passthrough | Risk factor score |
| PEP Check_Value | V_RiskClassificationDataLake | PEP Check_Value | passthrough | Risk factor value |
| Main Source of Income_RiskScore | V_RiskClassificationDataLake | Main Source of Income_RiskScore | passthrough | Risk factor score |
| Main Source of Income_Value | V_RiskClassificationDataLake | Main Source of Income_Value | passthrough | Risk factor value |
| Occupation_RiskScore | V_RiskClassificationDataLake | Occupation_RiskScore | passthrough | Risk factor score |
| Occupation_Value | V_RiskClassificationDataLake | Occupation_Value | passthrough | Risk factor value |
| Special Score_RiskScore | V_RiskClassificationDataLake | Special Score_RiskScore | passthrough | Risk factor score |
| Special Score_Value | V_RiskClassificationDataLake | Special Score_Value | passthrough | Risk factor value |
| Annual Income_RiskScore | V_RiskClassificationDataLake | Annual Income_RiskScore | passthrough | Risk factor score |
| Annual Income_Value | V_RiskClassificationDataLake | Annual Income_Value | passthrough | Risk factor value |
| Total Cash And Liquid Assets_RiskScore | V_RiskClassificationDataLake | Total Cash And Liquid Assets_RiskScore | passthrough | Risk factor score |
| Total Cash And Liquid Assets_Value | V_RiskClassificationDataLake | Total Cash And Liquid Assets_Value | passthrough | Risk factor value |
| Money plan To invest_RiskScore | V_RiskClassificationDataLake | Money plan To invest_RiskScore | passthrough | Risk factor score |
| Money plan To invest_Value | V_RiskClassificationDataLake | Money plan To invest_Value | passthrough | Risk factor value |
| High Risk_RiskScore | V_RiskClassificationDataLake | High Risk_RiskScore | passthrough | Risk factor score |
| High Risk_Value | V_RiskClassificationDataLake | High Risk_Value | passthrough | Risk factor value |
| Sector ML TF_RiskScore | V_RiskClassificationDataLake | Sector ML TF_RiskScore | passthrough | Risk factor score |
| Sector ML TF_Value | V_RiskClassificationDataLake | Sector ML TF_Value | passthrough | Risk factor value |
| Sector High Cash_RiskScore | V_RiskClassificationDataLake | Sector High Cash_RiskScore | passthrough | Risk factor score |
| Sector High Cash_Value | V_RiskClassificationDataLake | Sector High Cash_Value | passthrough | Risk factor value |
| Net Deposit_RiskScore | V_RiskClassificationDataLake | Net Deposit_RiskScore | passthrough | Risk factor score |
| Net Deposit_Value | V_RiskClassificationDataLake | Net Deposit_Value | passthrough | Risk factor value |
| Instruments Planned Investment_RiskScore | V_RiskClassificationDataLake | Instruments Planned Investment_RiskScore | passthrough | Risk factor score |
| Instruments Planned Investment_Value | V_RiskClassificationDataLake | Instruments Planned Investment_Value | passthrough | Risk factor value |
| FTD_RiskScore | V_RiskClassificationDataLake | FTD_RiskScore | passthrough | Risk factor score |
| FTD_Value | V_RiskClassificationDataLake | FTD_Value | passthrough | Risk factor value |
| ScoreExpectedOriginFunds_RiskScore | V_RiskClassificationDataLake | ScoreExpectedOriginFunds_RiskScore | passthrough | Risk factor score |
| ScoreExpectedOriginFunds_Value | V_RiskClassificationDataLake | ScoreExpectedOriginFunds_Value | passthrough | Risk factor value |
| ScoreExpectedDestinationPayments_RiskScore | V_RiskClassificationDataLake | ScoreExpectedDestinationPayments_RiskScore | passthrough | Risk factor score |
| ScoreExpectedDestinationPayments_Value | V_RiskClassificationDataLake | ScoreExpectedDestinationPayments_Value | passthrough | Risk factor value |
| SectorHighRisk_RiskScore | V_RiskClassificationDataLake | SectorHighRisk_RiskScore | passthrough | Risk factor score |
| SectorHighRisk_Value | V_RiskClassificationDataLake | SectorHighRisk_Value | passthrough | Risk factor value |
| Sector_ML_TF_RiskScore | V_RiskClassificationDataLake | Sector_ML_TF_RiskScore | passthrough | Risk factor score |
| Sector_ML_TF_Value | V_RiskClassificationDataLake | Sector_ML_TF_Value | passthrough | Risk factor value |
| SectorHighCash_RiskScore | V_RiskClassificationDataLake | SectorHighCash_RiskScore | passthrough | Risk factor score |
| SectorHighCash_Value | V_RiskClassificationDataLake | SectorHighCash_Value | passthrough | Risk factor value |
| EstablishmentApproved_RiskScore | V_RiskClassificationDataLake | EstablishmentApproved_RiskScore | passthrough | Risk factor score |
| EstablishmentApproved_Value | V_RiskClassificationDataLake | EstablishmentApproved_Value | passthrough | Risk factor value |
| HighPublicProfile_RiskScore | V_RiskClassificationDataLake | HighPublicProfile_RiskScore | passthrough | Risk factor score |
| HighPublicProfile_Value | V_RiskClassificationDataLake | HighPublicProfile_Value | passthrough | Risk factor value |
| DisclosureSubjected_RiskScore | V_RiskClassificationDataLake | DisclosureSubjected_RiskScore | passthrough | Risk factor score |
| DisclosureSubjected_Value | V_RiskClassificationDataLake | DisclosureSubjected_Value | passthrough | Risk factor value |
| RegionSupervised_RiskScore | V_RiskClassificationDataLake | RegionSupervised_RiskScore | passthrough | Risk factor score |
| RegionSupervised_Value | V_RiskClassificationDataLake | RegionSupervised_Value | passthrough | Risk factor value |
| JurisdictionNonCorrupt_RiskScore | V_RiskClassificationDataLake | JurisdictionNonCorrupt_RiskScore | passthrough | Risk factor score |
| JurisdictionNonCorrupt_Value | V_RiskClassificationDataLake | JurisdictionNonCorrupt_Value | passthrough | Risk factor value |
| AML_CFT_Failure_RiskScore | V_RiskClassificationDataLake | AML_CFT_Failure_RiskScore | passthrough | Risk factor score |
| AML_CFT_Failure_Value | V_RiskClassificationDataLake | AML_CFT_Failure_Value | passthrough | Risk factor value |
| BackgroundConsistent_RiskScore | V_RiskClassificationDataLake | BackgroundConsistent_RiskScore | passthrough | Risk factor score |
| BackgroundConsistent_Value | V_RiskClassificationDataLake | BackgroundConsistent_Value | passthrough | Risk factor value |
| TransactionSuspicious_RiskScore | V_RiskClassificationDataLake | TransactionSuspicious_RiskScore | passthrough | Risk factor score |
| TransactionSuspicious_Value | V_RiskClassificationDataLake | TransactionSuspicious_Value | passthrough | Risk factor value |
| IdentityEvidence_RiskScore | V_RiskClassificationDataLake | IdentityEvidence_RiskScore | passthrough | Risk factor score |
| IdentityEvidence_Value | V_RiskClassificationDataLake | IdentityEvidence_Value | passthrough | Risk factor value |
| AvoidBusinessRelations_RiskScore | V_RiskClassificationDataLake | AvoidBusinessRelations_RiskScore | passthrough | Risk factor score |
| AvoidBusinessRelations_Value | V_RiskClassificationDataLake | AvoidBusinessRelations_Value | passthrough | Risk factor value |
| OwnershipTransparent_RiskScore | V_RiskClassificationDataLake | OwnershipTransparent_RiskScore | passthrough | Risk factor score |
| OwnershipTransparent_Value | V_RiskClassificationDataLake | OwnershipTransparent_Value | passthrough | Risk factor value |
| AssetHoldingVehicle_RiskScore | V_RiskClassificationDataLake | AssetHoldingVehicle_RiskScore | passthrough | Risk factor score |
| AssetHoldingVehicle_Value | V_RiskClassificationDataLake | AssetHoldingVehicle_Value | passthrough | Risk factor value |
| TransactionsUnusual_RiskScore | V_RiskClassificationDataLake | TransactionsUnusual_RiskScore | passthrough | Risk factor score |
| TransactionsUnusual_Value | V_RiskClassificationDataLake | TransactionsUnusual_Value | passthrough | Risk factor value |
| SecrecyUnreasonable_RiskScore | V_RiskClassificationDataLake | SecrecyUnreasonable_RiskScore | passthrough | Risk factor score |
| SecrecyUnreasonable_Value | V_RiskClassificationDataLake | SecrecyUnreasonable_Value | passthrough | Risk factor value |
| NFTF_RiskScore | V_RiskClassificationDataLake | NFTF_RiskScore | passthrough | Risk factor score |
| NFTF_Value | V_RiskClassificationDataLake | NFTF_Value | passthrough | Risk factor value |
| IdentityDoubts_RiskScore | V_RiskClassificationDataLake | IdentityDoubts_RiskScore | passthrough | Risk factor score |
| IdentityDoubts_Value | V_RiskClassificationDataLake | IdentityDoubts_Value | passthrough | Risk factor value |
| ExpectedProductsUsed_RiskScore | V_RiskClassificationDataLake | ExpectedProductsUsed_RiskScore | passthrough | Risk factor score |
| ExpectedProductsUsed_Value | V_RiskClassificationDataLake | ExpectedProductsUsed_Value | passthrough | Risk factor value |
| NonProfitOrgAbused_RiskScore | V_RiskClassificationDataLake | NonProfitOrgAbused_RiskScore | passthrough | Risk factor score |
| NonProfitOrgAbused_Value | V_RiskClassificationDataLake | NonProfitOrgAbused_Value | passthrough | Risk factor value |
| CooperativeClient_RiskScore | V_RiskClassificationDataLake | CooperativeClient_RiskScore | passthrough | Risk factor score |
| CooperativeClient_Value | V_RiskClassificationDataLake | CooperativeClient_Value | passthrough | Risk factor value |
| IdentityAnonymous_RiskScore | V_RiskClassificationDataLake | IdentityAnonymous_RiskScore | passthrough | Risk factor score |
| IdentityAnonymous_Value | V_RiskClassificationDataLake | IdentityAnonymous_Value | passthrough | Risk factor value |
| TransactionComplexity_RiskScore | V_RiskClassificationDataLake | TransactionComplexity_RiskScore | passthrough | Risk factor score |
| TransactionComplexity_Value | V_RiskClassificationDataLake | TransactionComplexity_Value | passthrough | Risk factor value |
| PaymentsThirdParty_RiskScore | V_RiskClassificationDataLake | PaymentsThirdParty_RiskScore | passthrough | Risk factor score |
| PaymentsThirdParty_Value | V_RiskClassificationDataLake | PaymentsThirdParty_Value | passthrough | Risk factor value |
| UpdateDate | V_RiskClassificationDataLake | UpdateDate | passthrough | Last update timestamp |
| Place of Birth_RiskScore | V_RiskClassificationDataLake | Place of Birth_RiskScore | passthrough | Risk factor score |
| Place of Birth_Value | V_RiskClassificationDataLake | Place of Birth_Value | passthrough | Risk factor value |
| PreviousRisk | V_RiskClassificationDataLake | PreviousRisk | passthrough | Previous composite risk score |
| PreviousRiskUpdateDate | V_RiskClassificationDataLake | PreviousRiskUpdateDate | passthrough | Timestamp of previous risk assessment |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 103 |
| **Rename** | 0 |
| **ETL-computed** | 0 |
| **Total** | 103 |
