-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.Groups
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Groups.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_groups
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_groups (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_groups SET TBLPROPERTIES (
    'comment' = 'Lookup table defining internal user groups for BackOffice permission management — organizing dealing team members, CM tool users, and system operators into role-based access groups. Source: etoro.Dictionary.Groups on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Groups.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_groups SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'Groups',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_groups ALTER COLUMN GroupID COMMENT 'Primary key identifying the user group. Values: 1=All-Dealers, 2=Dealing-Managers, 5=Dealing-Seniors, 6=Reopen-Positions-Operation, 7=Dealing-CM-Tool, 8=Dealing-Special-Permissions, 9=Trading-CM-SystemOperations, 12=Trading-Core, 13=CEP-Users, 14=Dealers-Seniors, 15=USOPS-CM, 16=foglight-stg. Referenced by Internal.GroupsAndRoles for user-to-group assignment. (Tier 1 - upstream wiki, etoro.Dictionary.Groups)';
ALTER TABLE main.general.bronze_etoro_dictionary_groups ALTER COLUMN GroupName COMMENT 'Machine-readable group identifier using hyphenated naming convention (e.g., "All-Dealers", "Trading-CM-SystemOperations"). Used in Internal.CheckSinglePermission for programmatic permission checks. (Tier 1 - upstream wiki, etoro.Dictionary.Groups)';
ALTER TABLE main.general.bronze_etoro_dictionary_groups ALTER COLUMN GroupDesc COMMENT 'Human-readable description of the group''s purpose and access level. Displayed in BackOffice user management UI. Explains what operations group members are authorized to perform. (Tier 1 - upstream wiki, etoro.Dictionary.Groups)';

