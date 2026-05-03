-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.DepositRollbackTypeReason
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DepositRollbackTypeReason.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_depositrollbacktypereason
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_depositrollbacktypereason (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_depositrollbacktypereason SET TBLPROPERTIES (
    'comment' = 'Lookup table enumerating the 38 specific reasons why a deposit was rolled back - from fraud and fake documents to wrong amounts, failed deposits, and technical mishandling. Source: etoro.Dictionary.DepositRollbackTypeReason on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DepositRollbackTypeReason.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_depositrollbacktypereason SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'DepositRollbackTypeReason',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_depositrollbacktypereason ALTER COLUMN DepositRollbackTypeReasonID COMMENT 'Primary key identifying the rollback reason. 38 values from 0 (Fraud) to 37 (Wrong Deposit ID). Linked to rollback types via BackOffice.DepositRollbackTypeToReason mapping table. (Tier 1 - upstream wiki, etoro.Dictionary.DepositRollbackTypeReason)';
ALTER TABLE main.general.bronze_etoro_dictionary_depositrollbacktypereason ALTER COLUMN Name COMMENT 'Human-readable reason description displayed in BackOffice UI when an operator creates a deposit rollback. Used in SSRS risk and billing reports. (Tier 1 - upstream wiki, etoro.Dictionary.DepositRollbackTypeReason)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
