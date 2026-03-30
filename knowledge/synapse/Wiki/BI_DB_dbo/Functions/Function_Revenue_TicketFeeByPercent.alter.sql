-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_TicketFeeByPercent
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Percent-based ticket markup from `Fact_History_Cost` (cost subtype 4, calculation types 4 and 7 for DLT edge cases), joined to distribution for open vs close context; amounts before 2025-05-25 are zeroed so mistaken prod bookings stay in flat ticket fees. Output includes SQF tagging and margin settlement flags.

