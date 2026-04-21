-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Currency_Mapping_ISO
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_currency_mapping_iso
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_currency_mapping_iso SET TBLPROPERTIES (
    'comment' = '`eMoney_Currency_Mapping_ISO` is a manually maintained cross-reference table that maps the ISO 4217 currency standard (168 active currencies) to both alpha-3 and numeric codes. It serves as the bridge between the fiat platform''s use of ISO numeric currency codes in transaction data and the analytical data warehouse''s use of alpha-3 currency codes for instrument and price lookups. In the fiat transaction pipeline (`FiatTransactions`), currency of transaction is stored as a 3-digit ISO numeric code. `SP_eMoney_DimFact_Transaction` uses this table (steps 05a, 05b, 06) to resolve those numeric codes to `CurrencyAlphaThreeCode`, which then joins to `DWH_dbo.Dim_Instrument.BuyCurrency` / `SellCurrency` for instrument resolution and to `Fact_CurrencyPriceWithSplit` for USD conversion rates. HASH distribution on `CurrencyNumericCode_ISO` optimizes joins from `FiatTransactions` on the numeric currency code. All rows carry UpdateDate 2024-06-24 (single bulk load from ISO 4217 standard). Synapse: HASH(CurrencyNumeric...'
);

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_currency_mapping_iso SET TAGS (
    'domain' = 'finance',
    'object_type' = 'table',
    'source_schema' = 'eMoney_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH(CurrencyNumericCode_ISO)',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_currency_mapping_iso ALTER COLUMN `CurrencyName` COMMENT 'Full ISO 4217 currency name (e.g., "Pound Sterling", "Euro", "US Dollar"). (Tier 2 - Manual load context)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_currency_mapping_iso ALTER COLUMN `CurrencyAlphaThreeCode` COMMENT 'ISO 4217 alpha-3 currency code (e.g., GBP, EUR, USD). Joins to DWH_dbo.Dim_Instrument.BuyCurrency/SellCurrency and Fact_CurrencyPriceWithSplit. (Tier 2 - SP_eMoney_DimFact_Transaction steps 05a/05b/06)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_currency_mapping_iso ALTER COLUMN `CurrencyNumericCode_ISO` COMMENT 'ISO 4217 numeric code (3-digit string; e.g., ''826'', ''978'', ''840''). Primary FK from FiatTransactions numeric currency fields. HASH distribution key. (Tier 2 - SP_eMoney_DimFact_Transaction)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_currency_mapping_iso ALTER COLUMN `UpdateDate` COMMENT 'Bulk-load timestamp. Static; all rows = 2024-06-24. (Tier 2 - Manual load metadata)';

-- ---- Column PII Tags ----
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_currency_mapping_iso ALTER COLUMN `CurrencyName` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_currency_mapping_iso ALTER COLUMN `CurrencyAlphaThreeCode` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_currency_mapping_iso ALTER COLUMN `CurrencyNumericCode_ISO` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_currency_mapping_iso ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
