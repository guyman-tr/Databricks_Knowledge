-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_Platform
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platform
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platform SET TBLPROPERTIES (
    'comment' = 'Dim_Platform is a 4-row dictionary defining the device and application platforms from which customers access the eToro trading application. Every user session, trade, and interaction is tagged with a platform identifier to enable per-platform analytics, feature flagging, and UX customization. Platform determines which features are available (some are web-only or mobile-only), which UI is rendered, and which API endpoints are called. The data originates from `etoro.Dictionary.Platform` on the etoroDB-REAL production SQL Server. The Generic Pipeline exports this table daily (Override strategy) to `Bronze/etoro/Dictionary/Platform/` in the data lake. In production, the PK column is named `Id`; the DWH ETL renames it to `PlatformID`. Loaded by `SP_Dictionaries_DL_To_Synapse` via TRUNCATE + INSERT from `DWH_staging.etoro_Dictionary_Platform`. Refreshes daily. As of 2026-03-19, UpdateDate is 2026-03-11 -- 8 days stale due to known schema-wide ETL disruption. **Note**: No DWH SPs other than SP_Dictionaries_DL_To_...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platform SET TAGS (
    'domain' = 'general',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (PlatformID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platform ALTER COLUMN PlatformID COMMENT 'DWH platform identifier. 0=Undefined, 1=Web, 2=IOS, 3=Android. Renamed from `Id` in the production source (etoro.Dictionary.Platform) by the DWH ETL. Referenced by session and action tracking tables to indicate the originating device platform. DWH note: column renamed from production `Id` to `PlatformID` during TRUNCATE+INSERT load. (Tier 1 - upstream wiki, Dictionary.Platform)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platform ALTER COLUMN Platform COMMENT 'Platform name label: "Undefined", "Web", "IOS", "Android". Used in reporting dashboards and per-platform analytics. Passthrough from production -- same column name. (Tier 1 - upstream wiki, Dictionary.Platform)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platform ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp -- set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Does not reflect production data modification time. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platform ALTER COLUMN PlatformID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platform ALTER COLUMN Platform SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platform ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:25:02 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 8/8 succeeded
-- ====================
