-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_StakingFee
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Staking reward distribution economics per instrument and customer: rows from `Dealing_Staking_Results` filtered to attributed `DateID` (from `dateadd(MONTH,-1, UpdateDate)`) between `@sdateID` and `@edateID`, excluding bad `StakingMonthID` values (see `BadMonths` CTE). Normalizes month IDs (`left(StakingMonthID,6)`), splits eToro vs client USD using eligibility (`IsEligible`), and joins `Dim_Instrument` and `Fact_SnapshotCustomer` with EOM-aligned `Dim_Range` for customer attributes at month-end.

