-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_MonthlyRiskScore
-- Generated: 2026-05-07 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_monthlyriskscore
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_monthlyriskscore SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_MonthlyRiskScore **Schema**: BI_DB_dbo | **UC Target**: `general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_monthlyriskscore` **Row count**: ~105.9M (2013-01-01 -> 2024-04-01) | **Refresh**: nominally daily (Override) but **STALE since 2024-04-08** **Distribution**: ROUND_ROBIN | **Clustered Index**: (Year, Month, CID) ---'
);

-- ---- Table Tags ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_monthlyriskscore SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_monthlyriskscore ALTER COLUMN Year COMMENT 'Calendar year of the scoring period (e.g., 2024).';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_monthlyriskscore ALTER COLUMN Month COMMENT 'Calendar month of the scoring period (1 - 12).';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_monthlyriskscore ALTER COLUMN CID COMMENT 'Customer ID. Joins to `DWH_dbo.Dim_Customer.CID`.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_monthlyriskscore ALTER COLUMN MonthlyRiskScore COMMENT 'Risk score for the customer in this month (integer 1 - 10; higher = higher risk).';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_monthlyriskscore ALTER COLUMN StartPeriod COMMENT 'First day of the scoring month (e.g., 2024-04-01).';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_monthlyriskscore ALTER COLUMN EndPeriod COMMENT 'Last day of the scoring month (e.g., 2024-04-30).';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_monthlyriskscore ALTER COLUMN StartDateID COMMENT 'YYYYMMDD integer for `StartPeriod`. Joins to `DWH_dbo.Dim_Date.DateID`.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_monthlyriskscore ALTER COLUMN EndDateID COMMENT 'YYYYMMDD integer for `EndPeriod`. Joins to `DWH_dbo.Dim_Date.DateID`.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_monthlyriskscore ALTER COLUMN UpdateDate COMMENT 'Insert timestamp from the legacy writer (not the scoring date itself). All current rows have UpdateDate around 2024-04-08.';

-- ---- Column PII Tags ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_monthlyriskscore ALTER COLUMN Year SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_monthlyriskscore ALTER COLUMN Month SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_monthlyriskscore ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_monthlyriskscore ALTER COLUMN MonthlyRiskScore SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_monthlyriskscore ALTER COLUMN StartPeriod SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_monthlyriskscore ALTER COLUMN EndPeriod SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_monthlyriskscore ALTER COLUMN StartDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_monthlyriskscore ALTER COLUMN EndDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_monthlyriskscore ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-07 11:25:56 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 5
-- Statements: 20/20 succeeded
-- ====================
