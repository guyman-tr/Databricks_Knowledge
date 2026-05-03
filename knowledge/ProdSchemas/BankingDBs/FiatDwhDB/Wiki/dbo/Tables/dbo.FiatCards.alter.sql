-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.dbo.FiatCards
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatCards.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_dbo_fiatcards
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_dbo_fiatcards (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcards SET TBLPROPERTIES (
    'comment' = 'Entity table representing debit cards issued to fiat accounts, linking to card instances, card statuses, and provider mappings. Source: FiatDwhDB.dbo.FiatCards on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatCards.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcards SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'dbo',
    'source_table' = 'FiatCards',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcards ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate primary key. Referenced by FiatCardStatuses.CardId, FiatCardInstances (implicit), and CardsProvidersMapping.CardId. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCards)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcards ALTER COLUMN CardGuid COMMENT 'External-facing unique identifier for this card. Used in application APIs and provider integrations. Part of unique constraint with AccountId. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCards)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcards ALTER COLUMN AccountId COMMENT 'FK to dbo.FiatAccount.Id. The fiat account this card belongs to. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCards)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcards ALTER COLUMN Created COMMENT 'UTC timestamp when this card record was created in the data warehouse. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCards)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:05:44 UTC
-- Bronze deploy: FiatDwhDB batch 1
-- ====================
