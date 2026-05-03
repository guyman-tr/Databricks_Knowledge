-- =============================================================================
-- Databricks ALTER Script: bronze Sodreconciliation.apex.SodFiles
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.SodFiles.md
-- Layer: bronze
-- UC Target: main.finance.bronze_sodreconciliation_apex_sodfiles
-- =============================================================================

-- ---- UC Target: main.finance.bronze_sodreconciliation_apex_sodfiles (business_group=finance) ----
ALTER TABLE main.finance.bronze_sodreconciliation_apex_sodfiles SET TBLPROPERTIES (
    'comment' = 'Master registry of all SOD (Start-of-Day) files imported from Apex Clearing Corporation. Each row represents a single file ingested from Azure Blob Storage, tracking its source URL, processing status, extract format, and any errors. Source: Sodreconciliation.apex.SodFiles on the Sodreconciliation production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.SodFiles.md).'
);

ALTER TABLE main.finance.bronze_sodreconciliation_apex_sodfiles SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'Sodreconciliation',
    'source_schema' = 'apex',
    'source_table' = 'SodFiles',
    'business_group' = 'finance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.finance.bronze_sodreconciliation_apex_sodfiles ALTER COLUMN Id COMMENT 'Primary key. Auto-generated sequential GUID for each imported file. Referenced by all EXT tables via SodFileId FK. (Tier 1 - upstream wiki, Sodreconciliation.apex.SodFiles)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_sodfiles ALTER COLUMN BlobUrl COMMENT 'Full URL to the source file in Azure Blob Storage. Format: https://{account}.blob.core.windows.net/blob-container/{YYYYMMDD}/EXT{num}/EXT{num}_{correspondent}_{YYYYMMDD}.CSV. Contains the date, extract number, and correspondent code in the path. (Tier 1 - upstream wiki, Sodreconciliation.apex.SodFiles)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_sodfiles ALTER COLUMN ImportStartDate COMMENT 'Timestamp when the Azure Function started processing this file. Auto-set to current time on row creation. (Tier 1 - upstream wiki, Sodreconciliation.apex.SodFiles)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_sodfiles ALTER COLUMN ImportEndDate COMMENT 'Timestamp when processing completed (success, fail, or invalid). NULL while Status=InProgress. (Tier 1 - upstream wiki, Sodreconciliation.apex.SodFiles)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_sodfiles ALTER COLUMN ProcessDate COMMENT 'The business date this file belongs to (extracted from the file path date folder, e.g., 20260411 -> 2026-04-11). This is the date the data represents at Apex, not the import timestamp. (Tier 1 - upstream wiki, Sodreconciliation.apex.SodFiles)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_sodfiles ALTER COLUMN ApexFormat COMMENT 'Apex extract format number identifying the file type. Maps to the EXT table: 1=EXT001, 235=EXT235, 747=EXT747, 871=EXT871, etc. 0=Unknown/unrecognized format. Determines which parser and target table the Azure Function uses. (Tier 1 - upstream wiki, Sodreconciliation.apex.SodFiles)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_sodfiles ALTER COLUMN Status COMMENT 'File processing status. FK to dict.SodFileProcessingStatuses: 0=Unknown, 1=InProgress, 2=Success, 3=Fail, 4=Invalid. Default 0 (Unknown) on creation. (Tier 1 - upstream wiki, Sodreconciliation.apex.SodFiles)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_sodfiles ALTER COLUMN ErrorMessage COMMENT 'Error details when Status=3 (Fail) or Status=4 (Invalid). Contains exception stack traces for failures, or "Unknown file format" messages for invalid files. NULL on success. (Tier 1 - upstream wiki, Sodreconciliation.apex.SodFiles)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:42:23 UTC
-- Bronze deploy: Sodreconciliation batch 1
-- ====================
