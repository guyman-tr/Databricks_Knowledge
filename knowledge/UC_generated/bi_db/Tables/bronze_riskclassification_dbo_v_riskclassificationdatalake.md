---
object_fqn: main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 100
row_count: null
generated_at: '2026-05-19T12:13:00Z'
upstreams:
- RiskClassification.dbo.V_RiskClassificationDataLake
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md
  source_database: RiskClassification
  source_schema: dbo
  source_table: V_RiskClassificationDataLake
  source_repo: ComplianceDBs
  datalake_path: Bronze/RiskClassification/dbo/V_RiskClassificationDataLake
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 12
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 88
  unverified_columns: 0
---

# bronze_riskclassification_dbo_v_riskclassificationdatalake

> Bronze ingest in `main.bi_db` (1:1 passthrough of `RiskClassification.dbo.V_RiskClassificationDataLake`). 12 of 100 columns inherited from Tier 1 source wiki; 88 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 100 |
| **Generated** | 2026-05-19 |
| **Created** | Sun Jul 30 23:30:10 UTC 2023 |

---

## 1. What it is

Bronze ingest table populated from production source `RiskClassification.dbo.V_RiskClassificationDataLake` (`ComplianceDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md`.

- Lake path: `Bronze/RiskClassification/dbo/V_RiskClassificationDataLake`
- Copy strategy: `Override`
- Source database: `RiskClassification` (`ComplianceDBs`)
- Source schema/table: `dbo.V_RiskClassificationDataLake`
- 12 of 100 columns inherited; 88 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RiskScore_Explanation | STRING | YES | Same as V_RiskClassification. Comma-separated non-zero parameter names (Tier 1 — inherited from RiskClassification.dbo.V_RiskClassificationDataLake). |
| 1 | Regulation | STRING | YES | Regulation name from Dictionary.Regulation (Tier 1 — inherited from RiskClassification.dbo.V_RiskClassificationDataLake). |
| 2 | RiskScoreName | STRING | YES | Named risk level from Dictionary.RiskClassificationRegulation (Tier 1 — inherited from RiskClassification.dbo.V_RiskClassificationDataLake). |
| 3 | GCID | INT | YES | Global Customer ID (Tier 1 — inherited from RiskClassification.dbo.V_RiskClassificationDataLake). |
| 4 | CID | INT | YES | Customer ID (Tier 1 — inherited from RiskClassification.dbo.V_RiskClassificationDataLake). |
| 5 | RegulationID | INT | YES | Regulation ID. See [Regulation](_glossary.md#regulation) (Tier 1 — inherited from RiskClassification.dbo.V_RiskClassificationDataLake). |
| 6 | RiskScore | INT | YES | Final aggregate risk score (Tier 1 — inherited from RiskClassification.dbo.V_RiskClassificationDataLake). |
| 7 | RiskScore_Value | STRING | YES | Score formula in N*Score format (Tier 1 — inherited from RiskClassification.dbo.V_RiskClassificationDataLake). |
| 8 | BeginTime | TIMESTAMP | YES | Temporal row start (Tier 1 — inherited from RiskClassification.dbo.V_RiskClassificationDataLake). |
| 9 | EndTime | TIMESTAMP | YES | Temporal row end (Tier 1 — inherited from RiskClassification.dbo.V_RiskClassificationDataLake). |
| 10 | CountryofResidenceOnboarding_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.CountryofResidenceOnboarding_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 11 | CountryofResidenceOnboarding_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.CountryofResidenceOnboarding_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 12 | CountryofResidenceExistingClients_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.CountryofResidenceExistingClients_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 13 | CountryofResidenceExistingClients_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.CountryofResidenceExistingClients_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 14 | AgeofCustomer_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.AgeofCustomer_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 15 | AgeofCustomer_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.AgeofCustomer_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 16 | AgeAlert_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.AgeAlert_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 17 | AgeAlert_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.AgeAlert_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 18 | PEPCheck_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.PEPCheck_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 19 | PEPCheck_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.PEPCheck_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 20 | MainSourceofIncome_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.MainSourceofIncome_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 21 | MainSourceofIncome_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.MainSourceofIncome_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 22 | Occupation_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.Occupation_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 23 | Occupation_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.Occupation_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 24 | SpecialScore_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.SpecialScore_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 25 | SpecialScore_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.SpecialScore_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 26 | AnnualIncome_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.AnnualIncome_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 27 | AnnualIncome_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.AnnualIncome_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 28 | TotalCashAndLiquidAssets_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.TotalCashAndLiquidAssets_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 29 | TotalCashAndLiquidAssets_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.TotalCashAndLiquidAssets_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 30 | MoneyPlanToInvest_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.MoneyPlanToInvest_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 31 | MoneyPlanToInvest_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.MoneyPlanToInvest_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 32 | HighRisk_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.HighRisk_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 33 | HighRisk_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.HighRisk_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 34 | SectorMLTF_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.SectorMLTF_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 35 | SectorMLTF_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.SectorMLTF_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 36 | NetDeposit_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.NetDeposit_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 37 | NetDeposit_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.NetDeposit_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 38 | InstrumentsPlannedInvestment_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.InstrumentsPlannedInvestment_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 39 | InstrumentsPlannedInvestment_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.InstrumentsPlannedInvestment_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 40 | FTD_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.FTD_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 41 | FTD_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.FTD_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 42 | ScoreExpectedOriginFunds_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.ScoreExpectedOriginFunds_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 43 | ScoreExpectedOriginFunds_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.ScoreExpectedOriginFunds_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 44 | ScoreExpectedDestinationPayments_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.ScoreExpectedDestinationPayments_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 45 | ScoreExpectedDestinationPayments_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.ScoreExpectedDestinationPayments_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 46 | SectorHighRisk_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.SectorHighRisk_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 47 | SectorHighRisk_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.SectorHighRisk_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 48 | Sector_ML_TF_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.Sector_ML_TF_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 49 | Sector_ML_TF_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.Sector_ML_TF_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 50 | SectorHighCash_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.SectorHighCash_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 51 | SectorHighCash_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.SectorHighCash_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 52 | EstablishmentApproved_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.EstablishmentApproved_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 53 | EstablishmentApproved_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.EstablishmentApproved_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 54 | HighPublicProfile_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.HighPublicProfile_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 55 | HighPublicProfile_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.HighPublicProfile_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 56 | DisclosureSubjected_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.DisclosureSubjected_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 57 | DisclosureSubjected_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.DisclosureSubjected_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 58 | RegionSupervised_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.RegionSupervised_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 59 | RegionSupervised_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.RegionSupervised_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 60 | JurisdictionNonCorrupt_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.JurisdictionNonCorrupt_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 61 | JurisdictionNonCorrupt_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.JurisdictionNonCorrupt_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 62 | AML_CFT_Failure_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.AML_CFT_Failure_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 63 | AML_CFT_Failure_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.AML_CFT_Failure_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 64 | BackgroundConsistent_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.BackgroundConsistent_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 65 | BackgroundConsistent_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.BackgroundConsistent_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 66 | TransactionSuspicious_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.TransactionSuspicious_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 67 | TransactionSuspicious_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.TransactionSuspicious_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 68 | IdentityEvidence_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.IdentityEvidence_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 69 | IdentityEvidence_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.IdentityEvidence_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 70 | AvoidBusinessRelations_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.AvoidBusinessRelations_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 71 | AvoidBusinessRelations_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.AvoidBusinessRelations_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 72 | OwnershipTransparent_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.OwnershipTransparent_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 73 | OwnershipTransparent_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.OwnershipTransparent_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 74 | AssetHoldingVehicle_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.AssetHoldingVehicle_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 75 | AssetHoldingVehicle_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.AssetHoldingVehicle_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 76 | TransactionsUnusual_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.TransactionsUnusual_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 77 | TransactionsUnusual_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.TransactionsUnusual_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 78 | SecrecyUnreasonable_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.SecrecyUnreasonable_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 79 | SecrecyUnreasonable_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.SecrecyUnreasonable_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 80 | NFTF_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.NFTF_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 81 | NFTF_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.NFTF_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 82 | IdentityDoubts_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.IdentityDoubts_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 83 | IdentityDoubts_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.IdentityDoubts_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 84 | ExpectedProductsUsed_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.ExpectedProductsUsed_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 85 | ExpectedProductsUsed_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.ExpectedProductsUsed_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 86 | NonProfitOrgAbused_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.NonProfitOrgAbused_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 87 | NonProfitOrgAbused_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.NonProfitOrgAbused_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 88 | CooperativeClient_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.CooperativeClient_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 89 | CooperativeClient_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.CooperativeClient_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 90 | IdentityAnonymous_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.IdentityAnonymous_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 91 | IdentityAnonymous_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.IdentityAnonymous_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 92 | TransactionComplexity_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.TransactionComplexity_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 93 | TransactionComplexity_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.TransactionComplexity_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 94 | PaymentsThirdParty_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.PaymentsThirdParty_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 95 | PaymentsThirdParty_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.PaymentsThirdParty_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 96 | PlaceofBirth_RiskScore | INT | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.PlaceofBirth_RiskScore. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 97 | PlaceofBirth_Value | STRING | YES | Source: RiskClassification.dbo.V_RiskClassificationDataLake.PlaceofBirth_Value. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 98 | PreviousRisk | INT | YES | Previous risk score from history CTE (Tier 1 — inherited from RiskClassification.dbo.V_RiskClassificationDataLake). |
| 99 | PreviousRiskUpdateDate | TIMESTAMP | YES | When previous risk score was set (Tier 1 — inherited from RiskClassification.dbo.V_RiskClassificationDataLake). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `RiskClassification.dbo.V_RiskClassificationDataLake` | Primary | `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` |

### 4.2 Pipeline ASCII Diagram

```
RiskClassification.dbo.V_RiskClassificationDataLake
        │
        ▼
main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake   ←── this object
```

### 4.3 Cross-check vs system.access.column_lineage

`parsed=0 runtime=0 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 5. Sample Queries & Common JOINs

### 5.1 Sample queries

> Sample queries are not auto-generated in this pack; refer to `knowledge/skills/_de_existing/` and `system.query.history` for analyst usage.

### 5.2 Common JOIN partners

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered from upstream JOINs in `.lineage.md`) | — | — |

### 5.3 Gotchas

- See `.review-needed.md` for parser warnings, UNVERIFIED columns, and any Tier-4 sample-only candidates.

---

## 6. Deploy / UC ALTER provenance

| Column | Description source | Tier | Cited as |
|--------|--------------------|------|----------|
| RiskScore_Explanation | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RiskClassification.dbo.V_RiskClassificationDataLake) |
| Regulation | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RiskClassification.dbo.V_RiskClassificationDataLake) |
| RiskScoreName | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RiskClassification.dbo.V_RiskClassificationDataLake) |
| GCID | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RiskClassification.dbo.V_RiskClassificationDataLake) |
| CID | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RiskClassification.dbo.V_RiskClassificationDataLake) |
| RegulationID | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RiskClassification.dbo.V_RiskClassificationDataLake) |
| RiskScore | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RiskClassification.dbo.V_RiskClassificationDataLake) |
| RiskScore_Value | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RiskClassification.dbo.V_RiskClassificationDataLake) |
| BeginTime | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RiskClassification.dbo.V_RiskClassificationDataLake) |
| EndTime | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RiskClassification.dbo.V_RiskClassificationDataLake) |
| CountryofResidenceOnboarding_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `CountryofResidenceOnboarding_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| CountryofResidenceOnboarding_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `CountryofResidenceOnboarding_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| CountryofResidenceExistingClients_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `CountryofResidenceExistingClients_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| CountryofResidenceExistingClients_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `CountryofResidenceExistingClients_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| AgeofCustomer_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `AgeofCustomer_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| AgeofCustomer_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `AgeofCustomer_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| AgeAlert_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `AgeAlert_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| AgeAlert_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `AgeAlert_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| PEPCheck_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `PEPCheck_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| PEPCheck_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `PEPCheck_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| MainSourceofIncome_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `MainSourceofIncome_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| MainSourceofIncome_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `MainSourceofIncome_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Occupation_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `Occupation_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Occupation_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `Occupation_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| SpecialScore_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `SpecialScore_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| SpecialScore_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `SpecialScore_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| AnnualIncome_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `AnnualIncome_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| AnnualIncome_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `AnnualIncome_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| TotalCashAndLiquidAssets_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `TotalCashAndLiquidAssets_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| TotalCashAndLiquidAssets_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `TotalCashAndLiquidAssets_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| MoneyPlanToInvest_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `MoneyPlanToInvest_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| MoneyPlanToInvest_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `MoneyPlanToInvest_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| HighRisk_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `HighRisk_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| HighRisk_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `HighRisk_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| SectorMLTF_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `SectorMLTF_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| SectorMLTF_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `SectorMLTF_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| NetDeposit_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `NetDeposit_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| NetDeposit_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `NetDeposit_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| InstrumentsPlannedInvestment_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `InstrumentsPlannedInvestment_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| InstrumentsPlannedInvestment_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `InstrumentsPlannedInvestment_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| FTD_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `FTD_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| FTD_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `FTD_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| ScoreExpectedOriginFunds_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `ScoreExpectedOriginFunds_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| ScoreExpectedOriginFunds_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `ScoreExpectedOriginFunds_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| ScoreExpectedDestinationPayments_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `ScoreExpectedDestinationPayments_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| ScoreExpectedDestinationPayments_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `ScoreExpectedDestinationPayments_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| SectorHighRisk_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `SectorHighRisk_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| SectorHighRisk_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `SectorHighRisk_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Sector_ML_TF_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `Sector_ML_TF_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Sector_ML_TF_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `Sector_ML_TF_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| SectorHighCash_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `SectorHighCash_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| SectorHighCash_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `SectorHighCash_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| EstablishmentApproved_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `EstablishmentApproved_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| EstablishmentApproved_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `EstablishmentApproved_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| HighPublicProfile_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `HighPublicProfile_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| HighPublicProfile_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `HighPublicProfile_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| DisclosureSubjected_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `DisclosureSubjected_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| DisclosureSubjected_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `DisclosureSubjected_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| RegionSupervised_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `RegionSupervised_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| RegionSupervised_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `RegionSupervised_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| JurisdictionNonCorrupt_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `JurisdictionNonCorrupt_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| JurisdictionNonCorrupt_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `JurisdictionNonCorrupt_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| AML_CFT_Failure_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `AML_CFT_Failure_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| AML_CFT_Failure_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `AML_CFT_Failure_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| BackgroundConsistent_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `BackgroundConsistent_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| BackgroundConsistent_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `BackgroundConsistent_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| TransactionSuspicious_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `TransactionSuspicious_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| TransactionSuspicious_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `TransactionSuspicious_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| IdentityEvidence_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `IdentityEvidence_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| IdentityEvidence_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `IdentityEvidence_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| AvoidBusinessRelations_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `AvoidBusinessRelations_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| AvoidBusinessRelations_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `AvoidBusinessRelations_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| OwnershipTransparent_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `OwnershipTransparent_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| OwnershipTransparent_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `OwnershipTransparent_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| AssetHoldingVehicle_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `AssetHoldingVehicle_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| AssetHoldingVehicle_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `AssetHoldingVehicle_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| TransactionsUnusual_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `TransactionsUnusual_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| TransactionsUnusual_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `TransactionsUnusual_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| SecrecyUnreasonable_RiskScore | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `SecrecyUnreasonable_RiskScore` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| SecrecyUnreasonable_Value | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md` but column `SecrecyUnreasonable_Value` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| ... +20 more rows | ... | ... | ... |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 12 T1, 0 T2, 0 T3, 0 T4, 0 T5, 88 TN, 0 U | Elements: 100/100 | Source: bronze_tier1_inheritance*
