-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.AuditHistory
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.AuditHistory.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_audithistory
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_audithistory (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_audithistory SET TBLPROPERTIES (
    'comment' = 'Centralized column-level audit log maintained by the ASM (Audit Security Manager) trigger framework, recording every INSERT, UPDATE, and DELETE on tracked configuration tables across 26 tables in 6 schemas, from March 2014 to present. Source: etoro.History.AuditHistory on the etoro production database, ingested via the Generic Pipeline (Append strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.AuditHistory.md).'
);

ALTER TABLE main.general.bronze_etoro_history_audithistory SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'AuditHistory',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_audithistory ALTER COLUMN AuditHistoryID COMMENT 'Surrogate PK. Auto-generated IDENTITY, NOT FOR REPLICATION (independent sequence per replica). Clustered PK. (Tier 1 - upstream wiki, etoro.History.AuditHistory)';
ALTER TABLE main.general.bronze_etoro_history_audithistory ALTER COLUMN AuditDate COMMENT 'Local server timestamp when the change was recorded (GETDATE(), NOT UTC). Marks when the ASM trigger fired. Note: NOT UTC - see Section 2.3. (Tier 1 - upstream wiki, etoro.History.AuditHistory)';
ALTER TABLE main.general.bronze_etoro_history_audithistory ALTER COLUMN Operation COMMENT 'Change type: ''I''=Insert (4.99M, 65%), ''U''=Update (765K, 10%), ''D''=Delete (1.98M, 26%). Single-character code from the ASM trigger pattern. (Tier 1 - upstream wiki, etoro.History.AuditHistory)';
ALTER TABLE main.general.bronze_etoro_history_audithistory ALTER COLUMN UserName COMMENT 'Database login name that made the change. Resolved by Internal.GetUserAndAppName, fallback to SUSER_SNAME(). May be a service account (e.g., "DevTradingSTG"), a DBA login, or an application pool identity. (Tier 1 - upstream wiki, etoro.History.AuditHistory)';
ALTER TABLE main.general.bronze_etoro_history_audithistory ALTER COLUMN AppName COMMENT 'Application name that made the change. Resolved by Internal.GetUserAndAppName, fallback to app_name(). Examples: "SSMS" (direct DBA access), application service names, stored procedure names. (Tier 1 - upstream wiki, etoro.History.AuditHistory)';
ALTER TABLE main.general.bronze_etoro_history_audithistory ALTER COLUMN HostName COMMENT 'Hostname of the connection that triggered the change. From host_name() SQL Server function. Identifies the server or workstation that initiated the DML. (Tier 1 - upstream wiki, etoro.History.AuditHistory)';
ALTER TABLE main.general.bronze_etoro_history_audithistory ALTER COLUMN SchemaName COMMENT 'SQL Server schema of the changed table. Known values from data: Trade, Hedge, BackOffice, Dictionary, Price, History. (Tier 1 - upstream wiki, etoro.History.AuditHistory)';
ALTER TABLE main.general.bronze_etoro_history_audithistory ALTER COLUMN TableName COMMENT 'Name of the changed table (without schema). Combined with SchemaName uniquely identifies the audited object. 26 distinct tables in current data. (Tier 1 - upstream wiki, etoro.History.AuditHistory)';
ALTER TABLE main.general.bronze_etoro_history_audithistory ALTER COLUMN PK_Value COMMENT 'Primary key value(s) of the changed row, concatenated with commas. Format varies by table (each trigger hardcodes its own PK columns). Example: "1,4" for a 2-column PK (ProviderID=1, InstrumentID=4). NULL-able but always populated in practice. (Tier 1 - upstream wiki, etoro.History.AuditHistory)';
ALTER TABLE main.general.bronze_etoro_history_audithistory ALTER COLUMN ColumnName COMMENT 'The specific column that changed. One row in this table represents ONE column change. An UPDATE to 5 columns generates 5 rows with the same AuditDate, PK_Value, and UserName but different ColumnName/OldValue/NewValue. (Tier 1 - upstream wiki, etoro.History.AuditHistory)';
ALTER TABLE main.general.bronze_etoro_history_audithistory ALTER COLUMN OldValue COMMENT 'Previous value of the column, cast to VARCHAR(MAX). NULL for INSERT operations. For UPDATE: the value before the change. For DELETE: the value before deletion. (Tier 1 - upstream wiki, etoro.History.AuditHistory)';
ALTER TABLE main.general.bronze_etoro_history_audithistory ALTER COLUMN NewValue COMMENT 'New value of the column, cast to VARCHAR(MAX). NULL for DELETE operations. For INSERT: the value after insertion. For UPDATE: the value after the change. (Tier 1 - upstream wiki, etoro.History.AuditHistory)';
ALTER TABLE main.general.bronze_etoro_history_audithistory ALTER COLUMN ExistingFeedID COMMENT 'Price feed identifier, populated ONLY for Trade.InstrumentSpread rows (107K records with values 1 or 2). Identifies which price feed source the spread configuration applies to. NULL for all other audited tables. (Tier 1 - upstream wiki, etoro.History.AuditHistory)';

