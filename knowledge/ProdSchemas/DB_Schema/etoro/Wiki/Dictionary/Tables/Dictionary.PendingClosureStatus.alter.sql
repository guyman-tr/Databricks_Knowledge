-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.PendingClosureStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PendingClosureStatus.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_pendingclosurestatus
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_pendingclosurestatus (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_pendingclosurestatus SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 3 account closure workflow states - No (not pending), Suggested for Closure, and Approved for Closure - controlling the account closure pipeline. Source: etoro.Dictionary.PendingClosureStatus on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PendingClosureStatus.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_pendingclosurestatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'PendingClosureStatus',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_pendingclosurestatus ALTER COLUMN PendingClosureStatusID COMMENT 'Primary key identifying the closure workflow state. 1=No (not pending), 2=Suggested for Closure, 3=Approved for Closure. Stored in Customer.CustomerStatic and exposed through Customer.Customer and CustomerSafty views. Managed by BackOffice.AccountPendingClosureStatusChange. (Tier 1 - upstream wiki, etoro.Dictionary.PendingClosureStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_pendingclosurestatus ALTER COLUMN PendingClosureStatusName COMMENT 'Human-readable label for the closure state. Displayed in BackOffice customer cards, closure reports, and regulatory compliance screens. (Tier 1 - upstream wiki, etoro.Dictionary.PendingClosureStatus)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
