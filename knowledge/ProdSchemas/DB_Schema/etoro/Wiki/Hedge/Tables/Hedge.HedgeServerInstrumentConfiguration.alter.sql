-- =============================================================================
-- Databricks ALTER Script: main.trading.bronze_etoro_hedge_hedgeserverinstrumentconfiguration  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HedgeServerInstrumentConfiguration.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.trading.bronze_etoro_hedge_hedgeserverinstrumentconfiguration ALTER COLUMN HedgeServerID COMMENT 'The hedge server this configuration applies to. Part of composite PK. Implicit reference to Trade.HedgeServer (no FK constraint). Indexed via idx_HSID for per-server lookups.';
ALTER TABLE main.trading.bronze_etoro_hedge_hedgeserverinstrumentconfiguration ALTER COLUMN InstrumentID COMMENT 'The instrument this configuration applies to. Part of composite PK. Implicit reference to Trade.Instrument (no FK constraint). Indexed via idx_InstrumentID for per-instrument lookups.';
ALTER TABLE main.trading.bronze_etoro_hedge_hedgeserverinstrumentconfiguration ALTER COLUMN AllowHBCFailover COMMENT 'Whether HBC execution failure for this server/instrument can fall back to standard execution. 1=failover allowed, 0=strict (no fallback). Instrument-level override of Hedge.BusinessFlowBehavior.AllowHBCFailover. No DEFAULT - must be explicitly provided on insert.';
ALTER TABLE main.trading.bronze_etoro_hedge_hedgeserverinstrumentconfiguration ALTER COLUMN PriceSource COMMENT 'Price feed selection for this server/instrument pair. DEFAULT 1 = primary price source. Instrument-level override of Trade.HedgeServer.PriceSource. Exact enum values not defined in schema.';
ALTER TABLE main.trading.bronze_etoro_hedge_hedgeserverinstrumentconfiguration ALTER COLUMN AllowClosePositionMaxDealSizeCheck COMMENT 'Whether max deal size validation applies to close-position orders for this server/instrument. DEFAULT 1 = validate (same rules as open orders). 0 = bypass size check for close orders only.';
ALTER TABLE main.trading.bronze_etoro_hedge_hedgeserverinstrumentconfiguration ALTER COLUMN MinAmountForIM COMMENT 'Minimum order size (base currency) for routing via Institutional Market (IM) path. DEFAULT 0 = no minimum. Non-zero = orders below this threshold bypass IM routing for this server/instrument.';
ALTER TABLE main.trading.bronze_etoro_hedge_hedgeserverinstrumentconfiguration ALTER COLUMN DbLoginName COMMENT 'Computed audit column. SQL Server login executing the DML.';
ALTER TABLE main.trading.bronze_etoro_hedge_hedgeserverinstrumentconfiguration ALTER COLUMN AppLoginName COMMENT 'Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set.';
ALTER TABLE main.trading.bronze_etoro_hedge_hedgeserverinstrumentconfiguration ALTER COLUMN SysStartTime COMMENT 'Temporal period start. UTC timestamp when this row version became active.';
ALTER TABLE main.trading.bronze_etoro_hedge_hedgeserverinstrumentconfiguration ALTER COLUMN SysEndTime COMMENT 'Temporal period end. 9999-12-31 for current rows. History in History.HedgeServerInstrumentConfiguration.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:24:14 UTC
-- Statements: 10/10 succeeded
-- ====================
