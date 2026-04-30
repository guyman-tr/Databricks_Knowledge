-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.PaymentType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PaymentType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_paymenttype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_paymenttype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_paymenttype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 3 high-level payment categories — Deposit, Cashout, and Refund — classifying every payment transaction by its financial direction and purpose. Source: etoro.Dictionary.PaymentType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PaymentType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_paymenttype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'PaymentType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_paymenttype ALTER COLUMN PaymentTypeID COMMENT 'Primary key identifying the payment category. 1=Deposit (money in), 2=Cashout (money out), 3=Refund (money returned). Referenced by 4 tables with explicit FKs: Billing.Depot, Billing.Payment, Billing.Terminal, Billing.Volume. Also used in Billing.ACHBankAccount, Billing.ACHBanks, Billing.MerchantAccountRouting. Hard-coded value 1 appears in multiple deposit procedures for PaymentTypeID=Deposit filtering. (Tier 1 - upstream wiki, etoro.Dictionary.PaymentType)';
ALTER TABLE main.general.bronze_etoro_dictionary_paymenttype ALTER COLUMN Name COMMENT 'Human-readable payment category name. Unique constraint prevents duplicates. Values: ''Deposit'', ''Cashout'', ''Refund''. Used in payment reporting, filtering, and UI display. Referenced by Billing.DepositAdd (SELECT Name WHERE PaymentTypeID=1). (Tier 1 - upstream wiki, etoro.Dictionary.PaymentType)';

