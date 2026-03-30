-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_InterestFee
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Returns daily credit-line interest fees charged to customers (`Daily_CreditLine.DailyFee` as `InterestFee`), aligned to snapshot customer attributes via `Dim_Range` for the action date. Supports optional filtering to valid customers only.

