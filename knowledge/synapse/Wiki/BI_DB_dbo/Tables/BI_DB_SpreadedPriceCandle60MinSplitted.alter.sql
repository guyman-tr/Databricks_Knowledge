-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_SpreadedPriceCandle60MinSplitted
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_SpreadedPriceCandle60MinSplitted > 48.8M-row spread-adjusted 60-minute OHLC price candle table covering 8,445 instruments across 2 providers from 2015-01-01 to 2024-06-02. Sourced externally from the production Candle Builder service (Price:12 / Candles DB). Last updated 2024-06-02; appears dormant since then. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | Candle Builder service (Price:12 / Candles DB on AO-CANDLES-LSN); no Synapse writer SP | | **Refresh** | Dormant since 2024-06-02; previously loaded via external migration pipeline | | **Synapse Distribution** | ROUND_ROBIN | | **Synapse Index** | CLUSTERED INDEX (DateFrom ASC, DateTo ASC, ProviderID ASC, InstrumentID ASC) | | **Secondary Index** | IX_BI_DB_SpreadedPriceCandle60MinSplitted (InstrumentID ASC, DateFrom ASC) | | **UC Target** | _No'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN ProviderID COMMENT 'Price feed provider identifier. ProviderID=1 is the primary source (48.8M rows); ProviderID=0 is a secondary/fallback source (4,349 rows). Part of the clustered index. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and data distribution)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN InstrumentID COMMENT 'Financial instrument identifier. FK to Dim_Instrument. 8,445 distinct instruments observed. Part of the clustered index and NCI. Used by downstream SPs (SP_DailyNOP_ByInstrument, SP_M_EOMExposures, SP_NOP_LPandClients, SP_Max_NOP) to join price data to position/NOP calculations. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL, sample data, and downstream SP JOINs)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN DateFrom COMMENT 'Start of the 60-minute candle window (inclusive). Part of the clustered index and NCI. Downstream SPs filter on this column to locate the most recent candle before a target date. Range: 2015-01-01 to 2024-06-02. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and downstream SP usage)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN DateTo COMMENT 'End of the 60-minute candle window (exclusive). Equals DateFrom + 1 hour. Part of the clustered index. SP_Max_NOP joins on DateTo to match hourly holdings snapshots to candle close prices. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and SP_Max_NOP JOIN logic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN AskFirst COMMENT 'Ask (offer) price at the opening of the 60-minute candle window. The first ask quote recorded in the interval. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and OHLC naming convention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN AskLast COMMENT 'Ask (offer) price at the close of the 60-minute candle window. The last ask quote recorded in the interval. Used by SP_M_EOMExposures and SP_NOP_LPandClients for end-of-period pricing; SP_Max_NOP uses it to compute LocalAmount for short positions. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and downstream SP usage)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN AskMin COMMENT 'Lowest ask (offer) price observed during the 60-minute candle window. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and OHLC naming convention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN AskMax COMMENT 'Highest ask (offer) price observed during the 60-minute candle window. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and OHLC naming convention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN BidFirst COMMENT 'Bid price at the opening of the 60-minute candle window. The first bid quote recorded in the interval. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and OHLC naming convention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN BidLast COMMENT 'Bid price at the close of the 60-minute candle window. The last bid quote recorded in the interval. Used by SP_DailyNOP_ByInstrument as the last known price per instrument; SP_M_EOMExposures and SP_NOP_LPandClients use it for end-of-period pricing; SP_Max_NOP uses it to compute LocalAmount for long positions. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and downstream SP usage)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN BidMin COMMENT 'Lowest bid price observed during the 60-minute candle window. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and OHLC naming convention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN BidMax COMMENT 'Highest bid price observed during the 60-minute candle window. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and OHLC naming convention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN AskFirstOccurred COMMENT 'Exact timestamp when AskFirst (opening ask price) was recorded. May precede DateFrom due to weekend/holiday carryover from the prior trading session. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and sample data observation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN AskLastOccurred COMMENT 'Exact timestamp when AskLast (closing ask price) was recorded within the candle window. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and sample data observation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN AskMinOccurred COMMENT 'Exact timestamp when AskMin (lowest ask price) was recorded within the candle window. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and sample data observation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN AskMaxOccurred COMMENT 'Exact timestamp when AskMax (highest ask price) was recorded within the candle window. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and sample data observation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN BidFirstOccurred COMMENT 'Exact timestamp when BidFirst (opening bid price) was recorded. May precede DateFrom due to weekend/holiday carryover from the prior trading session. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and sample data observation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN BidLastOccurred COMMENT 'Exact timestamp when BidLast (closing bid price) was recorded within the candle window. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and sample data observation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN BidMinOccurred COMMENT 'Exact timestamp when BidMin (lowest bid price) was recorded within the candle window. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and sample data observation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN BidMaxOccurred COMMENT 'Exact timestamp when BidMax (highest bid price) was recorded within the candle window. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and sample data observation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN UpdateDate COMMENT 'Timestamp of the last ETL load or update for this row. Range: 2019-11-12 to 2024-06-02. Many older rows share UpdateDate=2019-11-12, suggesting a bulk historical reload. (Tier 3 --- no upstream wiki, no writer SP; identified from DDL and sample data observation)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN ProviderID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN DateFrom SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN DateTo SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN AskFirst SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN AskLast SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN AskMin SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN AskMax SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN BidFirst SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN BidLast SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN BidMin SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN BidMax SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN AskFirstOccurred SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN AskLastOccurred SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN AskMinOccurred SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN AskMaxOccurred SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN BidFirstOccurred SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN BidLastOccurred SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN BidMinOccurred SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN BidMaxOccurred SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_spreadedpricecandle60minsplitted ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 13:13:39 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 44/44 succeeded
-- ====================
