-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_SocialNetwork
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_socialnetwork
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_socialnetwork SET TBLPROPERTIES (
    'comment' = 'Dim_SocialNetwork defines the social network platforms through which customers registered on the eToro platform via OAuth / social login. Values: N/A (0=no social registration), Facebook (1), Twitter (2), LinkedIn (3). (Tier 3 - live data; no upstream wiki found) This table is a frozen legacy artifact. All 4 rows have timestamps from 2013-2014, consistent with an original on-premises DWH migration. No active ETL stored procedure refreshes this table - it is absent from SP_Dictionaries_DL_To_Synapse, and no other DWH_dbo SPs or views reference it in the SSDT repo. The Generic Pipeline exports the current Synapse state daily to UC Gold. LinkedIn social login and Twitter social login integrations are largely inactive in modern eToro. Facebook OAuth remains in use. The 4-row lookup is complete and stable. Synapse: REPLICATE, CLUSTERED INDEX (SocialNetworkID ASC).'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_socialnetwork SET TAGS (
    'domain' = 'general',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (SocialNetworkID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_socialnetwork ALTER COLUMN SocialNetworkID COMMENT 'Primary key. 0=N/A (email registration), 1=Facebook, 2=Twitter, 3=LinkedIn. Stored on customer records to indicate OAuth registration channel. (Tier 3 - live data)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_socialnetwork ALTER COLUMN Name COMMENT 'Social network platform name. Passthrough from source. (Tier 3 - live data)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_socialnetwork ALTER COLUMN DWHSocialNetworkID COMMENT 'ETL-computed alias of SocialNetworkID - always equals SocialNetworkID. DWH-specific redundant field. Use SocialNetworkID for joins. (Tier 4 - UNVERIFIED; no active SP found)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_socialnetwork ALTER COLUMN StatusID COMMENT 'Value 1 for all rows, consistent with "Active" pattern from SP_Dictionaries. ETL origin unclear (no active SP found). (Tier 4 - UNVERIFIED)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_socialnetwork ALTER COLUMN UpdateDate COMMENT 'Frozen 2013-2014 timestamps. Not GETDATE() - reflects original migration date. (Tier 3 - live data)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_socialnetwork ALTER COLUMN InsertDate COMMENT 'Frozen 2013-2014 timestamps. Same as UpdateDate. (Tier 3 - live data)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_socialnetwork ALTER COLUMN SocialNetworkID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_socialnetwork ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_socialnetwork ALTER COLUMN DWHSocialNetworkID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_socialnetwork ALTER COLUMN StatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_socialnetwork ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_socialnetwork ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');
