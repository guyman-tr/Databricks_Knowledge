-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.HedgeServer
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.HedgeServer.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_trade_hedgeserver
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_trade_hedgeserver (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver SET TBLPROPERTIES (
    'comment' = 'Configuration table for hedge execution servers that manage eToro''s net market exposure by routing client CFD positions to liquidity providers for hedging. Source: etoro.Trade.HedgeServer on the etoro production database, ingested via the Generic Pipeline (Override strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.HedgeServer.md).'
);

ALTER TABLE main.general.bronze_etoro_trade_hedgeserver SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'HedgeServer',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN HedgeServerID COMMENT 'Primary key. Unique identifier for the hedge server instance. 0 = placeholder. (Tier 1 - upstream wiki, etoro.Trade.HedgeServer)';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN IPAddress COMMENT 'IP address where the hedge server process listens. Localhost for local deployments. (Tier 1 - upstream wiki, etoro.Trade.HedgeServer)';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN Port COMMENT 'TCP port for hedge server communication. 0 for placeholder; actual servers use 9999, 1003, 1004, etc. (Tier 1 - upstream wiki, etoro.Trade.HedgeServer)';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN IsActive COMMENT '1 = server is active and receives hedge routing; 0 = inactive/disabled. Index Idx_Trade_HedgeServer_IsActive supports active-server lookups. (Tier 1 - upstream wiki, etoro.Trade.HedgeServer)';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN HedgingMode COMMENT 'Hedging behavior mode. Observed values 0 in sample data. No explicit lookup table found. (Tier 1 - upstream wiki, etoro.Trade.HedgeServer)';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN IsDummy COMMENT '0 = real hedge server (positions are re-hedged when moved here); 1 = dummy server (positions are NOT re-hedged). Trade.ChangePositionsHedgeServer uses this to decide whether to reset EntryHedgeQuery. (Tier 1 - upstream wiki, etoro.Trade.HedgeServer)';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN ConsiderOpenRequestsSec COMMENT 'Seconds to look back when summing open hedge requests for exposure. Trade.GetExposuresForAllHedgeServers: WHERE Occurred >= dateadd(ss, 0-ConsiderOpenRequestsSec, getdate()). (Tier 1 - upstream wiki, etoro.Trade.HedgeServer)';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN HedgeStrategyModeID COMMENT 'FK to Dictionary.HedgeStrategyMode. 0=STRATEGY_FULLY, 1=STRATEGY_BOUNDARIES, 2=STRATEGY_HBC, 3=STRATEGY_PERIODIC_BOUNDARIES. (Tier 1 - upstream wiki, etoro.Trade.HedgeServer)';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN ExecutionFactor COMMENT 'Multiplier for execution sizing. Must be 0.75-1 per Monitor.AlertForDealingExecutionConfigurationManager. (Tier 1 - upstream wiki, etoro.Trade.HedgeServer)';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN AllowMajor COMMENT 'Whether major/forex instruments are allowed. 0 = no, 1 = yes. (Tier 1 - upstream wiki, etoro.Trade.HedgeServer)';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN CircuitBreakerLimit COMMENT 'Max exposure threshold. Monitor alerts if < 10,000,000 or > 100,000,000. (Tier 1 - upstream wiki, etoro.Trade.HedgeServer)';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN CircuitBreakerWarningLimit COMMENT 'Warning threshold before circuit breaker trips. Read by Hedge.GetServerCircuitBreakerThresholds. (Tier 1 - upstream wiki, etoro.Trade.HedgeServer)';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN InstrumentIDToHedgeOn COMMENT 'Optional Trade.Instrument.InstrumentID to use for hedge sizing/quoting. NULL = use position instrument. (Tier 1 - upstream wiki, etoro.Trade.HedgeServer)';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN DbLoginName COMMENT 'Computed: current SQL login. Audit. (Tier 1 - upstream wiki, etoro.Trade.HedgeServer)';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN AppLoginName COMMENT 'Computed: application context from context_info(). Audit. (Tier 1 - upstream wiki, etoro.Trade.HedgeServer)';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN SysStartTime COMMENT 'System-versioning row start. Temporal table. (Tier 1 - upstream wiki, etoro.Trade.HedgeServer)';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN SysEndTime COMMENT 'System-versioning row end. Temporal table. (Tier 1 - upstream wiki, etoro.Trade.HedgeServer)';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN HostName COMMENT 'Computed: server hostname. Audit. (Tier 1 - upstream wiki, etoro.Trade.HedgeServer)';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN OperationalMode COMMENT 'Execution mode. Observed 1 and 2. Hedge.SSRS_Latency_Report groups by OperationalMode. (Tier 1 - upstream wiki, etoro.Trade.HedgeServer)';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN PriceSource COMMENT 'Price source for quoting. Maps to Dictionary.PriceSourceName (1=Xignite, etc). Hedge.GetHedgeServerSettings returns this. (Tier 1 - upstream wiki, etoro.Trade.HedgeServer)';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN PeriodicHedgeIntervalMinutes COMMENT 'Minutes between periodic hedge runs when using STRATEGY_PERIODIC_BOUNDARIES. (Tier 1 - upstream wiki, etoro.Trade.HedgeServer)';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN PeriodicHedgeHours COMMENT 'Schedule for periodic hedging (e.g. market hours). (Tier 1 - upstream wiki, etoro.Trade.HedgeServer)';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN UnitRoundingMethod COMMENT 'Rounding method for lot/unit quantities. Hedge.GetHedgeServerSettings returns this. (Tier 1 - upstream wiki, etoro.Trade.HedgeServer)';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN StrategyName COMMENT 'Human-readable strategy name. (Tier 1 - upstream wiki, etoro.Trade.HedgeServer)';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN StrategyGroup COMMENT 'References Dictionary.StrategyGroups.StrategyGroupID. Hedge.GetStrategyGroupsAndHedgeServerID JOINs by StrategyGroup. (Tier 1 - upstream wiki, etoro.Trade.HedgeServer)';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN SystemName COMMENT 'Execution system name. Default EMS (Execution Management System). (Tier 1 - upstream wiki, etoro.Trade.HedgeServer)';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN RequestedAlertIntervalSeconds COMMENT 'Interval in seconds for requested/alert reporting. (Tier 1 - upstream wiki, etoro.Trade.HedgeServer)';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN ManagedExposurePeriodSec COMMENT 'Period in seconds for managed exposure calculations. (Tier 1 - upstream wiki, etoro.Trade.HedgeServer)';
ALTER TABLE main.general.bronze_etoro_trade_hedgeserver ALTER COLUMN AllowOMSPricingPartialFill COMMENT 'Whether OMS allows pricing on partial fills. 0 = no, 1 = yes. (Tier 1 - upstream wiki, etoro.Trade.HedgeServer)';

