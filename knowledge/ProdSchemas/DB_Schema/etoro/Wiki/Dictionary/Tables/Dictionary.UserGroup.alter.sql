-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.UserGroup
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.UserGroup.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_usergroup
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_usergroup (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_usergroup SET TBLPROPERTIES (
    'comment' = 'Hierarchical organizational tree of BackOffice user groups (departments, teams, regional offices) used to assign permissions, route withdrawal approvals, manage affiliate relationships, and segment internal staff across the platform. Source: etoro.Dictionary.UserGroup on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.UserGroup.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_usergroup SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'UserGroup',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_usergroup ALTER COLUMN UserGroupID COMMENT 'Unique identifier for the user group. Manually assigned, not auto-incrementing. Referenced by 30+ procedures for permission checks, approval routing, and manager assignment. Values range from 1-53 with gaps. (Tier 1 - upstream wiki, etoro.Dictionary.UserGroup)';
ALTER TABLE main.general.bronze_etoro_dictionary_usergroup ALTER COLUMN Name COMMENT 'Display name of the group (e.g., "Administrators", "Risk", "Sales/Support"). Unique constraint (DGRP_NAME index) prevents duplicate group names. Used in BackOffice UI for group selection dropdowns and approval displays. (Tier 1 - upstream wiki, etoro.Dictionary.UserGroup)';
ALTER TABLE main.general.bronze_etoro_dictionary_usergroup ALTER COLUMN ParentID COMMENT 'Self-referencing FK to UserGroupID - points to this group''s parent in the organizational hierarchy. NULL for root-level departments (Administrators, Operations, Marketing, Trading, AML). FK_DUSG_DUSG enforces referential integrity. Indexed (DGRP_PARENT) for efficient hierarchy traversal. (Tier 1 - upstream wiki, etoro.Dictionary.UserGroup)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
