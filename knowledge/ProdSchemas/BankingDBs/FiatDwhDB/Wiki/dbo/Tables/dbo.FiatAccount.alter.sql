-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.dbo.FiatAccount
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatAccount.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_dbo_fiataccount
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_dbo_fiataccount (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiataccount SET TBLPROPERTIES (
    'comment' = 'Central entity table representing a customer''s fiat money account on the platform, linking to cards, currency balances, transactions, and program transitions. Source: FiatDwhDB.dbo.FiatAccount on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatAccount.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiataccount SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'dbo',
    'source_table' = 'FiatAccount',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiataccount ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate primary key. Referenced by all child entity tables as the FK to the account. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatAccount)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiataccount ALTER COLUMN Gcid COMMENT 'Global Customer ID. Identifies the customer across all eToro platforms (trading, crypto, fiat). Part of the unique constraint with AccountGuid. Used in Confluence queries as the primary customer lookup key. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatAccount)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiataccount ALTER COLUMN AccountGuid COMMENT 'External-facing unique identifier for this fiat account. Used in application APIs, provider integrations, and cross-system references. Indexed for efficient GUID-based lookups. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatAccount)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiataccount ALTER COLUMN Created COMMENT 'UTC timestamp when this account record was created in the data warehouse. Indexed for time-range queries. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatAccount)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiataccount ALTER COLUMN AccountProgramId COMMENT 'Account program type: 0=Unknown, 1=card (default), 2=iban. See Account Program. (Dictionary.AccountPrograms). Determines the fundamental product type (card-based vs IBAN-based banking). (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatAccount)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiataccount ALTER COLUMN SubProgramId COMMENT 'Specific sub-program variant: 1-16 (e.g., Card Premium UK, IBAN EU Green). See Sub-Program. FK to dbo.SubPrograms. NULL if not yet assigned to a specific variant. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatAccount)';

