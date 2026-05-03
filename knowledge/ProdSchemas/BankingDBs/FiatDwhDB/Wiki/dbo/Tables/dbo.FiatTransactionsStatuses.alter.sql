-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.dbo.FiatTransactionsStatuses
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatTransactionsStatuses.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_dbo_fiattransactionsstatuses
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_dbo_fiattransactionsstatuses (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactionsstatuses SET TBLPROPERTIES (
    'comment' = 'Event-sourced transaction status table tracking the complete lifecycle of each financial transaction, including amounts, currencies, risk actions, and authorization details. Source: FiatDwhDB.dbo.FiatTransactionsStatuses on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatTransactionsStatuses.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactionsstatuses SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'dbo',
    'source_table' = 'FiatTransactionsStatuses',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactionsstatuses ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate PK. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactionsStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactionsstatuses ALTER COLUMN TransactionId COMMENT 'FK to dbo.FiatTransactions.Id. The transaction this status belongs to. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactionsStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactionsstatuses ALTER COLUMN TransactionStatusId COMMENT 'Status: 0-7. See Transaction Status. (Dictionary.TransactionStatuses) (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactionsStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactionsstatuses ALTER COLUMN AuthorizationType COMMENT 'Authorization type: 0-14. See Authorization Type. (Dictionary.AuthorizationTypes) (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactionsStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactionsstatuses ALTER COLUMN HolderAmount COMMENT 'Transaction amount in the cardholder''s account currency. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactionsStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactionsstatuses ALTER COLUMN HolderCurrency COMMENT 'ISO 4217 alphabetical currency code of the holder''s balance (e.g., "GBP", "EUR"). (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactionsStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactionsstatuses ALTER COLUMN TransactionAmount COMMENT 'Transaction amount in the merchant/originator currency. May differ from HolderAmount for cross-border transactions. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactionsStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactionsstatuses ALTER COLUMN TransactionCurrency COMMENT 'ISO 4217 alphabetical currency code of the transaction (e.g., "USD" for a US merchant). (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactionsStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactionsstatuses ALTER COLUMN AccumulatedAmount COMMENT 'Cumulative balance impact from this transaction across all its status events. Used for reconciliation. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactionsStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactionsstatuses ALTER COLUMN TransactionOccured COMMENT 'When the transaction event occurred (source system timestamp). Part of unique constraint. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactionsStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactionsstatuses ALTER COLUMN Created COMMENT 'When this record was written to the DWH. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactionsStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactionsstatuses ALTER COLUMN RiskRuleCodes COMMENT 'Comma-separated risk rule codes that were triggered during this transaction. NULL if no risk rules fired. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactionsStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactionsstatuses ALTER COLUMN MarkTransactionAsSuspiciousRiskAction COMMENT 'Risk action: 1=transaction flagged as suspicious for review. Default 0. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactionsStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactionsstatuses ALTER COLUMN ChangeCardStatusToRiskRiskAction COMMENT 'Risk action: 1=card status changed to Risk(4) due to this transaction. Default 0. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactionsStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactionsstatuses ALTER COLUMN ChangeAccountStatusToSuspendedRiskAction COMMENT 'Risk action: 1=account suspended due to this transaction''s risk assessment. Default 0. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactionsStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactionsstatuses ALTER COLUMN RejectTransactionRiskAction COMMENT 'Risk action: 1=transaction rejected by the risk engine. Default 0. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactionsStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiattransactionsstatuses ALTER COLUMN CorrelationId COMMENT 'Links this status event to the business operation for distributed tracing. Nullable for legacy records. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatTransactionsStatuses)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:05:44 UTC
-- Bronze deploy: FiatDwhDB batch 1
-- ====================
