-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_CostSubtype
-- Generated: 2026-05-14 15:04:32 UTC | _tmp_phase1_remediation.py
-- UC Target: main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_costsubtype
-- =============================================================================

-- ---- Table Comment ----
-- (table comment intentionally omitted; regen tool only manages column comments)

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_costsubtype ALTER COLUMN CostSubtypeId COMMENT 'Nullable integer identifier for the cost subtype. Loaded by SP_Dictionaries_DL_To_Synapse from HistoryCosts staging.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_costsubtype ALTER COLUMN CostSubtype COMMENT 'Human-readable name for the cost subtype. Values: Markup, ConversionMarkup, TicketFee, SDRT, TransactionFee, Refund, FixPerLotFee. Passthrough from source - column name unchanged from staging. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_costsubtype ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp - set to GETDATE() on each full reload by SP_Dictionaries_DL_To_Synapse. Reflects when the batch SP last ran, not when the source data changed. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_costsubtype ALTER COLUMN CostSubtypeId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_costsubtype ALTER COLUMN CostSubtype SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_costsubtype ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

