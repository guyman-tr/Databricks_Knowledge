-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.RequestStatuses
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.RequestStatuses.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_requeststatuses
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_requeststatuses (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_requeststatuses SET TBLPROPERTIES (
    'comment' = 'Event-sourced status history for every wallet operation request, recording each state transition in the request lifecycle from creation through blockchain execution to completion or failure. Source: WalletDB.Wallet.RequestStatuses on the WalletDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.RequestStatuses.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_requeststatuses SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'RequestStatuses',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_requeststatuses ALTER COLUMN Id COMMENT 'Auto-incrementing event identifier. The highest Id for a given RequestId represents the most recent status. Used in composite unique index with RequestId for ordering. (Tier 1 - upstream wiki, WalletDB.Wallet.RequestStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_requeststatuses ALTER COLUMN RequestId COMMENT 'The request this status event belongs to. FK to Wallet.Requests.Id. Multiple status rows exist per request (event-sourced pattern). Indexed for efficient per-request lookups. (Tier 1 - upstream wiki, WalletDB.Wallet.RequestStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_requeststatuses ALTER COLUMN RequestStatusId COMMENT 'The status the request transitioned to: 0=Start, 1=Done, 2=Error, 3=ExecuterEnqueued, 4=ReadByExecuter, 5=TransactionSentToBlockChain, 6=TransactionConfirmed, 7=TransactionVerified, 8=AmlEnqueued, 9=ReadByAml, 16=TemporaryError, 25-27=ManualApproval flow, 28-42=extended statuses. See Request Status. FK to Dictionary.RequestStatuses. (Tier 1 - upstream wiki, WalletDB.Wallet.RequestStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_requeststatuses ALTER COLUMN Timestamp COMMENT 'When this status transition occurred. Used for SLA monitoring, processing time calculations, and chronological ordering. Indexed descending for recent-event queries. (Tier 1 - upstream wiki, WalletDB.Wallet.RequestStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_requeststatuses ALTER COLUMN DetailsJson COMMENT 'JSON payload with status-specific context. For ExecuterEnqueued: saga key, full request payload including amounts, addresses, AML/TravelRule data. For TransactionSentToBlockChain: blockchain transaction hash. For Done: correlation ID. NULL for simple transitions. (Tier 1 - upstream wiki, WalletDB.Wallet.RequestStatuses)';

