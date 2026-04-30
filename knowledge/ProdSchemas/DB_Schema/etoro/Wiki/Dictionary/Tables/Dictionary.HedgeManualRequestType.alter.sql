-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.HedgeManualRequestType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.HedgeManualRequestType.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_dictionary_hedgemanualrequesttype
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_dictionary_hedgemanualrequesttype (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_dictionary_hedgemanualrequesttype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the eight types of manual hedge requests — custom orders, exposure adjustments, netting moves, and queue management operations that hedge operators can submit outside the automated hedging flow. Source: etoro.Dictionary.HedgeManualRequestType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.HedgeManualRequestType.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_dictionary_hedgemanualrequesttype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'HedgeManualRequestType',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_dictionary_hedgemanualrequesttype ALTER COLUMN RequestTypeID COMMENT 'Primary key identifying the manual request type. 0=Custom Request, 1=Set Hedge Exposure, 2=Settle Requested Exposure, 3=SetTradeExposure, 4=Manual Exposure, 5=Custom Update Queued, 6=Clear Queued, 7=Move Netting. Stored in Hedge.ManualOrderExecutionLog for audit. (Tier 1 - upstream wiki, etoro.Dictionary.HedgeManualRequestType)';
ALTER TABLE main.bi_db.bronze_etoro_dictionary_hedgemanualrequesttype ALTER COLUMN Name COMMENT 'Human-readable label for the request type. Displayed in manual hedge operation logs and audit reports. (Tier 1 - upstream wiki, etoro.Dictionary.HedgeManualRequestType)';

