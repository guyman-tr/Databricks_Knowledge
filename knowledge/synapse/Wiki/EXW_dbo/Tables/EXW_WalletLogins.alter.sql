-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_WalletLogins
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- EXW_dbo.EXW_WalletLogins tracks login events for eToro wallet users — customers who have an active crypto wallet (HasWallet=1 in DWH_dbo.Dim_Customer). Each row represents one login session by one wallet user on the eToro platform. **What makes it wallet-specific**: The table is not a general login log. It filters the broader Fact_CustomerAction login stream to only wallet users via the `Dim_Customer.HasWallet=1` join. This makes it suitable for wallet product engagement analysis — how often wallet customers log in, session patterns, and cross-referencing with wallet transaction activity. **Application context**: `ApplicationIdentifier` is hardcoded as `''retoro''` — identifying the primary eToro wallet/crypto application. `EnvironmentDetails` is always NULL (the field exists for potential platform/browser context but is not populated in this pipeline). **Refresh pattern**: SP_WalletLogi

