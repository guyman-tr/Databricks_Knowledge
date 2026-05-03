-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Dictionary.PaymentStatuses
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.PaymentStatuses.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_dictionary_paymentstatuses
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_dictionary_paymentstatuses (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_dictionary_paymentstatuses SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the lifecycle statuses for fiat payment operations processed through the wallet system''s payment providers. Source: WalletDB.Dictionary.PaymentStatuses on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.PaymentStatuses.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_dictionary_paymentstatuses SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'PaymentStatuses',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_dictionary_paymentstatuses ALTER COLUMN Id COMMENT 'Unique identifier for the payment status. Values: 1=PendingProvider, 2=InitiateStarted, 3=DocumentCompleted, 4=InitiateCompleted, 5=InitiateFailed, 6=TransferCompleted, 7=PendingTransaction, 8=Failed, 9=Completed, 10=InternalError, 11=ProviderSubmitted. FK target for Wallet.PaymentStatuses. (Tier 1 - upstream wiki, WalletDB.Dictionary.PaymentStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_dictionary_paymentstatuses ALTER COLUMN Name COMMENT 'Status label used in payment tracking UIs, reconciliation reports, and provider integration logs. (Tier 1 - upstream wiki, WalletDB.Dictionary.PaymentStatuses)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
