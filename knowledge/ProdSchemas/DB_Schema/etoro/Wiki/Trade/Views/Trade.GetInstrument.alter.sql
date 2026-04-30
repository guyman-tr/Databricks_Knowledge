-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.GetInstrument
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Views/Trade.GetInstrument.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_trade_getinstrument
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_trade_getinstrument (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_trade_getinstrument SET TBLPROPERTIES (
    'comment' = 'Instrument deal view that joins Instrument with currency abbreviations and metadata to produce display-ready instrument rows with Name as "BUY/SELL", filtering out InstrumentID=0 and NULL InstrumentTypeID. Source: etoro.Trade.GetInstrument on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Views/Trade.GetInstrument.md).'
);

ALTER TABLE main.trading.bronze_etoro_trade_getinstrument SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'GetInstrument',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_trade_getinstrument ALTER COLUMN InstrumentID COMMENT 'Primary key from Trade.Instrument. Identifies the tradeable instrument pair. (Tier 1 - upstream wiki, etoro.Trade.GetInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_getinstrument ALTER COLUMN BuyCurrencyID COMMENT 'FK to Dictionary.Currency. Buy-side asset. For forex: base currency; for stocks: asset itself (BuyCurrencyID=InstrumentID). Inherited from Trade.Instrument. (Tier 1 - upstream wiki, etoro.Trade.GetInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_getinstrument ALTER COLUMN SellCurrencyID COMMENT 'FK to Dictionary.Currency. Sell-side (denomination) currency. For forex: quote currency; for stocks: trading currency. Inherited from Trade.Instrument. (Tier 1 - upstream wiki, etoro.Trade.GetInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_getinstrument ALTER COLUMN InstrumentTypeID COMMENT 'From IMD (InstrumentMetaData). Asset class: 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType. (Tier 1 - upstream wiki, etoro.Trade.GetInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_getinstrument ALTER COLUMN Name COMMENT 'Computed: TDCUR_BUY.Abbreviation + ''/'' + TDCUR_SEL.Abbreviation. Display name for UI (e.g., EUR/USD, AAPL/USD). (Tier 1 - upstream wiki, etoro.Trade.GetInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_getinstrument ALTER COLUMN TradeRange COMMENT 'Allowed trade range (pip distance) for pending orders. From Trade.Instrument. (Tier 1 - upstream wiki, etoro.Trade.GetInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_getinstrument ALTER COLUMN DollarRatio COMMENT 'Price scaling factor. Most=1; JPY pairs=100. From Trade.Instrument. (Tier 1 - upstream wiki, etoro.Trade.GetInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_getinstrument ALTER COLUMN Passport COMMENT 'Row version/concurrency token. From Trade.Instrument. (Tier 1 - upstream wiki, etoro.Trade.GetInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_getinstrument ALTER COLUMN PipDifferenceThreshold COMMENT 'Max pip difference for price validation. From Trade.Instrument. (Tier 1 - upstream wiki, etoro.Trade.GetInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_getinstrument ALTER COLUMN IsMajor COMMENT '1=major instrument (spread/margin treatment); 0=minor. From Trade.Instrument. (Tier 1 - upstream wiki, etoro.Trade.GetInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_getinstrument ALTER COLUMN Industry COMMENT 'Industry sector label from IMD (e.g., Technology, Consumer Goods). NULL for forex/crypto. From Trade.InstrumentMetaData. (Tier 1 - upstream wiki, etoro.Trade.GetInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_getinstrument ALTER COLUMN ExchangeID COMMENT 'FK to Price.Exchange. Primary exchange for price feed routing. From Trade.InstrumentMetaData. (Tier 1 - upstream wiki, etoro.Trade.GetInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_getinstrument ALTER COLUMN OperationMode COMMENT 'Trading operation mode: 0=Standard, 1=Alternate (e.g., European stocks in non-USD). From Trade.Instrument. (Tier 1 - upstream wiki, etoro.Trade.GetInstrument)';

