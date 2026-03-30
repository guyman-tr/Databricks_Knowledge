-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_TicketFee
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Ticket fee revenue with open/close context: before 2025-05-25 from distribution rows (`ActionTypeID` 35, `IsFeeDividend` 4); on/after 2025-05-25 from `Fact_History_Cost` joined to distribution for open vs close ticket fee actions, with SQF tagging. Amount sign convention differs by period (negated legacy amount vs direct cost value).

