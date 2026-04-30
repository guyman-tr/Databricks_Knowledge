-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.RegionByIP
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RegionByIP.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_regionbyip
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_regionbyip (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_regionbyip SET TBLPROPERTIES (
    'comment' = 'Mapping table with 4,206 IP-based geographic region codes per country — used for sub-country geolocation of customers during registration and regulatory compliance. Source: etoro.Dictionary.RegionByIP on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RegionByIP.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_regionbyip SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'RegionByIP',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_regionbyip ALTER COLUMN RegionByIP_ID COMMENT 'Auto-incrementing surrogate primary key. IDENTITY NOT FOR REPLICATION. Stored in Customer.CustomerStatic and Customer.Address. Referenced by 10+ consumers. (Tier 1 - upstream wiki, etoro.Dictionary.RegionByIP)';
ALTER TABLE main.general.bronze_etoro_dictionary_regionbyip ALTER COLUMN CountryID COMMENT 'FK → Dictionary.Country (implicit). The country this region belongs to. (Tier 1 - upstream wiki, etoro.Dictionary.RegionByIP)';
ALTER TABLE main.general.bronze_etoro_dictionary_regionbyip ALTER COLUMN Name COMMENT 'IP geolocation provider region code. Short numeric or alpha codes representing sub-country divisions. May be blank/whitespace for countries without region data. (Tier 1 - upstream wiki, etoro.Dictionary.RegionByIP)';

