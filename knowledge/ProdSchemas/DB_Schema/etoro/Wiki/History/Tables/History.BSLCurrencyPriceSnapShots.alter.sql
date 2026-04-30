-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.BSLCurrencyPriceSnapShots
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.BSLCurrencyPriceSnapShots.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_bslcurrencypricesnapshots
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_bslcurrencypricesnapshots (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_bslcurrencypricesnapshots SET TBLPROPERTIES (
    'comment' = 'Active BSL price snapshot table storing Bid/Ask rates per instrument at each BSL execution - the primary target used by Trade.CheckBSL for equity audit recalculation. Source: etoro.History.BSLCurrencyPriceSnapShots on the etoro production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.BSLCurrencyPriceSnapShots.md).'
);

ALTER TABLE main.general.bronze_etoro_history_bslcurrencypricesnapshots SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'BSLCurrencyPriceSnapShots',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_bslcurrencypricesnapshots ALTER COLUMN ExecutionID COMMENT 'Identifies the BSL execution run. Groups all price snapshots taken during the same BSL cycle. Corresponds to ExecutionID in Trade.ManageBSL/Trade.CheckBSL. PK component. (Tier 1 - upstream wiki, etoro.History.BSLCurrencyPriceSnapShots)';
ALTER TABLE main.general.bronze_etoro_history_bslcurrencypricesnapshots ALTER COLUMN PriceRateID COMMENT 'The specific price rate record from the instrument pricing system. Provides full traceability to the exact price feed entry used. bigint to match high-volume price rate IDs. PK component. (Tier 1 - upstream wiki, etoro.History.BSLCurrencyPriceSnapShots)';
ALTER TABLE main.general.bronze_etoro_history_bslcurrencypricesnapshots ALTER COLUMN InstrumentID COMMENT 'The financial instrument (stock, crypto, FX pair, index) whose price was snapshotted. Used by Trade.CheckBSL in equity calculations joined with position data. Implicit FK to History.Instrument. (Tier 1 - upstream wiki, etoro.History.BSLCurrencyPriceSnapShots)';
ALTER TABLE main.general.bronze_etoro_history_bslcurrencypricesnapshots ALTER COLUMN Bid COMMENT 'Bid (sell) price for the instrument at BSL execution time. Used for unrealized PnL of long (buy) positions: AmountUnits * (Bid - OpenRate). 8 decimal places for pip-level precision. (Tier 1 - upstream wiki, etoro.History.BSLCurrencyPriceSnapShots)';
ALTER TABLE main.general.bronze_etoro_history_bslcurrencypricesnapshots ALTER COLUMN Ask COMMENT 'Ask (buy) price for the instrument at BSL execution time. Used for unrealized PnL of short (sell) positions. (Tier 1 - upstream wiki, etoro.History.BSLCurrencyPriceSnapShots)';
ALTER TABLE main.general.bronze_etoro_history_bslcurrencypricesnapshots ALTER COLUMN Occurred COMMENT 'Server timestamp when the price snapshot was recorded. Default = getdate() (local server time). PK component and EndMonth partition key. (Tier 1 - upstream wiki, etoro.History.BSLCurrencyPriceSnapShots)';

