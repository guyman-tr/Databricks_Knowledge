-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_Label
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_label
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_label SET TBLPROPERTIES (
    'comment' = '`DWH_dbo.Dim_Label` is a reference dictionary for eToro''s white-label broker network -- the companies that licensed the eToro platform to offer it under their own brand to customers in specific regions. Each row maps a LabelID to a brand name (e.g., `RetailFX`, `ICMarkets`, `eToroUSA`, `Euroforex`). The label identifies which white-label channel a customer account originated from or is associated with. The table has 26 rows. Most entries represent historical white-label partners from eToro''s early expansion phase (2010-2015), when the platform was licensed to regional brokers. Some remain active (e.g., `eToroUSA`, `eToroChina`); others (e.g., `JCLyons`, `BT`, `Trend-Online`) are legacy brands that are no longer active. LabelID 0 (`eToro`) and LabelID 1 (`eToro`) are both the core eToro brand -- the distinction between 0 and 1 is a legacy artifact. ETL is part of the bulk `SP_Dictionaries_DL_To_Synapse` stored procedure (runs daily). Source is `DWH_staging.etoro_Dictionary_Label`, which is loaded from the G...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_label SET TAGS (
    'domain' = 'marketing',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (LabelID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_label ALTER COLUMN LabelID COMMENT 'Primary key identifying the platform brand/label. 0/1/9=eToro (primary), 2=RetailFX, 10-26=white-label partners, 14=eToroUSA, 27=Partners, 29=eToroRussia, 30=Dealing, 31=eToroChina. Stored in customer records and referenced across billing, reporting, and registration procedures. (Tier 1 - Dictionary.Label)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_label ALTER COLUMN Name COMMENT 'Brand name displayed in BackOffice interfaces, reports, and internal systems. Multiple LabelIDs can share the same Name (e.g., 0, 1, 9 all = ''eToro''). (Tier 1 - Dictionary.Label)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_label ALTER COLUMN DWHLabelID COMMENT 'Always equal to LabelID. Standard DWH DWH{X}ID redundancy pattern (ETL: `[LabelID] as [DWHLabelID]`). Do not use for JOINs. (Tier 2 -- SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_label ALTER COLUMN StatusID COMMENT 'Hardcoded to 1 for all rows (ETL: `1 as StatusID`). Conveys no business information. (Tier 2 -- SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_label ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp -- GETDATE() at load time. Does not reflect production modification date. (Tier 2 -- SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_label ALTER COLUMN InsertDate COMMENT 'ETL load timestamp -- GETDATE() at load time, identical to UpdateDate (TRUNCATE + INSERT pattern). Does not reflect production insertion date. (Tier 2 -- SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_label ALTER COLUMN LabelID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_label ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_label ALTER COLUMN DWHLabelID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_label ALTER COLUMN StatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_label ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_label ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');
