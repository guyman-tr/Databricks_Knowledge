-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.WalletBalances
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletBalances.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_walletbalances
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_walletbalances (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletbalances SET TBLPROPERTIES (
    'comment' = 'Time-series balance snapshots for each wallet-crypto combination, recording the confirmed balance at regular intervals for historical tracking, reporting, and reconciliation. Source: WalletDB.Wallet.WalletBalances on the WalletDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletBalances.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_walletbalances SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'WalletBalances',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletbalances ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate key for row identification. Not used as FK by other tables - the composite PK is the business key. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletBalances)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletbalances ALTER COLUMN WalletId COMMENT 'The wallet this balance belongs to. Part of composite clustered PK. Implicit reference to Wallet.WalletPool.WalletId. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletBalances)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletbalances ALTER COLUMN CryptoId COMMENT 'The cryptocurrency this balance measures. FK to Wallet.CryptoTypes.CryptoID. Part of composite clustered PK. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletBalances)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletbalances ALTER COLUMN DateFrom COMMENT 'Start of this balance snapshot''s validity window. Set to the time the balance was confirmed by the provider. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletBalances)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletbalances ALTER COLUMN DateTo COMMENT 'End of this balance snapshot''s validity window. 3000-01-01 = current/open balance. Updated to the next snapshot''s DateFrom when a new balance is recorded. Part of composite clustered PK. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletBalances)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletbalances ALTER COLUMN Balance COMMENT 'The confirmed crypto balance in native units (e.g., BTC, ETH). NULL is possible but rare - indicates the balance could not be determined. Uses high-precision decimal for sub-unit accuracy. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletBalances)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletbalances ALTER COLUMN Occurred COMMENT 'Timestamp when this balance record was created/updated in the database. May differ from DateFrom if there was processing delay. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletBalances)';

