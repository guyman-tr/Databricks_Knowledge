-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_CostType
-- Generated: 2026-05-14 15:04:32 UTC | _tmp_phase1_remediation.py
-- UC Target: main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_costtype
-- =============================================================================

-- ---- Table Comment ----
-- (table comment intentionally omitted; regen tool only manages column comments)

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_costtype ALTER COLUMN CostTypeId COMMENT 'Cost category identifier (nullable). Loaded by SP_Dictionaries_DL_To_Synapse from a HistoryCosts staging source. Not a primary key.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_costtype ALTER COLUMN CostType COMMENT 'Human-readable cost type name. Values: Markup, CurrencyMarkup, Fee, Tax. Passthrough from source - same column name as staging. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_costtype ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp - set to GETDATE() on each full reload by SP_Dictionaries_DL_To_Synapse. Reflects ETL run time, not source data change time. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_costtype ALTER COLUMN CostTypeId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_costtype ALTER COLUMN CostType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_costtype ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

