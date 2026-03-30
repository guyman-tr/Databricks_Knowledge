-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Population_Funded
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- On a single **`@dateInt`**, returns customers who are **past their first-funded date** per `Function_Population_First_Time_Funded` **and** have **positive combined equity** that day from **trading-platform balances**, **eMoney** settled balance, or **options** AUM (valid customers only on options leg). Prevents “funded” without an actual deposit/funded milestone.

