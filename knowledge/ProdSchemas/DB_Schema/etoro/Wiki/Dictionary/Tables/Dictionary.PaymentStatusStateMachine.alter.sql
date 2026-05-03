-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.PaymentStatusStateMachine
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PaymentStatusStateMachine.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_paymentstatusstatemachine
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_paymentstatusstatemachine (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_paymentstatusstatemachine SET TBLPROPERTIES (
    'comment' = 'Configuration table defining the valid payment status transitions per funding type, acting as a state machine guard for the deposit processing pipeline. Source: etoro.Dictionary.PaymentStatusStateMachine on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PaymentStatusStateMachine.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_paymentstatusstatemachine SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'PaymentStatusStateMachine',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_paymentstatusstatemachine ALTER COLUMN FundingTypeID COMMENT 'Payment method identifier - part of composite PK. References Dictionary.FundingType: 1=CreditCard, 2=ChinaUnionPay, 3=PayPal, 5=MoneyBookers, 6=Wire, 7=PayPal(alt), 8=Skrill, 9=Neteller, 10=WebMoney, 11=YandexMoney, etc. Each funding type has its own set of valid transitions. (Tier 1 - upstream wiki, etoro.Dictionary.PaymentStatusStateMachine)';
ALTER TABLE main.general.bronze_etoro_dictionary_paymentstatusstatemachine ALTER COLUMN BeforePaymentStatusID COMMENT 'The payment status BEFORE the transition - part of composite PK. FK to Dictionary.PaymentStatus: 1=Pending, 2=Approved/InProcess, 3=Processed, 4=Canceled, 5=Failed, 6=Reversed, 12=ChargeBack, 13=WaitingForProvider. (Tier 1 - upstream wiki, etoro.Dictionary.PaymentStatusStateMachine)';
ALTER TABLE main.general.bronze_etoro_dictionary_paymentstatusstatemachine ALTER COLUMN AfterPaymentStatusID COMMENT 'The payment status AFTER the transition - part of composite PK. FK to Dictionary.PaymentStatus. A row''s existence means "this transition is allowed." Billing.DepositProcess checks AfterPaymentStatusID = 2 (approved) to validate deposit approval. (Tier 1 - upstream wiki, etoro.Dictionary.PaymentStatusStateMachine)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
