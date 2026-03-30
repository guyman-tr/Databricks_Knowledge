-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_EvMatchStatus
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_evmatchstatus
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_evmatchstatus SET TBLPROPERTIES (
    'comment' = '`Dim_EvMatchStatus` is a small dictionary table (4 rows) mapping integer codes to human-readable labels for the EV (eVerification) identity matching process. "EV" refers to the automated document/identity verification matching pipeline used by eToro to satisfy KYC (Know Your Customer) regulatory requirements. The four statuses indicate whether a customer''s identity documents have been matched against a verification provider: 0=None (no match attempted), 1=PartiallyVerified, 2=Verified, 3=NotVerified. The data originates from `UserApiDB.Dictionary.EvMatchStatus` on the `UserApiDB-REAL` production server. UserApiDB is the eToro user/customer API backend database. The Generic Pipeline does not appear to export this specific dictionary table to the Bronze lake directly; instead, the DWH staging table `DWH_staging.UserApiDB_Dictionary_EvMatchStatus` is loaded via a separate mechanism, then consumed by `SP_Dictionaries_DL_To_Synapse`. `SP_Dictionaries_DL_To_Synapse` runs the ETL: TRUNCATE `Dim_EvMatchStatus`, th...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_evmatchstatus SET TAGS (
    'domain' = 'general',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (EvMatchStatusID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_evmatchstatus ALTER COLUMN EvMatchStatusID COMMENT 'Primary key. Integer code identifying the EV (eVerification) identity match status. Values: 0=None, 1=PartiallyVerified, 2=Verified, 3=NotVerified. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_evmatchstatus ALTER COLUMN EvMatchStatusName COMMENT 'Human-readable label for the EV match status. Renamed from `Name` in the production source. Values: None, PartiallyVerified, Verified, NotVerified. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_evmatchstatus ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp set to GETDATE() when SP_Dictionaries_DL_To_Synapse runs. Does not reflect production source update time. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_evmatchstatus ALTER COLUMN EvMatchStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_evmatchstatus ALTER COLUMN EvMatchStatusName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_evmatchstatus ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:21:40 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 8/8 succeeded
-- ====================
