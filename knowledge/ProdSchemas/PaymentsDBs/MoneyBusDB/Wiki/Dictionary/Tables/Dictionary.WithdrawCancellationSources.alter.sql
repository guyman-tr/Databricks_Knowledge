-- =============================================================================
-- Databricks ALTER Script: bronze MoneyBusDB.Dictionary.WithdrawCancellationSources
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.WithdrawCancellationSources.md
-- Layer: bronze
-- UC Target: main.billing.bronze_moneybusdb_dictionary_withdrawcancellationsources
-- =============================================================================

-- ---- UC Target: main.billing.bronze_moneybusdb_dictionary_withdrawcancellationsources (business_group=billing) ----
ALTER TABLE main.billing.bronze_moneybusdb_dictionary_withdrawcancellationsources SET TBLPROPERTIES (
    'comment' = 'Lookup table identifying who or what initiated the cancellation of a withdrawal request in the MoneyBus payment system. Source: MoneyBusDB.Dictionary.WithdrawCancellationSources on the MoneyBusDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.WithdrawCancellationSources.md).'
);

ALTER TABLE main.billing.bronze_moneybusdb_dictionary_withdrawcancellationsources SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'MoneyBusDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'WithdrawCancellationSources',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.billing.bronze_moneybusdb_dictionary_withdrawcancellationsources ALTER COLUMN ID COMMENT 'Primary key identifying each cancellation source. Explicitly assigned (not IDENTITY). Referenced as CancellationSource in MoneyBus.WithdrawCancelRequest. Values: 0=None, 1=User, 2=BackOffice, 3=Abort. See Withdraw Cancellation Source for full business definitions. (Tier 1 - upstream wiki, MoneyBusDB.Dictionary.WithdrawCancellationSources)';
ALTER TABLE main.billing.bronze_moneybusdb_dictionary_withdrawcancellationsources ALTER COLUMN Name COMMENT 'Human-readable label for the cancellation source. Has a UNIQUE constraint ensuring no duplicates. Used for display in cancellation reports and audit logs. (Tier 1 - upstream wiki, MoneyBusDB.Dictionary.WithdrawCancellationSources)';

