-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.GDCCheck
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.GDCCheck.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_gdccheck
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_gdccheck (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_gdccheck SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the four outcomes of GDC (Global Data Consortium) identity verification checks - None, One Source, Two Sources, or No Match - used to record electronic identity verification depth for KYC compliance. Source: etoro.Dictionary.GDCCheck on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.GDCCheck.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_gdccheck SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'GDCCheck',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_gdccheck ALTER COLUMN GDCCheckID COMMENT 'Primary key identifying the GDC verification outcome. 0=None (not checked), 1=One Source (basic verification), 2=Two Sources (strong verification), 3=No Match (failed verification). Stored on BackOffice.Customer to record the GDC result for each customer''s KYC process. (Tier 1 - upstream wiki, etoro.Dictionary.GDCCheck)';
ALTER TABLE main.general.bronze_etoro_dictionary_gdccheck ALTER COLUMN Name COMMENT 'Human-readable label for the GDC check outcome. Used in BackOffice KYC review screens, compliance reports, and audit trails. NULL allowed but all production values are populated. (Tier 1 - upstream wiki, etoro.Dictionary.GDCCheck)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
