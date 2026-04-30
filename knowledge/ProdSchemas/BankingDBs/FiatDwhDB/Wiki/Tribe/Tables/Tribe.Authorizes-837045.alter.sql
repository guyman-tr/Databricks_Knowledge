-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.Tribe.Authorizes-837045
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.Authorizes-837045.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_tribe_authorizes-837045
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_tribe_authorizes-837045 (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_authorizes-837045 SET TBLPROPERTIES (
    'comment' = 'Parent container table for Tribe Authorizes data files. Each row represents a received JSON file containing card authorization records from the Tribe provider. Source: FiatDwhDB.Tribe.Authorizes-837045 on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.Authorizes-837045.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_authorizes-837045 SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'Tribe',
    'source_table' = 'Authorizes-837045',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_authorizes-837045 ALTER COLUMN @Created COMMENT 'DWH insertion timestamp. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.Authorizes-837045)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_authorizes-837045 ALTER COLUMN @Id COMMENT 'Unique file identifier. PK. Referenced by child tables. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.Authorizes-837045)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_authorizes-837045 ALTER COLUMN @FileName COMMENT 'Source file name. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.Authorizes-837045)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_authorizes-837045 ALTER COLUMN Created COMMENT 'Source system timestamp. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.Authorizes-837045)';

