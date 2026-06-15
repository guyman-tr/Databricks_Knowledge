-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_etoro_hedge_hbcaccountconfiguration  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HBCAccountConfiguration.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_etoro_hedge_hbcaccountconfiguration ALTER COLUMN LiquidityAccountID COMMENT 'FK to Trade.LiquidityAccounts(LiquidityAccountID). The liquidity account these execution parameters apply to. Part of 3-column composite PK. 14 distinct accounts configured.';
ALTER TABLE main.bi_db.bronze_etoro_hedge_hbcaccountconfiguration ALTER COLUMN InstrumentID COMMENT 'FK to Trade.Instrument(InstrumentID). The instrument these execution parameters apply to. Part of 3-column composite PK. 10,458 distinct instruments configured.';
ALTER TABLE main.bi_db.bronze_etoro_hedge_hbcaccountconfiguration ALTER COLUMN ThresholdInEToroUnits COMMENT 'Order size tier boundary (in eToro units). Part of 3-column composite PK enabling tiered config. The HBC selects the row for orders at or below this threshold. 5 distinct values: 0, 5,271, 110,462, 1,137,139, 200,000,000. Most rows (97%) use 200,000,000.';
ALTER TABLE main.bi_db.bronze_etoro_hedge_hbcaccountconfiguration ALTER COLUMN MaxTimeMS COMMENT 'Maximum milliseconds to wait for an order to fill before timeout. Range: 0-25,000 in current data. Applied per-tier, per-instrument, per-account.';
ALTER TABLE main.bi_db.bronze_etoro_hedge_hbcaccountconfiguration ALTER COLUMN MaxRejectRetries COMMENT 'Maximum number of retry attempts when an order is rejected. Range: 0-10 in current data. Higher values = more persistent execution attempts.';
ALTER TABLE main.bi_db.bronze_etoro_hedge_hbcaccountconfiguration ALTER COLUMN MinOrderSizeInEToroUnits COMMENT 'Minimum order size in eToro units for this account/instrument/tier. Orders below this floor are not routed. NULL = no minimum applied.';
ALTER TABLE main.bi_db.bronze_etoro_hedge_hbcaccountconfiguration ALTER COLUMN MaxOrderSizeInEToroUnits COMMENT 'Maximum single-order execution size in eToro units. Orders exceeding this must be split. Controls individual order impact on the market.';
ALTER TABLE main.bi_db.bronze_etoro_hedge_hbcaccountconfiguration ALTER COLUMN UseExecutionRateWithSpread COMMENT 'Whether the execution rate calculation includes the bid-ask spread. 1=include spread (12,723 rows), 0=exclude spread (20,982 rows). Affects pricing calculation for execution rate benchmarking.';
ALTER TABLE main.bi_db.bronze_etoro_hedge_hbcaccountconfiguration ALTER COLUMN MinOrderSizeUSDForHBC COMMENT 'Minimum order size in USD for HBC routing. DEFAULT 0 = no USD minimum. Provides a USD-denominated floor in addition to the eToro units floor.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:25:54 UTC
-- Statements: 9/9 succeeded
-- ====================
