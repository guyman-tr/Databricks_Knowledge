-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Population_First_Time_Funded
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- For **depositors** with a warehouse **FTD** (excluding a curated “bad FTD” set), joins **first verified** snapshot range and left-joins **first trade**, **first IOB** (interest-on-balance), and **first options trade**. Computes a single **FirstFundedDateID/Date** as the latest of FTD, verification, and the earliest qualifying trading/options/IOB activity.

