-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.dbo.tblaff_Languages
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Languages.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_languages
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_languages (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_languages SET TBLPROPERTIES (
    'comment' = 'Language definitions used across the affiliate platform for localizing banners, landing pages, and affiliate communications. Source: fiktivo.dbo.tblaff_Languages on the fiktivo production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Languages.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_languages SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'dbo',
    'source_table' = 'tblaff_Languages',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_languages ALTER COLUMN LanguageID COMMENT 'Primary key. Auto-incrementing identifier for each language entry. Referenced by tblaff_Groups.LanguageID, tblaff_Banners.LanguageID, and tblaff_Affiliates.CommunicationLangID. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Languages)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_languages ALTER COLUMN LanguageName COMMENT 'English name of the language (e.g., "English", "Spanish", "German"). Used in admin UI dropdowns and reports. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Languages)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_languages ALTER COLUMN IsCommunicationLanguage COMMENT 'Whether this language is available for affiliate email communications. 1 = can be selected as an affiliate''s communication preference (104 entries). 0 = used only for banner/landing page targeting (951 entries). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Languages)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_languages ALTER COLUMN LanguageNaturalName COMMENT 'Native-script name of the language (e.g., "Deutsch", "Francais", "Arabic script"). Displayed in locale selectors. NULL/blank for languages with limited support. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Languages)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_languages ALTER COLUMN TLDURL COMMENT 'Base top-level domain URL for this locale. Routes affiliate tracking links to the correct regional site (e.g., etoro.it for Italian, etoro.fr for French). Defaults to main etoro.com domain. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Languages)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_languages ALTER COLUMN DefaultLandingPage COMMENT 'Custom landing page URL for affiliate traffic in this language. When set, overrides the TLDURL for campaign-specific routing. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Languages)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_languages ALTER COLUMN TierTwoLandingPage COMMENT 'Alternate landing page URL for tier-2 (sub-affiliate) traffic. Allows different conversion funnels for direct vs sub-affiliate traffic. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Languages)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_languages ALTER COLUMN Code COMMENT 'BCP 47/IETF language tag (e.g., "en-gb", "es-es", "zh-cn"). Used for locale matching in tracking URLs and API integrations. Unique constraint ensures no duplicate locale codes. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Languages)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:51:26 UTC
-- Bronze deploy: fiktivo batch 1
-- ====================
