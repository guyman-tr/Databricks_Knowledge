-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Dictionary_Provider
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_provider
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_provider SET TBLPROPERTIES (
    'comment' = '`eMoney_Dictionary_Provider` is a lookup/reference table that defines the valid values for external payment provider in the eToro Money fiat platform. Currently it contains a single row: `1=Tribe`, identifying Tribe Payments Ltd as the sole payment provider that powers eToro Money''s card and IBAN infrastructure. Tribe is the white-label fintech provider behind eToro Money - they supply the Mastercard card issuing, IBAN banking rails, and Closed User Group (CUG) program management. All eToro Money fiat accounts, currency balances, transactions, and card operations flow through Tribe''s platform, making this effectively a constant lookup in current production. Future providers would be added as new rows. This dictionary is sourced from `FiatDwhDB.Dictionary.Providers` via Generic Pipeline Bronze export. It is referenced by `FiatDwhDB` provider mapping tables but currently its `ProviderID` is not widely used as a join key in the Synapse eMoney layer (most provider attribution is implicit). Last loaded 2023-06-...'
);

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_provider SET TAGS (
    'domain' = 'general',
    'object_type' = 'table',
    'source_schema' = 'eMoney_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_provider ALTER COLUMN `ProviderID` COMMENT 'Lookup identifier. Primary key. 1=Tribe. (Tier 1 - Dictionary.Providers)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_provider ALTER COLUMN `Provider` COMMENT 'Human-readable name for this value. 1=Tribe. (Tier 1 - Dictionary.Providers)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_provider ALTER COLUMN `UpdateDate` COMMENT 'Timestamp of last Generic Pipeline ETL load from FiatDwhDB source. Static since 2023-06-12. (Tier 2 - Generic Pipeline)';

-- ---- Column PII Tags ----
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_provider ALTER COLUMN `ProviderID` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_provider ALTER COLUMN `Provider` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_provider ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
