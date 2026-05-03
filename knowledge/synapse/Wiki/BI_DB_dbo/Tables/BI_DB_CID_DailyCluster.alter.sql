-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_CID_DailyCluster
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_CID_DailyCluster > Customer clustering SCD2 history table - 13 columns tracking the evolution of each customer''s cluster assignment over time. One row per change period (FromDate -> ToDate). Built daily from BI_DB_ClusteringLog + BI_DB_ClusteringDailyPrepData via SP_CID_DailyCluster. Currently 5.1M active (open) customer clusters across 6 types. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | BI_DB_dbo.BI_DB_ClusteringLog (ML cluster assignments) | | **Refresh** | Daily (SP_CID_DailyCluster @Date, SCD2 MERGE + INSERT) | | | | | **Synapse Distribution** | ROUND_ROBIN | | **Synapse Index** | CLUSTERED (FromDateID ASC) + NONCLUSTERED (UpdateDateIDSF) | | | | | **OpsDB Priority** | 0 (declared) - note: SP reads from BI_DB_ClusteringDailyPrepData which is P20; LEFT JOIN makes ClusterDynamic gracefully de'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster ALTER COLUMN CID COMMENT 'Customer ID. One or more rows per customer - each row represents a distinct cluster period. (Tier 2 - SP_CID_DailyCluster)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster ALTER COLUMN ClusterDetail COMMENT 'Precise ML cluster name for this period. 6 values: ''Crypto'', ''Equities Traders'', ''Equities Crypto'', ''Equities Investors'', ''Leveraged Traders'', ''Diversified Traders''. Sourced from BI_DB_ClusteringLog.ClusterDesc. (Tier 2 - SP_CID_DailyCluster)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster ALTER COLUMN ClusterSF COMMENT 'Simplified Salesforce cluster bucket. 3 values: ''Investors'' (Equities Investors), ''Traders'' (Equities/Diversified/Leveraged Traders), ''Crypto'' (Crypto + Equities Crypto). Computed at INSERT from ClusterDetail CASE logic. (Tier 2 - SP_CID_DailyCluster)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster ALTER COLUMN FromDateID COMMENT 'Start date of this cluster period as YYYYMMDD integer. Clustered index key. Sourced from BI_DB_ClusteringLog.DateID. (Tier 2 - SP_CID_DailyCluster)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster ALTER COLUMN ToDateID COMMENT 'End date of this cluster period as YYYYMMDD integer. 99991231 = open/current period (IsLastCluster=1). Set to yesterday''s DateID when MERGE closes this period on cluster change. (Tier 2 - SP_CID_DailyCluster)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster ALTER COLUMN FromDate COMMENT 'Start date of this cluster period. Sourced from BI_DB_ClusteringLog.Date. (Tier 2 - SP_CID_DailyCluster)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster ALTER COLUMN ToDate COMMENT 'End date of this cluster period. ''9999-12-31'' for open periods; set to DATEADD(DAY,-1,@LoadDate) when cluster changes. (Tier 2 - SP_CID_DailyCluster)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster ALTER COLUMN IsLastCluster COMMENT '1 = this is the customer''s currently active cluster period (ToDateID=99991231). 0 = historical closed period. Primary filter for current-state queries. (Tier 2 - SP_CID_DailyCluster)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster ALTER COLUMN IsFirstCluster COMMENT '1 = this is the customer''s very first cluster assignment (no prior cluster record existed). 0 = customer had prior cluster history. (Tier 2 - SP_CID_DailyCluster)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster ALTER COLUMN IsSFCluster COMMENT 'Salesforce sync flag. 1 = this cluster record should be synced to Salesforce CRM. Updated bi-monthly (even months) for recent active clusters. 0 for historical/stale periods. (Tier 2 - SP_CID_DailyCluster)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. GETDATE() at INSERT or subsequent UPDATE (IsLastCluster/IsSFCluster corrections). (Tier 2 - ETL metadata)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster ALTER COLUMN UpdateDateIDSF COMMENT 'YYYYMMDD integer of the SP run date for this row''s last SF processing pass. NC index key. Supports SF sync batch identification. (Tier 2 - SP_CID_DailyCluster)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster ALTER COLUMN ClusterDynamic COMMENT 'Enhanced cluster label with crypto-adjustment. Same as ClusterDetail for all types except: ''Diversified Traders'' with CryptoRatio  >=  0.4 becomes ''Equities Crypto''. Enables finer segmentation of crypto-heavy diversified traders. NULL if ClusteringDailyPrepData has no ratio for the customer on that date (LEFT JOIN miss). (Tier 2 - SP_CID_DailyCluster)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster ALTER COLUMN ClusterDetail SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster ALTER COLUMN ClusterSF SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster ALTER COLUMN FromDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster ALTER COLUMN ToDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster ALTER COLUMN FromDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster ALTER COLUMN ToDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster ALTER COLUMN IsLastCluster SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster ALTER COLUMN IsFirstCluster SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster ALTER COLUMN IsSFCluster SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster ALTER COLUMN UpdateDateIDSF SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster ALTER COLUMN ClusterDynamic SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:25:40 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 28/28 succeeded
-- ====================
