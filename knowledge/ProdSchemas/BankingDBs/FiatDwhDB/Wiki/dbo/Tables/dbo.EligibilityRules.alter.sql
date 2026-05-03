-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.dbo.EligibilityRules
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.EligibilityRules.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules SET TBLPROPERTIES (
    'comment' = 'Configuration table defining which customer segments (by regulation, country, and club tier) are eligible for each fiat sub-program, with rollout percentages for gradual feature launches. Source: FiatDwhDB.dbo.EligibilityRules on the FiatDwhDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.EligibilityRules.md).'
);

ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'dbo',
    'source_table' = 'EligibilityRules',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate primary key. (Tier 1 - upstream wiki, FiatDwhDB.dbo.EligibilityRules)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules ALTER COLUMN FiatId COMMENT 'Fiat platform instance identifier. Groups rules by deployment context. (Tier 1 - upstream wiki, FiatDwhDB.dbo.EligibilityRules)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules ALTER COLUMN DesignatedRegulationId COMMENT 'Target regulatory jurisdiction. Determines which regulatory framework governs the sub-program for this rule. (Tier 1 - upstream wiki, FiatDwhDB.dbo.EligibilityRules)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules ALTER COLUMN CountryId COMMENT 'Country filter for the rule. Only customers in this country match. References an external country ID system. (Tier 1 - upstream wiki, FiatDwhDB.dbo.EligibilityRules)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules ALTER COLUMN ClubId COMMENT 'eToro club tier filter. Restricts eligibility to customers at a specific club/loyalty level. (Tier 1 - upstream wiki, FiatDwhDB.dbo.EligibilityRules)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules ALTER COLUMN SubProgramId COMMENT 'Target sub-program that eligible customers can access. FK to dbo.SubPrograms: 1=Card Premium UK, 2=Card Standard UK, ..., 16=IBAN Black DKK. See Sub-Program. (Tier 1 - upstream wiki, FiatDwhDB.dbo.EligibilityRules)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules ALTER COLUMN RolloutPercentage COMMENT 'Percentage of matching customers to enroll (0.0-100.0). Enables gradual rollout of new sub-programs. 100.0 = fully available. (Tier 1 - upstream wiki, FiatDwhDB.dbo.EligibilityRules)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules ALTER COLUMN RegulationId COMMENT 'Source regulatory jurisdiction of the customer. Used to match customers by their current regulation. (Tier 1 - upstream wiki, FiatDwhDB.dbo.EligibilityRules)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules ALTER COLUMN UpdateTime COMMENT 'Timestamp when this rule was last configured/deployed. (Tier 1 - upstream wiki, FiatDwhDB.dbo.EligibilityRules)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules ALTER COLUMN LastTimeOverride COMMENT 'Timestamp of the most recent bulk refresh/override of this rule. Updated when AddEligibilityRules runs. (Tier 1 - upstream wiki, FiatDwhDB.dbo.EligibilityRules)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules ALTER COLUMN Priority COMMENT 'Priority rank for rule evaluation. When multiple rules match, lowest number wins. Default 0 (highest priority). (Tier 1 - upstream wiki, FiatDwhDB.dbo.EligibilityRules)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:05:44 UTC
-- Bronze deploy: FiatDwhDB batch 1
-- ====================
