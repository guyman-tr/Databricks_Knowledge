-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.Currency
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Currency.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_currency
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_currency (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_currency SET TBLPROPERTIES (
    'comment' = 'Master reference table defining all 10,669 tradeable instruments (stocks, ETFs, forex pairs, commodities, indices, crypto) on the eToro platform. Source: etoro.Dictionary.Currency on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Currency.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_currency SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'Currency',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_currency ALTER COLUMN CurrencyID COMMENT 'Primary key identifying the instrument. 0=NULL placeholder, 1-8=major forex currencies, 1000+=stocks, 100000+=crypto. Referenced by Trade.PositionTbl.CurrencyID, Trade.DelayedOrderForOpen.CurrencyID, and virtually all trading tables. (Tier 1 - upstream wiki, etoro.Dictionary.Currency)';
ALTER TABLE main.general.bronze_etoro_dictionary_currency ALTER COLUMN CurrencyTypeID COMMENT 'FK to Dictionary.CurrencyType. Asset class: 1=Forex (176), 2=Commodity (412), 4=Indices (167), 5=Stocks (8,632), 6=ETF (652), 10=Crypto (630). Determines trading rules, leverage limits, and settlement eligibility. (Tier 1 - upstream wiki, etoro.Dictionary.Currency)';
ALTER TABLE main.general.bronze_etoro_dictionary_currency ALTER COLUMN Name COMMENT 'Full instrument name. "United States of America, US Dollar" for forex, company name for stocks, coin name for crypto. Padded with spaces (legacy). (Tier 1 - upstream wiki, etoro.Dictionary.Currency)';
ALTER TABLE main.general.bronze_etoro_dictionary_currency ALTER COLUMN Abbreviation COMMENT 'Trading symbol / ticker. "USD", "AAPL.US", "BTC", "GOLD". UNIQUE constraint. The primary identifier used in UIs and APIs. (Tier 1 - upstream wiki, etoro.Dictionary.Currency)';
ALTER TABLE main.general.bronze_etoro_dictionary_currency ALTER COLUMN Mask COMMENT 'Legacy bitmask value - power of 2 for original forex instruments. Used by Dictionary.GetCurrency/GetCommodity/GetIndices views to compute ForexType. 0 or NULL for newer instruments (stocks, crypto). (Tier 1 - upstream wiki, etoro.Dictionary.Currency)';
ALTER TABLE main.general.bronze_etoro_dictionary_currency ALTER COLUMN EEAStockExchange COMMENT 'Whether listed on a European Economic Area stock exchange. 216 instruments flagged. Triggers MiFID II PRIIPs KID requirements. Default=0. (Tier 1 - upstream wiki, etoro.Dictionary.Currency)';
ALTER TABLE main.general.bronze_etoro_dictionary_currency ALTER COLUMN ISINCode COMMENT 'International Securities Identification Number. 12-character code for stocks/ETFs (e.g., "US0378331005" for Apple). NULL for forex, commodities, indices, most crypto. Used for regulatory reporting and cross-system matching. (Tier 1 - upstream wiki, etoro.Dictionary.Currency)';
ALTER TABLE main.general.bronze_etoro_dictionary_currency ALTER COLUMN CurrencySymbol COMMENT 'Display symbol for the currency/instrument. "$" for USD, "€" for EUR, "£" for GBP. NULL for stocks and many instruments that use Abbreviation instead. (Tier 1 - upstream wiki, etoro.Dictionary.Currency)';
ALTER TABLE main.general.bronze_etoro_dictionary_currency ALTER COLUMN InterestRateID COMMENT 'FK to Dictionary.InterestRateOld. Links to interest/swap rate configuration for overnight fee calculations. Only applicable to forex/commodity instruments with overnight rollover. NULL for stocks, ETFs, crypto. (Tier 1 - upstream wiki, etoro.Dictionary.Currency)';
ALTER TABLE main.general.bronze_etoro_dictionary_currency ALTER COLUMN ISOCode COMMENT 'ISO 4217 numeric currency code. "840"=USD, "978"=EUR, "826"=GBP. Used for international financial reporting. NULL for non-currency instruments. (Tier 1 - upstream wiki, etoro.Dictionary.Currency)';
ALTER TABLE main.general.bronze_etoro_dictionary_currency ALTER COLUMN DisplayName COMMENT 'Alternative display name for UI purposes. Currently NULL for most instruments - the platform uses Name or Abbreviation instead. (Tier 1 - upstream wiki, etoro.Dictionary.Currency)';
ALTER TABLE main.general.bronze_etoro_dictionary_currency ALTER COLUMN ISOName COMMENT 'ISO 4217 alphabetic currency code. Same as Abbreviation for currencies ("USD", "EUR"). NULL for stocks and non-currency instruments. (Tier 1 - upstream wiki, etoro.Dictionary.Currency)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
