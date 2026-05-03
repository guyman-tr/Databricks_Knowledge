-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.UserGroupToPermission
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.UserGroupToPermission.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_usergrouptopermission
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_usergrouptopermission (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_usergrouptopermission SET TBLPROPERTIES (
    'comment' = 'Junction table mapping BackOffice user groups to their allowed permissions per provider, forming the core RBAC (Role-Based Access Control) matrix that determines what operations each team can perform in the BackOffice system. Source: etoro.Dictionary.UserGroupToPermission on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.UserGroupToPermission.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_usergrouptopermission SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'UserGroupToPermission',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_usergrouptopermission ALTER COLUMN UserGroupID COMMENT 'The user group receiving the permission. FK to Dictionary.UserGroup(UserGroupID) via FK_DGRP_DG2P. Values map to organizational teams: 1=Administrators, 2=Operations, 3=Risk, etc. See Dictionary.UserGroup for full hierarchy. (Tier 1 - upstream wiki, etoro.Dictionary.UserGroupToPermission)';
ALTER TABLE main.general.bronze_etoro_dictionary_usergrouptopermission ALTER COLUMN PermissionID COMMENT 'The permission being granted. FK to Dictionary.Permission(PermissionID) via FK_DPRM_DG2P. The 148 permissions cover actions like withdrawal approval, customer editing, trade operations, and reporting access. See Dictionary.Permission for full list. (Tier 1 - upstream wiki, etoro.Dictionary.UserGroupToPermission)';
ALTER TABLE main.general.bronze_etoro_dictionary_usergrouptopermission ALTER COLUMN ProviderID COMMENT 'The provider/trading entity scope for this permission. 0=global (applies to all providers), 1+=specific provider entity. Enables multi-entity isolation where some teams can operate on certain providers but not others. (Tier 1 - upstream wiki, etoro.Dictionary.UserGroupToPermission)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
