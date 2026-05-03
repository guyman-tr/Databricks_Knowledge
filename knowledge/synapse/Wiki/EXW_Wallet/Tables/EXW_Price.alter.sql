-- =============================================================================
-- Databricks ALTER Script: EXW_Wallet.EXW_Price
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price SET TBLPROPERTIES (
    'comment' = 'EXW_Wallet.EXW_Price > 9.95M-row hourly cryptocurrency price table tracking ask, bid, and average prices for ~172 crypto instruments across 12 blockchain networks from 2018-04-23 to present. Populated daily by SP_Prices from ETL_InstrumentRates_ByHour with hourly gap-filling logic. ~4,128 rows inserted per day (172 instruments x 24 hours). | Property | Value | |----------|-------| | **Schema** | EXW_Wallet | | **Object Type** | Table | | **Production Source** | Unknown (no resolvable upstream wiki; data originates from EXW_Wallet.ETL_InstrumentRates_ByHour via SP_Prices) | | **Refresh** | Daily - delete+insert per date via EXW_Wallet.SP_Prices(@dt) | | **Synapse Distribution** | ROUND_ROBIN | | **Synapse Index** | CLUSTERED INDEX (DateFrom ASC, CryptoID ASC) | | **UC Target** | _Not_Migrated | | **UC Format** | - | | **UC Partitioned By** | - | | **UC Table Type** | - | ---'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price SET TAGS (
    'source_schema' = 'EXW_Wallet',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price ALTER COLUMN InstrumentID COMMENT 'Composite instrument identifier. CASE WHEN eToroInstrumentID >= 100000 THEN eToroInstrumentID ELSE CryptoId END. For eToro-mapped instruments, equals eToroInstrumentID; for crypto-native instruments, equals CryptoID. Not a direct FK to EXW_Currency.Instruments. (Tier 2 - EXW_Wallet.CryptoTypes / EXW_Wallet.CryptoMarketRatesMappings)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price ALTER COLUMN eToroInstrumentID COMMENT 'eToro trading platform instrument identifier. Sourced from CryptoTypes.InstrumentId via the crypto mapping chain. NULL for ~65% of instruments that are crypto-native without eToro platform mapping. Values >= 100000 when present. (Tier 2 - EXW_Wallet.CryptoTypes)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price ALTER COLUMN CryptoID COMMENT 'Unique crypto asset identifier from CryptoMarketRatesMappings. Stable identifier for the crypto asset regardless of eToro mapping. One row per CryptoID per hour. (Tier 2 - EXW_Wallet.CryptoMarketRatesMappings)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price ALTER COLUMN CryptoName COMMENT 'Crypto asset ticker symbol (e.g., BNT, BTC, ETH, ALICE). Sourced as MarketRatesCurrencySymbol from CryptoMarketRatesMappings, renamed to CryptoName. (Tier 2 - EXW_Wallet.CryptoMarketRatesMappings)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price ALTER COLUMN AskLast COMMENT 'Average ask rate for the hour bucket. Sourced as AskRateAvg from ETL_InstrumentRates_ByHour. Gap-filled from the most recent prior hour with data, or from prior-day EXW_Price if the entire day is missing. Zero indicates a dormant or delisted instrument. (Tier 2 - EXW_Wallet.ETL_InstrumentRates_ByHour)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price ALTER COLUMN BidLast COMMENT 'Average bid rate for the hour bucket. Sourced as BidRateAvg from ETL_InstrumentRates_ByHour. Gap-filled from the most recent prior hour with data, or from prior-day EXW_Price if the entire day is missing. Zero indicates a dormant or delisted instrument. (Tier 2 - EXW_Wallet.ETL_InstrumentRates_ByHour)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price ALTER COLUMN AvgPrice COMMENT 'Midpoint price computed as (BidRateAvg + AskRateAvg) / 2 from ETL_InstrumentRates_ByHour. Gap-filled using same logic as AskLast/BidLast. Primary price column for portfolio valuation. (Tier 2 - EXW_Wallet.ETL_InstrumentRates_ByHour)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price ALTER COLUMN DateFrom COMMENT 'Start of the one-hour price bucket. Sourced as DateHour from ETL_InstrumentRates_ByHour. Part of the clustered index. Range: every hour on the hour from midnight to 23:00 for each date. (Tier 2 - EXW_Wallet.ETL_InstrumentRates_ByHour)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price ALTER COLUMN DateTo COMMENT 'End of the one-hour price bucket. Computed as DATEADD(HOUR, 1, DateHour). Always exactly one hour after DateFrom. (Tier 2 - EXW_Wallet.ETL_InstrumentRates_ByHour)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price ALTER COLUMN BlockchainCryptoId COMMENT 'Identifier of the parent blockchain network for this crypto asset. Resolved via CryptoTypes.BlockchainCryptoId - maps each token to its underlying blockchain (e.g., all ERC-20 tokens map to ETH''s BlockchainCryptoId). 12 distinct values. (Tier 2 - EXW_Wallet.CryptoTypes)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price ALTER COLUMN BlockchainCryptoName COMMENT 'Name of the parent blockchain network (e.g., ETH, BTC, SOL, ADA, XRP). Resolved from CryptoTypes.Name for the blockchain-level CryptoTypes row (ct1 alias in SP_Prices). 12 distinct values: ETH, BTC, LTC, SOL, TRX, XLM, XRP, ADA, BCH, DOGE, EOS, ETC. (Tier 2 - EXW_Wallet.CryptoTypes)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price ALTER COLUMN FullDate COMMENT 'Calendar date of the price record. Computed as CAST(DateHour AS DATE) from ETL_InstrumentRates_ByHour. Used for daily-level filtering and joins to EXW_PriceDaily. (Tier 2 - EXW_Wallet.ETL_InstrumentRates_ByHour)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price ALTER COLUMN FullDateID COMMENT 'Integer date key in YYYYMMDD format. Computed as CONVERT(VARCHAR(8), DateHour, 112) from ETL_InstrumentRates_ByHour. Used for date-range filtering and partition-style access. (Tier 2 - EXW_Wallet.ETL_InstrumentRates_ByHour)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price ALTER COLUMN UpdateDate COMMENT 'Timestamp when the row was inserted by SP_Prices. Set to GETDATE() at insert time. Not updated on backfill - reflects the ETL execution time, not the price observation time. (Tier 2 - EXW_Wallet.SP_Prices)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price ALTER COLUMN eToroInstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price ALTER COLUMN CryptoID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price ALTER COLUMN CryptoName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price ALTER COLUMN AskLast SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price ALTER COLUMN BidLast SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price ALTER COLUMN AvgPrice SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price ALTER COLUMN DateFrom SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price ALTER COLUMN DateTo SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price ALTER COLUMN BlockchainCryptoId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price ALTER COLUMN BlockchainCryptoName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price ALTER COLUMN FullDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price ALTER COLUMN FullDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:17:26 UTC
-- Batch deploy resume: EXW_Wallet deploy batch 1
-- Statements: 30/30 succeeded
-- ====================
