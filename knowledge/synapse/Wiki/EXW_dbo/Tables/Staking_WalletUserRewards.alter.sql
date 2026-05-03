-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.Staking_WalletUserRewards
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- EXW_dbo.Staking_WalletUserRewards is the per-user monthly ETH staking rewards table for the eToro Wallet ETH staking program. It records the actual ETH reward earned by each individual wallet user for each staking month from June 2021 (program launch) through June 2023 (wind-down). This is the historical record of every staking reward payout at the per-GCID level. **Program context**: eToro offered ETH staking rewards to Wallet users who held ETH on the platform. Rewards were computed monthly based on the user''s staked position, the pool''s monthly yield rate, and their eToro club tier (which determines their revenue share percentage). The program ran from June 2021 to May 2023 and was wound down after the Ethereum Merge transition to Proof-of-Stake. **User population**: 1,425 distinct GCIDs participated in the staking program across its full run. Growth was rapid: 11 users in Jun 2021,

