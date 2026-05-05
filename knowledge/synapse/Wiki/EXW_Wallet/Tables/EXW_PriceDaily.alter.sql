-- =============================================================================
-- Databricks ALTER Script: EXW_Wallet.EXW_PriceDaily
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily SET TBLPROPERTIES (
    'comment' = 'EXW_Wallet.EXW_PriceDaily > 414K-row daily cryptocurrency price table tracking average prices for 173 crypto assets across 13 blockchain networks from 2018-04-23 to present. Populated by `EXW_Wallet.SP_Prices` via daily DELETE+INSERT. One row per CryptoID per day representing the last hourly price snapshot. | Property | Value | |----------|-------| | **Schema** | EXW_Wallet | | **Object Type** | Table | | **Production Source** | Unknown (dormant - no upstream wiki resolvable) | | **Refresh** | Daily via `EXW_Wallet.SP_Prices @dt` - date-partitioned DELETE+INSERT | | **Synapse Distribution** | HASH(CryptoID) | | **Synapse Index** | CLUSTERED INDEX (FullDateID ASC, CryptoID ASC) | | **UC Target** | _Not_Migrated | | **UC Format** | - | | **UC Partitioned By** | - | | **UC Table Type** | - | ---'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily SET TAGS (
    'source_schema' = 'EXW_Wallet',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily ALTER COLUMN InstrumentID COMMENT 'Wallet instrument identifier. CASE logic: equals eToroInstrumentID when >= 100000 (eToro-listed), otherwise equals CryptoID (wallet-only). Derived from EXW_Currency.Instruments.Id via CryptoMarketRatesMappings join. (Tier 2 - EXW_Currency.Instruments / EXW_Wallet.CryptoMarketRatesMappings)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily ALTER COLUMN eToroInstrumentID COMMENT 'eToro trading platform instrument identifier. Sourced from EXW_Wallet.CryptoTypes.InstrumentId. NULL for wallet-only tokens not listed on the eToro platform (~83% of rows). (Tier 2 - EXW_Wallet.CryptoTypes)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily ALTER COLUMN CryptoID COMMENT 'Internal crypto asset identifier from EXW_Wallet.CryptoMarketRatesMappings. Distribution key. Used to uniquely identify each cryptocurrency across the wallet system. (Tier 2 - EXW_Wallet.CryptoMarketRatesMappings)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily ALTER COLUMN CryptoName COMMENT 'Cryptocurrency ticker symbol (e.g., BTC, ETH, CVC). Sourced as MarketRatesCurrencySymbol from EXW_Wallet.CryptoMarketRatesMappings. 173 distinct values. (Tier 2 - EXW_Wallet.CryptoMarketRatesMappings)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily ALTER COLUMN AvgPrice COMMENT 'Daily average price in USD. Computed as (BidRateAvg + AskRateAvg) / 2 from hourly rates in ETL_InstrumentRates_ByHour, taking the last hourly snapshot (ROW_NUMBER Rn=1 DESC by DateFrom). Gap-filled from prior hours or previous-day EXW_Price when missing. (Tier 2 - EXW_Wallet.ETL_InstrumentRates_ByHour)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily ALTER COLUMN BlockchainCryptoId COMMENT 'Identifier of the underlying blockchain network for this crypto asset. Sourced from EXW_Wallet.CryptoTypes.BlockchainCryptoId. 12 distinct values (e.g., 1=BTC, 2=ETH). (Tier 2 - EXW_Wallet.CryptoTypes)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily ALTER COLUMN BlockchainCryptoName COMMENT 'Name of the underlying blockchain network (e.g., BTC, ETH, XRP, SOL). Sourced as CryptoTypes.Name via self-join on BlockchainCryptoId. 13 distinct values; ETH dominates at ~95% of rows. (Tier 2 - EXW_Wallet.CryptoTypes)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily ALTER COLUMN FullDate COMMENT 'Calendar date for this daily price record. Derived as CAST(DateHour AS DATE) from ETL_InstrumentRates_ByHour.DateHour. Range: 2018-04-23 to present. (Tier 2 - EXW_Wallet.ETL_InstrumentRates_ByHour)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily ALTER COLUMN FullDateID COMMENT 'Integer date key in YYYYMMDD format (e.g., 20250101). Derived as CONVERT(VARCHAR(8), DateHour, 112) from ETL_InstrumentRates_ByHour.DateHour. Part of the clustered index. (Tier 2 - EXW_Wallet.ETL_InstrumentRates_ByHour)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() at INSERT time by SP_Prices. Indicates when this row was last written. (Tier 2 - EXW_Wallet.SP_Prices)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily ALTER COLUMN eToroInstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily ALTER COLUMN CryptoID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily ALTER COLUMN CryptoName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily ALTER COLUMN AvgPrice SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily ALTER COLUMN BlockchainCryptoId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily ALTER COLUMN BlockchainCryptoName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily ALTER COLUMN FullDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily ALTER COLUMN FullDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-05 13:08:32 UTC
-- Batch deploy resume: EXW_Wallet deploy batch 2
-- Statements: 22/22 succeeded
-- ====================
