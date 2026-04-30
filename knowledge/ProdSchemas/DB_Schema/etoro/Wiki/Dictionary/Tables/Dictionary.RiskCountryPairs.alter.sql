-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.RiskCountryPairs
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RiskCountryPairs.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_riskcountrypairs
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_riskcountrypairs (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_riskcountrypairs SET TBLPROPERTIES (
    'comment' = 'Mapping table with 725 conflicting country pairs — identifying geopolitically sensitive country combinations that trigger enhanced risk scrutiny when a customer''s nationality/residence conflicts with deposit or trading activity origins. Source: etoro.Dictionary.RiskCountryPairs on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RiskCountryPairs.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_riskcountrypairs SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'RiskCountryPairs',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_riskcountrypairs ALTER COLUMN CountryID COMMENT 'Part of composite PK. The customer''s country of registration/residence. References Dictionary.Country (implicit). (Tier 1 - upstream wiki, etoro.Dictionary.RiskCountryPairs)';
ALTER TABLE main.general.bronze_etoro_dictionary_riskcountrypairs ALTER COLUMN ConflictingCountryID COMMENT 'Part of composite PK. The conflicting country that triggers enhanced risk review when detected in the customer''s financial activity. References Dictionary.Country (implicit). (Tier 1 - upstream wiki, etoro.Dictionary.RiskCountryPairs)';

