-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.TradeProviderToInstrument
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.TradeProviderToInstrument.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_tradeprovidertoinstrument
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_tradeprovidertoinstrument (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument SET TBLPROPERTIES (
    'comment' = 'SQL Server system-versioned temporal history table for Trade.ProviderToInstrument - stores superseded full instrument configuration snapshots (92 trading parameters) per provider/instrument, enabling point-in-time auditing of all instrument trading rules. Source: etoro.History.TradeProviderToInstrument on the etoro production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.TradeProviderToInstrument.md).'
);

ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'TradeProviderToInstrument',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN ProviderID COMMENT 'Liquidity provider identifier. Part of composite PK in source table (ProviderID, InstrumentID). (Tier 1 - upstream wiki, etoro.History.TradeProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN InstrumentID COMMENT 'Instrument identifier. Combined with ProviderID identifies which instrument config row changed. (Tier 1 - upstream wiki, etoro.History.TradeProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN Precision COMMENT 'Price decimal precision for this instrument (e.g., 2 for EUR/USD = 1.23, 5 for crypto). (Tier 1 - upstream wiki, etoro.History.TradeProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN `PaymentBid / PaymentAsk` COMMENT 'Bid/Ask spread payment in pips. Used in overnight fee calculations. (Tier 1 - upstream wiki, etoro.History.TradeProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN StopLossPercentage COMMENT 'Default stop-loss as percentage of position value. Deprecated in favor of Min/Max/DefaultStopLossPercentage fields. (Tier 1 - upstream wiki, etoro.History.TradeProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN EndOfWeekFee COMMENT 'Weekly rollover fee charged on positions held over the weekend. (Tier 1 - upstream wiki, etoro.History.TradeProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN Enabled COMMENT 'Whether this instrument is enabled for trading on this provider: 0=disabled, 1=enabled. A change here in history marks when an instrument was suspended or re-enabled. (Tier 1 - upstream wiki, etoro.History.TradeProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN AllowBuy COMMENT 'Whether buy/long positions are allowed for this instrument. 0=buy blocked, 1=buy allowed. (Tier 1 - upstream wiki, etoro.History.TradeProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN AllowSell COMMENT 'Whether sell/short positions are allowed. Often false for real stocks (long-only). (Tier 1 - upstream wiki, etoro.History.TradeProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN MaxTakeProfitPercentage COMMENT 'Maximum take-profit as percentage above entry price (e.g., 200 = max 200% gain). (Tier 1 - upstream wiki, etoro.History.TradeProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN MinStopLossPercentage COMMENT 'Minimum stop-loss distance as % below entry. Prevents setting SL too close to market. (Tier 1 - upstream wiki, etoro.History.TradeProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN MaxStopLossPercentage COMMENT 'Maximum stop-loss distance as % below entry. Caps maximum SL distance. (Tier 1 - upstream wiki, etoro.History.TradeProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN AllowTrailingStopLoss COMMENT 'Whether trailing stop-loss (TSL) is permitted for this instrument. (Tier 1 - upstream wiki, etoro.History.TradeProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN AllowRedeem COMMENT 'Whether redemption (selling real stock shares) is permitted for this instrument. TINYINT for multi-mode support. (Tier 1 - upstream wiki, etoro.History.TradeProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN DesignatedExecutionSystem COMMENT 'Which execution system routes orders for this instrument (e.g., 0=internal, 1=external broker, etc.). (Tier 1 - upstream wiki, etoro.History.TradeProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN DbLoginName COMMENT 'SQL Server login that made the change, from suser_name() at DML time. (Tier 1 - upstream wiki, etoro.History.TradeProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN AppLoginName COMMENT 'Application login from context_info() at DML time. Identifies calling service. (Tier 1 - upstream wiki, etoro.History.TradeProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN SysStartTime COMMENT 'UTC timestamp when this instrument configuration became active. (Tier 1 - upstream wiki, etoro.History.TradeProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN SysEndTime COMMENT 'UTC timestamp when this configuration was superseded. Clustered index leading column. (Tier 1 - upstream wiki, etoro.History.TradeProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN `(Additional columns)` COMMENT 'All remaining 73 trading parameter columns from Trade.ProviderToInstrument are preserved verbatim. See Trade.ProviderToInstrument documentation for full column list. (Tier 1 - upstream wiki, etoro.History.TradeProviderToInstrument)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
