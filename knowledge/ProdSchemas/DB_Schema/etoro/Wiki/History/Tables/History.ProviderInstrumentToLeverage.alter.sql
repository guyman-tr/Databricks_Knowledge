-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.ProviderInstrumentToLeverage
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ProviderInstrumentToLeverage.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_history_providerinstrumenttoleverage
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_history_providerinstrumenttoleverage (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_etoro_history_providerinstrumenttoleverage SET TBLPROPERTIES (
    'comment' = 'Versioned historical log of leverage option availability per provider and instrument, using application-managed ValidFrom/ValidTo intervals to track which leverage tiers were available and at what margin percentages over time. Source: etoro.History.ProviderInstrumentToLeverage on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ProviderInstrumentToLeverage.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_history_providerinstrumenttoleverage SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'ProviderInstrumentToLeverage',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_history_providerinstrumenttoleverage ALTER COLUMN VersionID COMMENT 'Auto-incrementing row version identifier. Clustered PK. NOT FOR REPLICATION prevents identity gaps on replication targets. Provides a stable row key for joining. (Tier 1 - upstream wiki, etoro.History.ProviderInstrumentToLeverage)';
ALTER TABLE main.bi_db.bronze_etoro_history_providerinstrumenttoleverage ALTER COLUMN ProviderID COMMENT 'The price/execution provider for which this leverage option applies. Implicit FK to provider lookup (same as Trade.ProviderToInstrument.ProviderID). (Tier 1 - upstream wiki, etoro.History.ProviderInstrumentToLeverage)';
ALTER TABLE main.bi_db.bronze_etoro_history_providerinstrumenttoleverage ALTER COLUMN InstrumentID COMMENT 'The financial instrument for which this leverage tier is available. Implicit FK to instrument lookup. HPIL_INSTRUMENT index supports per-instrument queries. (Tier 1 - upstream wiki, etoro.History.ProviderInstrumentToLeverage)';
ALTER TABLE main.bi_db.bronze_etoro_history_providerinstrumenttoleverage ALTER COLUMN LeverageID COMMENT 'Identifies the leverage tier (e.g., 1:5, 1:10, 1:100). Implicit FK to leverage lookup (Dictionary.Leverage or Trade.Leverage). HPIL_LEVERAGE index supports per-leverage-tier queries. (Tier 1 - upstream wiki, etoro.History.ProviderInstrumentToLeverage)';
ALTER TABLE main.bi_db.bronze_etoro_history_providerinstrumenttoleverage ALTER COLUMN IsDefault COMMENT '1 = this is the default leverage tier presented to customers for this instrument. Only one tier per active (ProviderID, InstrumentID) pair should be IsDefault=1 at any time. (Tier 1 - upstream wiki, etoro.History.ProviderInstrumentToLeverage)';
ALTER TABLE main.bi_db.bronze_etoro_history_providerinstrumenttoleverage ALTER COLUMN Percentage COMMENT 'Margin percentage associated with this leverage tier. Observed value: 0. May represent a margin override percentage (0 = use system default) or may be populated differently in older rows. (Tier 1 - upstream wiki, etoro.History.ProviderInstrumentToLeverage)';
ALTER TABLE main.bi_db.bronze_etoro_history_providerinstrumenttoleverage ALTER COLUMN ValidFrom COMMENT 'Application-set timestamp when this leverage tier became available for this provider-instrument pair. Not UTC-guaranteed - local server datetime. Written by the application when adding a leverage tier. (Tier 1 - upstream wiki, etoro.History.ProviderInstrumentToLeverage)';
ALTER TABLE main.bi_db.bronze_etoro_history_providerinstrumenttoleverage ALTER COLUMN ValidTo COMMENT 'Application-set timestamp when this leverage tier was deactivated. Sentinel ''3000-01-01 00:00:00.000'' = currently active. Set to current timestamp when a tier is removed. HPIL_PROVIDERINSTRUMENTLEVERAGE index supports active-tier queries. (Tier 1 - upstream wiki, etoro.History.ProviderInstrumentToLeverage)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
