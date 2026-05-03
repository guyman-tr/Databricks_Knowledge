-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.dbo.FiatAccountsProperties
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatAccountsProperties.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_dbo_fiataccountsproperties
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_dbo_fiataccountsproperties (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiataccountsproperties SET TBLPROPERTIES (
    'comment' = 'Event-sourced property history table tracking changes to an account''s program and sub-program assignment over time. Source: FiatDwhDB.dbo.FiatAccountsProperties on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatAccountsProperties.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiataccountsproperties SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'dbo',
    'source_table' = 'FiatAccountsProperties',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiataccountsproperties ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate primary key. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatAccountsProperties)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiataccountsproperties ALTER COLUMN AccountId COMMENT 'FK to dbo.FiatAccount.Id. The account whose program assignment changed. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatAccountsProperties)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiataccountsproperties ALTER COLUMN AccountProgramId COMMENT 'Account program type at this point: 0=Unknown, 1=card, 2=iban. See Account Program. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatAccountsProperties)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiataccountsproperties ALTER COLUMN SubProgramId COMMENT 'Specific sub-program at this point: 1-16. See Sub-Program. FK to dbo.SubPrograms. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatAccountsProperties)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiataccountsproperties ALTER COLUMN Created COMMENT 'UTC timestamp when this program assignment was recorded. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatAccountsProperties)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:05:44 UTC
-- Bronze deploy: FiatDwhDB batch 1
-- ====================
