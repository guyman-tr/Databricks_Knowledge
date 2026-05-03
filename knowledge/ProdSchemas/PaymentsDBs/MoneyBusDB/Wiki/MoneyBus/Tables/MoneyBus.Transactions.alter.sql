-- =============================================================================
-- Databricks ALTER Script: bronze MoneyBusDB.MoneyBus.Transactions
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md
-- Layer: bronze
-- UC Target: main.billing.bronze_moneybusdb_moneybus_transactions
-- =============================================================================

-- ---- UC Target: main.billing.bronze_moneybusdb_moneybus_transactions (business_group=billing) ----
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions SET TBLPROPERTIES (
    'comment' = 'Core transactional table recording every money movement leg in the MoneyBus payment system - from trading position opens/closes to deposits and withdrawals - tracking the full hold-debit-credit pipeline with system versioning. Source: MoneyBusDB.MoneyBus.Transactions on the MoneyBusDB production database, ingested via the Generic Pipeline (Merge strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md).'
);

ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'MoneyBusDB',
    'source_schema' = 'MoneyBus',
    'source_table' = 'Transactions',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Merge',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions ALTER COLUMN ID COMMENT 'Auto-incrementing primary key. Part of composite clustered key with PartitionCol. Referenced by Containers.TransactionID. Used with modulo partitioning for efficient lookups (WHERE ID = @ID AND PartitionCol = @ID % 100). (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.Transactions)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions ALTER COLUMN GCID COMMENT 'Global Customer ID - identifies the user who owns this transaction. Indexed (IX_Transactions_GCID) for user-level queries. Nullable for system-generated transactions. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.Transactions)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions ALTER COLUMN Created COMMENT 'UTC timestamp when the transaction was created. Set to GETUTCDATE() by TransactionAdd/TransactionsAndGroupAdd if not provided. Indexed (IX_Transactions_Created). Range: 2023-05-07 to present. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.Transactions)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions ALTER COLUMN CreditorTypeID COMMENT 'Account type receiving funds: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. See Account Type. (Dictionary.AccountTypes). Paired with DebitorTypeID to define the transfer direction. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.Transactions)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions ALTER COLUMN DebitorTypeID COMMENT 'Account type sending funds: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. See Account Type. (Dictionary.AccountTypes). The combination CreditorTypeID+DebitorTypeID defines the money flow direction. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.Transactions)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions ALTER COLUMN StatusID COMMENT 'High-level transaction lifecycle state: 1=InProcess, 2=Success, 3=Decline, 4=Technical, 5=Canceled. See Transaction Status. (Dictionary.TransactionStatuses). ~98% reach Success. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.Transactions)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions ALTER COLUMN GroupID COMMENT 'FK to MoneyBus.TransactionsGroup.ID. Links this transaction to its parent group, tying together the debit and credit legs of a single business operation. Set by TransactionsAndGroupAdd after creating the group. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.Transactions)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions ALTER COLUMN ReferenceID COMMENT 'External reference identifier from the calling system (typically a UUID). Used for cross-system correlation and idempotency. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.Transactions)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions ALTER COLUMN Amount COMMENT 'Transaction amount in the currency specified by CurrencyID. Pre-calculated by the application. Ranges from small fractional amounts to large sums. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.Transactions)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions ALTER COLUMN CurrencyID COMMENT 'Currency of the transaction amount. Common values: 1 (USD), 2 (EUR), 3 (GBP). Maps to an external currency reference. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.Transactions)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions ALTER COLUMN Modified COMMENT 'UTC timestamp of the last status change. Updated by TransactionUpdate on every pipeline step transition. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.Transactions)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions ALTER COLUMN CreditorAccountID COMMENT 'Identifier of the creditor''s specific account within the creditor account type. May be a trading account number, IBAN, or internal account reference. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.Transactions)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions ALTER COLUMN DebitorAccountID COMMENT 'Identifier of the debitor''s specific account within the debitor account type. Paired with CreditorAccountID to fully specify both ends of the transfer. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.Transactions)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions ALTER COLUMN StatusReasonID COMMENT 'Detailed pipeline step: 1=Created, 2=Success, 3=Held, 4=Credited, 5=Debited, 6=HoldDecline, 7=CreditDecline, 8=DebitDecline, 9=ValidateDecline, 10=Technical, 11=DebitInitiated, 12=HoldInitiated, 13=CreditInitiated, 14=HoldCanceled, 15=ReconciliationAborted. See Transaction Status Reason. (Dictionary.TransactionStatusReasons). (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.Transactions)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions ALTER COLUMN PartitionCol COMMENT 'Computed: ID % 100. Persisted computed column used as the partition key in the PS_Transactions partition scheme. Distributes rows across 100 partitions for parallel query performance. Part of the composite clustered key. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.Transactions)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions ALTER COLUMN Trace COMMENT 'Computed: CONCAT(''{"HostName":"'',HOST_NAME(),...}). Non-persisted JSON audit trail capturing SQL Server session context (hostname, app name, login, SPID, database, procedure) at the time of last modification. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.Transactions)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions ALTER COLUMN ValidFrom COMMENT 'System-versioning start timestamp. Auto-managed by SQL Server temporal tables. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.Transactions)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions ALTER COLUMN ValidTo COMMENT 'System-versioning end timestamp. 9999-12-31 for current version. Old versions move to History.MoneyBusTransactions on UPDATE. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.Transactions)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions ALTER COLUMN CreditorReferenceID COMMENT 'Provider-side reference ID for the credit leg. Populated by TransactionUpdate after credit initiation. Used for reconciliation with the credit provider. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.Transactions)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions ALTER COLUMN DebitorReferenceID COMMENT 'Provider-side reference ID for the debit leg. Populated by TransactionUpdate after debit initiation. Used for reconciliation with the debit provider. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.Transactions)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions ALTER COLUMN FlowID COMMENT 'Business flow classifier: 1=Open position (buy), 2=Close position (sell), 3=Deposit/withdrawal. Determines which pipeline logic is applied. ~42% flow 1, ~43% flow 2, ~15% flow 3. NULL/0 for legacy transactions. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.Transactions)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions ALTER COLUMN ExtraData COMMENT 'JSON metadata carrying rich trading context. For Open flows: units, leverage, instrumentName, isBuy, isReal. For Close flows: positionId, orderId, action="Close". Always contains creditorData/debitorData with per-side Amount/Currency/CurrencyId. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.Transactions)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions ALTER COLUMN CreditorBaseExchangeRate COMMENT 'Market exchange rate for converting to the creditor''s currency. Used with CreditorExchangeFee to compute the effective CreditorExchangeRate. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.Transactions)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions ALTER COLUMN CreditorExchangeFee COMMENT 'Fee/spread applied to the creditor-side currency conversion, expressed as a rate adjustment. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.Transactions)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions ALTER COLUMN CreditorExchangeRate COMMENT 'Effective exchange rate applied to the creditor side (base rate adjusted by fee). Creditor amount = Amount * CreditorExchangeRate (approximately). (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.Transactions)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions ALTER COLUMN DebitorBaseExchangeRate COMMENT 'Market exchange rate for the debitor''s currency conversion. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.Transactions)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions ALTER COLUMN DebitorExchangeFee COMMENT 'Fee/spread applied to the debitor-side currency conversion. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.Transactions)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions ALTER COLUMN DebitorExchangeRate COMMENT 'Effective exchange rate applied to the debitor side. Debitor amount = Amount * DebitorExchangeRate (approximately). (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.Transactions)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transactions ALTER COLUMN HoldReferenceID COMMENT 'Provider-side reference ID for the hold/reserve operation. Used to release or settle held funds. Populated during HoldInitiated step. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.Transactions)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:41:14 UTC
-- Bronze deploy: MoneyBusDB batch 1
-- ====================
