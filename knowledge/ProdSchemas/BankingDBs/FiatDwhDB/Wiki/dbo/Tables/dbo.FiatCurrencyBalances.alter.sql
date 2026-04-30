-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.dbo.FiatCurrencyBalances
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatCurrencyBalances.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_dbo_fiatcurrencybalances
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_dbo_fiatcurrencybalances (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcurrencybalances SET TBLPROPERTIES (
    'comment' = 'Entity table representing currency-specific balance containers within a fiat account, linking to bank accounts, transactions, payment specifications, and provider mappings. Source: FiatDwhDB.dbo.FiatCurrencyBalances on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatCurrencyBalances.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcurrencybalances SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'dbo',
    'source_table' = 'FiatCurrencyBalances',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcurrencybalances ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate PK. Referenced by FiatTransactions, FiatCurrencyBalancesStatuses, CurrencyBalancesProvidersMapping, PaymentSpecifications, FiatBankAccount, and BalanceReports. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCurrencyBalances)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcurrencybalances ALTER COLUMN CurrencyBalanceGuid COMMENT 'External-facing unique identifier. Used in APIs and provider integrations. Indexed with AccountId for lookup. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCurrencyBalances)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcurrencybalances ALTER COLUMN AccountId COMMENT 'FK to dbo.FiatAccount.Id. The account this balance belongs to. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCurrencyBalances)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcurrencybalances ALTER COLUMN BankAccountId COMMENT 'FK to dbo.FiatBankAccount.Id. The internal bank account associated with this balance (for IBAN programs). NULL for card-only balances or newly created balances before bank account assignment. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCurrencyBalances)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcurrencybalances ALTER COLUMN CurrencyISON COMMENT 'ISO 4217 numeric currency code. E.g., "826"=GBP, "978"=EUR, "036"=AUD. See ISO Currency Info. Indexed for currency-based queries. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCurrencyBalances)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcurrencybalances ALTER COLUMN Created COMMENT 'UTC timestamp when this currency balance was created in the data warehouse. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCurrencyBalances)';

