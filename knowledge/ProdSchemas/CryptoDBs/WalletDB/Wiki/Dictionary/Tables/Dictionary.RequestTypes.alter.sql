-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Dictionary.RequestTypes
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.RequestTypes.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_dictionary_requesttypes
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_dictionary_requesttypes (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_dictionary_requesttypes SET TBLPROPERTIES (
    'comment' = 'Lookup table classifying the types of wallet operations that can be requested, from wallet creation to staking to crypto-to-position conversions. Source: WalletDB.Dictionary.RequestTypes on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.RequestTypes.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_dictionary_requesttypes SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'RequestTypes',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_dictionary_requesttypes ALTER COLUMN Id COMMENT 'Unique identifier for the request type. Values: 0=CreateWallet, 1=SendTransaction, 2=InitiatePayment, 3=Redeem, 4=Conversion, 5=Funding, 6=Staking, 7=ConversionToFiat, 8=ReceiveTransaction, 9=ConversionToPosition. FK target for Wallet.Requests.RequestTypeId. (Tier 1 - upstream wiki, WalletDB.Dictionary.RequestTypes)';
ALTER TABLE main.wallet.bronze_walletdb_dictionary_requesttypes ALTER COLUMN Name COMMENT 'PascalCase label mapping to application-layer enum. Determines which processing pipeline handles the request. (Tier 1 - upstream wiki, WalletDB.Dictionary.RequestTypes)';

