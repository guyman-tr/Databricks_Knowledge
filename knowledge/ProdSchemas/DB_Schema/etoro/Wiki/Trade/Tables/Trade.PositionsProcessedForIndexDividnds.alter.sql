-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.PositionsProcessedForIndexDividnds
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.PositionsProcessedForIndexDividnds.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_trade_positionsprocessedforindexdividnds
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_trade_positionsprocessedforindexdividnds (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_trade_positionsprocessedforindexdividnds SET TBLPROPERTIES (
    'comment' = 'Tracks which positions have been processed for each dividend event. Each row equals one position paid for one dividend; PaymentAmount records the actual credit/debit. Active table despite the "Dividnds" typo. Source: etoro.Trade.PositionsProcessedForIndexDividnds on the etoro production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.PositionsProcessedForIndexDividnds.md).'
);

ALTER TABLE main.trading.bronze_etoro_trade_positionsprocessedforindexdividnds SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'PositionsProcessedForIndexDividnds',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_trade_positionsprocessedforindexdividnds ALTER COLUMN PositionID COMMENT 'FK to Trade.PositionTbl (logical). Position that received the dividend. (Tier 1 - upstream wiki, etoro.Trade.PositionsProcessedForIndexDividnds)';
ALTER TABLE main.trading.bronze_etoro_trade_positionsprocessedforindexdividnds ALTER COLUMN DividendID COMMENT 'FK to Trade.IndexDividends. Dividend event. (Tier 1 - upstream wiki, etoro.Trade.PositionsProcessedForIndexDividnds)';
ALTER TABLE main.trading.bronze_etoro_trade_positionsprocessedforindexdividnds ALTER COLUMN ProcessTime COMMENT 'When this position was processed for this dividend. Partition key. (Tier 1 - upstream wiki, etoro.Trade.PositionsProcessedForIndexDividnds)';
ALTER TABLE main.trading.bronze_etoro_trade_positionsprocessedforindexdividnds ALTER COLUMN PaymentAmount COMMENT 'Amount credited (positive) or debited (negative). (Tier 1 - upstream wiki, etoro.Trade.PositionsProcessedForIndexDividnds)';
ALTER TABLE main.trading.bronze_etoro_trade_positionsprocessedforindexdividnds ALTER COLUMN CreditID COMMENT 'Links to credit transaction record. (Tier 1 - upstream wiki, etoro.Trade.PositionsProcessedForIndexDividnds)';
ALTER TABLE main.trading.bronze_etoro_trade_positionsprocessedforindexdividnds ALTER COLUMN BuyTax COMMENT 'Tax rate applied for buy-side positions. (Tier 1 - upstream wiki, etoro.Trade.PositionsProcessedForIndexDividnds)';
ALTER TABLE main.trading.bronze_etoro_trade_positionsprocessedforindexdividnds ALTER COLUMN SellTax COMMENT 'Tax rate applied for sell-side positions. (Tier 1 - upstream wiki, etoro.Trade.PositionsProcessedForIndexDividnds)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
