-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Trading_Volume_PositionLevel
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Position-level **one row per open or close event** (not aggregated across positions): **opens** with `OpenDateID` between `@sdateInt` and `@edateInt`, **closes** with `CloseDateID` in that range, unioned like `Function_Trading_Volume`. Exposes both **persisted** volume (`Volume` / `VolumeOnClose`) and **QA recomputed** notional from units × FX (and conversion-rate fallback chain on open), plus `IsValidCustomer` and product/context flags—no final `GROUP BY` volume roll-up.

