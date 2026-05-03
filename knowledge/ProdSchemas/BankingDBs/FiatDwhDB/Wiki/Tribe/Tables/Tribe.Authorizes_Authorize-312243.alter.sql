-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.Tribe.Authorizes_Authorize-312243
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.Authorizes_Authorize-312243.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_tribe_authorizes_authorize-312243
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_tribe_authorizes_authorize-312243 (business_group=emoney) ----
ALTER TABLE main.emoney.`bronze_fiatdwhdb_tribe_authorizes_authorize-312243` SET TBLPROPERTIES (
    'comment' = 'Child table storing detailed card authorization records from Tribe, containing authorization request/response fields including amounts, currencies, merchant data, and authorization codes. Source: FiatDwhDB.Tribe.Authorizes_Authorize-312243 on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.Authorizes_Authorize-312243.md).'
);

ALTER TABLE main.emoney.`bronze_fiatdwhdb_tribe_authorizes_authorize-312243` SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'Tribe',
    'source_table' = 'Authorizes_Authorize-312243',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.`bronze_fiatdwhdb_tribe_authorizes_authorize-312243` ALTER COLUMN `@Created` COMMENT 'DWH insertion timestamp. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.Authorizes_Authorize-312243)';
ALTER TABLE main.emoney.`bronze_fiatdwhdb_tribe_authorizes_authorize-312243` ALTER COLUMN `@Id` COMMENT 'PK. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.Authorizes_Authorize-312243)';
ALTER TABLE main.emoney.`bronze_fiatdwhdb_tribe_authorizes_authorize-312243` ALTER COLUMN `@Authorizes@Id-837045` COMMENT 'FK to parent Tribe.Authorizes-837045. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.Authorizes_Authorize-312243)';
ALTER TABLE main.emoney.`bronze_fiatdwhdb_tribe_authorizes_authorize-312243` ALTER COLUMN Created COMMENT 'Source timestamp. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.Authorizes_Authorize-312243)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:09:36 UTC
-- Bronze deploy: FiatDwhDB batch 2
-- ====================
