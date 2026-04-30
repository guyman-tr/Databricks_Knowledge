-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.PositionsHedgeServerChangeSummaryLog
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.PositionsHedgeServerChangeSummaryLog.md
-- Layer: bronze
-- UC Target: main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog
-- =============================================================================

-- ---- UC Target: main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog (business_group=dealing) ----
ALTER TABLE main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog SET TBLPROPERTIES (
    'comment' = 'Parent log table that groups hedge-server rerouting operations. Each row represents one reroute batch with a start/end time window and optional comments for audit and monitoring. Source: etoro.Trade.PositionsHedgeServerChangeSummaryLog on the etoro production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.PositionsHedgeServerChangeSummaryLog.md).'
);

ALTER TABLE main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'PositionsHedgeServerChangeSummaryLog',
    'business_group' = 'dealing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog ALTER COLUMN ID COMMENT 'Surrogate primary key. Returned by scope_identity() from PositionsHedgeServerChangeSummaryLogInsert and passed as OperationSummaryID to MovePositionsHedgeServers/MovePositionsHedgeServersByRerouteService. Referenced by Trade.PositionsHedgeServerChangeLog.OperationSummaryID (FK). (Tier 1 - upstream wiki, etoro.Trade.PositionsHedgeServerChangeSummaryLog)';
ALTER TABLE main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog ALTER COLUMN StartTime COMMENT 'UTC timestamp when the reroute operation began. Set at INSERT via getutcdate() in PositionsHedgeServerChangeSummaryLogInsert. Marks the start of the batch. (Tier 1 - upstream wiki, etoro.Trade.PositionsHedgeServerChangeSummaryLog)';
ALTER TABLE main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog ALTER COLUMN EndTime COMMENT 'UTC timestamp when the reroute operation completed. Initially NULL; updated by MovePositionsHedgeServers and MovePositionsHedgeServersByRerouteService on successful COMMIT. Difference from StartTime indicates operation duration. (Tier 1 - upstream wiki, etoro.Trade.PositionsHedgeServerChangeSummaryLog)';
ALTER TABLE main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog ALTER COLUMN Comments COMMENT 'Free-text description of the operation (e.g., operator name, reason). Supplied by caller to PositionsHedgeServerChangeSummaryLogInsert. Used by Monitor.AlertForDealingExecutionConfigurationManager when alerting on large batches (>1000 positions). (Tier 1 - upstream wiki, etoro.Trade.PositionsHedgeServerChangeSummaryLog)';

