-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.CardTypeToBank
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CardTypeToBank.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_cardtypetobank
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_cardtypetobank (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_cardtypetobank SET TBLPROPERTIES (
    'comment' = 'Junction table mapping credit card types (Visa, MasterCard, Amex, etc.) to processing banks, with an active/inactive flag controlling which card-bank combinations are enabled for payment routing. Core routing configuration for credit card deposits. Source: etoro.Dictionary.CardTypeToBank on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CardTypeToBank.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_cardtypetobank SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'CardTypeToBank',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_cardtypetobank ALTER COLUMN CardTypeID COMMENT 'FK to Dictionary.CardType; which card type (Visa, MasterCard, Amex, etc.). Part of composite PK. (Tier 1 - upstream wiki, etoro.Dictionary.CardTypeToBank)';
ALTER TABLE main.general.bronze_etoro_dictionary_cardtypetobank ALTER COLUMN BankID COMMENT 'FK to Dictionary.Bank; which bank/gateway supports this card type. Part of composite PK. NC index DC2B_BANK on this column. (Tier 1 - upstream wiki, etoro.Dictionary.CardTypeToBank)';
ALTER TABLE main.general.bronze_etoro_dictionary_cardtypetobank ALTER COLUMN IsActive COMMENT 'Whether this card-type-to-bank route is currently active for routing. DEFAULT 0. Trigger fires when changed to 1. (Tier 1 - upstream wiki, etoro.Dictionary.CardTypeToBank)';

