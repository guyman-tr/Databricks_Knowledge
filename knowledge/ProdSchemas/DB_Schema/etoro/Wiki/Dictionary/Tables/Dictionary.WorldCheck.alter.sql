-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.WorldCheck
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.WorldCheck.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_worldcheck
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_worldcheck (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_worldcheck SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the five outcomes of World-Check screening (Refinitiv''s sanctions/PEP database) - from unscreened through PEP Match and Risk Match - used to classify customers by their AML/sanctions screening result. Source: etoro.Dictionary.WorldCheck on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.WorldCheck.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_worldcheck SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'WorldCheck',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_worldcheck ALTER COLUMN WorldCheckID COMMENT 'Unique identifier for the World-Check screening outcome: 0=Unscreened, 1=Pending, 2=No Match, 3=PEP Match, 4=Risk Match. Stored on BackOffice.Customer.WorldCheckID and incorporated into risk classification scoring by 10+ compliance and risk procedures. (Tier 1 - upstream wiki, etoro.Dictionary.WorldCheck)';
ALTER TABLE main.general.bronze_etoro_dictionary_worldcheck ALTER COLUMN WorldCheckName COMMENT 'Display label for the screening outcome. ID 0 has an empty string (not NULL). Used in BackOffice customer displays, PEP reports, and compliance dashboards. (Tier 1 - upstream wiki, etoro.Dictionary.WorldCheck)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
