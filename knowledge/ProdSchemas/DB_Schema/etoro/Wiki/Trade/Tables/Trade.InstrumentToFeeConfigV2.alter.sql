-- =============================================================================
-- Databricks ALTER Script: main.trading.bronze_etoro_trade_instrumenttofeeconfigv2  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.InstrumentToFeeConfigV2.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN InstrumentID COMMENT 'PK; FK to Trade.Instrument.';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN SettlementTypeID COMMENT '0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE.';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN FeeCalculationTypeID COMMENT '0=ExposureFormula, 1=LoanFormula.';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN NonLeveragedSellEndOfWeekFee COMMENT 'Weekend fee for non-leveraged sell.';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN NonLeveragedBuyEndOfWeekFee COMMENT 'Weekend fee for non-leveraged buy.';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN NonLeveragedBuyOverNightFee COMMENT 'Overnight fee for non-leveraged buy.';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN NonLeveragedSellOverNightFee COMMENT 'Overnight fee for non-leveraged sell.';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN LeveragedSellEndOfWeekFee COMMENT 'Weekend fee for leveraged sell.';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN LeveragedBuyEndOfWeekFee COMMENT 'Weekend fee for leveraged buy.';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN LeveragedBuyOverNightFee COMMENT 'Overnight fee for leveraged buy.';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN LeveragedSellOverNightFee COMMENT 'Overnight fee for leveraged sell.';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN Occurred COMMENT 'When config was last changed.';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN UpdatedByUser COMMENT 'User/system that updated.';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN BeginTime COMMENT 'Temporal row start.';
ALTER TABLE main.trading.bronze_etoro_trade_instrumenttofeeconfigv2 ALTER COLUMN EndTime COMMENT 'Temporal row end.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:24:54 UTC
-- Statements: 15/15 succeeded
-- ====================
