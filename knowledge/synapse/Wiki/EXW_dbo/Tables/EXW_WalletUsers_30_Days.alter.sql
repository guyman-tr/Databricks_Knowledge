-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_WalletUsers_30_Days
-- UC Target: _Not_Migrated
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- EXW_WalletUsers_30_Days provides a current-state view of wallet user activity over the trailing 30 days, enriched with geography (country, region, continent). Each row represents one wallet user with: - Their KYC and club status (from EXW_DimUser) - A flag indicating whether they logged in within the last 31 calendar days - A flag indicating whether they made a non-internal transaction in the last 31 days - Geographic attributes at country, marketing-region, and continent level The table is a full-refresh snapshot - it is completely rebuilt from TRUNCATE on every SP run. There is no date column or DateID; the table always reflects the current state of active-30-day users. It feeds regional aggregation dashboards and active-user reporting.

