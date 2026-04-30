-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.PaymentStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PaymentStatus.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_paymentstatus
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_paymentstatus (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_paymentstatus SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 7 lifecycle states of payment transactions (deposits and internal transfers). Source: etoro.Dictionary.PaymentStatus on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PaymentStatus.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_paymentstatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'PaymentStatus',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_paymentstatus ALTER COLUMN PaymentStatusID COMMENT 'Primary key identifying the payment state. 1=Pending, 2=InProcess, 3=Processed, 4=Canceled, 5=Failed, 6=Reversed, 7=CompletedExternally. See Payment Status. (Dictionary.PaymentStatus) (Tier 1 - upstream wiki, etoro.Dictionary.PaymentStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_paymentstatus ALTER COLUMN Name COMMENT 'Human-readable status label. UNIQUE constraint. Used in back-office payment management UI and reconciliation reports. (Tier 1 - upstream wiki, etoro.Dictionary.PaymentStatus)';

