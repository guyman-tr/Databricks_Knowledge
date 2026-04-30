-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.dbo.tblaff_AffiliatesGroups
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_AffiliatesGroups.md
-- Layer: bronze
-- UC Targets (2):
--   main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatesgroups_masked
--   main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatesgroups
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatesgroups_masked (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatesgroups_masked SET TBLPROPERTIES (
    'comment' = 'Organizational groups that partition affiliates for management assignment, reporting segmentation, and access control scoping. Source: fiktivo.dbo.tblaff_AffiliatesGroups on the fiktivo production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_AffiliatesGroups.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatesgroups_masked SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'dbo',
    'source_table' = 'tblaff_AffiliatesGroups',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatesgroups_masked ALTER COLUMN AffiliatesGroupsID COMMENT 'Primary key. Referenced by tblaff_Affiliates.AffiliatesGroupsID, tblaff_Country.AffiliatesGroupsID, dbo.Channels.AffiliatesGroupsID, and tblaff_AffiliateGroups_Viewers. ID=1 is the "view all" sentinel. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliatesGroups)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatesgroups_masked ALTER COLUMN AffiliatesGroupsName COMMENT 'Display name of the group (e.g., "Affiliates", "Media", "SEM"). Shown in admin UI dropdowns, reports, and affiliate portal. MASKED (dynamic data masking) in non-privileged contexts. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliatesGroups)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatesgroups_masked ALTER COLUMN AccountManagerName COMMENT 'Display name of the assigned account manager. MASKED. Denormalized from tblaff_User for quick display. May be blank if no manager assigned. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliatesGroups)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatesgroups_masked ALTER COLUMN AccountManagerEmail COMMENT 'Email of the assigned account manager. MASKED. Used in Dynamics CRM sync trigger for group manager change notifications. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliatesGroups)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatesgroups_masked ALTER COLUMN AccountManagerImagePath COMMENT 'URL/path to the account manager''s profile photo. Displayed in the affiliate portal alongside the group contact information. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliatesGroups)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatesgroups_masked ALTER COLUMN ManagerUserID COMMENT 'FK to dbo.tblaff_User.UserID. The admin user responsible for this group. 0 or NULL = no dedicated manager. Used in the Dynamics CRM sync trigger. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliatesGroups)';

-- ---- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatesgroups (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatesgroups SET TBLPROPERTIES (
    'comment' = 'Organizational groups that partition affiliates for management assignment, reporting segmentation, and access control scoping. Source: fiktivo.dbo.tblaff_AffiliatesGroups on the fiktivo production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_AffiliatesGroups.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatesgroups SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'dbo',
    'source_table' = 'tblaff_AffiliatesGroups',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatesgroups ALTER COLUMN AffiliatesGroupsID COMMENT 'Primary key. Referenced by tblaff_Affiliates.AffiliatesGroupsID, tblaff_Country.AffiliatesGroupsID, dbo.Channels.AffiliatesGroupsID, and tblaff_AffiliateGroups_Viewers. ID=1 is the "view all" sentinel. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliatesGroups)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatesgroups ALTER COLUMN AffiliatesGroupsName COMMENT 'Display name of the group (e.g., "Affiliates", "Media", "SEM"). Shown in admin UI dropdowns, reports, and affiliate portal. MASKED (dynamic data masking) in non-privileged contexts. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliatesGroups)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatesgroups ALTER COLUMN AccountManagerName COMMENT 'Display name of the assigned account manager. MASKED. Denormalized from tblaff_User for quick display. May be blank if no manager assigned. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliatesGroups)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatesgroups ALTER COLUMN AccountManagerEmail COMMENT 'Email of the assigned account manager. MASKED. Used in Dynamics CRM sync trigger for group manager change notifications. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliatesGroups)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatesgroups ALTER COLUMN AccountManagerImagePath COMMENT 'URL/path to the account manager''s profile photo. Displayed in the affiliate portal alongside the group contact information. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliatesGroups)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatesgroups ALTER COLUMN ManagerUserID COMMENT 'FK to dbo.tblaff_User.UserID. The admin user responsible for this group. 0 or NULL = no dedicated manager. Used in the Dynamics CRM sync trigger. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_AffiliatesGroups)';

