-- =============================================================================
-- Databricks ALTER Script: bronze WalletBalancesReportDB.Wallet.FinanceReportRuns
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRuns.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletbalancesreportdb_wallet_financereportruns
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletbalancesreportdb_wallet_financereportruns (business_group=wallet) ----
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportruns SET TBLPROPERTIES (
    'comment' = 'Tracks individual executions of the crypto wallet balance reconciliation process, recording when each run started, ended, and what parameters controlled its behavior. Source: WalletBalancesReportDB.Wallet.FinanceReportRuns on the WalletBalancesReportDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRuns.md).'
);

ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportruns SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletBalancesReportDB',
    'source_schema' = 'Wallet',
    'source_table' = 'FinanceReportRuns',
    'business_group' = 'wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportruns ALTER COLUMN Id COMMENT 'Auto-incrementing primary key identifying each reconciliation run. Referenced as ReportId by Wallet.FinanceReportRecords (FK) to link individual wallet-crypto results back to their parent run. Also read by Wallet.UpdateReportRecords to extract Parameters JSON. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportRuns)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportruns ALTER COLUMN StartTime COMMENT 'UTC timestamp when the reconciliation run began. Set to GETUTCDATE() by Wallet.CreateNewReportRun at the start of the transaction. Used by Wallet.GetLastReportRun (ORDER BY Id DESC) to identify the most recent run. Indexed (IX_FinanceReportRuns__StartTime DESC) for efficient latest-run lookups. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportRuns)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportruns ALTER COLUMN EndTime COMMENT 'Timestamp when the reconciliation run completed. NULL while the run is in progress; set to GETDATE() by Wallet.UpdateReportRun after all reconciliation results have been processed. In production, all 621 historical runs have EndTime populated -- no abandoned runs exist. Note: uses GETDATE() (local time) rather than GETUTCDATE(), creating a potential timezone inconsistency with StartTime. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportRuns)';
ALTER TABLE main.wallet.bronze_walletbalancesreportdb_wallet_financereportruns ALTER COLUMN Parameters COMMENT 'JSON-serialized execution parameters that controlled this run''s behavior. Structure: {"Threshold": decimal, "ProcessAllRecords": bool, "RetryDays": int}. Threshold = balance difference tolerance for flagging discrepancies; ProcessAllRecords = whether to recheck all wallets or only changed ones; RetryDays = lookback window for retrying discrepant records. Read at runtime by Wallet.UpdateReportRecords to determine pruning behavior. All production runs use identical parameters: Threshold=0, ProcessAllRecords=false, RetryDays=1. (Tier 1 - upstream wiki, WalletBalancesReportDB.Wallet.FinanceReportRuns)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:39:29 UTC
-- Bronze deploy: WalletBalancesReportDB batch 1
-- ====================
