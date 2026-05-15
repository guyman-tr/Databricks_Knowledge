-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_Instrument_Correlation_GroupsInstruments
-- Generated: 2026-05-14 15:33:13 UTC
-- UC Target: main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation_groupsinstruments
-- =============================================================================

-- ---- Table Comment ----

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation_groupsinstruments ALTER COLUMN GroupID COMMENT 'Stable identifier for a correlation shard created by `SP_Dim_Instrument_Correlation_Build_GroupsInstruments`; referenced downstream when routing half-matrix computations. (Tier 2 - SP_Dim_Instrument_Correlation_Build_GroupsInstruments)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation_groupsinstruments ALTER COLUMN MinInstrumentID COMMENT 'Inclusive lower bound of InstrumentIDs assigned to the shard; MCP sample shows contiguous chunks beginning at instrument 1 onward. (Tier 3 - live sample BI_DB MCP)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation_groupsinstruments ALTER COLUMN MaxInstrumentID COMMENT 'Inclusive upper bound counterpart to `MinInstrumentID`; pairing with MIN defines the routed instrument band for shard `GroupID`. (Tier 3 - live sample BI_DB MCP)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation_groupsinstruments ALTER COLUMN GroupID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation_groupsinstruments ALTER COLUMN MinInstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation_groupsinstruments ALTER COLUMN MaxInstrumentID SET TAGS ('pii' = 'none');

