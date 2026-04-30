-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.CorrelatedRequests
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CorrelatedRequests.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_walletdb_wallet_correlatedrequests
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_walletdb_wallet_correlatedrequests (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_walletdb_wallet_correlatedrequests SET TBLPROPERTIES (
    'comment' = 'Links causally related wallet requests (parent-child), tracking when one operation triggers another - primarily used for bounceback scenarios where an incoming transaction triggers a return send. Source: WalletDB.Wallet.CorrelatedRequests on the WalletDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CorrelatedRequests.md).'
);

ALTER TABLE main.bi_db.bronze_walletdb_wallet_correlatedrequests SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'CorrelatedRequests',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_walletdb_wallet_correlatedrequests ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate primary key. (Tier 1 - upstream wiki, WalletDB.Wallet.CorrelatedRequests)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_correlatedrequests ALTER COLUMN CorrelatedRequestsTypeId COMMENT 'Type of correlation: 1=Bounceback (only type currently used). See Correlated Request Type. Implicit FK to Dictionary.CorrelatedRequestsTypes. (Tier 1 - upstream wiki, WalletDB.Wallet.CorrelatedRequests)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_correlatedrequests ALTER COLUMN ParentRequestCorrelationId COMMENT 'CorrelationId of the original (parent) request that triggered the child. For bouncebacks, this is the received transaction''s CorrelationId from Wallet.Requests. (Tier 1 - upstream wiki, WalletDB.Wallet.CorrelatedRequests)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_correlatedrequests ALTER COLUMN ChildRequestCorrelationId COMMENT 'CorrelationId of the triggered (child) request. For bouncebacks, this is the send-back transaction''s CorrelationId from Wallet.Requests. (Tier 1 - upstream wiki, WalletDB.Wallet.CorrelatedRequests)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_correlatedrequests ALTER COLUMN Created COMMENT 'Timestamp when this correlation was established. (Tier 1 - upstream wiki, WalletDB.Wallet.CorrelatedRequests)';

