-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_Currency
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency SET TBLPROPERTIES (
    'comment' = '`Dim_Currency` is the **universal instrument registry** for the eToro DWH. Despite its misleading name (inherited from eToro''s origins as a forex-only platform), it contains every tradeable asset on the platform: 13,044 stocks, 1,094 ETFs, 686 crypto assets, 533 commodities, 203 indices, and 174 forex pairs - 15,734 rows total as of 2026-03-11. `CurrencyID` is the platform-wide instrument identifier. It is referenced by virtually every fact table in the DWH: trade positions, deposits, credit events, and cost history all use CurrencyID to identify the instrument involved. Joining to Dim_Currency decodes CurrencyID into instrument name, asset class (CurrencyTypeID), and trading properties. The ETL is a full TRUNCATE+INSERT daily reload from `DWH_staging.etoro_Dictionary_Currency`. All 9 source columns are passthroughs; only UpdateDate is ETL-computed. The DWH has more rows than the upstream wiki documents (15.7K vs 10.7K upstream) because the wiki was written earlier and the platform has added more instrumen...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency SET TAGS (
    'domain' = 'finance',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (CurrencyID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency ALTER COLUMN CurrencyID COMMENT 'Primary key. Universal instrument identifier. 0=NULL placeholder, 1-8=major forex currencies, ~1000+=stocks (AAPL, GOOG, etc.), ~100000+=crypto (BTC, ETH). Referenced by virtually all DWH fact tables. Legacy name: eToro originated as forex-only. (Tier 1 - Dictionary.Currency upstream wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency ALTER COLUMN CurrencyTypeID COMMENT 'FK to Dim_CurrencyType (if exists). Asset class: 1=Forex (174), 2=Commodity (533), 4=Indices (203), 5=Stocks (13,044), 6=ETF (1,094), 10=Crypto (686). Determines trading rules, leverage limits, and settlement eligibility. (Tier 1 - Dictionary.Currency upstream wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency ALTER COLUMN Name COMMENT 'Full instrument name. Verbose for forex ("United States of America, US Dollar"), company name for stocks, coin name for crypto. (Tier 1 - Dictionary.Currency upstream wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency ALTER COLUMN Abbreviation COMMENT 'Ticker symbol. "USD", "EUR" for forex; "AAPL.US", "TSLA.US" for US stocks (format: TICKER.EXCHANGE); "BTC" for crypto. Unique across all instruments. Use this for human-readable instrument identification. (Tier 1 - Dictionary.Currency upstream wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency ALTER COLUMN Mask COMMENT 'Legacy power-of-2 bitmask for original 8 major forex currencies (USD=1, EUR=2, GBP=4, JPY=8, AUD=16, CHF=32, CAD=64, NZD=128). NULL or 0 for all stocks, crypto, commodities, indices. Only used in legacy forex calculations. (Tier 1 - Dictionary.Currency upstream wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency ALTER COLUMN EEAStockExchange COMMENT 'Whether this instrument is listed on a European Economic Area exchange, requiring KID documents under MiFID II PRIIPs regulation. 1=EEA-listed (~216 instruments), 0=not EEA-listed. Affects instrument availability for retail EU users. (Tier 1 - Dictionary.Currency upstream wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency ALTER COLUMN ISINCode COMMENT 'International Securities Identification Number (12-char: 2-char country + 9-char ticker + check digit). Available for stocks and ETFs. NULL for forex, commodities, crypto, and indices. Used for regulatory reporting and cross-system integration. (Tier 1 - Dictionary.Currency upstream wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency ALTER COLUMN CurrencySymbol COMMENT 'Display symbol for the instrument (e.g., "$" for USD, "€" for EUR, "£" for GBP, "₿" for BTC). NULL for most stocks and commodities. nchar type supports Unicode symbols. (Tier 2 - SP passthrough; live data confirms)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency ALTER COLUMN InterestRateID COMMENT 'FK to an interest rate configuration for this instrument. Used for overnight financing rates on leveraged positions. NULL for most instruments. (Tier 2 - SP passthrough; live data confirms for major forex)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() on each daily full reload by SP_Dictionaries_DL_To_Synapse. Reflects ETL run time, not source data change time. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency ALTER COLUMN CurrencyID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency ALTER COLUMN CurrencyTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency ALTER COLUMN Abbreviation SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency ALTER COLUMN Mask SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency ALTER COLUMN EEAStockExchange SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency ALTER COLUMN ISINCode SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency ALTER COLUMN CurrencySymbol SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency ALTER COLUMN InterestRateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
