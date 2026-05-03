-- =============================================================================
-- Databricks ALTER Script: bronze MoneyBusDB.Dictionary.TransactionStatusReasons
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.TransactionStatusReasons.md
-- Layer: bronze
-- UC Target: main.billing.bronze_moneybusdb_dictionary_transactionstatusreasons
-- =============================================================================

-- ---- UC Target: main.billing.bronze_moneybusdb_dictionary_transactionstatusreasons (business_group=billing) ----
ALTER TABLE main.billing.bronze_moneybusdb_dictionary_transactionstatusreasons SET TBLPROPERTIES (
    'comment' = 'Lookup table providing granular sub-states within the transaction lifecycle, mapping each step-level reason to its parent transaction status. Source: MoneyBusDB.Dictionary.TransactionStatusReasons on the MoneyBusDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.TransactionStatusReasons.md).'
);

ALTER TABLE main.billing.bronze_moneybusdb_dictionary_transactionstatusreasons SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'MoneyBusDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'TransactionStatusReasons',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.billing.bronze_moneybusdb_dictionary_transactionstatusreasons ALTER COLUMN ID COMMENT 'Primary key identifying each transaction status reason. Explicitly assigned (not IDENTITY). Referenced as StatusReasonID in MoneyBus.Transactions and MoneyBus.TransactionsTable_New (UDT). Values: 1=Created, 2=Success, 3=Held, 4=Credited, 5=Debited, 6=HoldDecline, 7=CreditDecline, 8=DebitDecline, 9=ValidateDecline, 10=Technical, 11=DebitInitiated, 12=HoldInitiated, 13=CreditInitiated, 14=HoldCanceled, 15=ReconciliationAborted. See Transaction Status Reason for full business definitions. (Tier 1 - upstream wiki, MoneyBusDB.Dictionary.TransactionStatusReasons)';
ALTER TABLE main.billing.bronze_moneybusdb_dictionary_transactionstatusreasons ALTER COLUMN Name COMMENT 'Human-readable label for the status reason. Descriptive names follow a consistent pattern: {Step}{Outcome} (e.g., HoldInitiated, CreditDecline). Consumed by TransactionStatusReasonsGet for application-level caching and display. (Tier 1 - upstream wiki, MoneyBusDB.Dictionary.TransactionStatusReasons)';
ALTER TABLE main.billing.bronze_moneybusdb_dictionary_transactionstatusreasons ALTER COLUMN TransactionStatusID COMMENT 'Parent status that this reason belongs to. Implicit FK to Dictionary.TransactionStatuses.ID. Maps each granular reason to its top-level outcome category: 1=InProcess, 2=Success, 3=Decline, 4=Technical, 5=Canceled. Critical for determining recoverability - reasons mapping to InProcess are retryable, others are terminal. See Transaction Status. (Tier 1 - upstream wiki, MoneyBusDB.Dictionary.TransactionStatusReasons)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:41:14 UTC
-- Bronze deploy: MoneyBusDB batch 1
-- ====================
