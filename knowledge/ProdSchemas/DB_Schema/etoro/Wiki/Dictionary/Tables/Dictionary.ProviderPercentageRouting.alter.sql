-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.ProviderPercentageRouting
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ProviderPercentageRouting.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_providerpercentagerouting
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_providerpercentagerouting (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_providerpercentagerouting SET TBLPROPERTIES (
    'comment' = 'Configuration table defining percentage-based payment routing rules by depot and country — controlling how deposit transactions are distributed across payment providers. Source: etoro.Dictionary.ProviderPercentageRouting on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ProviderPercentageRouting.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_providerpercentagerouting SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'ProviderPercentageRouting',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_providerpercentagerouting ALTER COLUMN ID COMMENT 'Auto-incrementing surrogate primary key. (Tier 1 - upstream wiki, etoro.Dictionary.ProviderPercentageRouting)';
ALTER TABLE main.general.bronze_etoro_dictionary_providerpercentagerouting ALTER COLUMN DepotID COMMENT 'References a payment depot (Billing.Depot). Identifies which payment processing configuration receives the routed transactions. (Tier 1 - upstream wiki, etoro.Dictionary.ProviderPercentageRouting)';
ALTER TABLE main.general.bronze_etoro_dictionary_providerpercentagerouting ALTER COLUMN CountryID COMMENT 'References Dictionary.Country. 0=global default (all countries). Specifies the customer''s country for routing decisions. (Tier 1 - upstream wiki, etoro.Dictionary.ProviderPercentageRouting)';
ALTER TABLE main.general.bronze_etoro_dictionary_providerpercentagerouting ALTER COLUMN FromAmount COMMENT 'Lower bound of the transaction amount range (inclusive). Typically 0 for "any amount". (Tier 1 - upstream wiki, etoro.Dictionary.ProviderPercentageRouting)';
ALTER TABLE main.general.bronze_etoro_dictionary_providerpercentagerouting ALTER COLUMN ToAmount COMMENT 'Upper bound of the transaction amount range (inclusive). NULL means no upper limit. (Tier 1 - upstream wiki, etoro.Dictionary.ProviderPercentageRouting)';
ALTER TABLE main.general.bronze_etoro_dictionary_providerpercentagerouting ALTER COLUMN Percentage COMMENT 'Percentage of matching transactions routed to this depot (0-100). Complementary rules for the same country should sum to 100. (Tier 1 - upstream wiki, etoro.Dictionary.ProviderPercentageRouting)';

