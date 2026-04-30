-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.vw_WalletBalanaces
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.vw_WalletBalanaces.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_vw_walletbalanaces
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_vw_walletbalanaces (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_vw_walletbalanaces SET TBLPROPERTIES (
    'comment' = 'Denormalized view enriching wallet balance snapshots with blockchain address identifiers by joining WalletBalances to active customer wallets and their addresses, answering "what balance does this wallet address hold?" Source: WalletDB.Wallet.vw_WalletBalanaces on the WalletDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.vw_WalletBalanaces.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_vw_walletbalanaces SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'vw_WalletBalanaces',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_vw_walletbalanaces ALTER COLUMN Id COMMENT 'Balance snapshot surrogate key. From Wallet.WalletBalances.Id. (Tier 1 - upstream wiki, WalletDB.Wallet.vw_WalletBalanaces)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_vw_walletbalanaces ALTER COLUMN WalletAddressesId COMMENT 'The specific WalletAddresses record for this balance''s blockchain address. Resolved by JOIN WalletAddresses ON Address = CustomerWalletsView.Address. From Wallet.WalletAddresses.Id. (Tier 1 - upstream wiki, WalletDB.Wallet.vw_WalletBalanaces)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_vw_walletbalanaces ALTER COLUMN DateFrom COMMENT 'Start of balance snapshot validity window. From Wallet.WalletBalances.DateFrom. (Tier 1 - upstream wiki, WalletDB.Wallet.vw_WalletBalanaces)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_vw_walletbalanaces ALTER COLUMN DateTo COMMENT 'End of balance snapshot validity window. 3000-01-01 = current balance. From Wallet.WalletBalances.DateTo. (Tier 1 - upstream wiki, WalletDB.Wallet.vw_WalletBalanaces)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_vw_walletbalanaces ALTER COLUMN Balance COMMENT 'Confirmed crypto balance in native units. From Wallet.WalletBalances.Balance. (Tier 1 - upstream wiki, WalletDB.Wallet.vw_WalletBalanaces)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_vw_walletbalanaces ALTER COLUMN CryptoId COMMENT 'The cryptocurrency. From Wallet.WalletBalances.CryptoId. FK to Wallet.CryptoTypes.CryptoID. (Tier 1 - upstream wiki, WalletDB.Wallet.vw_WalletBalanaces)';

