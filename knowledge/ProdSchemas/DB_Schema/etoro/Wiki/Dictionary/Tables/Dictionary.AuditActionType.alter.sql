-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.AuditActionType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AuditActionType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_auditactiontype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_auditactiontype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_auditactiontype SET TBLPROPERTIES (
    'comment' = 'Comprehensive lookup table of 358 BackOffice audit action types - every auditable operation performed by operators and system processes, from deposit processing to account status changes to compliance actions. Source: etoro.Dictionary.AuditActionType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AuditActionType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_auditactiontype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'AuditActionType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_auditactiontype ALTER COLUMN AuditActionTypeID COMMENT 'Primary key identifying the auditable action. Values 1-358 (with gaps). Written to audit log by BackOffice.AuditActionAdd and AuditActionAdd_V2. Read by BackOffice.GetAuditHistory to resolve action names. Each value represents a specific BackOffice operation that requires audit tracking. (Tier 1 - upstream wiki, etoro.Dictionary.AuditActionType)';
ALTER TABLE main.general.bronze_etoro_dictionary_auditactiontype ALTER COLUMN AuditActionTypeName COMMENT 'Descriptive name of the audit action, often matching the stored procedure name that performs the operation (e.g., ''BackOffice.CustomerSetRiskClassification'', ''Billing.WithdrawRequestAdd''). Nullable but all current rows have values. VARCHAR(MAX) accommodates long procedure-style names. (Tier 1 - upstream wiki, etoro.Dictionary.AuditActionType)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
