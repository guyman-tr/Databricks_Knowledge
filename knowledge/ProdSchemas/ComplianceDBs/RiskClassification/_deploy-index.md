---

## bronze: RiskClassification

db_key: ComplianceDBs/RiskClassification
total_deployable: 4
generated: 0
failed: 1
deployed: 3
last_generated: "2026-04-30"
last_deploy_batch: 1
last_deployed: "2026-05-03"
source_tool: tools/uc_bronze/generate_bronze_alters.py

## Bronze ALTER Generation Status

| Object | UC Target | Status |
|--------|-----------|--------|
| [Dictionary.CySecRiskClassificationParameter](Wiki/Dictionary/Tables/Dictionary.CySecRiskClassificationParameter.md) | `main.bi_db.bronze_riskclassification_dictionary_cysecriskclassificationparameter` | Deployed (Batch 1) - 2026-05-03 |
| [RiskClassification.CustomerOnboardingRiskClassification](Wiki/RiskClassification/Tables/RiskClassification.CustomerOnboardingRiskClassification.md) | `main.bi_db.bronze_riskclassification_riskclassification_customeronboardingriskclassification` | Deployed (Batch 1) - 2026-05-03 |
| [RiskClassification.CySecRiskClassificationParameter](Wiki/RiskClassification/Tables/RiskClassification.CySecRiskClassificationParameter.md) | `main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.V_RiskClassificationDataLake](Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md) | `main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake` | Failed (Batch 1) - [UNRESOLVED_COLUMN.WITH_SUGGESTION] A column, variable, or function parameter with name `_RiskScore / _Value (sanitized  |
