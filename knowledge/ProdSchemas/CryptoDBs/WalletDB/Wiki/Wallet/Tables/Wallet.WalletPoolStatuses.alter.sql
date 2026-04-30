-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.WalletPoolStatuses
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPoolStatuses.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_walletpoolstatuses
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_walletpoolstatuses (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletpoolstatuses SET TBLPROPERTIES (
    'comment' = 'Event-sourced status history for pool wallets, recording each lifecycle transition from creation through verification, funding, and assignment to a customer. Source: WalletDB.Wallet.WalletPoolStatuses on the WalletDB production database, ingested via the Generic Pipeline (Append strategy, 120-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPoolStatuses.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_walletpoolstatuses SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'WalletPoolStatuses',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '120'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletpoolstatuses ALTER COLUMN Id COMMENT 'Auto-incrementing event identifier. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletPoolStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletpoolstatuses ALTER COLUMN WalletPoolId COMMENT 'The pool wallet this status event belongs to. FK to Wallet.WalletPool.Id. Multiple status rows per wallet (event-sourced). (Tier 1 - upstream wiki, WalletDB.Wallet.WalletPoolStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletpoolstatuses ALTER COLUMN WalletPoolStatusId COMMENT 'The lifecycle status: 1=Pending, 2=Verified, 3=Failed, 4=FundingInitiated, 5=FundingSent, 6=FundingVerified, 7=FundingFailed, 10=Timeout, 11=VerifiedForAssign. See Wallet Pool Status. FK to Dictionary.WalletPoolStatuses. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletPoolStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletpoolstatuses ALTER COLUMN Occurred COMMENT 'Timestamp of this status transition. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletPoolStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletpoolstatuses ALTER COLUMN PromotionTagId COMMENT 'Links to a promotional campaign if this wallet is part of a promotion. NULL for standard wallets. FK to Wallet.PromotionTags.Id. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletPoolStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletpoolstatuses ALTER COLUMN CorrelationId COMMENT 'Links this status event to the parent request that triggered the transition. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletPoolStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletpoolstatuses ALTER COLUMN Processed COMMENT 'Whether downstream systems have consumed this status event: 0=pending processing, 1=processed. Used by the assignment system to find wallets ready for customer assignment. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletPoolStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletpoolstatuses ALTER COLUMN CryptoId COMMENT 'The cryptocurrency this pool wallet is for. FK to Wallet.CryptoTypes.CryptoID. Denormalized from WalletPool for efficient status-based filtering. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletPoolStatuses)';

