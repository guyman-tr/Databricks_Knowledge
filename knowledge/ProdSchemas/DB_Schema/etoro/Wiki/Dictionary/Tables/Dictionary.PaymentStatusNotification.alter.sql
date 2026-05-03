-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.PaymentStatusNotification
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PaymentStatusNotification.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_paymentstatusnotification
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_paymentstatusnotification (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_paymentstatusnotification SET TBLPROPERTIES (
    'comment' = 'Localized notification message templates displayed to customers for each payment status - HTML-formatted deposit outcome messages in multiple languages. Source: etoro.Dictionary.PaymentStatusNotification on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PaymentStatusNotification.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_paymentstatusnotification SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'PaymentStatusNotification',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_paymentstatusnotification ALTER COLUMN PaymentStatusID COMMENT 'FK to Dictionary.PaymentStatus. Identifies which payment outcome this notification applies to. Part of composite PK. Values include: 2=Success, 3/4=Decline, 6=Cancel, 7=Duplicate, 8=CardBlocked, 10=LimitExceeded, 13=Pending, 14-17=ProviderBlocked, 18=RegionRestriction, 19=AccountRestriction, 22-24=ProviderBlocked, 28=SofortBlocked. (Tier 1 - upstream wiki, etoro.Dictionary.PaymentStatusNotification)';
ALTER TABLE main.general.bronze_etoro_dictionary_paymentstatusnotification ALTER COLUMN LanguageID COMMENT 'FK to Dictionary.Language. Identifies the language of the notification message. Part of composite PK. Currently only LanguageID=1 (English) is populated. Supports multi-language expansion. (Tier 1 - upstream wiki, etoro.Dictionary.PaymentStatusNotification)';
ALTER TABLE main.general.bronze_etoro_dictionary_paymentstatusnotification ALTER COLUMN NotificationMessage COMMENT 'HTML-formatted notification message displayed to the customer. Supports template placeholders: <#amount#> (deposit amount), <#transactionId#> (transaction reference). Contains HTML tags for formatting (br, ul, li, a href). (Tier 1 - upstream wiki, etoro.Dictionary.PaymentStatusNotification)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
