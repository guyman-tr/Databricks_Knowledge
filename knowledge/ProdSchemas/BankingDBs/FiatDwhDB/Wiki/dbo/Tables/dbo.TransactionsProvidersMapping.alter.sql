-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.dbo.TransactionsProvidersMapping
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.TransactionsProvidersMapping.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_dbo_transactionsprovidersmapping
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_dbo_transactionsprovidersmapping (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_transactionsprovidersmapping SET TBLPROPERTIES (
    'comment' = 'Mapping table linking internal transaction IDs to provider-side (Tribe) transaction identifiers for cross-system reconciliation and support investigations. Source: FiatDwhDB.dbo.TransactionsProvidersMapping on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.TransactionsProvidersMapping.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_transactionsprovidersmapping SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'dbo',
    'source_table' = 'TransactionsProvidersMapping',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_transactionsprovidersmapping ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate PK. (Tier 1 - upstream wiki, FiatDwhDB.dbo.TransactionsProvidersMapping)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_transactionsprovidersmapping ALTER COLUMN TransactionId COMMENT 'FK to dbo.FiatTransactions.Id. The internal transaction being mapped. (Tier 1 - upstream wiki, FiatDwhDB.dbo.TransactionsProvidersMapping)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_transactionsprovidersmapping ALTER COLUMN ProviderId COMMENT 'FK to Dictionary.Providers. Currently 1=Tribe. See Provider. (Tier 1 - upstream wiki, FiatDwhDB.dbo.TransactionsProvidersMapping)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_transactionsprovidersmapping ALTER COLUMN TransactionProviderId COMMENT 'The provider''s identifier for this transaction. Used for provider API calls, reconciliation, and support lookups. (Tier 1 - upstream wiki, FiatDwhDB.dbo.TransactionsProvidersMapping)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_transactionsprovidersmapping ALTER COLUMN Created COMMENT 'UTC timestamp when this mapping was recorded. (Tier 1 - upstream wiki, FiatDwhDB.dbo.TransactionsProvidersMapping)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:05:44 UTC
-- Bronze deploy: FiatDwhDB batch 1
-- ====================
