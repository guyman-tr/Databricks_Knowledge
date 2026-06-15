-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_history_tradeprovidertoinstrument  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.TradeProviderToInstrument.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN ProviderID COMMENT 'Liquidity provider identifier. Part of composite PK in source table (ProviderID, InstrumentID).';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN InstrumentID COMMENT 'Instrument identifier. Combined with ProviderID identifies which instrument config row changed.';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN Precision COMMENT 'Price decimal precision for this instrument (e.g., 2 for EUR/USD = 1.23, 5 for crypto).';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN StopLossPercentage COMMENT 'Default stop-loss as percentage of position value. Deprecated in favor of Min/Max/DefaultStopLossPercentage fields.';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN EndOfWeekFee COMMENT 'Weekly rollover fee charged on positions held over the weekend.';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN Enabled COMMENT 'Whether this instrument is enabled for trading on this provider: 0=disabled, 1=enabled. A change here in history marks when an instrument was suspended or re-enabled.';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN AllowBuy COMMENT 'Whether buy/long positions are allowed for this instrument. 0=buy blocked, 1=buy allowed.';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN AllowSell COMMENT 'Whether sell/short positions are allowed. Often false for real stocks (long-only).';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN MaxTakeProfitPercentage COMMENT 'Maximum take-profit as percentage above entry price (e.g., 200 = max 200% gain).';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN MinStopLossPercentage COMMENT 'Minimum stop-loss distance as % below entry. Prevents setting SL too close to market.';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN MaxStopLossPercentage COMMENT 'Maximum stop-loss distance as % below entry. Caps maximum SL distance.';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN AllowTrailingStopLoss COMMENT 'Whether trailing stop-loss (TSL) is permitted for this instrument.';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN AllowRedeem COMMENT 'Whether redemption (selling real stock shares) is permitted for this instrument. TINYINT for multi-mode support.';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN DesignatedExecutionSystem COMMENT 'Which execution system routes orders for this instrument (e.g., 0=internal, 1=external broker, etc.).';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN DbLoginName COMMENT 'SQL Server login that made the change, from suser_name() at DML time.';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN AppLoginName COMMENT 'Application login from context_info() at DML time. Identifies calling service.';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN SysStartTime COMMENT 'UTC timestamp when this instrument configuration became active.';
ALTER TABLE main.general.bronze_etoro_history_tradeprovidertoinstrument ALTER COLUMN SysEndTime COMMENT 'UTC timestamp when this configuration was superseded. Clustered index leading column.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:18:46 UTC
-- Statements: 18/18 succeeded
-- ====================
