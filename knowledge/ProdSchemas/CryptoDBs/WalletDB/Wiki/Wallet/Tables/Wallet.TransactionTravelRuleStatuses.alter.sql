-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.TransactionTravelRuleStatuses
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleStatuses.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_walletdb_wallet_transactiontravelrulestatuses
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_walletdb_wallet_transactiontravelrulestatuses (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_walletdb_wallet_transactiontravelrulestatuses SET TBLPROPERTIES (
    'comment' = 'Event-sourced status history for Travel Rule compliance workflows, tracking each step of the beneficiary information collection and approval process. Source: WalletDB.Wallet.TransactionTravelRuleStatuses on the WalletDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleStatuses.md).'
);

ALTER TABLE main.bi_db.bronze_walletdb_wallet_transactiontravelrulestatuses SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'TransactionTravelRuleStatuses',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_walletdb_wallet_transactiontravelrulestatuses ALTER COLUMN Id COMMENT 'Auto-incrementing event identifier. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionTravelRuleStatuses)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_transactiontravelrulestatuses ALTER COLUMN TransactionTravelRuleInformationId COMMENT 'Parent Travel Rule record. FK to Wallet.TransactionTravelRuleInformation.Id. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionTravelRuleStatuses)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_transactiontravelrulestatuses ALTER COLUMN TravelRuleStatusId COMMENT 'Status: 0=PendingManualApproval, 1=Approved, 2=Canceled, 3=PendingMissingInformation, 4=MissingInformationAdded, 5=MustCancel. See Travel Rule Status. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionTravelRuleStatuses)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_transactiontravelrulestatuses ALTER COLUMN Occurred COMMENT 'Timestamp of status transition. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionTravelRuleStatuses)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_transactiontravelrulestatuses ALTER COLUMN DetailsJson COMMENT 'JSON with status-specific details (approval notes, missing info details). (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionTravelRuleStatuses)';

