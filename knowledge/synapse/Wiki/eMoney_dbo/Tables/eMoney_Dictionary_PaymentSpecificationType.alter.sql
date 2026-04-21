-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Dictionary_PaymentSpecificationType
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_paymentspecificationtype
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_paymentspecificationtype SET TBLPROPERTIES (
    'comment' = '`eMoney_Dictionary_PaymentSpecificationType` is a lookup/reference table that defines the valid types of payment specification - that is, the type of recurring or automated payment instruction set up on an eToro Money currency balance. Each row maps an integer ID to a human-readable name. With only 2 values, this dictionary is minimal: `Unknown (0)` is the sentinel for undetermined type, and `DirectDebit (1)` identifies a pull-payment mandate where a third-party creditor is authorized to debit the balance on a scheduled or recurring basis. Payment specifications are sourced from `dbo.PaymentSpecifications` in FiatDwhDB. This dictionary is sourced from `FiatDwhDB.Dictionary.PaymentSpecificationTypes` via Generic Pipeline Bronze export. All Synapse rows carry UpdateDate 2023-06-12 (single bulk load). Synapse: REPLICATE, HEAP.'
);

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_paymentspecificationtype SET TAGS (
    'domain' = 'billing',
    'object_type' = 'table',
    'source_schema' = 'eMoney_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_paymentspecificationtype ALTER COLUMN `PaymentSpecificationTypeID` COMMENT 'Lookup identifier. Primary key. 0=Unknown, 1=DirectDebit. (Tier 1 - Dictionary.PaymentSpecificationTypes)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_paymentspecificationtype ALTER COLUMN `PaymentSpecificationType` COMMENT 'Human-readable name for this value. 0=Unknown, 1=DirectDebit. (Tier 1 - Dictionary.PaymentSpecificationTypes)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_paymentspecificationtype ALTER COLUMN `UpdateDate` COMMENT 'Timestamp of last Generic Pipeline ETL load from FiatDwhDB source. Static since 2023-06-12. (Tier 2 - Generic Pipeline)';

-- ---- Column PII Tags ----
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_paymentspecificationtype ALTER COLUMN `PaymentSpecificationTypeID` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_paymentspecificationtype ALTER COLUMN `PaymentSpecificationType` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_paymentspecificationtype ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
