-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_Trading_Fees_Breakdown
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Trading-fee detail from `BI_DB_Fact_Customer_Action_Position_Distribution` as two combined sets: (1) `ActionTypeID = 36` with `CompensationReasonID IN (117, 118)`, `TradingFeeName` from `Dim_CompensationReason`, and `PositionID` parsed from `Description` when the trailing token is numeric; (2) ticket-fee rows with `ActionTypeID = 35` AND `IsFeeDividend = 4`, labeled `TradingFeeName = ''TicketFee''`. Revenue sign uses `-1 * Amount` on the outer projection.

