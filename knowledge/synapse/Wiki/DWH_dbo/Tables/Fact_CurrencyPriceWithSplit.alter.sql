-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Fact_CurrencyPriceWithSplit
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit SET TBLPROPERTIES (
    'comment' = 'Fact_CurrencyPriceWithSplit is the DWH''s authoritative daily price reference table. It stores one or more price rows per instrument per calendar day, including the raw bid/ask prices, spread-adjusted prices (AskSpreaded/BidSpreaded), and the last execution rate (RateLastEx). The `isvalid` flag marks whether a given price row was the active price at end-of-day. This table is the primary source for historical price look-ups used in P&L calculations across the warehouse. Data originates from the PriceLog Candles pipeline in the Data Lake. The staging view `DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView` delivers daily candlestick prices for all instruments. On dates when a stock split occurs (identified via `DWH_staging.etoro_History_SplitRatio`), the ETL switches to `PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory`, which provides historically-adjusted prices for the affected instruments. Loaded daily by `SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse(@dt)`. The SP deletes a...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit SET TAGS (
    'domain' = 'trading',
    'object_type' = 'fact',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH(InstrumentID)',
    'synapse_index' = 'CLUSTERED COLUMNSTORE + NONCLUSTERED(OccurredDateID)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit ALTER COLUMN ProviderID COMMENT 'Price provider identifier. 3 distinct values in production. Indicates which data provider sourced the price candle. Passed through from DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit ALTER COLUMN InstrumentID COMMENT 'Financial instrument identifier. Foreign key to DWH_dbo.Dim_Instrument. HASH distribution column - include in all JOINs for optimal Synapse performance. 15,416 distinct instruments in production. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit ALTER COLUMN Occurred COMMENT 'Exact timestamp when the price was recorded. Sub-day precision. Use OccurredDate or OccurredDateID for date-level aggregations. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit ALTER COLUMN OccurredDate COMMENT 'Calendar date of the price record. Date portion of Occurred. Use for date joins or display. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit ALTER COLUMN OccurredDateID COMMENT 'Date as YYYYMMDD integer (e.g., 20240113). Secondary NCI index key. Use this column for date-range filters to leverage the NONCLUSTERED index. Corresponds to DWH_dbo.Dim_Date.DateID. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit ALTER COLUMN isvalid COMMENT 'Row validity flag. 1 = active/valid end-of-day price for this instrument on this date. 0 = non-active record (e.g., intraday snapshot or superseded row). Filter isvalid = 1 for end-of-day analytical queries. ~54% of rows are valid. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit ALTER COLUMN AskSpreaded COMMENT 'Spread-adjusted ask (offer) price for the instrument. The ask price with the broker spread applied. Used in P&L calculations for buy-side opening cost. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit ALTER COLUMN BidSpreaded COMMENT 'Spread-adjusted bid price for the instrument. The bid price with the broker spread applied. Used in P&L calculations for sell-side closing proceeds. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit ALTER COLUMN RateLastEx COMMENT 'Last execution rate for the instrument on this date. The price at which the most recent trade was executed. Reference rate for settlement. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit ALTER COLUMN Ask COMMENT 'Raw ask (offer) price before spread adjustment. Mid-price reference. Compare to AskSpreaded to derive the spread. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit ALTER COLUMN Bid COMMENT 'Raw bid price before spread adjustment. Mid-price reference. Compare to BidSpreaded to derive the spread. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit ALTER COLUMN UpdateDate COMMENT 'DWH load timestamp. Set to GETDATE() at ETL execution time. Not the price timestamp - use Occurred for price time. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit ALTER COLUMN ConvertRateIsBuy_1 COMMENT 'Pre-computed USD conversion rate for buy-side positions (IsBuy=1). Logic: if SellCurrencyID=1 then 1.00; if BuyCurrencyID=1 then 1/Bid; otherwise cross-rate via coalesce with 1.00 fallback. NULL for rows outside the current ETL load date (UPDATE only applies to @DateID). Added 2023-02-26.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit ALTER COLUMN ConvertRateIsBuy_0 COMMENT 'Pre-computed USD conversion rate for sell-side positions (IsBuy=0). Logic: if SellCurrencyID=1 then 1.00; if BuyCurrencyID=1 then 1/Ask; otherwise cross-rate via coalesce with 1.00 fallback. NULL for rows outside the current ETL load date (UPDATE only applies to @DateID). Added 2023-02-26.';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit ALTER COLUMN ProviderID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit ALTER COLUMN Occurred SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit ALTER COLUMN OccurredDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit ALTER COLUMN OccurredDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit ALTER COLUMN isvalid SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit ALTER COLUMN AskSpreaded SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit ALTER COLUMN BidSpreaded SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit ALTER COLUMN RateLastEx SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit ALTER COLUMN Ask SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit ALTER COLUMN Bid SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit ALTER COLUMN ConvertRateIsBuy_1 SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit ALTER COLUMN ConvertRateIsBuy_0 SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:30:24 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 30/30 succeeded
-- ====================
