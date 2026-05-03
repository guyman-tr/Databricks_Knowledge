-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.CurrencyPrice
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.CurrencyPrice.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_trade_currencyprice
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_trade_currencyprice (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_trade_currencyprice SET TBLPROPERTIES (
    'comment' = 'Real-time price cache for all instruments per provider. Stores latest bid, ask, and derived pricing used by order placement and position valuation. Source: etoro.Trade.CurrencyPrice on the etoro production database, ingested via the Generic Pipeline (Override strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.CurrencyPrice.md).'
);

ALTER TABLE main.trading.bronze_etoro_trade_currencyprice SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'CurrencyPrice',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_trade_currencyprice ALTER COLUMN ProviderID COMMENT 'Part of PK. FK to Trade.ProviderToInstrument. TCRP_NULLPROVIDER default. (Tier 1 - upstream wiki, etoro.Trade.CurrencyPrice)';
ALTER TABLE main.trading.bronze_etoro_trade_currencyprice ALTER COLUMN InstrumentID COMMENT 'Part of PK. FK to Trade.ProviderToInstrument. TCRP_NULLINSTRUMENT default. (Tier 1 - upstream wiki, etoro.Trade.CurrencyPrice)';
ALTER TABLE main.trading.bronze_etoro_trade_currencyprice ALTER COLUMN Bid COMMENT 'Current bid rate. OrdersAdd, PositionClose, FnGetCurrentClosingRate read this. (Tier 1 - upstream wiki, etoro.Trade.CurrencyPrice)';
ALTER TABLE main.trading.bronze_etoro_trade_currencyprice ALTER COLUMN Ask COMMENT 'Current ask rate. Used with Bid for mid-price and validation. (Tier 1 - upstream wiki, etoro.Trade.CurrencyPrice)';
ALTER TABLE main.trading.bronze_etoro_trade_currencyprice ALTER COLUMN Occurred COMMENT 'When this price was last updated. TCRP_LASTUPDATE default. (Tier 1 - upstream wiki, etoro.Trade.CurrencyPrice)';
ALTER TABLE main.trading.bronze_etoro_trade_currencyprice ALTER COLUMN OccurredOnServer COMMENT 'Server timestamp of price reception. (Tier 1 - upstream wiki, etoro.Trade.CurrencyPrice)';
ALTER TABLE main.trading.bronze_etoro_trade_currencyprice ALTER COLUMN PriceRateID COMMENT 'Tick/rate identifier. Links to price feed stream. Indexed (IX_PriceRateID). (Tier 1 - upstream wiki, etoro.Trade.CurrencyPrice)';
ALTER TABLE main.trading.bronze_etoro_trade_currencyprice ALTER COLUMN ReceivedOnPriceServer COMMENT 'When price server received the tick. (Tier 1 - upstream wiki, etoro.Trade.CurrencyPrice)';
ALTER TABLE main.trading.bronze_etoro_trade_currencyprice ALTER COLUMN MarketPriceRateID COMMENT 'Market rate ID. TCRP_NullMarketPriceRateID default. (Tier 1 - upstream wiki, etoro.Trade.CurrencyPrice)';
ALTER TABLE main.trading.bronze_etoro_trade_currencyprice ALTER COLUMN LastPrice COMMENT 'Last traded/reference price. DF_CurrencyPrice_LastPrice default. (Tier 1 - upstream wiki, etoro.Trade.CurrencyPrice)';
ALTER TABLE main.trading.bronze_etoro_trade_currencyprice ALTER COLUMN BidMarketPriceRateID COMMENT 'Rate ID for bid source. (Tier 1 - upstream wiki, etoro.Trade.CurrencyPrice)';
ALTER TABLE main.trading.bronze_etoro_trade_currencyprice ALTER COLUMN AskMarketPriceRateID COMMENT 'Rate ID for ask source. (Tier 1 - upstream wiki, etoro.Trade.CurrencyPrice)';
ALTER TABLE main.trading.bronze_etoro_trade_currencyprice ALTER COLUMN MarkupPips COMMENT 'Markup in pips. (Tier 1 - upstream wiki, etoro.Trade.CurrencyPrice)';
ALTER TABLE main.trading.bronze_etoro_trade_currencyprice ALTER COLUMN UnitMargin COMMENT 'Margin per unit for P&L. DF_CurrencyPrice_UnitMargin. GetEstimatedTreeUnitsByCID uses this. (Tier 1 - upstream wiki, etoro.Trade.CurrencyPrice)';
ALTER TABLE main.trading.bronze_etoro_trade_currencyprice ALTER COLUMN SkewValueBid COMMENT 'Bid skew. Default 0. (Tier 1 - upstream wiki, etoro.Trade.CurrencyPrice)';
ALTER TABLE main.trading.bronze_etoro_trade_currencyprice ALTER COLUMN SkewValueAsk COMMENT 'Ask skew. Default 0. (Tier 1 - upstream wiki, etoro.Trade.CurrencyPrice)';
ALTER TABLE main.trading.bronze_etoro_trade_currencyprice ALTER COLUMN BidDiscounted COMMENT 'Spread-discounted bid. DF_TCRP_BidDiscounted. (Tier 1 - upstream wiki, etoro.Trade.CurrencyPrice)';
ALTER TABLE main.trading.bronze_etoro_trade_currencyprice ALTER COLUMN AskDiscounted COMMENT 'Spread-discounted ask. DF_TCRP_AskDiscounted. (Tier 1 - upstream wiki, etoro.Trade.CurrencyPrice)';
ALTER TABLE main.trading.bronze_etoro_trade_currencyprice ALTER COLUMN UnitMarginBidDiscounted COMMENT 'Discounted unit margin for bid side. (Tier 1 - upstream wiki, etoro.Trade.CurrencyPrice)';
ALTER TABLE main.trading.bronze_etoro_trade_currencyprice ALTER COLUMN UnitMarginAskDiscounted COMMENT 'Discounted unit margin for ask side. (Tier 1 - upstream wiki, etoro.Trade.CurrencyPrice)';
ALTER TABLE main.trading.bronze_etoro_trade_currencyprice ALTER COLUMN UnitMarginBid COMMENT 'Unit margin for bid. (Tier 1 - upstream wiki, etoro.Trade.CurrencyPrice)';
ALTER TABLE main.trading.bronze_etoro_trade_currencyprice ALTER COLUMN UnitMarginAsk COMMENT 'Unit margin for ask. (Tier 1 - upstream wiki, etoro.Trade.CurrencyPrice)';
ALTER TABLE main.trading.bronze_etoro_trade_currencyprice ALTER COLUMN USDConversionRateBidSpreaded COMMENT 'USD conversion rate (bid, spreaded) for non-USD instruments. (Tier 1 - upstream wiki, etoro.Trade.CurrencyPrice)';
ALTER TABLE main.trading.bronze_etoro_trade_currencyprice ALTER COLUMN USDConversionRateAskSpreaded COMMENT 'USD conversion rate (ask, spreaded). (Tier 1 - upstream wiki, etoro.Trade.CurrencyPrice)';
ALTER TABLE main.trading.bronze_etoro_trade_currencyprice ALTER COLUMN USDConversionPriceRateID COMMENT 'Rate ID for USD conversion instrument. (Tier 1 - upstream wiki, etoro.Trade.CurrencyPrice)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
