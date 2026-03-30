-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_MirrorType
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirrortype
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirrortype SET TBLPROPERTIES (
    'comment' = '`DWH_dbo.Dim_MirrorType` classifies the type of "mirror" (copy-trading) relationship on the eToro social trading platform. A "mirror" represents a follower copying a leader''s portfolio -- when the leader opens/closes positions, the follower''s account mirrors those trades proportionally. The 4 types: | ID | Name | Meaning | |----|------|---------| | 1 | Regular | Standard CopyTrader relationship -- one customer automatically copies another customer''s trades | | 2 | CopyMe | The "Popular Investor" or CopyPortfolio leader is a public figure/influencer; followers copy en masse | | 3 | Social Index | A Smart Portfolio (formerly CopyPortfolio) -- a curated basket of assets with algorithmic rebalancing | | 4 | Fund | An eToro-managed fund product | This table is the type lookup for `DWH_dbo.Dim_Mirror` (the mirror relationship dimension), where each active/historical copy relationship carries a MirrorTypeID. Synapse: REPLICATE, CLUSTERED INDEX (MirrorTypeID ASC).'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirrortype SET TAGS (
    'domain' = 'trading',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (MirrorTypeID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirrortype ALTER COLUMN MirrorTypeID COMMENT 'Primary key identifying the copy relationship type. 1=Regular (standard copy), 2=CopyMe (legacy), 3=Social Index (algorithmic), 4=Fund (managed). (Tier 1 - Dictionary.MirrorType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirrortype ALTER COLUMN MirrorTypeName COMMENT 'Short code name used in code branching and API responses. (Tier 1 - Dictionary.MirrorType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirrortype ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp -- GETDATE() at load time. (Tier 2 -- SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirrortype ALTER COLUMN MirrorTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirrortype ALTER COLUMN MirrorTypeName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirrortype ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
