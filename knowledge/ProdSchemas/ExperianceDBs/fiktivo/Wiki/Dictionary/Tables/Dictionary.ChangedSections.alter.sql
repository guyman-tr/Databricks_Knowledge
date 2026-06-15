-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_fiktivo_dictionary_changedsections  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/Dictionary/Tables/Dictionary.ChangedSections.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_fiktivo_dictionary_changedsections ALTER COLUMN SectionID COMMENT 'Primary key identifying the business area affected by an audit-logged change. Values: 1=Affiliates, 2=AffiliateTypes, 3=Affiliate Group, 4=Announcements, 5=Categories, 6=Countries, 7=Brands, 8=Languages, 9=Payment Details, 10=MediaTag, 11=RegistrationRates, 12=FirstPositionAssetPlan, 13=BlockedCountries, 14=AffiliateURLs, 15=Tier2Members, 16=AffiliateTypeCategories, 17=AffiliatePixel, 18=Banners, 19=IOBPlan, 20=ISAPlan. See [Changed Sections](../../_glossary.md#changed-sections) for full definitions.';
ALTER TABLE main.general.bronze_fiktivo_dictionary_changedsections ALTER COLUMN Name COMMENT 'Human-readable label for the business area. Used in audit log displays to show which part of the system was modified. Names match the business domain entities they represent.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:57:10 UTC
-- Statements: 2/2 succeeded
-- ====================
