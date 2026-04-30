-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.PaymentDirection
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PaymentDirection.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_paymentdirection
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_paymentdirection (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_paymentdirection SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 2 payment communication directions — From Googess (internal) and From PSP (external) — identifying who initiated the payment message. Source: etoro.Dictionary.PaymentDirection on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PaymentDirection.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_paymentdirection SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'PaymentDirection',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_paymentdirection ALTER COLUMN PaymentDirectionID COMMENT 'Primary key identifying the communication direction. 1=From Googess (outbound, eToro→PSP), 2=From PSP (inbound, PSP→eToro). Referenced by History.PaymentLog via explicit FK. Written by Billing.PaymentLogAdd for every payment communication event. (Tier 1 - upstream wiki, etoro.Dictionary.PaymentDirection)';
ALTER TABLE main.general.bronze_etoro_dictionary_paymentdirection ALTER COLUMN Name COMMENT 'Human-readable direction label. Unique constraint prevents duplicates. Values: ''From Googess'', ''From PSP''. "Googess" is eToro''s internal payment gateway name. Used in payment logs, reconciliation reports, and debugging UIs. (Tier 1 - upstream wiki, etoro.Dictionary.PaymentDirection)';

