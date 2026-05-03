-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.dbo.AccountsProviderHoldersMapping
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.AccountsProviderHoldersMapping.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_dbo_accountsproviderholdersmapping
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_dbo_accountsproviderholdersmapping (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_accountsproviderholdersmapping SET TBLPROPERTIES (
    'comment' = 'Mapping table linking internal fiat account IDs to provider-side (Tribe) holder identifiers for cross-system reconciliation. Source: FiatDwhDB.dbo.AccountsProviderHoldersMapping on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.AccountsProviderHoldersMapping.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_accountsproviderholdersmapping SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'dbo',
    'source_table' = 'AccountsProviderHoldersMapping',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_accountsproviderholdersmapping ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate primary key. (Tier 1 - upstream wiki, FiatDwhDB.dbo.AccountsProviderHoldersMapping)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_accountsproviderholdersmapping ALTER COLUMN AccountId COMMENT 'FK to dbo.FiatAccount.Id. The internal platform account this mapping belongs to. (Tier 1 - upstream wiki, FiatDwhDB.dbo.AccountsProviderHoldersMapping)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_accountsproviderholdersmapping ALTER COLUMN ProviderHolderId COMMENT 'The external provider''s (Tribe) identifier for this account holder. Used in all provider API interactions and support queries. Stored as string to accommodate different provider ID formats. (Tier 1 - upstream wiki, FiatDwhDB.dbo.AccountsProviderHoldersMapping)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_accountsproviderholdersmapping ALTER COLUMN Created COMMENT 'UTC timestamp when this mapping was recorded in the data warehouse. (Tier 1 - upstream wiki, FiatDwhDB.dbo.AccountsProviderHoldersMapping)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:05:44 UTC
-- Bronze deploy: FiatDwhDB batch 1
-- ====================
