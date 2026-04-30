-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.ManagerPermit
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ManagerPermit.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_managerpermit
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_managerpermit (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_managerpermit SET TBLPROPERTIES (
    'comment' = 'Defines the permission levels granted to BackOffice account managers, controlling whether they can perform trading operations, fund operations, or both on behalf of customers. Source: etoro.Dictionary.ManagerPermit on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ManagerPermit.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_managerpermit SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'ManagerPermit',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_managerpermit ALTER COLUMN ManagerPermitID COMMENT 'Unique identifier for the permission tier: 1=None (view only), 2=Trade and Fund (full access), 3=Trade only, 4=Fund only. Referenced by BackOffice.Customer and NFA reporting procedures. (Tier 1 - upstream wiki, etoro.Dictionary.ManagerPermit)';
ALTER TABLE main.general.bronze_etoro_dictionary_managerpermit ALTER COLUMN Name COMMENT 'Human-readable permission label. Enforced unique by UK_DMP_Name constraint. Displayed in BackOffice manager assignment screens. (Tier 1 - upstream wiki, etoro.Dictionary.ManagerPermit)';

