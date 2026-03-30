-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_OptionsPlatform
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Aggregates US options/equity PFOF (payment for order flow) payback from Apex reconciliation revenue reports per customer and trade date, shaped like other revenue metrics (action types, instrument type, transaction counts). Maps clearing accounts to internal customers via the US broker options bridge table and excludes designated house accounts. The **`Amount`** column is `SUM(ABS(CustomerPFOFPayback))` only over rows whose `TradeDate` falls between the parameter dates and whose `ClearingAccount` is not in the excluded house list.

