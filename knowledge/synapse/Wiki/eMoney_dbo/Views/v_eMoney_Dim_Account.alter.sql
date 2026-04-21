-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.v_eMoney_Dim_Account
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- `v_eMoney_Dim_Account` is a live operational view over `eMoney_Dim_Account` (the central eToro Money account dimension). It provides a **today-only window** into the daily refresh result: on any given day that SP_eMoney_Dim_Account ran, this view exposes the freshly loaded data. The view achieves this with a CTE-based date filter: ```sql WITH a AS (SELECT MAX(UpdateDate) FROM eMoney_Dim_Account) SELECT TOP (1000) ... WHERE CAST(GETDATE() AS DATE) = (SELECT CAST(UpdateDate AS DATE) FROM a) ``` This means: - **On refresh days**: returns up to 1,000 rows from the current batch (UpdateDate = today) - **On non-refresh days**: returns 0 rows — the view is effectively empty until the next SP run **TOP (1000) without ORDER BY**: The view limits to 1,000 rows with no ordering clause. This means the 1,000 rows returned are arbitrary — not the "most recent" or "most important" accounts. The view is

