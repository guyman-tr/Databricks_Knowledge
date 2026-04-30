-- =============================================================================
-- Databricks ALTER Script: bronze USABroker.History.ApexData
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/History/Tables/History.ApexData.md
-- Layer: bronze
-- UC Target: main.finance.bronze_usabroker_history_apexdata
-- =============================================================================

-- ---- UC Target: main.finance.bronze_usabroker_history_apexdata (business_group=finance) ----
ALTER TABLE main.finance.bronze_usabroker_history_apexdata SET TBLPROPERTIES (
    'comment' = 'System-versioned temporal history table that automatically stores previous versions of Apex.ApexData rows when they are updated, providing a complete audit trail of account status changes. Source: USABroker.History.ApexData on the USABroker production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/History/Tables/History.ApexData.md).'
);

ALTER TABLE main.finance.bronze_usabroker_history_apexdata SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'USABroker',
    'source_schema' = 'History',
    'source_table' = 'ApexData',
    'business_group' = 'finance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.finance.bronze_usabroker_history_apexdata ALTER COLUMN ApexID COMMENT 'Apex Clearing account identifier. Same value as Apex.ApexData.ApexID at the time this version was active. (Tier 1 - upstream wiki, USABroker.History.ApexData)';
ALTER TABLE main.finance.bronze_usabroker_history_apexdata ALTER COLUMN GCID COMMENT 'Global Customer ID. Same value as Apex.ApexData.GCID. (Tier 1 - upstream wiki, USABroker.History.ApexData)';
ALTER TABLE main.finance.bronze_usabroker_history_apexdata ALTER COLUMN StatusID COMMENT 'Account status AT THE TIME this version was active. See Apex Status for values. The transition from one StatusID to the next creates a new history row. (Tier 1 - upstream wiki, USABroker.History.ApexData)';
ALTER TABLE main.finance.bronze_usabroker_history_apexdata ALTER COLUMN BeginTime COMMENT 'When this version became active (was originally written to Apex.ApexData). Part of the temporal period. (Tier 1 - upstream wiki, USABroker.History.ApexData)';
ALTER TABLE main.finance.bronze_usabroker_history_apexdata ALTER COLUMN EndTime COMMENT 'When this version was superseded by a newer version. The update timestamp. Part of the temporal period. Clustered index key (EndTime, BeginTime) for efficient temporal range queries. (Tier 1 - upstream wiki, USABroker.History.ApexData)';
ALTER TABLE main.finance.bronze_usabroker_history_apexdata ALTER COLUMN UpdatedSync COMMENT 'Sync flag value at the time this version was active. Tracks whether the trading platform had synced this version. (Tier 1 - upstream wiki, USABroker.History.ApexData)';

