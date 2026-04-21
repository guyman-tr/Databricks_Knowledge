-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.Staking_BI_Version_ETH_Transactions
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- EXW_dbo.Staking_BI_Version_ETH_Transactions is the transaction-level detail table for the eToro ETH staking program, providing the position-by-position breakdown that underpins the monthly reward summaries in `Staking_BI_Version_WalletUserRewards`. **Relationship to summary table**: While `Staking_BI_Version_WalletUserRewards` has one row per wallet per reward month (user-month grain), this table has one row per staking operation (transaction grain). Multiple rows here can aggregate to one row in the summary table — the `EligibleTransactions` column in the summary counts how many rows this table contributes per user-month. **What each row represents**: A single ETH staking transfer — the delegation of a specific ETH amount from a user''s wallet to eToro''s staking pool (address `0xCB2A66540680c344bab5f818d68c3e4B9D57363B`). The row includes the initiation timestamp (`Staking_DateTime`), 

