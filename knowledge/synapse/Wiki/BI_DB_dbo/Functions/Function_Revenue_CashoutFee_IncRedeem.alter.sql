-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_CashoutFee_IncRedeem
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Returns **cashout fee** (`Fact_CustomerAction.Commission`) for **ActionTypeID IN (30)** **including redeem-related rows** (no `IsRedeem` exclusion). Customer attributes come from `Fact_SnapshotCustomer` aligned to the action date via `Dim_Range`.

