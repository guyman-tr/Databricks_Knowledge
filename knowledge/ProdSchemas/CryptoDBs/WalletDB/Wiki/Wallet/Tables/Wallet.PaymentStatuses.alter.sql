-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.PaymentStatuses
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentStatuses.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_paymentstatuses
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_paymentstatuses (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_paymentstatuses SET TBLPROPERTIES (
    'comment' = 'Event-sourced status history for fiat payment operations, tracking each step from provider initiation through document handling to final settlement or failure. Source: WalletDB.Wallet.PaymentStatuses on the WalletDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentStatuses.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_paymentstatuses SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'PaymentStatuses',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_paymentstatuses ALTER COLUMN Id COMMENT 'Auto-incrementing event identifier. (Tier 1 - upstream wiki, WalletDB.Wallet.PaymentStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_paymentstatuses ALTER COLUMN PaymentId COMMENT 'Parent payment. FK to Wallet.Payments.Id. (Tier 1 - upstream wiki, WalletDB.Wallet.PaymentStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_paymentstatuses ALTER COLUMN PaymentStatusId COMMENT 'Status: 1=PendingProvider through 11=ProviderSubmitted. See Payment Status. FK to Dictionary.PaymentStatuses. (Tier 1 - upstream wiki, WalletDB.Wallet.PaymentStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_paymentstatuses ALTER COLUMN DetailsJson COMMENT 'JSON with status-specific details (provider responses, error info). (Tier 1 - upstream wiki, WalletDB.Wallet.PaymentStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_paymentstatuses ALTER COLUMN Occurred COMMENT 'Timestamp of this status transition. (Tier 1 - upstream wiki, WalletDB.Wallet.PaymentStatuses)';

