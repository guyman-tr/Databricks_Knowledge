-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_WalletClosedCountryProjects
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- This table is a manually maintained registry of countries where eToro''s Wallet service was closed and users received compensation. Each row represents a single country-project combination - that is, a country that was included in a specific closure campaign (Project), optionally scoped to a particular regulatory jurisdiction (RegulationID). The 89 rows span 77 distinct countries and 8 named Projects, covering closure waves from 2021 through 2024. The table serves as a JOIN reference in key Wallet ETL procedures: - **SP_DimUser** LEFT JOINs on CountryID + RegulationID to determine whether a user''s country of residence has been closed under a Wallet compensation project - **SP_EXW_CompensationClosingCountries** JOINs to scope compensation reports - **SP_EXW_UserSettingsWalletAllowance** LEFT JOINs to evaluate ongoing wallet eligibility restrictions There is no automated ETL pipeline popu

