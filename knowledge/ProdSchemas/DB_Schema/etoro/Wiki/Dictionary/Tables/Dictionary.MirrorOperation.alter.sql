-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.MirrorOperation
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.MirrorOperation.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_mirroroperation
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_mirroroperation (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_mirroroperation SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 13 CopyTrading operations — from Register/UnRegister Mirror through balance edits, state changes, pause/resume, position detach, and alignment tracking. Source: etoro.Dictionary.MirrorOperation on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.MirrorOperation.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_mirroroperation SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'MirrorOperation',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_mirroroperation ALTER COLUMN ID COMMENT 'Primary key identifying the copy operation. Range 1-13. Referenced by History.Mirror.MirrorOperationID (FK). Heavily filtered in Trade.TAPI procedures (ID=2 for unregistration). Used in WHERE, CASE, and IIF expressions across 35+ procedures. (Tier 1 - upstream wiki, etoro.Dictionary.MirrorOperation)';
ALTER TABLE main.general.bronze_etoro_dictionary_mirroroperation ALTER COLUMN MirrorOperation COMMENT 'Human-readable operation name. Not nullable. Joined in Monitor procedures (UnclosedMirrorPositionsBySSE, ClosedPositionsBySSE) and Trade alerts for display. Used in account statement reports as transaction type labels. (Tier 1 - upstream wiki, etoro.Dictionary.MirrorOperation)';

