-- =============================================================================
-- Databricks ALTER Script: bronze USABroker.apex.ApexData
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.ApexData.md
-- Layer: bronze
-- UC Target: main.finance.bronze_usabroker_apex_apexdata
-- =============================================================================

-- ---- UC Target: main.finance.bronze_usabroker_apex_apexdata (business_group=finance) ----
ALTER TABLE main.finance.bronze_usabroker_apex_apexdata SET TBLPROPERTIES (
    'comment' = 'Core mapping table linking each customer (GCID) to their Apex Clearing brokerage account (ApexID) and tracking the high-level account status. Source: USABroker.apex.ApexData on the USABroker production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.ApexData.md).'
);

ALTER TABLE main.finance.bronze_usabroker_apex_apexdata SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'USABroker',
    'source_schema' = 'apex',
    'source_table' = 'ApexData',
    'business_group' = 'finance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.finance.bronze_usabroker_apex_apexdata ALTER COLUMN ApexID COMMENT 'The unique account identifier assigned by Apex Clearing. Format observed: "3ER" prefix + 5-digit numeric sequence (e.g., "3ER05011"). This is the primary key and the external identifier used in all API calls to Apex. Maximum 8 characters. Immutably bound to one GCID - SaveApexData throws error 51000 if an attempt is made to reassign an ApexID to a different customer. (Tier 1 - upstream wiki, USABroker.apex.ApexData)';
ALTER TABLE main.finance.bronze_usabroker_apex_apexdata ALTER COLUMN GCID COMMENT 'Global Customer ID - the platform''s unique identifier for a user. Each GCID appears at most once (UNIQUE constraint), enforcing a 1:1 relationship between platform customers and Apex accounts. Used as the primary lookup key by GetApexData and as the JOIN key across all Apex schema tables. (Tier 1 - upstream wiki, USABroker.apex.ApexData)';
ALTER TABLE main.finance.bronze_usabroker_apex_apexdata ALTER COLUMN StatusID COMMENT 'High-level lifecycle status of the Apex brokerage account. FK to Dictionary.ApexStatus. Distribution: 12=COMPLETE (604,566 - 79%), 11=REJECTED (68,370 - 9%), 15=RESTRICTED (46,871 - 6%), 4=ACTION_REQUIRED (40,010 - 5%), 5=SUSPENDED (3,476), 10=ERROR (39), 3=INVESTIGATION_SUBMITTED (12), 2=PENDING (4), 7=BACK_OFFICE (2), 8=ACCOUNT_SETUP (1). See Apex Status for full definitions. (Dictionary.ApexStatus) (Tier 1 - upstream wiki, USABroker.apex.ApexData)';
ALTER TABLE main.finance.bronze_usabroker_apex_apexdata ALTER COLUMN BeginTime COMMENT 'System versioning row start time. Records when this version of the row became active. Default is 1 second before current UTC time (offset to avoid temporal table edge cases). Used by GetApexData to return creation/modification timestamps to callers. Part of SYSTEM_TIME period for temporal table History.ApexData. (Tier 1 - upstream wiki, USABroker.apex.ApexData)';
ALTER TABLE main.finance.bronze_usabroker_apex_apexdata ALTER COLUMN EndTime COMMENT 'System versioning row end time. Value of ''9999-12-31'' indicates the current active row. When a row is updated, the old version''s EndTime is set to the update time and moved to History.ApexData. Part of SYSTEM_TIME period. (Tier 1 - upstream wiki, USABroker.apex.ApexData)';
ALTER TABLE main.finance.bronze_usabroker_apex_apexdata ALTER COLUMN UpdatedSync COMMENT 'Synchronization flag for the trading platform. Set to 0 (false) by SaveApexData whenever StatusID changes, signaling the trading platform that this account''s status needs to be re-synced. The trading platform reads records with UpdatedSync=0, processes them, and sets it to 1 (true). Default is 0 (needs sync) for new records. Distribution: ~722K false (synced), ~42K true. (Tier 1 - upstream wiki, USABroker.apex.ApexData)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:47:20 UTC
-- Bronze deploy: USABroker batch 1
-- ====================
