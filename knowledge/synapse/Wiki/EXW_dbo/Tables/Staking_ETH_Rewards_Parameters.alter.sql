-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.Staking_ETH_Rewards_Parameters
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- EXW_dbo.Staking_ETH_Rewards_Parameters is a historical reference table recording the ETH staking program''s monthly reward parameters from the eToro Wallet staking program. It contains exactly 26 rows, one per completed staking period between 2021-06-16 and 2023-05-10. Each row represents one monthly (or partial-monthly) ETH staking cycle and stores two key financial metrics: the total ETH rewards distributed in that period (`Rewards`) and the equivalent yield expressed as a decimal fraction (`YieldInDecimal`). **The ETH staking program has ended.** All 26 rows have `IsActive = 0` and `MinimumDays = 0`. The most recent record covers 2023-05-01 to 2023-05-10 (partial month), updated 2023-06-05. The program wound down in May 2023 as eToro transitioned its staking model following the Ethereum Merge (Sep 2022 -> Proof-of-Stake). No new rows have been added since. This table is a **frozen hist

