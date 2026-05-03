-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.DWH_CIDs7DaysDeviation
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cids7daysdeviation
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cids7daysdeviation SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.DWH_CIDs7DaysDeviation > 4.8B-row daily 7-day rolling portfolio deviation table storing the average standard deviation of unrealized PnL for every customer - computed from DWH_dbo.Fact_CustomerUnrealized_PnL over a trailing 7-day window, covering Jan 2013 to present. Used as the risk score input for copy-trading block decisions. Refreshed daily by SP_DWH_CIDs7DaysDeviation via DELETE+INSERT by FullDate. Not migrated to Unity Catalog. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | ETL-computed by `BI_DB_dbo.SP_DWH_CIDs7DaysDeviation` from DWH_dbo.Fact_CustomerUnrealized_PnL | | **Refresh** | Daily - DELETE WHERE FullDate=@start + INSERT. Accumulating by date. | | **Synapse Distribution** | ROUND_ROBIN | | **Synapse Index** | HEAP (PK on CID, FullDate - NOT ENFORCED) | | **UC Target** | `_Not_Migrated` | '
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cids7daysdeviation SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cids7daysdeviation ALTER COLUMN FullDate COMMENT 'Snapshot date. The target date for the 7-day rolling window calculation. PK component (NOT ENFORCED). Used as DELETE+INSERT key. (Tier 2 - SP_DWH_CIDs7DaysDeviation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cids7daysdeviation ALTER COLUMN CID COMMENT 'Customer ID. FK to Dim_Customer.RealCID. One row per customer per day. PK component (NOT ENFORCED). (Tier 2 - SP_DWH_CIDs7DaysDeviation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cids7daysdeviation ALTER COLUMN Deviation COMMENT '7-day rolling average of portfolio standard deviation. AVG(Fact_CustomerUnrealized_PnL.StandardDeviation) from (FullDate-6) to FullDate. Higher values indicate more volatile trading. Consumed by SP_WeeklyCopyBlock for risk score bucketing (1-10 scale). (Tier 2 - SP_DWH_CIDs7DaysDeviation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cids7daysdeviation ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was inserted by SP_DWH_CIDs7DaysDeviation. (Tier 5 - ETL infrastructure)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cids7daysdeviation ALTER COLUMN FullDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cids7daysdeviation ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cids7daysdeviation ALTER COLUMN Deviation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_cids7daysdeviation ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 13:17:43 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 10/10 succeeded
-- ====================
