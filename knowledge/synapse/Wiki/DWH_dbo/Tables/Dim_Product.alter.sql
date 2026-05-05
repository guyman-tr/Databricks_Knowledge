-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_Product
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_product
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_product SET TBLPROPERTIES (
    'comment' = 'Dim_Product is a static lookup table that classifies eToro client applications into a three-level hierarchy: Platform (Mobile/Web), SubPlatform (Android/iOS/Browsers), and Product (individual app names). It enumerates the named client applications (OpenBook, Trader, Wallet, eToroX, Delta, reToro, RegistrationAPI, Other) across mobile and web delivery channels. ProductID 99 serves as the universal null-sentinel row for fact table JOINs. No production source has been identified. All 27 rows have InsertDate = 2018-09-02, indicating a one-time legacy migration from the on-premises DWH. A single UpdateDate of 2020-07-28 suggests a minor post-migration correction. No Generic Pipeline export feeds into this table - it is the DWH itself that exports to Gold via the Generic Pipeline (uc_table: bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_product). This table has no active ETL stored procedure. It is a frozen lookup dictionary. Analysts should treat it as a stable but potentially incomplete mapping - newer product names in...'
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_product SET TAGS (
    'domain' = 'general',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (ProductID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_product ALTER COLUMN ProductID COMMENT 'Primary key. Client application identifier. Sentinel: 99 = No Platform (null substitute for fact table JOINs). Known IDs: 99=No Platform, 101-126=named apps across platforms. (Tier 3b - DDL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_product ALTER COLUMN Product COMMENT 'Client application display name. Values: No Platform, OpenBook, Other, RegistrationAPI, reToro, reToroAndroid, reToroiOS, Trader, Wallet, eToroX, Delta. "Other" is a catch-all for unclassified sessions. (Tier 3 - live data)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_product ALTER COLUMN Platform COMMENT 'Top-level delivery platform. Values: empty string (No Platform sentinel), Mobile, Web. (Tier 3 - live data)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_product ALTER COLUMN SubPlatform COMMENT 'Operating system or browser category. Values: empty string (No Platform sentinel), Android, iOS, Browsers. (Tier 3 - live data)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_product ALTER COLUMN InsertDate COMMENT 'ETL or migration timestamp when the row was inserted. All rows = 2018-09-02 (one-time migration). (Tier 3b - DDL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_product ALTER COLUMN UpdateDate COMMENT 'Last modification timestamp. Max value 2020-07-28 (Delta/eToroX rows added). Static for all other rows. (Tier 3 - live data)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_product ALTER COLUMN ProductID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_product ALTER COLUMN Product SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_product ALTER COLUMN Platform SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_product ALTER COLUMN SubPlatform SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_product ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_product ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-05 13:12:08 UTC
-- Batch deploy resume: DWH_dbo deploy batch 10
-- Statements: 14/14 succeeded
-- ====================
