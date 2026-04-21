-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.Hourly_WalletInventory
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Hourly_WalletInventory provides a current-state snapshot of eToro Wallet Exchange''s pre-provisioned blockchain wallet pool, broken down by cryptocurrency and pool status. It is one of six tables rebuilt each hour by SP_EXW_Hourly and is the primary operational KPI source for wallet inventory management — answering questions like "how many free ETH wallets do we have?", "how fast are we allocating wallets today?", and "are we running low on inventory for a specific crypto?" **The pre-provisioned pool model**: eToro pre-creates blockchain wallets in advance (via BitGo or CUG custody providers) and stores them in WalletDB.Wallet.WalletPool. When a customer needs a wallet, a free pool wallet is assigned (allocated) to them instantly, avoiding on-chain creation latency. With ~2.47M pool entries, this represents a large provisioning buffer. **Scope**: Native coin wallets only. ERC-20 token wa

