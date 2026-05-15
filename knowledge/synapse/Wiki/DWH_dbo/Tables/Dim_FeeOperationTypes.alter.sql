-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_FeeOperationTypes
-- Generated: 2026-05-14 15:04:32 UTC | _tmp_phase1_remediation.py
-- UC Target: main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_feeoperationtypes
-- =============================================================================

-- ---- Table Comment ----
-- (table comment intentionally omitted; regen tool only manages column comments)

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_feeoperationtypes ALTER COLUMN FeeOperationTypeID COMMENT 'Fee timing phase: 1=Open (at position entry), 2=Close (at position exit), 3=All (both phases). Referenced by Trade.FixPerLotConfigurations, Trade.FeeInPercentageConfigurations, and fee validation procedures. (Tier 1 - Dictionary.FeeOperationTypes)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_feeoperationtypes ALTER COLUMN FeeOperationTypeName COMMENT 'Human-readable phase label: ''Open'', ''Close'', ''All''. Used in trading engine configuration and admin UIs. (Tier 1 - Dictionary.FeeOperationTypes)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_feeoperationtypes ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() on each SP run. NOT NULL constraint (unusual for DWH dict tables). Because there is no TRUNCATE, this column stores the time of each accumulated run, not just the last run. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_feeoperationtypes ALTER COLUMN FeeOperationTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_feeoperationtypes ALTER COLUMN FeeOperationTypeName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_feeoperationtypes ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

