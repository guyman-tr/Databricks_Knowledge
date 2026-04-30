-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.DepositDRStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DepositDRStatus.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_dictionary_depositdrstatus
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_dictionary_depositdrstatus (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_dictionary_depositdrstatus SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the lifecycle states of deposit dispute resolution (DR) cases — from initial filing through rejection or completion. Source: etoro.Dictionary.DepositDRStatus on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DepositDRStatus.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_dictionary_depositdrstatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'DepositDRStatus',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_dictionary_depositdrstatus ALTER COLUMN DepositDRStatusID COMMENT 'Primary key identifying the dispute resolution status. 0=NA (no dispute), 1=Pending, 2=Rejected, 3=Completed. (Tier 1 - upstream wiki, etoro.Dictionary.DepositDRStatus)';
ALTER TABLE main.bi_db.bronze_etoro_dictionary_depositdrstatus ALTER COLUMN Name COMMENT 'Human-readable dispute status name. Nullable in DDL but all 4 rows have values. (Tier 1 - upstream wiki, etoro.Dictionary.DepositDRStatus)';

