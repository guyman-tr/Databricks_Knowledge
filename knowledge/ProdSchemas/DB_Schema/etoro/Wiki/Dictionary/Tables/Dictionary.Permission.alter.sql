-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.Permission
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Permission.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_permission
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_permission (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_permission SET TBLPROPERTIES (
    'comment' = 'Master registry of 148 BackOffice permission definitions — granular access controls covering trading operations, customer management, compliance, financial operations, CopyTrading, and administrative functions. Source: etoro.Dictionary.Permission on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Permission.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_permission SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'Permission',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_permission ALTER COLUMN PermissionID COMMENT 'Primary key identifying the permission. 148 values covering all BackOffice functions. Referenced by Dictionary.UserGroupToPermission (group assignment) and BackOffice.ManagerToPermission (direct user assignment). (Tier 1 - upstream wiki, etoro.Dictionary.Permission)';
ALTER TABLE main.general.bronze_etoro_dictionary_permission ALTER COLUMN Name COMMENT 'Unique short code for the permission. Enforced unique by DPRM_NAME index. Used programmatically in permission checks (e.g., "Allow close position", "Compliance", "RightToBeForgotten"). (Tier 1 - upstream wiki, etoro.Dictionary.Permission)';
ALTER TABLE main.general.bronze_etoro_dictionary_permission ALTER COLUMN Description COMMENT 'Human-readable description explaining what the permission grants. Displayed in BackOffice user management screens. Some entries are empty (PermissionID 127). (Tier 1 - upstream wiki, etoro.Dictionary.Permission)';

