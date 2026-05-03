-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Dictionary.TravelRuleComplianceOptions
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.TravelRuleComplianceOptions.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_walletdb_dictionary_travelrulecomplianceoptions
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_walletdb_dictionary_travelrulecomplianceoptions (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_walletdb_dictionary_travelrulecomplianceoptions SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the compliance action options available for travel rule address verification - identical to AddressOwnershipProofOption but specific to the travel rule compliance context. Source: WalletDB.Dictionary.TravelRuleComplianceOptions on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.TravelRuleComplianceOptions.md).'
);

ALTER TABLE main.bi_db.bronze_walletdb_dictionary_travelrulecomplianceoptions SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'TravelRuleComplianceOptions',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_walletdb_dictionary_travelrulecomplianceoptions ALTER COLUMN Id COMMENT 'Unique identifier. Values: 0=None, 1=Blocked, 2=Declaration, 3=ProofOfOwnership. (Tier 1 - upstream wiki, WalletDB.Dictionary.TravelRuleComplianceOptions)';
ALTER TABLE main.bi_db.bronze_walletdb_dictionary_travelrulecomplianceoptions ALTER COLUMN Name COMMENT 'Compliance action label. (Tier 1 - upstream wiki, WalletDB.Dictionary.TravelRuleComplianceOptions)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
