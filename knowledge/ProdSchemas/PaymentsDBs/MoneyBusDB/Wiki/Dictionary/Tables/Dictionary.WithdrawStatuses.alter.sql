-- =============================================================================
-- Databricks ALTER Script: bronze MoneyBusDB.Dictionary.WithdrawStatuses
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.WithdrawStatuses.md
-- Layer: bronze
-- UC Target: main.billing.bronze_moneybusdb_dictionary_withdrawstatuses
-- =============================================================================

-- ---- UC Target: main.billing.bronze_moneybusdb_dictionary_withdrawstatuses (business_group=billing) ----
ALTER TABLE main.billing.bronze_moneybusdb_dictionary_withdrawstatuses SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the top-level lifecycle states of withdrawal requests in the MoneyBus payment system. Source: MoneyBusDB.Dictionary.WithdrawStatuses on the MoneyBusDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.WithdrawStatuses.md).'
);

ALTER TABLE main.billing.bronze_moneybusdb_dictionary_withdrawstatuses SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'MoneyBusDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'WithdrawStatuses',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.billing.bronze_moneybusdb_dictionary_withdrawstatuses ALTER COLUMN ID COMMENT 'Primary key identifying each withdrawal status. Explicitly assigned (not IDENTITY). Referenced as StatusID in MoneyBus.Withdrawals and as WithdrawStatusID in Dictionary.WithdrawStatusReasons. Values: 1=InProcess, 2=Success, 3=Decline, 4=Technical, 5=Cancelled. See Withdraw Status for full business definitions. (Tier 1 - upstream wiki, MoneyBusDB.Dictionary.WithdrawStatuses)';
ALTER TABLE main.billing.bronze_moneybusdb_dictionary_withdrawstatuses ALTER COLUMN Name COMMENT 'Human-readable status label used for display in withdrawal reports and operational dashboards. (Tier 1 - upstream wiki, MoneyBusDB.Dictionary.WithdrawStatuses)';

