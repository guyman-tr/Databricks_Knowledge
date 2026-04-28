-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Dictionary_TransactionType
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactiontype
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactiontype SET TBLPROPERTIES (
    'comment' = '`eMoney_Dictionary_TransactionType` is a lookup/reference table that defines the 15 valid transaction type values for the eToro Money fiat platform. Each row maps a `TransactionTypeID` integer to a human-readable type name. These types categorize every financial transaction flowing through eToro Money: card payments, IBAN transfers, fees, balance adjustments, direct debits, and the crypto-to-fiat bridge. This dictionary is the foundational classification used by analysts and ETL SPs throughout the eMoney layer. The `eMoney_Calculated_Balance` SP groups these types into business-level buckets (CardActivity, Loads, Unloads, BankingPaymentsIN, BankingPaymentsOut, Fee, BalanceAdjustments, DirectDebit, Unknown, TBD). The full type map with 15 rows matches the FiatDwhDB source - no lag. Synapse: REPLICATE, HEAP.'
);

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactiontype SET TAGS (
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
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactiontype ALTER COLUMN `TransactionTypeID` COMMENT 'Lookup identifier. Primary key. 0=Unknown, 1=CardPayment, 2=Contactless, 3=OnlinePayment, 4=CashWithdrawal, 5=TransferReceived, 6=Transfer, 7=PaymentReceived, 8=Payment, 9=Refund, 10=Fee, 11=CreditBA, 12=DebitBA, 13=DirectDebit, 14=CryptoToFiat. (Tier 1 - Dictionary.TransactionTypes)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactiontype ALTER COLUMN `TransactionType` COMMENT 'Human-readable name for this value. 0=Unknown, 1=CardPayment, 2=Contactless, 3=OnlinePayment, 4=CashWithdrawal, 5=TransferReceived, 6=Transfer, 7=PaymentReceived, 8=Payment, 9=Refund, 10=Fee, 11=CreditBA, 12=DebitBA, 13=DirectDebit, 14=CryptoToFiat. (Tier 1 - Dictionary.TransactionTypes)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactiontype ALTER COLUMN `UpdateDate` COMMENT 'Timestamp of last Generic Pipeline ETL load from FiatDwhDB source. Static since 2023-06-12. (Tier 2 - Generic Pipeline)';

-- ---- Column PII Tags ----
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactiontype ALTER COLUMN `TransactionTypeID` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactiontype ALTER COLUMN `TransactionType` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactiontype ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
