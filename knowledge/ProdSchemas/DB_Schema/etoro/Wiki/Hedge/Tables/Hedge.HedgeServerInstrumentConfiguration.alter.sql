-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Hedge.HedgeServerInstrumentConfiguration
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HedgeServerInstrumentConfiguration.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_hedge_hedgeserverinstrumentconfiguration
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_hedge_hedgeserverinstrumentconfiguration (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_hedge_hedgeserverinstrumentconfiguration SET TBLPROPERTIES (
    'comment' = 'Per-hedge-server, per-instrument override configuration table defining failover behavior, price source selection, deal size validation, and IM routing thresholds - currently empty (designed but not yet operationally activated). Source: etoro.Hedge.HedgeServerInstrumentConfiguration on the etoro production database, ingested via the Generic Pipeline (Override strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HedgeServerInstrumentConfiguration.md).'
);

ALTER TABLE main.trading.bronze_etoro_hedge_hedgeserverinstrumentconfiguration SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Hedge',
    'source_table' = 'HedgeServerInstrumentConfiguration',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_hedge_hedgeserverinstrumentconfiguration ALTER COLUMN HedgeServerID COMMENT 'The hedge server this configuration applies to. Part of composite PK. Implicit reference to Trade.HedgeServer (no FK constraint). Indexed via idx_HSID for per-server lookups. (Tier 1 - upstream wiki, etoro.Hedge.HedgeServerInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_hedge_hedgeserverinstrumentconfiguration ALTER COLUMN InstrumentID COMMENT 'The instrument this configuration applies to. Part of composite PK. Implicit reference to Trade.Instrument (no FK constraint). Indexed via idx_InstrumentID for per-instrument lookups. (Tier 1 - upstream wiki, etoro.Hedge.HedgeServerInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_hedge_hedgeserverinstrumentconfiguration ALTER COLUMN AllowHBCFailover COMMENT 'Whether HBC execution failure for this server/instrument can fall back to standard execution. 1=failover allowed, 0=strict (no fallback). Instrument-level override of Hedge.BusinessFlowBehavior.AllowHBCFailover. No DEFAULT - must be explicitly provided on insert. (Tier 1 - upstream wiki, etoro.Hedge.HedgeServerInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_hedge_hedgeserverinstrumentconfiguration ALTER COLUMN PriceSource COMMENT 'Price feed selection for this server/instrument pair. DEFAULT 1 = primary price source. Instrument-level override of Trade.HedgeServer.PriceSource. Exact enum values not defined in schema. (Tier 1 - upstream wiki, etoro.Hedge.HedgeServerInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_hedge_hedgeserverinstrumentconfiguration ALTER COLUMN AllowClosePositionMaxDealSizeCheck COMMENT 'Whether max deal size validation applies to close-position orders for this server/instrument. DEFAULT 1 = validate (same rules as open orders). 0 = bypass size check for close orders only. (Tier 1 - upstream wiki, etoro.Hedge.HedgeServerInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_hedge_hedgeserverinstrumentconfiguration ALTER COLUMN MinAmountForIM COMMENT 'Minimum order size (base currency) for routing via Institutional Market (IM) path. DEFAULT 0 = no minimum. Non-zero = orders below this threshold bypass IM routing for this server/instrument. (Tier 1 - upstream wiki, etoro.Hedge.HedgeServerInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_hedge_hedgeserverinstrumentconfiguration ALTER COLUMN DbLoginName COMMENT 'Computed audit column. SQL Server login executing the DML. (Tier 1 - upstream wiki, etoro.Hedge.HedgeServerInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_hedge_hedgeserverinstrumentconfiguration ALTER COLUMN AppLoginName COMMENT 'Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set. (Tier 1 - upstream wiki, etoro.Hedge.HedgeServerInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_hedge_hedgeserverinstrumentconfiguration ALTER COLUMN SysStartTime COMMENT 'Temporal period start. UTC timestamp when this row version became active. (Tier 1 - upstream wiki, etoro.Hedge.HedgeServerInstrumentConfiguration)';
ALTER TABLE main.trading.bronze_etoro_hedge_hedgeserverinstrumentconfiguration ALTER COLUMN SysEndTime COMMENT 'Temporal period end. 9999-12-31 for current rows. History in History.HedgeServerInstrumentConfiguration. (Tier 1 - upstream wiki, etoro.Hedge.HedgeServerInstrumentConfiguration)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
