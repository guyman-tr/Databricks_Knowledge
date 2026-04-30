-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.dbo.FiatAccountStatuses
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatAccountStatuses.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_dbo_fiataccountstatuses
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_dbo_fiataccountstatuses (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiataccountstatuses SET TBLPROPERTIES (
    'comment' = 'Event-sourced status history table tracking all lifecycle state changes (Active, Suspended, Deleted) for fiat accounts. Source: FiatDwhDB.dbo.FiatAccountStatuses on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatAccountStatuses.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiataccountstatuses SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'dbo',
    'source_table' = 'FiatAccountStatuses',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiataccountstatuses ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate primary key. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatAccountStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiataccountstatuses ALTER COLUMN AccountId COMMENT 'FK to dbo.FiatAccount.Id. The account whose status changed. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatAccountStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiataccountstatuses ALTER COLUMN StatusType COMMENT 'Account status: 0=Active, 1=Suspended, 2=Deleted. See Account Status. (Dictionary.AccountStatuses) (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatAccountStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiataccountstatuses ALTER COLUMN Created COMMENT 'UTC timestamp when this status change was recorded. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatAccountStatuses)';

