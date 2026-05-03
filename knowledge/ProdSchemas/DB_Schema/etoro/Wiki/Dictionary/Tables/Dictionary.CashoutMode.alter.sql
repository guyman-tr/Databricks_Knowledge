-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.CashoutMode
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CashoutMode.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_cashoutmode
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_cashoutmode (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_cashoutmode SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 4 cashout (withdrawal) processing modes - Manual, Auto Create, Mass Auto Create, and Instant Withdrawal - with priority weights for processing order. Source: etoro.Dictionary.CashoutMode on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CashoutMode.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_cashoutmode SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'CashoutMode',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_cashoutmode ALTER COLUMN CashoutModeID COMMENT 'Primary key identifying the processing mode. 0=Manual, 1=Auto Create, 2=Mass Auto Create, 3=Instant Withdrawal. TINYINT type (0-255). Stored on Billing.WithdrawToFunding and History.WithdrawToFundingAction. Set at withdrawal creation time. (Tier 1 - upstream wiki, etoro.Dictionary.CashoutMode)';
ALTER TABLE main.general.bronze_etoro_dictionary_cashoutmode ALTER COLUMN CashoutModeName COMMENT 'Human-readable mode name. Unique constraint prevents duplicates. Note: column named CashoutModeName (not just Name) - differs from most Dictionary tables. Used in BackOffice JOINs as the display label (aliased as CashoutMode or EntryMethod). (Tier 1 - upstream wiki, etoro.Dictionary.CashoutMode)';
ALTER TABLE main.general.bronze_etoro_dictionary_cashoutmode ALTER COLUMN CashoutModeWeight COMMENT 'Processing priority weight - higher values are processed first. 0=Manual (lowest), 10=Auto, 20=Mass Auto, 30=Instant (highest). DEFAULT 100 for new modes (high priority by default). Used by payout processing to determine execution order. (Tier 1 - upstream wiki, etoro.Dictionary.CashoutMode)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
