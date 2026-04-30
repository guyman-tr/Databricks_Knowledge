-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.HedgeOrderState
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.HedgeOrderState.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_hedgeorderstate
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_hedgeorderstate (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_hedgeorderstate SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the eight lifecycle states of a hedge order — from initial creation through execution, partial fill, rejection, failure, or cancellation at the liquidity provider. Source: etoro.Dictionary.HedgeOrderState on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.HedgeOrderState.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_hedgeorderstate SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'HedgeOrderState',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_hedgeorderstate ALTER COLUMN ID COMMENT 'Primary key identifying the hedge order state. 0=None (unset), 1=Sent (transmitted to LP), 2=New (LP acknowledged), 3=Partial (partially filled), 4=Fill (fully executed), 5=Reject (LP rejected), 6=Fail (technical failure), 7=Cancelled (cancelled before execution). Stored in Hedge.ExecutionLog. (Tier 1 - upstream wiki, etoro.Dictionary.HedgeOrderState)';
ALTER TABLE main.general.bronze_etoro_dictionary_hedgeorderstate ALTER COLUMN Name COMMENT 'Human-readable label for the order state. Displayed in hedge monitoring dashboards and execution log reports. (Tier 1 - upstream wiki, etoro.Dictionary.HedgeOrderState)';

