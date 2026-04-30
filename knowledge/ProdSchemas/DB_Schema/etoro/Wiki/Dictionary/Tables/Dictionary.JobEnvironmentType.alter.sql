-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.JobEnvironmentType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.JobEnvironmentType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_jobenvironmenttype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_jobenvironmenttype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_jobenvironmenttype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining three job execution environments — Israel, Cyprus, and Amsterdam — representing the geographic data center locations where scheduled BackOffice jobs run. Source: etoro.Dictionary.JobEnvironmentType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.JobEnvironmentType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_jobenvironmenttype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'JobEnvironmentType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_jobenvironmenttype ALTER COLUMN JobEnvironmentTypeID COMMENT 'Primary key identifying the execution environment. 1=Israel, 2=Cyprus, 3=Amsterdam. Stored in BackOffice.ScheduledJob to route jobs to the correct data center. (Tier 1 - upstream wiki, etoro.Dictionary.JobEnvironmentType)';
ALTER TABLE main.general.bronze_etoro_dictionary_jobenvironmenttype ALTER COLUMN JobEnvironmentType COMMENT 'Geographic name of the execution environment. Displayed in BackOffice job scheduling UI for operators to select the target environment. Note: "Amsterdam" value has trailing whitespace. (Tier 1 - upstream wiki, etoro.Dictionary.JobEnvironmentType)';

