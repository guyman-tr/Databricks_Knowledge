-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.dbo.Channels
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.Channels.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_fiktivo_dbo_channels
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiktivo_dbo_channels (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_channels SET TBLPROPERTIES (
    'comment' = 'Denormalized lookup mapping affiliates to their group and marketing expense channel, combining IDs with display names for fast reporting. Source: fiktivo.dbo.Channels on the fiktivo production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.Channels.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_dbo_channels SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'dbo',
    'source_table' = 'Channels',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_channels ALTER COLUMN AffiliateID COMMENT 'Primary key. References dbo.tblaff_Affiliates. One channel entry per affiliate. (Tier 1 - upstream wiki, fiktivo.dbo.Channels)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_channels ALTER COLUMN AffiliatesGroupsID COMMENT 'The affiliate''s group ID. Denormalized from tblaff_Affiliates.AffiliatesGroupsID. (Tier 1 - upstream wiki, fiktivo.dbo.Channels)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_channels ALTER COLUMN MarketingExpenseID COMMENT 'Marketing expense channel ID. Denormalized from tblaff_Affiliates.MarketingExpenseID. (Tier 1 - upstream wiki, fiktivo.dbo.Channels)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_channels ALTER COLUMN MarketingExpenseName COMMENT 'Display name of the marketing expense channel. Denormalized from tblaff_MarketingExpense.MarketingExpenseName. (Tier 1 - upstream wiki, fiktivo.dbo.Channels)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_channels ALTER COLUMN AffiliatesGroupsName COMMENT 'Display name of the affiliate group. Denormalized from tblaff_AffiliatesGroups.AffiliatesGroupsName. (Tier 1 - upstream wiki, fiktivo.dbo.Channels)';

