-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.PaymentActionType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PaymentActionType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_paymentactiontype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_paymentactiontype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_paymentactiontype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 7 types of payment actions — PreAuthorization, Purchase, Cashout, Refund, Settle, PostBack, and Cancel — classifying each step in payment transaction processing. Source: etoro.Dictionary.PaymentActionType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PaymentActionType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_paymentactiontype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'PaymentActionType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_paymentactiontype ALTER COLUMN PaymentActionTypeID COMMENT 'Primary key identifying the payment operation type. 1=PreAuth, 2=Purchase, 3=Cashout, 4=Refund, 5=Settle, 6=PostBack, 7=Cancel. Referenced by History.PaymentAction (explicit FK), History.DepositAction, and Dictionary.Response (explicit FK). Hard-coded values appear in Billing.DepositAdd (2), Billing.DepositProcess (2), Billing.PaymentByPayPalProcess (6), Billing.DepositsCancelByLastDays (7). (Tier 1 - upstream wiki, etoro.Dictionary.PaymentActionType)';
ALTER TABLE main.general.bronze_etoro_dictionary_paymentactiontype ALTER COLUMN Name COMMENT 'Human-readable action type name. Unique constraint prevents duplicates. Note: ID 1 contains typo "PreAuhtorization" in production data. Used in payment audit trails, debugging, and reporting. (Tier 1 - upstream wiki, etoro.Dictionary.PaymentActionType)';

