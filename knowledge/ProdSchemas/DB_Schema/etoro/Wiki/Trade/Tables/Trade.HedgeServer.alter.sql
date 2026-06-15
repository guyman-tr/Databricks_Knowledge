-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_trade_hedgeserver  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.HedgeServer.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN HedgeServerID COMMENT 'Primary key. Unique identifier for the hedge server instance. 0 = placeholder.';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN IPAddress COMMENT 'IP address where the hedge server process listens. Localhost for local deployments.';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN Port COMMENT 'TCP port for hedge server communication. 0 for placeholder; actual servers use 9999, 1003, 1004, etc.';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN IsActive COMMENT '1 = server is active and receives hedge routing; 0 = inactive/disabled. Index Idx_Trade_HedgeServer_IsActive supports active-server lookups.';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN HedgingMode COMMENT 'Hedging behavior mode. Observed values 0 in sample data. No explicit lookup table found.';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN IsDummy COMMENT '0 = real hedge server (positions are re-hedged when moved here); 1 = dummy server (positions are NOT re-hedged). Trade.ChangePositionsHedgeServer uses this to decide whether to reset EntryHedgeQuery.';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN ConsiderOpenRequestsSec COMMENT 'Seconds to look back when summing open hedge requests for exposure. Trade.GetExposuresForAllHedgeServers: WHERE Occurred >= dateadd(ss, 0-ConsiderOpenRequestsSec, getdate()).';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN HedgeStrategyModeID COMMENT 'FK to Dictionary.HedgeStrategyMode. 0=STRATEGY_FULLY, 1=STRATEGY_BOUNDARIES, 2=STRATEGY_HBC, 3=STRATEGY_PERIODIC_BOUNDARIES.';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN ExecutionFactor COMMENT 'Multiplier for execution sizing. Must be 0.75-1 per Monitor.AlertForDealingExecutionConfigurationManager.';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN AllowMajor COMMENT 'Whether major/forex instruments are allowed. 0 = no, 1 = yes.';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN CircuitBreakerLimit COMMENT 'Max exposure threshold. Monitor alerts if < 10,000,000 or > 100,000,000.';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN CircuitBreakerWarningLimit COMMENT 'Warning threshold before circuit breaker trips. Read by Hedge.GetServerCircuitBreakerThresholds.';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN InstrumentIDToHedgeOn COMMENT 'Optional Trade.Instrument.InstrumentID to use for hedge sizing/quoting. NULL = use position instrument.';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN DbLoginName COMMENT 'Computed: current SQL login. Audit.';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN AppLoginName COMMENT 'Computed: application context from context_info(). Audit.';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN SysStartTime COMMENT 'System-versioning row start. Temporal table.';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN SysEndTime COMMENT 'System-versioning row end. Temporal table.';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN HostName COMMENT 'Computed: server hostname. Audit.';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN OperationalMode COMMENT 'Execution mode. Observed 1 and 2. Hedge.SSRS_Latency_Report groups by OperationalMode.';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN PriceSource COMMENT 'Price source for quoting. Maps to Dictionary.PriceSourceName (1=Xignite, etc). Hedge.GetHedgeServerSettings returns this.';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN PeriodicHedgeIntervalMinutes COMMENT 'Minutes between periodic hedge runs when using STRATEGY_PERIODIC_BOUNDARIES.';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN PeriodicHedgeHours COMMENT 'Schedule for periodic hedging (e.g. market hours).';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN UnitRoundingMethod COMMENT 'Rounding method for lot/unit quantities. Hedge.GetHedgeServerSettings returns this.';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN StrategyName COMMENT 'Human-readable strategy name.';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN StrategyGroup COMMENT 'References Dictionary.StrategyGroups.StrategyGroupID. Hedge.GetStrategyGroupsAndHedgeServerID JOINs by StrategyGroup.';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN SystemName COMMENT 'Execution system name. Default EMS (Execution Management System).';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN RequestedAlertIntervalSeconds COMMENT 'Interval in seconds for requested/alert reporting.';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN ManagedExposurePeriodSec COMMENT 'Period in seconds for managed exposure calculations.';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN AllowOMSPricingPartialFill COMMENT 'Whether OMS allows pricing on partial fills. 0 = no, 1 = yes.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:21:52 UTC
-- Statements: 29/29 succeeded
-- ====================
