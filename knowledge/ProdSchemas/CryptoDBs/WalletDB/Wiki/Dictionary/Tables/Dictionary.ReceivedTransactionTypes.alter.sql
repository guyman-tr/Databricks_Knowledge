-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Dictionary.ReceivedTransactionTypes
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.ReceivedTransactionTypes.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_dictionary_receivedtransactiontypes
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_dictionary_receivedtransactiontypes (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_dictionary_receivedtransactiontypes SET TBLPROPERTIES (
    'comment' = 'Lookup table classifying the types of incoming cryptocurrency transactions received by wallets on the platform. Source: WalletDB.Dictionary.ReceivedTransactionTypes on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.ReceivedTransactionTypes.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_dictionary_receivedtransactiontypes SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'ReceivedTransactionTypes',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_dictionary_receivedtransactiontypes ALTER COLUMN Id COMMENT 'Unique identifier for the received transaction type. Values: 1=MoneyIn, 2=Redeem, 3=Funding, 4=ConversionFromUser, 5=ConversionFromEtoro, 6=Payment, 7=RedeemAsic, 8=StakeAndRewardsRefund. FK target for Wallet.ReceivedTransactions.ReceivedTransactionTypeId. (Tier 1 - upstream wiki, WalletDB.Dictionary.ReceivedTransactionTypes)';
ALTER TABLE main.wallet.bronze_walletdb_dictionary_receivedtransactiontypes ALTER COLUMN Name COMMENT 'Label for the transaction type. Used in transaction reporting, compliance dashboards, and financial reconciliation. (Tier 1 - upstream wiki, WalletDB.Dictionary.ReceivedTransactionTypes)';

