-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.HedgeRecoveryState
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.HedgeRecoveryState.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_hedgerecoverystate
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_hedgerecoverystate (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_hedgerecoverystate SET TBLPROPERTIES (
    'comment' = 'Lookup table defining five hedge recovery states - tracking the lifecycle of hedge position entries during the disaster recovery and reconciliation process between eToro''s systems and liquidity providers. Source: etoro.Dictionary.HedgeRecoveryState on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.HedgeRecoveryState.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_hedgerecoverystate SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'HedgeRecoveryState',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_hedgerecoverystate ALTER COLUMN ID COMMENT 'Primary key identifying the recovery state. 0=None (unclassified/matched), 1=Added (new LP position), 2=Updated (details changed), 3=Removed (not at LP), 4=Detected (initial scan state). Stored in Hedge.RecoveryLog. (Tier 1 - upstream wiki, etoro.Dictionary.HedgeRecoveryState)';
ALTER TABLE main.general.bronze_etoro_dictionary_hedgerecoverystate ALTER COLUMN Name COMMENT 'Human-readable label for the recovery state. Displayed in recovery logs, reconciliation reports, and monitoring dashboards. (Tier 1 - upstream wiki, etoro.Dictionary.HedgeRecoveryState)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
