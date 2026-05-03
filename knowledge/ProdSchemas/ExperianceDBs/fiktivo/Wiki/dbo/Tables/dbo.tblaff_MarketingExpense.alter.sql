-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.dbo.tblaff_MarketingExpense
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_MarketingExpense.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_marketingexpense
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_marketingexpense (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_marketingexpense SET TBLPROPERTIES (
    'comment' = 'Marketing channel/expense category lookup defining how customer acquisition costs are classified (Affiliate, SEO, SEM, Direct, PR, TV, etc.). Source: fiktivo.dbo.tblaff_MarketingExpense on the fiktivo production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_MarketingExpense.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_marketingexpense SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'dbo',
    'source_table' = 'tblaff_MarketingExpense',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_marketingexpense ALTER COLUMN MarketingExpenseID COMMENT 'Primary key. Referenced by tblaff_Affiliates.MarketingExpenseID and dbo.Channels.MarketingExpenseID. Non-sequential IDs (gap at 10021-10022) suggest later additions. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_MarketingExpense)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_marketingexpense ALTER COLUMN MarketingExpenseName COMMENT 'Display name of the marketing channel. Values include: Affiliate, Media Performance, Direct, SEO, SEM, SMM, Offline Partners, Local Offices, RAF, Local Partners, Introducing Agents, Networks, Mobile media, PR, Sponsorships, Events, Productions, OOH, Club, systems, Content Partnerships, Media Programmatic, TV, Social Organic, Media CPA, Affiliate Branding. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_MarketingExpense)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:51:26 UTC
-- Bronze deploy: fiktivo batch 1
-- ====================
