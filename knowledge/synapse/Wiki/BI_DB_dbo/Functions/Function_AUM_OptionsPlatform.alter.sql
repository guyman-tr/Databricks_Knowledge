-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_AUM_OptionsPlatform
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Returns one row per customer linked via **Apex options** (`External_USABroker_Apex_Options`) to **buy-power** rows in `External_Sodreconciliation_apex_EXT981_BuyPowerSummary` where `OfficeCode IN (''4GS'',''5GU'')`, house accounts excluded, `ProcessDate` equals the **latest** snapshot `<= CONVERT(date, @sdateInt)`, and the customer’s `Fact_SnapshotCustomer` range (`Dim_Range`) covers that `ProcessDate` as `DateID`. **OptionsTotalEquity / CashEquity / PositionMarketValue** are only meaningful under those joins and filters—not raw feed totals. Optional `@OnlyValidCustomers = 1` keeps `IsValidCustomer = 1`. First-options dates come from the **first** `ProcessDate` row per `AccountNumber` in the buy-power CTE (`ROW_NUMBER … RN = 1`).

