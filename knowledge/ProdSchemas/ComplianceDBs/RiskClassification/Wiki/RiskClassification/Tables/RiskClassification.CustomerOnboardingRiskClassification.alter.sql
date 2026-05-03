-- =============================================================================
-- Databricks ALTER Script: bronze RiskClassification.RiskClassification.CustomerOnboardingRiskClassification
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/RiskClassification/Tables/RiskClassification.CustomerOnboardingRiskClassification.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_riskclassification_riskclassification_customeronboardingriskclassification
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_riskclassification_riskclassification_customeronboardingriskclassification (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_riskclassification_riskclassification_customeronboardingriskclassification SET TBLPROPERTIES (
    'comment' = 'Customer onboarding risk classification table storing a weighted composite risk score and full JSON scoring breakdown for each customer, powering the new-generation onboarding risk assessment model. Source: RiskClassification.RiskClassification.CustomerOnboardingRiskClassification on the RiskClassification production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/RiskClassification/Tables/RiskClassification.CustomerOnboardingRiskClassification.md).'
);

ALTER TABLE main.bi_db.bronze_riskclassification_riskclassification_customeronboardingriskclassification SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'RiskClassification',
    'source_schema' = 'RiskClassification',
    'source_table' = 'CustomerOnboardingRiskClassification',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_riskclassification_riskclassification_customeronboardingriskclassification ALTER COLUMN GCID COMMENT 'Global Customer ID. PK. One row per customer who has completed the onboarding risk assessment. Same customer identifier used across all eToro systems. (Tier 1 - upstream wiki, RiskClassification.RiskClassification.CustomerOnboardingRiskClassification)';
ALTER TABLE main.bi_db.bronze_riskclassification_riskclassification_customeronboardingriskclassification ALTER COLUMN Score COMMENT 'Weighted composite onboarding risk score. Continuous decimal value representing the sum of all parameter WeightedScores. Higher values indicate higher risk. Common values: 4.5-5.0 (low), 10.0-11.5 (medium), 13.0-14.5 (elevated). Not on the 0/50/100 scale of the legacy dbo.T_RiskClassification system. (Tier 1 - upstream wiki, RiskClassification.RiskClassification.CustomerOnboardingRiskClassification)';
ALTER TABLE main.bi_db.bronze_riskclassification_riskclassification_customeronboardingriskclassification ALTER COLUMN LastUpdate COMMENT 'Timestamp of the most recent score calculation. Set to CURRENT_TIMESTAMP on both INSERT and UPDATE by the Upsert procedure. Actively updated - recent records from today. (Tier 1 - upstream wiki, RiskClassification.RiskClassification.CustomerOnboardingRiskClassification)';
ALTER TABLE main.bi_db.bronze_riskclassification_riskclassification_customeronboardingriskclassification ALTER COLUMN Data COMMENT 'Complete JSON scoring breakdown. Contains a "Contributions" object with nested objects per parameter (CountryOfResidenceRank, PlaceOfBirthRank, CountryOfCitizenshipRank, etc.), each with Answer (input value), Score (parameter score), Weight (decimal weight), and WeightedScore (Score * Weight). Added via ALTER TABLE after initial table creation - a later enhancement to provide full scoring transparency. (Tier 1 - upstream wiki, RiskClassification.RiskClassification.CustomerOnboardingRiskClassification)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:38:55 UTC
-- Bronze deploy: RiskClassification batch 1
-- ====================
