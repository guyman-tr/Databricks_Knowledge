-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.PaymentActionStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PaymentActionStatus.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_paymentactionstatus
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_paymentactionstatus (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_paymentactionstatus SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 3-state lifecycle of payment actions - New, InProcess, and Closed - tracking each payment operation from initiation through completion. Source: etoro.Dictionary.PaymentActionStatus on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PaymentActionStatus.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_paymentactionstatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'PaymentActionStatus',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_paymentactionstatus ALTER COLUMN PaymentActionStatusID COMMENT 'Primary key identifying the action lifecycle state. 1=New (created), 2=InProcess (being processed), 3=Closed (finalized). Referenced by History.PaymentAction (explicit FK) and History.DepositAction. Written by all deposit/payment action procedures in the Billing schema. (Tier 1 - upstream wiki, etoro.Dictionary.PaymentActionStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_paymentactionstatus ALTER COLUMN Name COMMENT 'Human-readable status name. Unique constraint prevents duplicates. Values: ''New'', ''InProcess'', ''Closed''. Used in payment dashboards, audit reports, and debugging. (Tier 1 - upstream wiki, etoro.Dictionary.PaymentActionStatus)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
