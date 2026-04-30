-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Hedge.BoundariesConfiguration
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.BoundariesConfiguration.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_hedge_boundariesconfiguration
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_hedge_boundariesconfiguration (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_hedge_boundariesconfiguration SET TBLPROPERTIES (
    'comment' = 'Per-strategy, per-instrument boundary configuration table defining USD-denominated exposure thresholds and desired target exposure bands for a band-based hedge rebalancing strategy. Source: etoro.Hedge.BoundariesConfiguration on the etoro production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.BoundariesConfiguration.md).'
);

ALTER TABLE main.trading.bronze_etoro_hedge_boundariesconfiguration SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Hedge',
    'source_table' = 'BoundariesConfiguration',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_hedge_boundariesconfiguration ALTER COLUMN StrategyID COMMENT 'Identifies the hedge strategy this boundary rule applies to. Part of the composite PK. No FK constraint - strategy IDs are managed by the application. One strategy can have different boundary rules per instrument. (Tier 1 - upstream wiki, etoro.Hedge.BoundariesConfiguration)';
ALTER TABLE main.trading.bronze_etoro_hedge_boundariesconfiguration ALTER COLUMN InstrumentID COMMENT 'Identifies the instrument this boundary rule applies to. Part of the composite PK. No FK constraint in DDL (implicit reference to Trade.Instrument). (Tier 1 - upstream wiki, etoro.Hedge.BoundariesConfiguration)';
ALTER TABLE main.trading.bronze_etoro_hedge_boundariesconfiguration ALTER COLUMN LowerThresholdUSD COMMENT 'Lower bound of the dead-band (in USD). When current exposure falls below this value, rebalancing is triggered toward LowerBoundaryDesiredExposureUSD. DEFAULT 0. (Tier 1 - upstream wiki, etoro.Hedge.BoundariesConfiguration)';
ALTER TABLE main.trading.bronze_etoro_hedge_boundariesconfiguration ALTER COLUMN UpperThresholdUSD COMMENT 'Upper bound of the dead-band (in USD). When current exposure exceeds this value, rebalancing is triggered toward UpperBoundaryDesiredExposureUSD. DEFAULT 0. (Tier 1 - upstream wiki, etoro.Hedge.BoundariesConfiguration)';
ALTER TABLE main.trading.bronze_etoro_hedge_boundariesconfiguration ALTER COLUMN LowerBoundaryDesiredExposureUSD COMMENT 'Target exposure (in USD) to rebalance toward when exposure is too low (below LowerThresholdUSD). Defines the desired floor for this strategy/instrument pair. DEFAULT 0. (Tier 1 - upstream wiki, etoro.Hedge.BoundariesConfiguration)';
ALTER TABLE main.trading.bronze_etoro_hedge_boundariesconfiguration ALTER COLUMN UpperBoundaryDesiredExposureUSD COMMENT 'Target exposure (in USD) to rebalance toward when exposure is too high (above UpperThresholdUSD). Defines the desired ceiling for this strategy/instrument pair. DEFAULT 0. (Tier 1 - upstream wiki, etoro.Hedge.BoundariesConfiguration)';
ALTER TABLE main.trading.bronze_etoro_hedge_boundariesconfiguration ALTER COLUMN DbLoginName COMMENT 'Computed audit column. SQL Server login executing the DML. (Tier 1 - upstream wiki, etoro.Hedge.BoundariesConfiguration)';
ALTER TABLE main.trading.bronze_etoro_hedge_boundariesconfiguration ALTER COLUMN AppLoginName COMMENT 'Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set. (Tier 1 - upstream wiki, etoro.Hedge.BoundariesConfiguration)';
ALTER TABLE main.trading.bronze_etoro_hedge_boundariesconfiguration ALTER COLUMN SysStartTime COMMENT 'Temporal period start. UTC timestamp when this row version became active. (Tier 1 - upstream wiki, etoro.Hedge.BoundariesConfiguration)';
ALTER TABLE main.trading.bronze_etoro_hedge_boundariesconfiguration ALTER COLUMN SysEndTime COMMENT 'Temporal period end. 9999-12-31 for current rows. History in History.BoundariesConfiguration. (Tier 1 - upstream wiki, etoro.Hedge.BoundariesConfiguration)';

