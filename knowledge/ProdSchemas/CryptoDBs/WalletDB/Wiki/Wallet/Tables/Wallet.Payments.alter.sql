-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.Payments
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Payments.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_payments
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_payments (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_payments SET TBLPROPERTIES (
    'comment' = 'Records fiat payment operations linked to crypto wallets, tracking fiat-to-crypto purchases where users buy cryptocurrency using fiat currency through a payment provider. Source: WalletDB.Wallet.Payments on the WalletDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Payments.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_payments SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'Payments',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_payments ALTER COLUMN Id COMMENT 'Auto-incrementing primary key. FK target for Wallet.PaymentStatuses, Wallet.PaymentTransactions, and Wallet.Chargebacks. (Tier 1 - upstream wiki, WalletDB.Wallet.Payments)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_payments ALTER COLUMN WalletId COMMENT 'The customer''s wallet receiving the purchased crypto. FK to Wallet.Wallets.WalletId. (Tier 1 - upstream wiki, WalletDB.Wallet.Payments)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_payments ALTER COLUMN ProviderPaymentId COMMENT 'Payment identifier assigned by the external payment provider. Used for reconciliation and provider API calls. (Tier 1 - upstream wiki, WalletDB.Wallet.Payments)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_payments ALTER COLUMN Amount COMMENT 'Fiat amount of the payment. Denominated in the currency specified by FiatId (e.g., 125 EUR). (Tier 1 - upstream wiki, WalletDB.Wallet.Payments)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_payments ALTER COLUMN FiatId COMMENT 'The fiat currency used for payment: 1=USD, 2=EUR, 3=GBP, 5=AUD. FK to Wallet.FiatTypes.Id. (Tier 1 - upstream wiki, WalletDB.Wallet.Payments)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_payments ALTER COLUMN CorrelationId COMMENT 'Links to the parent request in Wallet.Requests.CorrelationId. (Tier 1 - upstream wiki, WalletDB.Wallet.Payments)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_payments ALTER COLUMN Occurred COMMENT 'Timestamp when the payment was initiated. (Tier 1 - upstream wiki, WalletDB.Wallet.Payments)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_payments ALTER COLUMN CryptoId COMMENT 'The cryptocurrency being purchased. FK to Wallet.CryptoTypes.CryptoID. (Tier 1 - upstream wiki, WalletDB.Wallet.Payments)';

