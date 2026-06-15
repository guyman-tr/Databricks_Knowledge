-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_fiktivo_dbo_tblaff_languages  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Languages.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_languages ALTER COLUMN LanguageID COMMENT 'Primary key. Auto-incrementing identifier for each language entry. Referenced by tblaff_Groups.LanguageID, tblaff_Banners.LanguageID, and tblaff_Affiliates.CommunicationLangID.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_languages ALTER COLUMN LanguageName COMMENT 'English name of the language (e.g., "English", "Spanish", "German"). Used in admin UI dropdowns and reports.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_languages ALTER COLUMN IsCommunicationLanguage COMMENT 'Whether this language is available for affiliate email communications. 1 = can be selected as an affiliate''s communication preference (104 entries). 0 = used only for banner/landing page targeting (951 entries).';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_languages ALTER COLUMN LanguageNaturalName COMMENT 'Native-script name of the language (e.g., "Deutsch", "Francais", "Arabic script"). Displayed in locale selectors. NULL/blank for languages with limited support.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_languages ALTER COLUMN TLDURL COMMENT 'Base top-level domain URL for this locale. Routes affiliate tracking links to the correct regional site (e.g., etoro.it for Italian, etoro.fr for French). Defaults to main etoro.com domain.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_languages ALTER COLUMN DefaultLandingPage COMMENT 'Custom landing page URL for affiliate traffic in this language. When set, overrides the TLDURL for campaign-specific routing.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_languages ALTER COLUMN TierTwoLandingPage COMMENT 'Alternate landing page URL for tier-2 (sub-affiliate) traffic. Allows different conversion funnels for direct vs sub-affiliate traffic.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_languages ALTER COLUMN Code COMMENT 'BCP 47/IETF language tag (e.g., "en-gb", "es-es", "zh-cn"). Used for locale matching in tracking URLs and API integrations. Unique constraint ensures no duplicate locale codes.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:28:29 UTC
-- Statements: 8/8 succeeded
-- ====================
