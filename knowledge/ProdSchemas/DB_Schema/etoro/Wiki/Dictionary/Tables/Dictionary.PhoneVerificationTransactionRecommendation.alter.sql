-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.PhoneVerificationTransactionRecommendation
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PhoneVerificationTransactionRecommendation.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_phoneverificationtransactionrecommendation
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_phoneverificationtransactionrecommendation (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_phoneverificationtransactionrecommendation SET TBLPROPERTIES (
    'comment' = 'Lookup table defining 6 transaction recommendations from phone verification — Block, Flag, Allow, NotApplicable, None, and Other — guiding automated transaction decisions based on phone risk. Source: etoro.Dictionary.PhoneVerificationTransactionRecommendation on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PhoneVerificationTransactionRecommendation.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_phoneverificationtransactionrecommendation SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'PhoneVerificationTransactionRecommendation',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_phoneverificationtransactionrecommendation ALTER COLUMN RecommendationID COMMENT 'Primary key identifying the transaction recommendation. 0=None, 1=Block, 2=Flag, 3=Allow, 4=NotApplicable, 2147483647=Other. Stored in Customer.PhoneVerificationDetails. (Tier 1 - upstream wiki, etoro.Dictionary.PhoneVerificationTransactionRecommendation)';
ALTER TABLE main.general.bronze_etoro_dictionary_phoneverificationtransactionrecommendation ALTER COLUMN Recommmendation COMMENT 'Human-readable recommendation label. Note: column name has a typo (triple ''m'') preserved from the original DDL. Used in verification reports and transaction routing dashboards. (Tier 1 - upstream wiki, etoro.Dictionary.PhoneVerificationTransactionRecommendation)';

