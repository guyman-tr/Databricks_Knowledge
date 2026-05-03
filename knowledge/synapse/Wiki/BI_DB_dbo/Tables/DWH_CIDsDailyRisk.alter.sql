-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.DWH_CIDsDailyRisk
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cidsdailyrisk
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cidsdailyrisk SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.DWH_CIDsDailyRisk > 4.7B-row daily portfolio risk table storing the average hourly portfolio standard deviation for every customer - calculated using a Markowitz-style weighted portfolio covariance model with 24 hourly iterations per day, covering Jan 2013 to present. Sources: Dim_Position (holdings), Dim_Instrument_Correlation (covariance matrix), V_Liabilities + History.Credit (equity). Refreshed daily by SP_DWH_CIDsDailyRisk via DELETE+INSERT by FullDate. Not migrated to Unity Catalog. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | ETL-computed by `BI_DB_dbo.SP_DWH_CIDsDailyRisk` from Dim_Position + Dim_Instrument_Correlation + equity sources | | **Refresh** | Daily - DELETE WHERE FullDate=@date + INSERT. Accumulating by date. | | **Synapse Distribution** | ROUND_ROBIN | | **Synapse Index** | HEAP (P'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cidsdailyrisk SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cidsdailyrisk ALTER COLUMN FullDate COMMENT 'Snapshot date. The target date for hourly risk calculation. PK component (NOT ENFORCED). Used as DELETE+INSERT key. (Tier 2 - SP_DWH_CIDsDailyRisk)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cidsdailyrisk ALTER COLUMN CID COMMENT 'Customer ID. FK to Dim_Customer.RealCID. One row per customer per day. PK component (NOT ENFORCED). (Tier 2 - SP_DWH_CIDsDailyRisk)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cidsdailyrisk ALTER COLUMN AvgSTD COMMENT 'Average hourly portfolio standard deviation for this customer on this date. Calculated using Markowitz portfolio variance: sqrt(SUM(Weight_a × Weight_b × Covariance_ab)). Higher values = more volatile portfolio. Average across all 24 hourly iterations. (Tier 2 - SP_DWH_CIDsDailyRisk)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cidsdailyrisk ALTER COLUMN HoursInSample COMMENT 'Number of hourly iterations (out of 24) where this customer had valid data (open positions + positive equity). Average ~20. Lower values may indicate data gaps or intermittent position activity. (Tier 2 - SP_DWH_CIDsDailyRisk)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cidsdailyrisk ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was inserted by SP_DWH_CIDsDailyRisk. (Tier 5 - ETL infrastructure)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cidsdailyrisk ALTER COLUMN FullDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cidsdailyrisk ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cidsdailyrisk ALTER COLUMN AvgSTD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cidsdailyrisk ALTER COLUMN HoursInSample SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cidsdailyrisk ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 13:17:50 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 12/12 succeeded
-- ====================
