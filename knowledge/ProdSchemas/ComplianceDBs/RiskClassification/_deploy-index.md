---

## bronze: RiskClassification

db_key: ComplianceDBs/RiskClassification
total_deployable: 4
generated: 4
failed: 0
deployed: 0
last_generated: "2026-04-30"
source_tool: tools/uc_bronze/generate_bronze_alters.py

## Bronze ALTER Generation Status

| Object | UC Target | Status |
|--------|-----------|--------|
| [Dictionary.CySecRiskClassificationParameter](Wiki/Dictionary/Tables/Dictionary.CySecRiskClassificationParameter.md) | `main.bi_db.bronze_riskclassification_dictionary_cysecriskclassificationparameter` | Generated |
| [RiskClassification.CustomerOnboardingRiskClassification](Wiki/RiskClassification/Tables/RiskClassification.CustomerOnboardingRiskClassification.md) | `main.bi_db.bronze_riskclassification_riskclassification_customeronboardingriskclassification` | Generated |
| [RiskClassification.CySecRiskClassificationParameter](Wiki/RiskClassification/Tables/RiskClassification.CySecRiskClassificationParameter.md) | `main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter` | Generated |
| [dbo.V_RiskClassificationDataLake](Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md) | `main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake` | Generated |
