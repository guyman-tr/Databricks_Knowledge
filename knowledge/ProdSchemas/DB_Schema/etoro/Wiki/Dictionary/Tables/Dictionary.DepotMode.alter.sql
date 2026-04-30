-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.DepotMode
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DepotMode.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_depotmode
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_depotmode (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_depotmode SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the account modes for payment processing depot configuration — General, Live, and Demo — used to route merchant/protocol settings to the correct environment. Source: etoro.Dictionary.DepotMode on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DepotMode.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_depotmode SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'DepotMode',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_depotmode ALTER COLUMN DepotModeID COMMENT 'Primary key identifying the depot mode. 0=General, 1=Live, 2=Demo. Referenced by Billing.MerchantAccountRouting, Billing.DepotValue, Billing.ProtocolValue, Billing.ProtocolMIDSettings as a routing dimension. (Tier 1 - upstream wiki, etoro.Dictionary.DepotMode)';
ALTER TABLE main.general.bronze_etoro_dictionary_depotmode ALTER COLUMN DepotModeName COMMENT 'Human-readable mode name. Nullable in DDL but all 3 rows have values. Used in BackOffice configuration UIs and billing setup procedures. (Tier 1 - upstream wiki, etoro.Dictionary.DepotMode)';

