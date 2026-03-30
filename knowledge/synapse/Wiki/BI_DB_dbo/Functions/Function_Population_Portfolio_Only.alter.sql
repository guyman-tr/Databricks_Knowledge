-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Population_Portfolio_Only
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Identifies customers who qualify as **portfolio-only** under the DDR terminology framework: they hold open positions (or positive options buying power) in the date range but are **not** active traders in that same window. Flags break out manual vs copy, instrument families (CFD, crypto, stocks, ETF), copy-fund mirrors, and US options exposure from Apex buy-power data.

