-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.InstrumentImages
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.InstrumentImages.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_trade_instrumentimages
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_trade_instrumentimages (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_trade_instrumentimages SET TBLPROPERTIES (
    'comment' = 'Stores logo and avatar image URLs per instrument at multiple resolutions - drives UI display in the trading app, API responses, and Facebook product feeds. Source: etoro.Trade.InstrumentImages on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.InstrumentImages.md).'
);

ALTER TABLE main.trading.bronze_etoro_trade_instrumentimages SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'InstrumentImages',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_trade_instrumentimages ALTER COLUMN ImageID COMMENT 'Surrogate primary key. IDENTITY, NOT FOR REPLICATION. Allocated on INSERT. (Tier 1 - upstream wiki, etoro.Trade.InstrumentImages)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentimages ALTER COLUMN InstrumentID COMMENT 'FK to Trade.Instrument.InstrumentID. The instrument this image row belongs to. (Tier 1 - upstream wiki, etoro.Trade.InstrumentImages)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentimages ALTER COLUMN Width COMMENT 'Image width in pixels. Common values: 35, 50, 70, 80, 90, 150. Used with Height to identify resolution. NULL allowed (e.g., SVG rows from Trade.InsertInstrumentMetadataSecurityOpsAPI). (Tier 1 - upstream wiki, etoro.Trade.InstrumentImages)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentimages ALTER COLUMN Height COMMENT 'Image height in pixels. Typically equals Width for square avatars. NULL for non-raster (SVG). (Tier 1 - upstream wiki, etoro.Trade.InstrumentImages)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentimages ALTER COLUMN Uri COMMENT 'Full URL or path to the image. CDN: etoro-cdn.etorostatic.com/market-avatars/{symbol}/{W}x{H}.png. S3: s3.etoro.com/images/markets/avatars/{symbol}/{W}x{H}.png. Legacy: /medium/{SYMBOL}.png. (Tier 1 - upstream wiki, etoro.Trade.InstrumentImages)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentimages ALTER COLUMN BackgroundColor COMMENT 'Optional background color for image display (e.g., hex or CSS color). NULL in sampled data - may be unused or for future theming. (Tier 1 - upstream wiki, etoro.Trade.InstrumentImages)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentimages ALTER COLUMN TextColor COMMENT 'Optional text/overlay color. NULL in sampled data - may be unused or for future theming. (Tier 1 - upstream wiki, etoro.Trade.InstrumentImages)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
