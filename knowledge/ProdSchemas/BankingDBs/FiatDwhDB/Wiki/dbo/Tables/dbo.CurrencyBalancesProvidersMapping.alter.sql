-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.dbo.CurrencyBalancesProvidersMapping
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.CurrencyBalancesProvidersMapping.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_dbo_currencybalancesprovidersmapping
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_dbo_currencybalancesprovidersmapping (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_currencybalancesprovidersmapping SET TBLPROPERTIES (
    'comment' = 'Mapping table linking internal currency balance IDs to provider-side (Tribe) balance identifiers for cross-system reconciliation. Source: FiatDwhDB.dbo.CurrencyBalancesProvidersMapping on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.CurrencyBalancesProvidersMapping.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_currencybalancesprovidersmapping SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'dbo',
    'source_table' = 'CurrencyBalancesProvidersMapping',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_currencybalancesprovidersmapping ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate primary key. (Tier 1 - upstream wiki, FiatDwhDB.dbo.CurrencyBalancesProvidersMapping)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_currencybalancesprovidersmapping ALTER COLUMN CurrencyBalanceId COMMENT 'FK to dbo.FiatCurrencyBalances.Id. The internal currency balance being mapped. (Tier 1 - upstream wiki, FiatDwhDB.dbo.CurrencyBalancesProvidersMapping)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_currencybalancesprovidersmapping ALTER COLUMN ProviderId COMMENT 'FK to Dictionary.Providers. Currently 1=Tribe. See Provider. (Tier 1 - upstream wiki, FiatDwhDB.dbo.CurrencyBalancesProvidersMapping)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_currencybalancesprovidersmapping ALTER COLUMN CurrencyBalanceProviderId COMMENT 'The provider''s identifier for this currency balance. Used for provider API calls and reconciliation. (Tier 1 - upstream wiki, FiatDwhDB.dbo.CurrencyBalancesProvidersMapping)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_currencybalancesprovidersmapping ALTER COLUMN Created COMMENT 'UTC timestamp when this mapping was recorded. (Tier 1 - upstream wiki, FiatDwhDB.dbo.CurrencyBalancesProvidersMapping)';

