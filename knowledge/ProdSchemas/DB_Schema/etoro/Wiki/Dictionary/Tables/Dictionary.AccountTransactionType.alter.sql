-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.AccountTransactionType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AccountTransactionType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_accounttransactiontype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_accounttransactiontype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_accounttransactiontype SET TBLPROPERTIES (
    'comment' = 'Lookup table classifying financial transaction types for hedge account operations — deposits, withdrawals, fees, adjustments, and other money movements in hedge liquidity accounts. Source: etoro.Dictionary.AccountTransactionType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AccountTransactionType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_accounttransactiontype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'AccountTransactionType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_accounttransactiontype ALTER COLUMN TransactionTypeID COMMENT 'Primary key identifying the transaction category. 1–13 map to Deposit, Withdrawal, Refund, Compensation, Commission, Adjustment, Interest, Transaction Fees, Overnight Fees, Conversion, Rebate, Manual Cost, System Cost. Referenced by Hedge.AccountTransactions via FK. (Tier 1 - upstream wiki, etoro.Dictionary.AccountTransactionType)';
ALTER TABLE main.general.bronze_etoro_dictionary_accounttransactiontype ALTER COLUMN TransactionTypeName COMMENT 'Human-readable transaction type name. Used in reports, statements, and UI. Values match live data (MCP verified). (Tier 1 - upstream wiki, etoro.Dictionary.AccountTransactionType)';

