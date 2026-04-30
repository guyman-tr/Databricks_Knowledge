-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.CloseMirrorActionType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CloseMirrorActionType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_closemirroractiontype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_closemirroractiontype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_closemirroractiontype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining who or what triggered the closing or stopping of a CopyTrading (mirror) relationship. Critical for CopyTrading analytics and compliance auditing. Source: etoro.Dictionary.CloseMirrorActionType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CloseMirrorActionType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_closemirroractiontype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'CloseMirrorActionType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_closemirroractiontype ALTER COLUMN ID COMMENT 'Primary key. Values 0–6. Referenced by Trade.Mirror and History.Mirror via CloseMirrorActionTypeID. Set by Trade.ChangeMirrorState, Trade.PostDetachPositionFromMirror, and related procs. (Tier 1 - upstream wiki, etoro.Dictionary.CloseMirrorActionType)';
ALTER TABLE main.general.bronze_etoro_dictionary_closemirroractiontype ALTER COLUMN CloseMirrorActionName COMMENT 'Human-readable label. Values: Customer, Stop Loss, BSL, Manual Liquidation, BackOffice, Customer Detach, BackOffice Detach. Used in reporting and UI. (Tier 1 - upstream wiki, etoro.Dictionary.CloseMirrorActionType)';

