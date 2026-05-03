-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.RedeemStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RedeemStatus.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_redeemstatus
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_redeemstatus (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_redeemstatus SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 7 lifecycle states of a copy-trading fund redemption (stop-copy with funds return). Source: etoro.Dictionary.RedeemStatus on the etoro production database, ingested via the Generic Pipeline (Override strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RedeemStatus.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_redeemstatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'RedeemStatus',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_redeemstatus ALTER COLUMN RedeemStatusID COMMENT 'Primary key identifying the redeem lifecycle state. See Redeem Status. (Dictionary.RedeemStatus) (Tier 1 - upstream wiki, etoro.Dictionary.RedeemStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_redeemstatus ALTER COLUMN Name COMMENT 'Internal code name used in procedures and API responses. (Tier 1 - upstream wiki, etoro.Dictionary.RedeemStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_redeemstatus ALTER COLUMN DisplayName COMMENT 'User-facing display label. More readable than the internal Name. Shown in copy-trading UI and notifications. (Tier 1 - upstream wiki, etoro.Dictionary.RedeemStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_redeemstatus ALTER COLUMN IsCancelable COMMENT 'Whether the user can still cancel the redeem request at this stage. 1=cancellable (Pending), 0=committed (InProcess, Completed, Failed). The cancel boundary is the point when positions start closing. (Tier 1 - upstream wiki, etoro.Dictionary.RedeemStatus)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
