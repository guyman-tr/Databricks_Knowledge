-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_VerificationStatus
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationstatus
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationstatus SET TBLPROPERTIES (
    'comment' = '`DWH_dbo.Dim_VerificationStatus` is a 3-row reference table holding verification status values from the UserApiDB system - a separate verification workflow database distinct from the main etoroDB. While `Dim_VerificationLevel` (etoro.Dictionary) tracks the KYC tier (Level 0-3), this table tracks the verification *workflow state* within UserApiDB''s verification pipeline. Source: `UserApiDB.Dictionary.VerificationStatus`. The Generic Pipeline exports this daily to Bronze, staged into `DWH_staging.UserApiDB_Dictionary_VerificationStatus`, and SP_Dictionaries_DL_To_Synapse loads with TRUNCATE + INSERT. No upstream wiki exists for this table (UserApiDB schema not yet documented). The exact business meaning of each status value (VerificationStatusID) is derived from SP code and live data sampling only. With 3 rows observed at Phase 2, this is a compact classification table for verification workflow states. Synapse: REPLICATE, CLUSTERED (VerificationStatusID ASC).'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationstatus SET TAGS (
    'domain' = 'customer',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED (VerificationStatusID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationstatus ALTER COLUMN VerificationStatusID COMMENT 'Nullable integer identifier for the verification status, sourced from UserApiDB_Dictionary_VerificationStatus. Not declared as a primary key or indexed in the DDL.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationstatus ALTER COLUMN Name COMMENT 'Human-readable label for the verification status. The name values observed (3 rows) describe verification workflow states from the UserApiDB system. Truncated to varchar(20) - longer names may be clipped. (Tier 3 - Phase 2 live sample)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationstatus ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Not a production change timestamp. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationstatus ALTER COLUMN VerificationStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationstatus ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationstatus ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:27:13 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 8/8 succeeded
-- ====================
