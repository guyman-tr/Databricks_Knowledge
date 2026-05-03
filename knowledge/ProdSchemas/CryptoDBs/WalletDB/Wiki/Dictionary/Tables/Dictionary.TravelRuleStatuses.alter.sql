-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Dictionary.TravelRuleStatuses
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.TravelRuleStatuses.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_walletdb_dictionary_travelrulestatuses
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_walletdb_dictionary_travelrulestatuses (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_walletdb_dictionary_travelrulestatuses SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the lifecycle statuses for travel rule compliance workflows on cryptocurrency transactions. Source: WalletDB.Dictionary.TravelRuleStatuses on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.TravelRuleStatuses.md).'
);

ALTER TABLE main.bi_db.bronze_walletdb_dictionary_travelrulestatuses SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'TravelRuleStatuses',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_walletdb_dictionary_travelrulestatuses ALTER COLUMN Id COMMENT 'Unique identifier. Values: 0=PendingManualApproval, 1=Approved, 2=Canceled, 3=PendingMissingInformation, 4=MissingInformationAdded, 5=MustCancel. FK target for Wallet.TransactionTravelRuleStatuses. (Tier 1 - upstream wiki, WalletDB.Dictionary.TravelRuleStatuses)';
ALTER TABLE main.bi_db.bronze_walletdb_dictionary_travelrulestatuses ALTER COLUMN Name COMMENT 'Status label. Unique constraint ensures no duplicates. Used in compliance dashboards and travel rule workflow UIs. (Tier 1 - upstream wiki, WalletDB.Dictionary.TravelRuleStatuses)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
