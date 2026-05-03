-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.dbo.CardsProvidersMapping
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.CardsProvidersMapping.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_dbo_cardsprovidersmapping
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_dbo_cardsprovidersmapping (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_cardsprovidersmapping SET TBLPROPERTIES (
    'comment' = 'Mapping table linking internal card IDs to provider-side (Tribe) card identifiers for cross-system reconciliation and API calls. Source: FiatDwhDB.dbo.CardsProvidersMapping on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.CardsProvidersMapping.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_cardsprovidersmapping SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'dbo',
    'source_table' = 'CardsProvidersMapping',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_cardsprovidersmapping ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate primary key. (Tier 1 - upstream wiki, FiatDwhDB.dbo.CardsProvidersMapping)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_cardsprovidersmapping ALTER COLUMN CardId COMMENT 'FK to dbo.FiatCards.Id. The internal card being mapped. (Tier 1 - upstream wiki, FiatDwhDB.dbo.CardsProvidersMapping)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_cardsprovidersmapping ALTER COLUMN ProviderId COMMENT 'FK to Dictionary.Providers. Currently 1=Tribe. See Provider. (Tier 1 - upstream wiki, FiatDwhDB.dbo.CardsProvidersMapping)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_cardsprovidersmapping ALTER COLUMN CardProviderId COMMENT 'The provider''s identifier for this card in their system. Used for provider API calls. (Tier 1 - upstream wiki, FiatDwhDB.dbo.CardsProvidersMapping)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_cardsprovidersmapping ALTER COLUMN Created COMMENT 'UTC timestamp when this mapping was recorded. (Tier 1 - upstream wiki, FiatDwhDB.dbo.CardsProvidersMapping)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:05:44 UTC
-- Bronze deploy: FiatDwhDB batch 1
-- ====================
