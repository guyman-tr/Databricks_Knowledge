-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_FactBalance
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- This is the primary Wallet balance fact table. It stores a daily snapshot of every Wallet user''s crypto holdings across all crypto assets they hold. Each row represents one user (identified by GCID) holding one crypto asset (CryptoId/CryptoName) as of the snapshot date (FullDate), with Balance in native crypto units and BalanceUSD as the USD equivalent at that day''s price. At 2.37 billion rows, this is the largest table in EXW_dbo. It grows by approximately 700,000 rows per day (one row per active Wallet × crypto pair). The table is managed by a daily DELETE + INSERT pattern: SP_EXW_FactBalance deletes all rows for the target date and re-inserts from the WalletDB balance source, ensuring each day''s snapshot is authoritative. The balance source is the CopyFromLake pipeline view of WalletDB''s WalletBalances table, filtered by DateFrom/DateTo window. The scope is EXW_Wallet.CustomerWall

