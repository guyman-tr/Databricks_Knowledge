-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_Commissions
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Returns **trading commission** components by customer action from `Fact_CustomerAction` where the first CTE restricts rows to **ActionTypeID IN (1,2,3,39,4,5,6,28,40)** (open-style vs close-style families). It joins snapshot context and `Dim_Instrument`. **CommissionOnOpen** applies when **ActionTypeID IN (1,2,3,39)**; **CommissionOnClose** / **CommissionCloseAdjustment** apply when **ActionTypeID IN (4,5,6,28,40)** (close adjustment uses `CommissionOnClose - CommissionByUnits`). **TotalCommission** selects open vs close branch by the same groupings. Adds copy and margin flags and **IsSQF** via `Function_Instrument_Snapshot_Enriched(@edateInt)`.

