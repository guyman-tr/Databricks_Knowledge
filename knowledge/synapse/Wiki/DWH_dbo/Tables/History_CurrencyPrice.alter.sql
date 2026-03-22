-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.History_CurrencyPrice
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar SET TBLPROPERTIES (
    'comment' = 'DWH_dbo.History_CurrencyPrice is a Synapse external table that reads the complete historical price tick archive for all instruments from the Bronze data lake layer. Every tick received by the eToro price feed system is persisted here as a parquet record - capturing bid/ask prices, spread adjustments, USD conversion rates, market rate IDs, and skew values at each point in time. The production source is `Trade.CurrencyPrice` - the live price cache (one row per ProviderID+InstrumentID, continuously overwritten). When a price update arrives, the tick is also written to `History.CurrencyPrice` (the production database archive) and lands in Bronze via the PriceLog pipeline. The DWH external table reads directly from this Bronze layer. This is the DWH''s primary source for: - **Position P&L valuation**: SP_Dim_Position_DL_To_Synapse uses staging derivatives (`PriceLog_History_CurrencyPrice_Active`) to get the open/close market prices and USD conversion rates for each position - **Instrument recency**: SP_Dim_Instr...'
);

ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar SET TAGS (
    'domain' = 'finance',
    'object_type' = 'table',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'N/A (External Table - no Synapse storage; data in ADLS Gen2)',
    'synapse_index' = 'N/A (External Table - no index; access via PolyBase scan)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN Tier 5 COMMENT 'Domain expert confirmed';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN Tier 1 COMMENT 'Upstream production wiki verbatim';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN Tier 2 COMMENT 'Synapse SP code or migration DDL';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN Tier 3 COMMENT 'Live data sampling or DDL structure';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN Tier 4 COMMENT 'Inferred from column name only';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN CurrencyPriceID COMMENT 'Unique tick identifier. Bigint supports high-volume tick stream. (Tier 1 - upstream wiki, Trade.CurrencyPrice)';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN ProviderID COMMENT 'Price provider identifier. Identifies which feed/liquidity provider produced this tick. Composite key with InstrumentID. (Tier 1 - upstream wiki, Trade.CurrencyPrice)';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN InstrumentID COMMENT 'Instrument identifier (EUR/USD=1, GBP=2, etc.). FK to Dim_Instrument. Used to join positions to their price data. (Tier 1 - upstream wiki, Trade.CurrencyPrice)';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN PriceRateID COMMENT 'Tick-level rate identifier. Key for joining to Dim_Position.OpenMarketPriceRateID and CloseMarketPriceRateID for P&L calculation. (Tier 1 - upstream wiki, Trade.CurrencyPrice)';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN MarketPriceRateID COMMENT 'Market-level rate ID for this tick. Links to the composite market price at this point. Distinct from PriceRateID when bid/ask have separate market sources. (Tier 1 - upstream wiki, Trade.CurrencyPrice)';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN BidMarketPriceRateID COMMENT 'Market price rate ID specifically for the bid side. Used when bid and ask are sourced from different market feeds. (Tier 1 - upstream wiki, Trade.CurrencyPrice)';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN AskMarketPriceRateID COMMENT 'Market price rate ID specifically for the ask side. (Tier 1 - upstream wiki, Trade.CurrencyPrice)';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN LiquidityAccountID COMMENT 'Liquidity account that provided this price tick. Links to internal liquidity routing configuration. (Tier 4 - inferred from column name)';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN Bid COMMENT 'Raw market bid price. Best price at which customer can sell. (Tier 1 - upstream wiki, Trade.CurrencyPrice)';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN Ask COMMENT 'Raw market ask price. Best price at which customer can buy. (Tier 1 - upstream wiki, Trade.CurrencyPrice)';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN BidSpreaded COMMENT 'Customer-facing bid after eToro markup spread applied. Lower than raw market Bid for sell orders. (Tier 2 - DDL + SP_Dim_Position usage context)';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN AskSpreaded COMMENT 'Customer-facing ask after eToro markup spread applied. Higher than raw market Ask for buy orders. (Tier 2 - DDL + SP_Dim_Position usage context)';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN MarkupPips COMMENT 'Spread markup in PIPs added to the raw market price. The DWH-to-customer pricing margin. (Tier 2 - DDL structure)';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN RateLastEx COMMENT 'Last executed rate at this tick; view vs execution rates can differ when the market moves between quote and fill. (Tier 4 — Confluence, Rates / prices (Buy, Sell, Bid, Ask))';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN USDConversionRate COMMENT 'USD conversion rate for non-USD instruments at this tick. Used by SP_Dim_Position to convert P&L to USD. 1.0 for USD-based instruments. (Tier 1 - upstream wiki, Trade.CurrencyPrice)';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN SkewValueBid COMMENT 'Asymmetric spread skew applied to the bid side for risk management. Adjusts effective bid rate. (Tier 2 - DDL structure)';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN SkewValueAsk COMMENT 'Asymmetric spread skew applied to the ask side. (Tier 2 - DDL structure)';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN ValidFrom COMMENT 'Start of the period during which this tick was the "current" price. Used for temporal price lookups. (Tier 1 - upstream wiki, Trade.CurrencyPrice)';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN ValidTo COMMENT 'End of the period during which this tick was current. ValidFrom/ValidTo define a non-overlapping time series per (ProviderID, InstrumentID). (Tier 1 - upstream wiki, Trade.CurrencyPrice)';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN Occurred COMMENT 'Official timestamp of the price tick (eToro system time). Primary temporal reference for price history. Source for partition columns etr_y/etr_ym/etr_ymd. (Tier 1 - upstream wiki, Trade.CurrencyPrice)';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN OccurredOnProvider COMMENT 'Timestamp reported by the external price provider. May differ from Occurred due to network latency. (Tier 1 - upstream wiki, Trade.CurrencyPrice)';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN ReceivedOnPriceServer COMMENT 'Timestamp when eToro price server received this tick. Used by SP_Dim_Instrument to detect instrument recency: "last tick received for this instrument". (Tier 2 - SP_Dim_Instrument usage: min(ReceivedOnPriceServer) for instrument last seen)';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN MarketReceivedTime COMMENT 'Timestamp when the market feed received this tick from the exchange (latency vs `Occurred` / `ReceivedOnPriceServer`). (Tier 4 — Confluence, Rates / prices (Buy, Sell, Bid, Ask))';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN etr_y COMMENT 'Year partition column (e.g., "2024"). Physical parquet partition for Bronze/PriceLog/History/CurrencyPrice/etr_y={y}/. ALWAYS include in WHERE for year-level filtering. (Tier 2 - DDL + parquet location pattern)';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN etr_ym COMMENT 'Year-month partition column (e.g., "2024-06"). Physical parquet partition. Use for monthly queries. (Tier 2 - DDL + parquet location pattern)';
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN etr_ymd COMMENT 'Year-month-day partition column (e.g., "2024-06-30"). Most granular partition. Use for daily queries. Filter as string: WHERE etr_ymd = ''2024-06-30''. (Tier 2 - DDL + parquet location pattern)';

-- ---- Column PII Tags ----
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN Tier 5 SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN Tier 1 SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN Tier 2 SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN Tier 3 SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN Tier 4 SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN CurrencyPriceID SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN ProviderID SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN PriceRateID SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN MarketPriceRateID SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN BidMarketPriceRateID SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN AskMarketPriceRateID SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN LiquidityAccountID SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN Bid SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN Ask SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN BidSpreaded SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN AskSpreaded SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN MarkupPips SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN RateLastEx SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN USDConversionRate SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN SkewValueBid SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN SkewValueAsk SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN ValidFrom SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN ValidTo SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN Occurred SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN OccurredOnProvider SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN ReceivedOnPriceServer SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN MarketReceivedTime SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN etr_y SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN etr_ym SET TAGS ('pii' = 'none');
ALTER TABLE main.Likely already in UC as `bronze.pricelog_history_currencyprice` or similar ALTER COLUMN etr_ymd SET TAGS ('pii' = 'none');
