-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.PositionSplit
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.PositionSplit.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_history_positionsplit
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_history_positionsplit (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_history_positionsplit SET TBLPROPERTIES (
    'comment' = 'Records which closed positions have been processed for each stock split event, serving as the idempotency marker that prevents a position from being adjusted twice for the same split. Source: etoro.History.PositionSplit on the etoro production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.PositionSplit.md).'
);

ALTER TABLE main.trading.bronze_etoro_history_positionsplit SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'PositionSplit',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_history_positionsplit ALTER COLUMN PositionID COMMENT 'ID of the closed trading position in History.Position that was adjusted. Part of the composite clustered PK (PositionID, SplitID). Also included in the SplitID-only NCI for SplitID-first lookups. (Tier 1 - upstream wiki, etoro.History.PositionSplit)';
ALTER TABLE main.trading.bronze_etoro_history_positionsplit ALTER COLUMN SplitID COMMENT 'ID of the stock split event. References History.SplitRatio.ID (which contains the PriceRatio, AmountRatio, InstrumentID, and MinDate for the split). Together with PositionID forms the composite PK ensuring one adjustment per (position, split). Indexed independently (ix_HistoryPositionSplit on SplitID INCLUDE PositionID) for finding all positions in a split. (Tier 1 - upstream wiki, etoro.History.PositionSplit)';
ALTER TABLE main.trading.bronze_etoro_history_positionsplit ALTER COLUMN SplitDate COMMENT 'UTC timestamp when the adjustment was applied to this position. Set via GETUTCDATE() in the OUTPUT clause of History.SplitClosePositions. Represents the actual processing time, not the corporate split announcement or effective date. (Tier 1 - upstream wiki, etoro.History.PositionSplit)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
