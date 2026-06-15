-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_riskclassification_riskclassification_customeronboardingriskclassification  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/RiskClassification/Tables/RiskClassification.CustomerOnboardingRiskClassification.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_riskclassification_riskclassification_customeronboardingriskclassification ALTER COLUMN GCID COMMENT 'Global Customer ID. PK. One row per customer who has completed the onboarding risk assessment. Same customer identifier used across all eToro systems.';
ALTER TABLE main.bi_db.bronze_riskclassification_riskclassification_customeronboardingriskclassification ALTER COLUMN Score COMMENT 'Weighted composite onboarding risk score. Continuous decimal value representing the sum of all parameter WeightedScores. Higher values indicate higher risk. Common values: 4.5-5.0 (low), 10.0-11.5 (medium), 13.0-14.5 (elevated). Not on the 0/50/100 scale of the legacy dbo.T_RiskClassification system.';
ALTER TABLE main.bi_db.bronze_riskclassification_riskclassification_customeronboardingriskclassification ALTER COLUMN LastUpdate COMMENT 'Timestamp of the most recent score calculation. Set to CURRENT_TIMESTAMP on both INSERT and UPDATE by the Upsert procedure. Actively updated - recent records from today.';
ALTER TABLE main.bi_db.bronze_riskclassification_riskclassification_customeronboardingriskclassification ALTER COLUMN Data COMMENT 'Complete JSON scoring breakdown. Contains a "Contributions" object with nested objects per parameter (CountryOfResidenceRank, PlaceOfBirthRank, CountryOfCitizenshipRank, etc.), each with Answer (input value), Score (parameter score), Weight (decimal weight), and WeightedScore (Score * Weight). Added via ALTER TABLE after initial table creation - a later enhancement to provide full scoring transparency.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:29:14 UTC
-- Statements: 4/4 succeeded
-- ====================
