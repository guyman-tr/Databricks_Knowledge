-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.BonusStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.BonusStatus.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_bonusstatus
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_bonusstatus (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_bonusstatus SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the lifecycle states of deposit bonuses - from New through Approved, Declined, or Reverted. Referenced by bonus-related billing and deposit tables. Source: etoro.Dictionary.BonusStatus on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.BonusStatus.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_bonusstatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'BonusStatus',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_bonusstatus ALTER COLUMN BonusStatusID COMMENT 'Primary key; unique identifier. Range 0 - 3. Referenced by Billing.Deposit, BackOffice.Bonus, and related procs. MCP-verified 4 rows. (Tier 1 - upstream wiki, etoro.Dictionary.BonusStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_bonusstatus ALTER COLUMN Name COMMENT 'Human-readable status label (New, Approved, Declined, Reverted). Used in joins for display and reporting. (Tier 1 - upstream wiki, etoro.Dictionary.BonusStatus)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
