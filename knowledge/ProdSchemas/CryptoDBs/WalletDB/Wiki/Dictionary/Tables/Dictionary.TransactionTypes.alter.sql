-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Dictionary.TransactionTypes
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.TransactionTypes.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_dictionary_transactiontypes
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_dictionary_transactiontypes (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_dictionary_transactiontypes SET TBLPROPERTIES (
    'comment' = 'Lookup table classifying all types of blockchain transactions in the wallet system, distinguishing between customer withdrawals, funding operations, conversions, payments, staking, and other crypto movements. Source: WalletDB.Dictionary.TransactionTypes on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.TransactionTypes.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_dictionary_transactiontypes SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'TransactionTypes',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_dictionary_transactiontypes ALTER COLUMN Id COMMENT 'Unique identifier. Values: 0=Redeem, 1=CustomerMoneyOut, 2=AmlMoneyBack, 4=Funding, 5=ConversionMoneyIn, 6=ConversionMoneyOut, 7=Payment, 8=RedeemAsic, 9=Staking, 10=BlockChainActivation, 11=OmnibusMoneyOut, 12=ConversionToFiat, 13=ManualUserMoneyOut, 14=StakeAndRewardsRefund, 15=CustomerMoneyBack. Gap at Id=3. FK target for SentTransactions, ReceivedTransactions, Redemptions, LimitationsDefinitions, LimitExceeds. (Tier 1 - upstream wiki, WalletDB.Dictionary.TransactionTypes)';
ALTER TABLE main.wallet.bronze_walletdb_dictionary_transactiontypes ALTER COLUMN Name COMMENT 'PascalCase type label. Used across views, stored procedures, and functions for transaction categorization and reporting. (Tier 1 - upstream wiki, WalletDB.Dictionary.TransactionTypes)';

