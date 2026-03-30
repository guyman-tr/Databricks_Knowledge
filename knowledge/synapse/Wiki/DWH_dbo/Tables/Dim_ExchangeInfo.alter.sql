-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_ExchangeInfo
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_exchangeinfo
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_exchangeinfo SET TBLPROPERTIES (
    'comment' = '`Dim_ExchangeInfo` is a 51-row dictionary mapping integer `ExchangeID` codes to descriptive labels for financial exchanges and broad market categories. The descriptions cover global stock exchanges (Nasdaq, NYSE, LSE, Euronext Paris, Bolsa De Madrid, Borsa Italiana, SIX, TYO, Oslo, Stockholm, etc.) as well as broad asset class categories (FX, Commodity, CFD, Digital Currency). This dimension represents the marketplace or market type where a financial instrument is traded. The data originates from `etoro.Dictionary.ExchangeInfo` on the production etoroDB-REAL server. It is exported via the Generic Pipeline to the DWH staging layer as `DWH_staging.etoro_Dictionary_ExchangeInfo`, then loaded to DWH by `SP_Dictionaries_DL_To_Synapse`. **Important**: As of the last pipeline analysis, `ExchangeID` appears to have been removed (commented out) from `Dim_Instrument` and `SP_Fact_CustomerUnrealized_PnL`. This means `Dim_ExchangeInfo` is currently **not actively referenced as a foreign key** by any DWH table. It is m...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_exchangeinfo SET TAGS (
    'domain' = 'finance',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (ExchangeID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_exchangeinfo ALTER COLUMN ExchangeID COMMENT 'Primary key. Exchange identifier. Production values 1-56; test values 99+. (Tier 1 - Dictionary.ExchangeInfo)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_exchangeinfo ALTER COLUMN ExchangeDescription COMMENT 'Exchange name or abbreviation. (Tier 1 - Dictionary.ExchangeInfo)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_exchangeinfo ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp set to GETDATE() when SP_Dictionaries_DL_To_Synapse runs. Does not reflect production data update time. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_exchangeinfo ALTER COLUMN ExchangeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_exchangeinfo ALTER COLUMN ExchangeDescription SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_exchangeinfo ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:21:43 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 8/8 succeeded
-- ====================
