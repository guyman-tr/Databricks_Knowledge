-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Dictionary_PaymentSchemaType
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_paymentschematype
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_paymentschematype SET TBLPROPERTIES (
    'comment' = '`eMoney_Dictionary_PaymentSchemaType` is a lookup/reference table that defines the valid payment scheme types for eToro Money banking transactions. Each row maps an integer ID to a human-readable scheme name. Payment schema type determines the routing, settlement speed, and applicable regulations for each transaction processed through the fiat platform. The 8 values cover UK domestic schemes (FasterPayments, Chaps, Bacs), pan-European SEPA variants (SEPAstandart, SEPAinstantTransfer, SEPAdirectDebit), a generic Transfer type, and an Unknown sentinel. Note: `SEPAstandart` (ID=5) preserves a typo from the FiatDwhDB source - use this exact spelling in all filters and joins. This dictionary is sourced from `FiatDwhDB.Dictionary.PaymentSchemaType` via Generic Pipeline Bronze export and applied to transactions in `dbo.FiatTransactions`. All Synapse rows carry UpdateDate 2023-06-11 (single bulk load, one day earlier than the other dictionaries in this batch). Synapse: REPLICATE, HEAP.'
);

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_paymentschematype SET TAGS (
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
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_paymentschematype ALTER COLUMN `PaymentSchemaTypeID` COMMENT 'Lookup identifier. Primary key. 0=Unknown, 1=Transfer, 2=FasterPayments, 3=Chaps, 4=Bacs, 5=SEPAstandart, 6=SEPAinstantTransfer, 7=SEPAdirectDebit. (Tier 1 - Dictionary.PaymentSchemaType)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_paymentschematype ALTER COLUMN `PaymentSchemaType` COMMENT 'Human-readable name for this value. 0=Unknown, 1=Transfer, 2=FasterPayments, 3=Chaps, 4=Bacs, 5=SEPAstandart, 6=SEPAinstantTransfer, 7=SEPAdirectDebit. (Tier 1 - Dictionary.PaymentSchemaType)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_paymentschematype ALTER COLUMN `UpdateDate` COMMENT 'Timestamp of last Generic Pipeline ETL load from FiatDwhDB source. Static since 2023-06-11. (Tier 2 - Generic Pipeline)';

-- ---- Column PII Tags ----
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_paymentschematype ALTER COLUMN `PaymentSchemaTypeID` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_paymentschematype ALTER COLUMN `PaymentSchemaType` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_paymentschematype ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
