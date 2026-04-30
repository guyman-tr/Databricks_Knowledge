-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.HedgeServerInstrumentConfiguration
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeServerInstrumentConfiguration.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_history_hedgeserverinstrumentconfiguration
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_history_hedgeserverinstrumentconfiguration (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_history_hedgeserverinstrumentconfiguration SET TBLPROPERTIES (
    'comment' = 'SQL Server system-versioned temporal history table for Hedge.HedgeServerInstrumentConfiguration, recording every change to the per-hedge-server, per-instrument configuration including HBC failover permissions, price source assignment, deal size check flags, and initial margin minimums. Source: etoro.History.HedgeServerInstrumentConfiguration on the etoro production database, ingested via the Generic Pipeline (Append strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeServerInstrumentConfiguration.md).'
);

ALTER TABLE main.trading.bronze_etoro_history_hedgeserverinstrumentconfiguration SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'HedgeServerInstrumentConfiguration',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_history_hedgeserverinstrumentconfiguration ALTER COLUMN HedgeServerID COMMENT 'The hedge server for which this instrument configuration applies. Part of the composite PK. Implicit FK to Trade.HedgeServer(HedgeServerID). The source has nonclustered index idx_HSID on this column for fast lookup of all instruments on a given server. (Tier 1 - upstream wiki, etoro.History.HedgeServerInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_history_hedgeserverinstrumentconfiguration ALTER COLUMN InstrumentID COMMENT 'The financial instrument being configured on this hedge server. Part of the composite PK. Implicit FK to Trade.Instrument(InstrumentID). Source has nonclustered index idx_InstrumentID on this column for fast lookup of all servers for a given instrument. (Tier 1 - upstream wiki, etoro.History.HedgeServerInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_history_hedgeserverinstrumentconfiguration ALTER COLUMN AllowHBCFailover COMMENT 'Whether the HBC system is permitted to fail over this instrument to an alternative hedge server. 1=failover allowed, 0=pinned to this server (no failover). Source has no explicit DEFAULT - must be set on insert. (Tier 1 - upstream wiki, etoro.History.HedgeServerInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_history_hedgeserverinstrumentconfiguration ALTER COLUMN DbLoginName COMMENT 'SQL Server login (suser_name()) at time of change. Computed column in source, materialized in history. (Tier 1 - upstream wiki, etoro.History.HedgeServerInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_history_hedgeserverinstrumentconfiguration ALTER COLUMN AppLoginName COMMENT 'Application context from context_info() at time of change. May contain operator email or service identifier. (Tier 1 - upstream wiki, etoro.History.HedgeServerInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_history_hedgeserverinstrumentconfiguration ALTER COLUMN SysStartTime COMMENT 'UTC timestamp when this server-instrument configuration version became active. Source DEFAULT=getutcdate(). For INSERT-trigger-captured rows, equals SysEndTime. (Tier 1 - upstream wiki, etoro.History.HedgeServerInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_history_hedgeserverinstrumentconfiguration ALTER COLUMN SysEndTime COMMENT 'UTC timestamp when this version was superseded. CLUSTERED index leading column. Source DEFAULT=''9999-12-31''. (Tier 1 - upstream wiki, etoro.History.HedgeServerInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_history_hedgeserverinstrumentconfiguration ALTER COLUMN PriceSource COMMENT 'Price feed source for this instrument on this hedge server. Source DEFAULT=1 (primary price source). The integer maps to an internal price source enum determining which market data feed is used for pricing decisions. (Tier 1 - upstream wiki, etoro.History.HedgeServerInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_history_hedgeserverinstrumentconfiguration ALTER COLUMN AllowClosePositionMaxDealSizeCheck COMMENT 'Whether the HBC max deal size check also applies when closing positions (not just opening). Source DEFAULT=1 (check enabled on close). 0=bypass the check on close, allowing large positions to be unwound even if they exceed the current deal size limit. (Tier 1 - upstream wiki, etoro.History.HedgeServerInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_history_hedgeserverinstrumentconfiguration ALTER COLUMN MinAmountForIM COMMENT 'Minimum position size (in the instrument''s base unit) that requires an Initial Margin (IM) calculation. Source DEFAULT=0 (all positions require IM). Positive values exempt small fractional positions from margin overhead. (Tier 1 - upstream wiki, etoro.History.HedgeServerInstrumentConfiguration)';

