-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.AccountUpdateType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AccountUpdateType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_accountupdatetype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_accountupdatetype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_accountupdatetype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 14 types of account balance updates - deposits, cashouts, bonuses, trade operations, fees, and cancellations - that modify a customer''s financial account. Source: etoro.Dictionary.AccountUpdateType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AccountUpdateType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_accountupdatetype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'AccountUpdateType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_accountupdatetype ALTER COLUMN AccountUpdateTypeID COMMENT 'Primary key identifying the update type. Used as NONCLUSTERED PK (unusual - suggests the table was originally heap-organized). Values 1-14 covering deposits, cashouts, bonuses, trades, fees, and cancellations. Stored in History.Account and referenced by Billing.AmountAdd, Billing.AmountSubstract, Billing.CashoutRequestAdd, Customer.SetBalance. (Tier 1 - upstream wiki, etoro.Dictionary.AccountUpdateType)';
ALTER TABLE main.general.bronze_etoro_dictionary_accountupdatetype ALTER COLUMN Name COMMENT 'Human-readable name of the balance update type. Unique index enforced (DPMS_NAME). Used in reports and audit trails to describe what financial operation occurred. Loaded into billing service memory by Billing.LoadAccountUpdateTypes. (Tier 1 - upstream wiki, etoro.Dictionary.AccountUpdateType)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
