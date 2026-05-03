-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.WalletPoolAttributes
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPoolAttributes.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_walletdb_wallet_walletpoolattributes
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_walletdb_wallet_walletpoolattributes (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_walletdb_wallet_walletpoolattributes SET TBLPROPERTIES (
    'comment' = 'Stores supplementary attributes for pool wallets, including reserved amounts and creation fees, providing additional configuration data beyond the core WalletPool record. Source: WalletDB.Wallet.WalletPoolAttributes on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPoolAttributes.md).'
);

ALTER TABLE main.bi_db.bronze_walletdb_wallet_walletpoolattributes SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'WalletPoolAttributes',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_walletdb_wallet_walletpoolattributes ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate primary key. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletPoolAttributes)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_walletpoolattributes ALTER COLUMN WalletPoolId COMMENT 'The pool wallet this attribute record belongs to. FK to Wallet.WalletPool.Id. Unique constraint - one attributes record per pool wallet. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletPoolAttributes)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_walletpoolattributes ALTER COLUMN ReservedAmount COMMENT 'Amount of crypto that must remain in the wallet as a blockchain-mandated minimum reserve. Cannot be withdrawn by the user. Common for XRP (1.2) and XLM (1.0). (Tier 1 - upstream wiki, WalletDB.Wallet.WalletPoolAttributes)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_walletpoolattributes ALTER COLUMN Occurred COMMENT 'Timestamp when this attributes record was created. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletPoolAttributes)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_walletpoolattributes ALTER COLUMN CreationFee COMMENT 'Fee paid to create this wallet on the blockchain. NULL for blockchains without on-chain wallet creation fees. Relevant for account-based blockchains like EOS. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletPoolAttributes)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
