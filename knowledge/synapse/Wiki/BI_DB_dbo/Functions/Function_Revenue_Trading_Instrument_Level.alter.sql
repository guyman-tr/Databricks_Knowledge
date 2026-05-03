-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_Trading_Instrument_Level
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- Combines multiple trading revenue TVFs (full commissions, rollover, ticket fees, percent ticket fees, admin fee, spot adjustment) at instrument and position grain, then adds copy-fund, IBAN, and recurring-investment flags before aggregating to customer × date × instrument × metric. Produces large datasets suitable for asset-level revenue attribution.

