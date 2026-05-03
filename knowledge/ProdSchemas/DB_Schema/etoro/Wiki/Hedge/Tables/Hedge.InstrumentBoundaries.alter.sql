-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Hedge.InstrumentBoundaries
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentBoundaries.md
-- Layer: bronze
-- UC Target: main.dealing.bronze_etoro_hedge_instrumentboundaries
-- =============================================================================

-- ---- UC Target: main.dealing.bronze_etoro_hedge_instrumentboundaries (business_group=dealing) ----
ALTER TABLE main.dealing.bronze_etoro_hedge_instrumentboundaries SET TBLPROPERTIES (
    'comment' = 'CBH "Boundaries" strategy configuration: per (HedgeServer, Instrument) thresholds defining when to open a hedge (OpenThresholdUSD), when to reduce it (CloseThresholdPercentage), and how much to hedge (HedgeRiskLimitUSD / HRL); 111K rows covering 32 servers and 10,498 instruments; audited via ASM-generated DML triggers. Source: etoro.Hedge.InstrumentBoundaries on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentBoundaries.md).'
);

ALTER TABLE main.dealing.bronze_etoro_hedge_instrumentboundaries SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Hedge',
    'source_table' = 'InstrumentBoundaries',
    'business_group' = 'dealing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.dealing.bronze_etoro_hedge_instrumentboundaries ALTER COLUMN HedgeServerID COMMENT 'FK to Trade.HedgeServer(HedgeServerID). The hedge server this boundary config applies to. Part of composite PK. HedgeServerID=0 used as global/default placeholder (all zeros). (Tier 1 - upstream wiki, etoro.Hedge.InstrumentBoundaries)';
ALTER TABLE main.dealing.bronze_etoro_hedge_instrumentboundaries ALTER COLUMN InstrumentID COMMENT 'The instrument this boundary config applies to. Implicit reference to Trade.Instrument (no DDL FK). Part of composite PK. 10,498 distinct instruments across all servers. (Tier 1 - upstream wiki, etoro.Hedge.InstrumentBoundaries)';
ALTER TABLE main.dealing.bronze_etoro_hedge_instrumentboundaries ALTER COLUMN OpenThresholdUSD COMMENT 'The net USD exposure threshold that triggers a Boundaries hedging order. When (Tier 1 - upstream wiki, etoro.Hedge.InstrumentBoundaries)';
ALTER TABLE main.dealing.bronze_etoro_hedge_instrumentboundaries ALTER COLUMN CloseThresholdPercentage COMMENT 'Percentage of OpenThresholdUSD below which the existing hedge position is reduced. E.g., 50 means: reduce hedge when exposure < (OpenThresholdUSD * 50% = half the open threshold). Prevents frequent open/close cycling. Typical value: 50. 0 = not configured. (Tier 1 - upstream wiki, etoro.Hedge.InstrumentBoundaries)';
ALTER TABLE main.dealing.bronze_etoro_hedge_instrumentboundaries ALTER COLUMN HedgeRiskLimitUSD COMMENT 'Maximum USD amount to hedge (the Hedge Risk Limit = HRL). Hedge server stops adding hedge when HedgedUSD >= HRL. 0 = no upper cap - fully hedge the entire exposure above OpenThresholdUSD. Range: 0 to $2.5M. (Tier 1 - upstream wiki, etoro.Hedge.InstrumentBoundaries)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
