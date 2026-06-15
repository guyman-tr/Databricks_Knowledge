-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.EligibilityRules.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate primary key.';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules ALTER COLUMN FiatId COMMENT 'Fiat platform instance identifier. Groups rules by deployment context.';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules ALTER COLUMN DesignatedRegulationId COMMENT 'Target regulatory jurisdiction. Determines which regulatory framework governs the sub-program for this rule.';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules ALTER COLUMN CountryId COMMENT 'Country filter for the rule. Only customers in this country match. References an external country ID system.';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules ALTER COLUMN ClubId COMMENT 'eToro club tier filter. Restricts eligibility to customers at a specific club/loyalty level.';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules ALTER COLUMN SubProgramId COMMENT 'Target sub-program that eligible customers can access. FK to dbo.SubPrograms: 1=Card Premium UK, 2=Card Standard UK, ..., 16=IBAN Black DKK. See [Sub-Program](../../_glossary.md#sub-program).';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules ALTER COLUMN RolloutPercentage COMMENT 'Percentage of matching customers to enroll (0.0-100.0). Enables gradual rollout of new sub-programs. 100.0 = fully available.';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules ALTER COLUMN RegulationId COMMENT 'Source regulatory jurisdiction of the customer. Used to match customers by their current regulation.';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules ALTER COLUMN UpdateTime COMMENT 'Timestamp when this rule was last configured/deployed.';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules ALTER COLUMN LastTimeOverride COMMENT 'Timestamp of the most recent bulk refresh/override of this rule. Updated when AddEligibilityRules runs.';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules ALTER COLUMN Priority COMMENT 'Priority rank for rule evaluation. When multiple rules match, lowest number wins. Default 0 (highest priority).';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:26:58 UTC
-- Statements: 11/11 succeeded
-- ====================
