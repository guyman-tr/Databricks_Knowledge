-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Dictionary_TransactionStatus
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactionstatus
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactionstatus SET TBLPROPERTIES (
    'comment' = '`eMoney_Dictionary_TransactionStatus` is a lookup/reference table that defines the valid values for fiat transaction lifecycle state in the eToro Money platform. Each row maps an integer ID to a human-readable status name. Transactions flow through these states from authorization through settlement or failure; understanding these states is essential for reconciliation, AML monitoring, and customer-facing reporting. As of 2026-04-20, the Synapse DWH table contains 6 of the 8 values defined in `FiatDwhDB.Dictionary.TransactionStatuses`. Statuses `6=Reserved` and `7=Cancelled` are defined in FiatDwhDB but have not been propagated to Synapse - any transactions with these statuses would appear with unmapped IDs. This is flagged in the review sidecar. This dictionary is referenced by `eMoney_Dim_Transaction.TransactionStatusID`, `eMoney_Fact_Transaction_Status.TransactionStatusID`, and `eMoney_Calculated_Balance` analytics throughout the eMoney layer. Last loaded 2023-06-12. Synapse: REPLICATE, HEAP.'
);

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactionstatus SET TAGS (
    'domain' = 'general',
    'object_type' = 'table',
    'source_schema' = 'eMoney_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactionstatus ALTER COLUMN `TransactionStatusID` COMMENT 'Lookup identifier. Primary key. 0=Failed, 1=Authorized, 2=Settled, 3=Rejected, 4=Returned, 5=Expired. Note: 6=Reserved and 7=Cancelled are defined in FiatDwhDB source but absent from this Synapse table. (Tier 1 - Dictionary.TransactionStatuses)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactionstatus ALTER COLUMN `TransactionStatus` COMMENT 'Human-readable name for this value. 0=Failed, 1=Authorized, 2=Settled, 3=Rejected, 4=Returned, 5=Expired. (Tier 1 - Dictionary.TransactionStatuses)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactionstatus ALTER COLUMN `UpdateDate` COMMENT 'Timestamp of last Generic Pipeline ETL load from FiatDwhDB source. Static since 2023-06-12. (Tier 2 - Generic Pipeline)';

-- ---- Column PII Tags ----
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactionstatus ALTER COLUMN `TransactionStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactionstatus ALTER COLUMN `TransactionStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactionstatus ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
