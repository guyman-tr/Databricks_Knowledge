-- =============================================================================
-- Databricks ALTER Script: bronze WalletBalancesReportDB.Wallet.FinanceReports
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReports.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletbalancesreportdb_wallet_financereports
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletbalancesreportdb_wallet_financereports (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereports SET TBLPROPERTIES (
    'comment' = 'Legacy run-level audit table for the original crypto wallet balance reconciliation system, tracking when each reconciliation execution started and ended. Source: WalletBalancesReportDB.Wallet.FinanceReports on the WalletBalancesReportDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReports.md).'
);

ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereports SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletBalancesReportDB',
    'source_schema' = 'Wallet',
    'source_table' = 'FinanceReports',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereports ALTER COLUMN Id COMMENT 'Auto-incrementing primary key identifying each legacy reconciliation run. Referenced as ReportId by Wallet.FinanceReportsBalances and Wallet.FinanceReportsBalances_old (FK) to link child balance results back to their parent run. Gaps exist in the sequence (e.g., 2139 to 2141) suggesting occasional deleted or rolled-back runs. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReports)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereports ALTER COLUMN StartTime COMMENT 'UTC timestamp when the reconciliation run began. Set to GETUTCDATE() by Wallet.CreateNewReports at the start of the transaction. Originally ran at ~05:40 UTC (2019), later shifted to ~02:00 UTC. Used by Wallet.GetLastReport (ORDER BY Id DESC) to identify the most recent run. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReports)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereports ALTER COLUMN EndTime COMMENT 'Timestamp when the reconciliation run completed. NULL while the run is in progress or if the run failed/was abandoned. Set to GETDATE() by Wallet.UpdateReports. 68 rows (3.2%) have NULL EndTime, indicating incomplete runs over the 5-year history. Note: uses GETDATE() (local time) rather than GETUTCDATE(), creating a potential timezone inconsistency with StartTime. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReports)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:39:29 UTC
-- Bronze deploy: WalletBalancesReportDB batch 1
-- ====================
