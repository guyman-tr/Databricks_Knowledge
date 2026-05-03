-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoneyProcessStatusLog
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- `eMoneyProcessStatusLog` is the operational audit log for the eToro Money (eTM) Synapse ETL pipeline. It records lifecycle events (Start, Complete, Fail) for every stored procedure executed within the eTM pipeline orchestration, driven by `SP_eMoney_Execute_Group_One`. Each SP execution generates at least one log entry: - **Start** entry when the SP begins - **Complete** entry on success - **Fail** entry on error (with the error message in `ErrorDescription`) The log covered 17 distinct SP names across approximately 851 daily pipeline runs (2022-11-23 to 2023-10-30). The most active SP was `SP_eMoney_Dim_Country_Rollout` (1,702 entries), reflecting roughly 851 Start+Complete pairs. Out of 16,726 total rows, 32 are Fail entries recording pipeline errors. **Why it is frozen**: On 2023-10-30, Katy F commented out all SP execution calls within `SP_eMoney_Execute_Group_One` (git history / SP 

