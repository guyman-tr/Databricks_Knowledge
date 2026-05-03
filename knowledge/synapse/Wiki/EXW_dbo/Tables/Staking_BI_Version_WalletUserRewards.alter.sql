-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.Staking_BI_Version_WalletUserRewards
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- EXW_dbo.Staking_BI_Version_WalletUserRewards is the BI-enriched version of `Staking_WalletUserRewards`, containing per-user monthly ETH staking rewards with additional data quality improvements: proper uniqueidentifier type for WalletID, numeric ClubRevShare (vs varchar in base), and the `IsTestUser` flag for filtering analysis to real vs test accounts. **Relationship to base table**: The BI version contains 42 more rows than the base table (23,659 vs 23,617) due to inclusion of test users (42 IsTestUser=1 rows). However, it covers fewer months: starts Jul 2021 (not Jun 2021) and ends May 2023 (not Jun 2023). The missing Jun 2021 pilot month and Jun 2023 trailing records suggest different ETL run windows. **Same program context**: This is the ETH staking program historical archive (2021 - 2023). Each row represents one wallet user''s reward for one staking month. The program ended in May 2

