-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.Hourly_WalletAllocations
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- Hourly_WalletAllocations provides a rolling 7-day extract of customer wallet allocation events - each row representing a wallet that was assigned to a customer (Occurred within the last 7 days), along with the wallet''s blockchain address, crypto type, status, and provider details. It is one of six tables rebuilt each hour by SP_EXW_Hourly. Unlike the other five Hourly tables (which are aggregates), Hourly_WalletAllocations is a **row-level** extract. Each row corresponds to a specific wallet allocation: one customer (GCID) × one crypto (CryptoID) × one blockchain address. This granularity enables dashboards to answer "which customers received wallets this week?" and "what''s the current address for a recently allocated wallet?" **Scope**: Wallets where `CustomerWalletsView.Occurred >= last 7 days`. In practice only WalletTypeId=5 (Customer wallets) appear in any 7-day window, since syst

