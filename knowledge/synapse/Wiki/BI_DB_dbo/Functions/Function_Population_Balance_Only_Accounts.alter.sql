-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Population_Balance_Only_Accounts
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Identifies customers who had **positive equity** somewhere in the period (trading-platform balances, **eMoney** IBAN USD-adjusted balance, or **options** Apex total equity) but **did not** appear as active traders or portfolio-only users in the same date range. Implements the DDR **“balance only”** cohort.

