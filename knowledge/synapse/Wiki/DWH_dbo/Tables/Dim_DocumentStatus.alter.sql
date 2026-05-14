-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_DocumentStatus
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_documentstatus
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_documentstatus SET TBLPROPERTIES (
    'comment' = '`Dim_DocumentStatus` is a 7-row reference dictionary for KYC (Know Your Customer) document review states in the eToro identity verification pipeline. It classifies the review lifecycle of customer-uploaded identity documents: from initial upload (New Upload) through manual review (Reviewed) to final decision (Accepted/Rejected) and specific document-type approvals (POIApproved = Proof of Identity, POAApproved = Proof of Address). The source is `etoro.Dictionary.DocumentStatus`. Both columns are passthroughs from the staging table; only UpdateDate is ETL-computed. The ETL is a full TRUNCATE-and-INSERT daily reload. Upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DocumentStatus.md`. Synapse: REPLICATE, CLUSTERED INDEX (DocumentStatusID ASC).'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_documentstatus SET TAGS (
    'domain' = 'general',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (DocumentStatusID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_documentstatus ALTER COLUMN DocumentStatusID COMMENT 'Primary key identifying the document review state. 1=New Upload, 2=Reviewed, 3=Accepted, 4=Rejected, 5=POIApproved. (Tier 1 - Dictionary.DocumentStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_documentstatus ALTER COLUMN DocumentStatusName COMMENT 'Human-readable status label. Used in compliance review UI, customer communications, and regulatory reporting. (Tier 1 - Dictionary.DocumentStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_documentstatus ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() on each daily full reload by SP_Dictionaries_DL_To_Synapse. Reflects ETL run time, not source data change time. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_documentstatus ALTER COLUMN DocumentStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_documentstatus ALTER COLUMN DocumentStatusName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_documentstatus ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:21:36 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 8/8 succeeded
-- ====================
