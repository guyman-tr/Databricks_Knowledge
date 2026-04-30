-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.Dictionary.ChangedSections
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/Dictionary/Tables/Dictionary.ChangedSections.md
-- Layer: bronze
-- UC Target: main.general.bronze_fiktivo_dictionary_changedsections
-- =============================================================================

-- ---- UC Target: main.general.bronze_fiktivo_dictionary_changedsections (business_group=general) ----
ALTER TABLE main.general.bronze_fiktivo_dictionary_changedsections SET TBLPROPERTIES (
    'comment' = 'Lookup table identifying which business area or entity was modified in audit log entries, mapping each audit record to the specific configuration or data section that changed. Source: fiktivo.Dictionary.ChangedSections on the fiktivo production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/Dictionary/Tables/Dictionary.ChangedSections.md).'
);

ALTER TABLE main.general.bronze_fiktivo_dictionary_changedsections SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'Dictionary',
    'source_table' = 'ChangedSections',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_fiktivo_dictionary_changedsections ALTER COLUMN SectionID COMMENT 'Primary key identifying the business area affected by an audit-logged change. Values: 1=Affiliates, 2=AffiliateTypes, 3=Affiliate Group, 4=Announcements, 5=Categories, 6=Countries, 7=Brands, 8=Languages, 9=Payment Details, 10=MediaTag, 11=RegistrationRates, 12=FirstPositionAssetPlan, 13=BlockedCountries, 14=AffiliateURLs, 15=Tier2Members, 16=AffiliateTypeCategories, 17=AffiliatePixel, 18=Banners, 19=IOBPlan, 20=ISAPlan. See Changed Sections for full definitions. (Tier 1 - upstream wiki, fiktivo.Dictionary.ChangedSections)';
ALTER TABLE main.general.bronze_fiktivo_dictionary_changedsections ALTER COLUMN Name COMMENT 'Human-readable label for the business area. Used in audit log displays to show which part of the system was modified. Names match the business domain entities they represent. (Tier 1 - upstream wiki, fiktivo.Dictionary.ChangedSections)';

