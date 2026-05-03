-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.PaymentTransactions
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_paymenttransactions
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_paymenttransactions (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_paymenttransactions SET TBLPROPERTIES (
    'comment' = 'Stores execution details for fiat payment transactions, recording the exchange rate, destination address, amounts, and fee breakdown for the crypto leg of a fiat-to-crypto purchase. Source: WalletDB.Wallet.PaymentTransactions on the WalletDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_paymenttransactions SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'PaymentTransactions',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_paymenttransactions ALTER COLUMN Id COMMENT 'Auto-incrementing primary key. (Tier 1 - upstream wiki, WalletDB.Wallet.PaymentTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_paymenttransactions ALTER COLUMN PaymentId COMMENT 'Parent payment. FK to Wallet.Payments.Id. Unique constraint - one transaction record per payment. (Tier 1 - upstream wiki, WalletDB.Wallet.PaymentTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_paymenttransactions ALTER COLUMN ExchangeRate COMMENT 'Fiat-to-crypto exchange rate at execution time. Used to convert the fiat Amount to crypto. (Tier 1 - upstream wiki, WalletDB.Wallet.PaymentTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_paymenttransactions ALTER COLUMN ToAddress COMMENT 'Blockchain destination address for the purchased crypto. (Tier 1 - upstream wiki, WalletDB.Wallet.PaymentTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_paymenttransactions ALTER COLUMN Amount COMMENT 'Amount of crypto being purchased/transferred. (Tier 1 - upstream wiki, WalletDB.Wallet.PaymentTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_paymenttransactions ALTER COLUMN EtoroFeePercentage COMMENT 'eToro service fee as a percentage. (Tier 1 - upstream wiki, WalletDB.Wallet.PaymentTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_paymenttransactions ALTER COLUMN EtoroFeeCalculated COMMENT 'Calculated eToro fee in crypto units. (Tier 1 - upstream wiki, WalletDB.Wallet.PaymentTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_paymenttransactions ALTER COLUMN ProviderFeePercentage COMMENT 'Payment provider''s fee as a percentage. (Tier 1 - upstream wiki, WalletDB.Wallet.PaymentTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_paymenttransactions ALTER COLUMN ProviderFeeCalculated COMMENT 'Calculated provider fee in crypto units. (Tier 1 - upstream wiki, WalletDB.Wallet.PaymentTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_paymenttransactions ALTER COLUMN EstimatedBlockChainFee COMMENT 'Estimated blockchain network fee. (Tier 1 - upstream wiki, WalletDB.Wallet.PaymentTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_paymenttransactions ALTER COLUMN Occurred COMMENT 'Timestamp of record creation. (Tier 1 - upstream wiki, WalletDB.Wallet.PaymentTransactions)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
