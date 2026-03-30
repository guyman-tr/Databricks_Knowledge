-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Single entry point for **first-time deposit (FTD)** attributes per customer across eMoney and trading-platform sources, with **date-routed logic**: before 2025-09-01 uses legacy IBAN/TP union and row-numbering; on/after uses `Dim_Customer` as the spine with joins to refreshed IBAN/TP extracts, C2USD billing, and bad-FTD exclusion. Each row is enriched with `Fact_SnapshotCustomer` as-of the FTD date via `Dim_Range`.

