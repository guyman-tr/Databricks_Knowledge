-- =============================================================================
-- Databricks ALTER Script: bronze WalletConversionDB.Dictionary.ConversionToFiatStatuses
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/Dictionary/Tables/Dictionary.ConversionToFiatStatuses.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_walletconversiondb_dictionary_conversiontofiatstatuses
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_walletconversiondb_dictionary_conversiontofiatstatuses (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_walletconversiondb_dictionary_conversiontofiatstatuses SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the four possible lifecycle states for crypto-to-fiat conversion operations, used as the FK target for C2F.ConversionStatuses.StatusId. Source: WalletConversionDB.Dictionary.ConversionToFiatStatuses on the WalletConversionDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/Dictionary/Tables/Dictionary.ConversionToFiatStatuses.md).'
);

ALTER TABLE main.bi_db.bronze_walletconversiondb_dictionary_conversiontofiatstatuses SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletConversionDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'ConversionToFiatStatuses',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_walletconversiondb_dictionary_conversiontofiatstatuses ALTER COLUMN Id COMMENT 'Primary key identifying the conversion status type. Referenced by C2F.ConversionStatuses.StatusId via explicit FK. Values: 1=Pending, 2=Failed, 3=Completed, 4=Rejected. See Conversion To Fiat Status. (Tier 1 - upstream wiki, WalletConversionDB.Dictionary.ConversionToFiatStatuses)';
ALTER TABLE main.bi_db.bronze_walletconversiondb_dictionary_conversiontofiatstatuses ALTER COLUMN Name COMMENT 'Human-readable label for the status. Maps 1:1 with Id values. Used in application code for display and logging. (Tier 1 - upstream wiki, WalletConversionDB.Dictionary.ConversionToFiatStatuses)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:40:44 UTC
-- Bronze deploy: WalletConversionDB batch 1
-- ====================
