-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.PositionsHedgeServerChangeLog
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.PositionsHedgeServerChangeLog.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_trade_positionshedgeserverchangelog
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_trade_positionshedgeserverchangelog (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_trade_positionshedgeserverchangelog SET TBLPROPERTIES (
    'comment' = 'Detail log table recording every individual position''s hedge server change, capturing the from/to server IDs and the routing rule that triggered the move, linked to parent operation summaries. Source: etoro.Trade.PositionsHedgeServerChangeLog on the etoro production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.PositionsHedgeServerChangeLog.md).'
);

ALTER TABLE main.trading.bronze_etoro_trade_positionshedgeserverchangelog SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'PositionsHedgeServerChangeLog',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_trade_positionshedgeserverchangelog ALTER COLUMN OperationSummaryID COMMENT 'FK to Trade.PositionsHedgeServerChangeSummaryLog(ID). Groups this position change into a logical batch operation with start/end timestamps and comments. Part of composite PK. Multiple positions share the same OperationSummaryID when moved in the same batch. (Tier 1 - upstream wiki, etoro.Trade.PositionsHedgeServerChangeLog)';
ALTER TABLE main.trading.bronze_etoro_trade_positionshedgeserverchangelog ALTER COLUMN PositionID COMMENT 'The position that was moved between hedge servers. References Trade.PositionTbl.PositionID (implicit - no declared FK). Part of composite PK with OperationSummaryID. A position can appear multiple times if moved across different operations. (Tier 1 - upstream wiki, etoro.Trade.PositionsHedgeServerChangeLog)';
ALTER TABLE main.trading.bronze_etoro_trade_positionshedgeserverchangelog ALTER COLUMN ADM_DATE COMMENT 'Timestamp of when this position change was recorded. Default is UTC time at insert. Indexed (IDX_TPHSCL_ADM_DATE_BIGINT) for time-range queries. Used by monitoring and reporting to analyze rerouting activity over time. (Tier 1 - upstream wiki, etoro.Trade.PositionsHedgeServerChangeLog)';
ALTER TABLE main.trading.bronze_etoro_trade_positionshedgeserverchangelog ALTER COLUMN FromHedgeServerID COMMENT 'The hedge server ID the position was on before this operation. Captured from Trade.PositionTbl.HedgeServerID at the time of the move. References Trade.HedgeServer (implicit). (Tier 1 - upstream wiki, etoro.Trade.PositionsHedgeServerChangeLog)';
ALTER TABLE main.trading.bronze_etoro_trade_positionshedgeserverchangelog ALTER COLUMN ToHedgeServerID COMMENT 'The hedge server ID the position was moved to. After this operation, Trade.PositionTbl.HedgeServerID equals this value for the affected position. (Tier 1 - upstream wiki, etoro.Trade.PositionsHedgeServerChangeLog)';
ALTER TABLE main.trading.bronze_etoro_trade_positionshedgeserverchangelog ALTER COLUMN FromRootHedgeServerID COMMENT 'The root-level hedge server ID before the move. Nullable because older records or certain scenarios may not track root server changes. From Trade.PositionTbl.RootHedgeServerID. (Tier 1 - upstream wiki, etoro.Trade.PositionsHedgeServerChangeLog)';
ALTER TABLE main.trading.bronze_etoro_trade_positionshedgeserverchangelog ALTER COLUMN ToRootHedgeServerID COMMENT 'The root-level hedge server ID after the move. Nullable for same reasons as FromRootHedgeServerID. Tracks hierarchical server assignment changes. (Tier 1 - upstream wiki, etoro.Trade.PositionsHedgeServerChangeLog)';
ALTER TABLE main.trading.bronze_etoro_trade_positionshedgeserverchangelog ALTER COLUMN RuleID COMMENT 'Identifies the automated routing rule that triggered this position move. Positive values correspond to reroute service rules. -1 = manual/ad-hoc move (not triggered by a rule). NULL if not applicable. Rule 88 is the most common in recent data. (Tier 1 - upstream wiki, etoro.Trade.PositionsHedgeServerChangeLog)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
