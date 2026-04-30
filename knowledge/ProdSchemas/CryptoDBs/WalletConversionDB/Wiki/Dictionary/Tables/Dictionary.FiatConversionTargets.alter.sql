-- =============================================================================
-- Databricks ALTER Script: bronze WalletConversionDB.Dictionary.FiatConversionTargets
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/Dictionary/Tables/Dictionary.FiatConversionTargets.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_walletconversiondb_dictionary_fiatconversiontargets
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_walletconversiondb_dictionary_fiatconversiontargets (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_walletconversiondb_dictionary_fiatconversiontargets SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the three possible fiat destination types for crypto-to-fiat conversions, determining where the converted fiat proceeds are routed after the crypto sell operation. Source: WalletConversionDB.Dictionary.FiatConversionTargets on the WalletConversionDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/Dictionary/Tables/Dictionary.FiatConversionTargets.md).'
);

ALTER TABLE main.bi_db.bronze_walletconversiondb_dictionary_fiatconversiontargets SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletConversionDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'FiatConversionTargets',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_walletconversiondb_dictionary_fiatconversiontargets ALTER COLUMN Id COMMENT 'Primary key identifying the fiat destination type. Referenced by C2F.Conversions.TargetPlatformId via explicit FK. Values: 1=IbanAccount, 2=EtoroPlatform, 3=EtoroPosition. See Fiat Conversion Target. (Tier 1 - upstream wiki, WalletConversionDB.Dictionary.FiatConversionTargets)';
ALTER TABLE main.bi_db.bronze_walletconversiondb_dictionary_fiatconversiontargets ALTER COLUMN Name COMMENT 'Human-readable label for the target platform. Maps 1:1 with Id values. (Tier 1 - upstream wiki, WalletConversionDB.Dictionary.FiatConversionTargets)';

