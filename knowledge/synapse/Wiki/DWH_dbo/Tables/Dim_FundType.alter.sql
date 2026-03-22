-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_FundType
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundtype
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundtype SET TBLPROPERTIES (
    'comment' = '`Dim_FundType` is a 3-row dictionary classifying eToro Smart Portfolios (Funds) by their curation model: - 1 = TopTraders: Portfolios built from eToro''s highest-performing copy traders - 2 = Partners: Portfolios curated by eToro partner organizations or affiliates - 3 = Market: Thematic or sector-based market portfolios (the dominant type with 795 of 877 funds) This dimension is the FK target for `DWH_dbo.Dim_Fund.FundType`. The data originates from `etoro.Dictionary.FundType` via `DWH_staging.etoro_Dictionary_FundType`. ETL: TRUNCATE + INSERT with `Description` renamed to `FundTypeName`. Synapse: REPLICATE, CLUSTERED INDEX (FundTypeID ASC).'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundtype SET TAGS (
    'domain' = 'general',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (FundTypeID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundtype ALTER COLUMN FundTypeID COMMENT 'Primary key identifying the fund category. 1=TopTraders (copy-based), 2=Partners (external strategist), 3=Market (thematic index). Referenced by Trade.Fund to classify each CopyFund/SmartPortfolio. Replicated to SettingsDB for configuration management. (Tier 1 — Dictionary.FundType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundtype ALTER COLUMN FundTypeName COMMENT 'Human-readable label for the fund type. Used in the platform UI, fund details pages, and management reporting. Describes the fundamental strategy approach of the fund category. (Tier 1 — Dictionary.FundType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundtype ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() when SP_Dictionaries_DL_To_Synapse runs. NOT NULL. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundtype ALTER COLUMN FundTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundtype ALTER COLUMN FundTypeName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundtype ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
