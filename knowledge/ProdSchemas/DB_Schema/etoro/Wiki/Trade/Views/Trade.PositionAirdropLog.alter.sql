-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.PositionAirdropLog
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Views/Trade.PositionAirdropLog.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_trade_positionairdroplog
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_trade_positionairdroplog (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_trade_positionairdroplog SET TBLPROPERTIES (
    'comment' = 'Backward-compatible view that unifies old airdrop log data with new admin position log data for BI reporting on historical airdrop and compensation events. Source: etoro.Trade.PositionAirdropLog on the etoro production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Views/Trade.PositionAirdropLog.md).'
);

ALTER TABLE main.trading.bronze_etoro_trade_positionairdroplog SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'PositionAirdropLog',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_trade_positionairdroplog ALTER COLUMN AirdropID COMMENT 'Unique identifier. From AirdropID in old table or AdminPositionID in AdminPositionLog. (Tier 1 - upstream wiki, etoro.Trade.PositionAirdropLog)';
ALTER TABLE main.trading.bronze_etoro_trade_positionairdroplog ALTER COLUMN CID COMMENT 'Customer ID. User who received the airdrop or compensation. (Tier 1 - upstream wiki, etoro.Trade.PositionAirdropLog)';
ALTER TABLE main.trading.bronze_etoro_trade_positionairdroplog ALTER COLUMN InstrumentID COMMENT 'FK to Trade.Instrument. Instrument of the airdropped/compensated position. (Tier 1 - upstream wiki, etoro.Trade.PositionAirdropLog)';
ALTER TABLE main.trading.bronze_etoro_trade_positionairdroplog ALTER COLUMN Amount COMMENT 'Monetary amount of the airdrop or compensation. (Tier 1 - upstream wiki, etoro.Trade.PositionAirdropLog)';
ALTER TABLE main.trading.bronze_etoro_trade_positionairdroplog ALTER COLUMN HedgeServerID COMMENT 'Hedge server where the position was created or intended. (Tier 1 - upstream wiki, etoro.Trade.PositionAirdropLog)';
ALTER TABLE main.trading.bronze_etoro_trade_positionairdroplog ALTER COLUMN RequestOccurred COMMENT 'When the airdrop/compensation was requested. (Tier 1 - upstream wiki, etoro.Trade.PositionAirdropLog)';
ALTER TABLE main.trading.bronze_etoro_trade_positionairdroplog ALTER COLUMN UserName COMMENT 'Username or identifier of the operator who initiated the request. (Tier 1 - upstream wiki, etoro.Trade.PositionAirdropLog)';
ALTER TABLE main.trading.bronze_etoro_trade_positionairdroplog ALTER COLUMN ExecutionOccurred COMMENT 'When the position was actually created (or NULL if failed/pending). (Tier 1 - upstream wiki, etoro.Trade.PositionAirdropLog)';
ALTER TABLE main.trading.bronze_etoro_trade_positionairdroplog ALTER COLUMN PositionID COMMENT 'Created position ID. NULL if execution failed or pending. (Tier 1 - upstream wiki, etoro.Trade.PositionAirdropLog)';
ALTER TABLE main.trading.bronze_etoro_trade_positionairdroplog ALTER COLUMN Result COMMENT '1=success, 0=failure, NULL=pending (State 1 or 2). Mapped from AdminPositionLog.State for new records. (Tier 1 - upstream wiki, etoro.Trade.PositionAirdropLog)';
ALTER TABLE main.trading.bronze_etoro_trade_positionairdroplog ALTER COLUMN FailReason COMMENT 'Error message or reason when Result=0. (Tier 1 - upstream wiki, etoro.Trade.PositionAirdropLog)';
ALTER TABLE main.trading.bronze_etoro_trade_positionairdroplog ALTER COLUMN AmountInUnits COMMENT 'Position size in units/shares. (Tier 1 - upstream wiki, etoro.Trade.PositionAirdropLog)';
ALTER TABLE main.trading.bronze_etoro_trade_positionairdroplog ALTER COLUMN Cusip COMMENT 'CUSIP identifier for the instrument when applicable. (Tier 1 - upstream wiki, etoro.Trade.PositionAirdropLog)';
ALTER TABLE main.trading.bronze_etoro_trade_positionairdroplog ALTER COLUMN ApexID COMMENT 'Apex account or reference ID. (Tier 1 - upstream wiki, etoro.Trade.PositionAirdropLog)';
ALTER TABLE main.trading.bronze_etoro_trade_positionairdroplog ALTER COLUMN Rate COMMENT 'Execution or reference rate used. (Tier 1 - upstream wiki, etoro.Trade.PositionAirdropLog)';
ALTER TABLE main.trading.bronze_etoro_trade_positionairdroplog ALTER COLUMN TerminalID COMMENT 'Terminal identifier. Empty string for AdminPositionLog records, populated for old records. (Tier 1 - upstream wiki, etoro.Trade.PositionAirdropLog)';
ALTER TABLE main.trading.bronze_etoro_trade_positionairdroplog ALTER COLUMN CompensationReasonID COMMENT 'FK to compensation reason lookup. NULL for old records. (Tier 1 - upstream wiki, etoro.Trade.PositionAirdropLog)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
