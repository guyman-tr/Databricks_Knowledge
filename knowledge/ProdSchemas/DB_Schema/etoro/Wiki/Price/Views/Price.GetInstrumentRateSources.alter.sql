-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Price.GetInstrumentRateSources
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Views/Price.GetInstrumentRateSources.md
-- Layer: bronze
-- UC Target: main.dealing.bronze_etoro_price_getinstrumentratesources
-- =============================================================================

-- ---- UC Target: main.dealing.bronze_etoro_price_getinstrumentratesources (business_group=dealing) ----
ALTER TABLE main.dealing.bronze_etoro_price_getinstrumentratesources SET TBLPROPERTIES (
    'comment' = 'Enriched instrument rate source view that adds human-readable source names, benchmark designation, and quality scores to the raw InstrumentRateSources priority table - the primary read API for pricing configuration dashboards and tooling. Source: etoro.Price.GetInstrumentRateSources on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Views/Price.GetInstrumentRateSources.md).'
);

ALTER TABLE main.dealing.bronze_etoro_price_getinstrumentratesources SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Price',
    'source_table' = 'GetInstrumentRateSources',
    'business_group' = 'dealing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.dealing.bronze_etoro_price_getinstrumentratesources ALTER COLUMN PriceServerID COMMENT 'Price server instance identifier from Trade.Instrument. Identifies which price server handles this instrument. Different instruments may route to different servers (PriceServerID=1 vs 3 seen in data). (Tier 1 - upstream wiki, etoro.Price.GetInstrumentRateSources)';
ALTER TABLE main.dealing.bronze_etoro_price_getinstrumentratesources ALTER COLUMN InstrumentID COMMENT 'eToro instrument identifier from Price.InstrumentRateSources. Must exist in both Trade.Instrument and Trade.GetInstrument. (Tier 1 - upstream wiki, etoro.Price.GetInstrumentRateSources)';
ALTER TABLE main.dealing.bronze_etoro_price_getinstrumentratesources ALTER COLUMN AccountRateSourceID COMMENT 'Rate source identifier from Price.InstrumentRateSources. FK to Price.AccountRateSource. Integer key resolved to Name in this view. (Tier 1 - upstream wiki, etoro.Price.GetInstrumentRateSources)';
ALTER TABLE main.dealing.bronze_etoro_price_getinstrumentratesources ALTER COLUMN Name COMMENT 'Human-readable name of the rate source from Price.AccountRateSource. Examples: "ZBFX Price1", "FD Demo", "FX NDF Provider". NULL only if AccountRateSourceID has no matching row in AccountRateSource (data integrity issue). (Tier 1 - upstream wiki, etoro.Price.GetInstrumentRateSources)';
ALTER TABLE main.dealing.bronze_etoro_price_getinstrumentratesources ALTER COLUMN Priority COMMENT 'Feed priority tier from Price.InstrumentRateSources: 10=primary, 20=secondary, 30=tertiary, 40=quaternary. Lower value = higher precedence. An instrument may skip tiers (e.g., P10 and P30 but no P20). (Tier 1 - upstream wiki, etoro.Price.GetInstrumentRateSources)';
ALTER TABLE main.dealing.bronze_etoro_price_getinstrumentratesources ALTER COLUMN IsBenchmark COMMENT 'Whether this source is the designated benchmark for the instrument''s type: 1=benchmark, 0=not benchmark. Computed: IIF(BenchmarkAccountRateSourceID IS NULL, 0, 1). Currently always 0 (BenchmarkFeedConfiguration is empty). (Tier 1 - upstream wiki, etoro.Price.GetInstrumentRateSources)';
ALTER TABLE main.dealing.bronze_etoro_price_getinstrumentratesources ALTER COLUMN Quality COMMENT 'Benchmark quality score from Price.BenchmarkFeedConfiguration. -1 when no benchmark is configured (ISNULL default). A positive value indicates the quality weight of this benchmark source for the instrument''s type. Currently always -1. (Tier 1 - upstream wiki, etoro.Price.GetInstrumentRateSources)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
