-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Dictionary.TravelRuleAddressType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.TravelRuleAddressType.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_walletdb_dictionary_travelruleaddresstype
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_walletdb_dictionary_travelruleaddresstype (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_walletdb_dictionary_travelruleaddresstype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining whether a cryptocurrency address is private (self-hosted) or hosted by an exchange/custodian, as required by travel rule compliance. Source: WalletDB.Dictionary.TravelRuleAddressType on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.TravelRuleAddressType.md).'
);

ALTER TABLE main.bi_db.bronze_walletdb_dictionary_travelruleaddresstype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'TravelRuleAddressType',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_walletdb_dictionary_travelruleaddresstype ALTER COLUMN Id COMMENT 'Unique identifier. Values: 1=Private, 2=Hosted. FK target for Wallet.TravelRuleAddresses. (Tier 1 - upstream wiki, WalletDB.Dictionary.TravelRuleAddressType)';
ALTER TABLE main.bi_db.bronze_walletdb_dictionary_travelruleaddresstype ALTER COLUMN Name COMMENT 'Address hosting type label. (Tier 1 - upstream wiki, WalletDB.Dictionary.TravelRuleAddressType)';
ALTER TABLE main.bi_db.bronze_walletdb_dictionary_travelruleaddresstype ALTER COLUMN Created COMMENT 'Registration timestamp. Both types created 2022-07-24 when travel rule support was implemented. (Tier 1 - upstream wiki, WalletDB.Dictionary.TravelRuleAddressType)';

