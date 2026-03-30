-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_SpotAdjustFee
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Returns spot-adjustment fee revenue (`ActionTypeID` 36, `CompensationReasonID` 118) from the customer action position distribution, negating `Amount` as `SpotAdjustFee`, with instrument type, SQF, copy, and margin attributes for analytics consistent with other trading fee TVFs.

