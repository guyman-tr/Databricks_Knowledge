-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.dbo.CustomerEODBalance
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.CustomerEODBalance.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_dbo_customereodbalance
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_dbo_customereodbalance (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_customereodbalance SET TBLPROPERTIES (
    'comment' = 'End-of-day balance snapshot table that records each customer''s fiat currency balance at market close for historical reporting and reconciliation. Source: FiatDwhDB.dbo.CustomerEODBalance on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 720-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.CustomerEODBalance.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_customereodbalance SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'dbo',
    'source_table' = 'CustomerEODBalance',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '720'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_customereodbalance ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate primary key. (Tier 1 - upstream wiki, FiatDwhDB.dbo.CustomerEODBalance)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_customereodbalance ALTER COLUMN DateId COMMENT 'Numeric date key in YYYYMMDD format (e.g., 20260413). Used for efficient date-based filtering and partitioning in reporting queries. (Tier 1 - upstream wiki, FiatDwhDB.dbo.CustomerEODBalance)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_customereodbalance ALTER COLUMN EODBalanceDate COMMENT 'The business date for this end-of-day balance snapshot. Combined with GCID and COIN, uniquely identifies a balance record. (Tier 1 - upstream wiki, FiatDwhDB.dbo.CustomerEODBalance)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_customereodbalance ALTER COLUMN GCID COMMENT 'Global Customer ID. Identifies the customer whose balance is recorded. Shared across all eToro platforms. (Tier 1 - upstream wiki, FiatDwhDB.dbo.CustomerEODBalance)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_customereodbalance ALTER COLUMN EODBalanceAmount COMMENT 'The customer''s fiat balance amount in the specified currency at end of day. NULL if balance could not be calculated (edge case). High precision supports multi-currency calculations. (Tier 1 - upstream wiki, FiatDwhDB.dbo.CustomerEODBalance)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_customereodbalance ALTER COLUMN COIN COMMENT 'ISO 4217 numeric currency code identifying the balance currency. E.g., 978=EUR, 826=GBP, 036=AUD, 840=USD. See ISO Currency Info. (Tier 1 - upstream wiki, FiatDwhDB.dbo.CustomerEODBalance)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_customereodbalance ALTER COLUMN MarketRateSymbol COMMENT 'Market rate pair symbol used for USD conversion reporting (e.g., "EURUSD", "GBPUSD"). Captured at EOD for historical rate tracking. (Tier 1 - upstream wiki, FiatDwhDB.dbo.CustomerEODBalance)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_customereodbalance ALTER COLUMN RateConverstionToUSD COMMENT 'Exchange rate to USD at end of day. Stored as string for display purposes. Note: column name contains a misspelling ("Converstion" instead of "Conversion") preserved from original DDL. (Tier 1 - upstream wiki, FiatDwhDB.dbo.CustomerEODBalance)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_customereodbalance ALTER COLUMN Created COMMENT 'UTC timestamp when this EOD balance record was calculated and inserted by DailyBalanceCalculation. (Tier 1 - upstream wiki, FiatDwhDB.dbo.CustomerEODBalance)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_customereodbalance ALTER COLUMN LastDailyMovementCreated COMMENT 'Timestamp of the most recent daily movement record that contributed to this EOD balance calculation. Used to determine data freshness and identify if movements were missed. (Tier 1 - upstream wiki, FiatDwhDB.dbo.CustomerEODBalance)';

