# MoneyBus.Transactions

> Core transactional table recording every money movement leg in the MoneyBus payment system - from trading position opens/closes to deposits and withdrawals - tracking the full hold-debit-credit pipeline with system versioning.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Table |
| **Key Identifier** | ID (BIGINT, IDENTITY, CLUSTERED PK) + PartitionCol (computed) |
| **Partition** | Yes - PS_Transactions on PartitionCol (ID % 100) |
| **Indexes** | 3 active (PK + IX_Created + IX_GCID) |

---

## 1. Business Meaning

MoneyBus.Transactions is the central ledger table recording every individual money movement leg in the MoneyBus payment system. Each row represents a single directional fund transfer from a debitor account type to a creditor account type. Transactions are grouped via GroupID into logical operations (see MoneyBus.TransactionsGroup) so that the debit and credit sides of a single business action are tied together.

This table exists as the authoritative record of all fund movements for audit, reconciliation, and compliance. It tracks the complete lifecycle of each transaction through a Hold -> Debit -> Credit pipeline via StatusID and StatusReasonID. The system-versioning with History.MoneyBusTransactions preserves every state change. The table is partitioned across 100 partitions (ID % 100) for performance at scale (~7.7M rows).

Data flows in primarily through TransactionAdd (single transaction) and TransactionsAndGroupAdd (batch with group creation). TransactionUpdate modifies status as the transaction progresses through pipeline steps. The ExtraData JSON column carries rich trading context including instrument IDs, position IDs, units, leverage, and action type (Open/Close), revealing that the primary use case is funding trading position operations and processing deposits/withdrawals.

---

## 2. Business Logic

### 2.1 Transaction Lifecycle Pipeline

**What**: Each transaction progresses through a hold-debit-credit pipeline tracked by StatusID and StatusReasonID.

**Columns/Parameters Involved**: `StatusID`, `StatusReasonID`

**Rules**:
- StatusID maps to Dictionary.TransactionStatuses: 1=InProcess, 2=Success, 3=Decline, 4=Technical, 5=Canceled
- StatusReasonID maps to Dictionary.TransactionStatusReasons for step-level detail
- Happy path: Created(1) -> HoldInitiated(12) -> Held(3) -> DebitInitiated(11) -> Debited(5) -> CreditInitiated(13) -> Credited(4) -> Success(2)
- ~98% of transactions reach Success (StatusID=2, StatusReasonID=2)
- ValidateDecline (3/9) is the most common failure - pre-validation rejects the transaction before fund movement
- HoldCanceled (5/14) means previously reserved funds were released

**Diagram**:
```
Created(1/1) -> HoldInitiated(1/12) -> Held(1/3) -> DebitInitiated(1/11) -> Debited(1/5)
    |                |                                    |                      |
    v                v                                    v                      v
ValidateDecline   HoldDecline(3/6)                DebitDecline(1/8)    CreditInitiated(1/13)
   (3/9)              |                                                       |
                      v                                                       v
               HoldCanceled(5/14)                                      Credited(1/4)
                                                                             |
                                                                             v
Technical(4/10) <-- [any step failure]                              Success(2/2)
ReconciliationAborted(5/15)

Legend: (StatusID/StatusReasonID)
```

### 2.2 Creditor/Debitor Direction Patterns

**What**: Each transaction has a direction defined by the creditor (receiving) and debitor (sending) account types, revealing the business flow type.

**Columns/Parameters Involved**: `CreditorTypeID`, `DebitorTypeID`, `FlowID`

**Rules**:
- IBAN(3)->Trading(1): ~50% - Deposits from bank to trading account
- Trading(1)->IBAN(3): ~49% - Withdrawals from trading to bank account
- Options(2)<->Trading(1): ~1% - Internal transfers between trading and options accounts
- FlowID further classifies: 1=Open position, 2=Close position, 3=deposit/withdrawal flow
- The direction determines which account is debited and which is credited

### 2.3 Exchange Rate Tracking (Cross-Currency Transactions)

**What**: When creditor and debitor operate in different currencies, the transaction records full exchange rate details for both sides.

**Columns/Parameters Involved**: `CreditorBaseExchangeRate`, `CreditorExchangeFee`, `CreditorExchangeRate`, `DebitorBaseExchangeRate`, `DebitorExchangeFee`, `DebitorExchangeRate`, `CurrencyID`

**Rules**:
- CurrencyID is the transaction's base currency
- Each side has: BaseExchangeRate (market rate), ExchangeFee (spread/fee rate), ExchangeRate (effective rate = base adjusted by fee)
- ExtraData JSON contains creditorData/debitorData sub-objects with per-side Amount, Currency, CurrencyId
- Example: A close-position flow may debit USD from Trading and credit EUR to IBAN, with conversion rates recorded on both sides

---

## 3. Data Overview

| ID | CreditorTypeID | DebitorTypeID | StatusID | Amount | CurrencyID | FlowID | Meaning |
|---|---|---|---|---|---|---|---|
| 7747200 | 1 (Trading) | 3 (IBAN) | 2 (Success) | 2500 | 2 | 1 | Deposit: funds moved from IBAN to Trading account for position opening. Flow 1 = Open. |
| 7747000 | 3 (IBAN) | 1 (Trading) | 2 (Success) | 150.32 | 1 | 3 | Withdrawal: funds moved from Trading to IBAN. Flow 3 = general deposit/withdrawal flow. |
| 7732600 | 1 (Trading) | 3 (IBAN) | 3 (Decline) | 31.05 | 3 | 1 | Declined open-position flow - ValidateDecline(9). ExtraData shows: POL instrument, 500 units, leverage 1, real stock. Pre-validation rejected. |
| 7733000 | 3 (IBAN) | 1 (Trading) | 4 (Technical) | 103.33 | 1 | 2 | Technical failure on close-position flow. ExtraData shows positionId, orderId, action=Close. System error during processing. |
| 7746800 | 3 (IBAN) | 1 (Trading) | 2 (Success) | 57.96 | 1 | 2 | Successful close-position withdrawal. Flow 2 = Close. Funds returned from Trading to IBAN. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key. Part of composite clustered key with PartitionCol. Referenced by Containers.TransactionID. Used with modulo partitioning for efficient lookups (WHERE ID = @ID AND PartitionCol = @ID % 100). |
| 2 | GCID | bigint | YES | - | CODE-BACKED | Global Customer ID - identifies the user who owns this transaction. Indexed (IX_Transactions_GCID) for user-level queries. Nullable for system-generated transactions. |
| 3 | Created | datetime | NO | GETDATE() | CODE-BACKED | UTC timestamp when the transaction was created. Set to GETUTCDATE() by TransactionAdd/TransactionsAndGroupAdd if not provided. Indexed (IX_Transactions_Created). Range: 2023-05-07 to present. |
| 4 | CreditorTypeID | int | NO | - | CODE-BACKED | Account type receiving funds: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. See [Account Type](../../_glossary.md#account-type). (Dictionary.AccountTypes). Paired with DebitorTypeID to define the transfer direction. |
| 5 | DebitorTypeID | int | NO | - | CODE-BACKED | Account type sending funds: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. See [Account Type](../../_glossary.md#account-type). (Dictionary.AccountTypes). The combination CreditorTypeID+DebitorTypeID defines the money flow direction. |
| 6 | StatusID | int | NO | - | CODE-BACKED | High-level transaction lifecycle state: 1=InProcess, 2=Success, 3=Decline, 4=Technical, 5=Canceled. See [Transaction Status](../../_glossary.md#transaction-status). (Dictionary.TransactionStatuses). ~98% reach Success. |
| 7 | GroupID | bigint | YES | - | CODE-BACKED | FK to MoneyBus.TransactionsGroup.ID. Links this transaction to its parent group, tying together the debit and credit legs of a single business operation. Set by TransactionsAndGroupAdd after creating the group. |
| 8 | ReferenceID | nvarchar(500) | YES | - | CODE-BACKED | External reference identifier from the calling system (typically a UUID). Used for cross-system correlation and idempotency. |
| 9 | Amount | money | NO | - | CODE-BACKED | Transaction amount in the currency specified by CurrencyID. Pre-calculated by the application. Ranges from small fractional amounts to large sums. |
| 10 | CurrencyID | int | NO | - | CODE-BACKED | Currency of the transaction amount. Common values: 1 (USD), 2 (EUR), 3 (GBP). Maps to an external currency reference. |
| 11 | Modified | datetime | NO | GETDATE() | CODE-BACKED | UTC timestamp of the last status change. Updated by TransactionUpdate on every pipeline step transition. |
| 12 | CreditorAccountID | nvarchar(500) | YES | - | CODE-BACKED | Identifier of the creditor's specific account within the creditor account type. May be a trading account number, IBAN, or internal account reference. |
| 13 | DebitorAccountID | nvarchar(500) | YES | - | CODE-BACKED | Identifier of the debitor's specific account within the debitor account type. Paired with CreditorAccountID to fully specify both ends of the transfer. |
| 14 | StatusReasonID | int | YES | - | CODE-BACKED | Detailed pipeline step: 1=Created, 2=Success, 3=Held, 4=Credited, 5=Debited, 6=HoldDecline, 7=CreditDecline, 8=DebitDecline, 9=ValidateDecline, 10=Technical, 11=DebitInitiated, 12=HoldInitiated, 13=CreditInitiated, 14=HoldCanceled, 15=ReconciliationAborted. See [Transaction Status Reason](../../_glossary.md#transaction-status-reason). (Dictionary.TransactionStatusReasons). |
| 15 | PartitionCol | (computed, persisted) | NO | - | CODE-BACKED | Computed: `ID % 100`. Persisted computed column used as the partition key in the PS_Transactions partition scheme. Distributes rows across 100 partitions for parallel query performance. Part of the composite clustered key. |
| 16 | Trace | (computed) | - | - | CODE-BACKED | Computed: `CONCAT('{"HostName":"',HOST_NAME(),...})`. Non-persisted JSON audit trail capturing SQL Server session context (hostname, app name, login, SPID, database, procedure) at the time of last modification. |
| 17 | ValidFrom | datetime2(7) | NO | (system-managed) | CODE-BACKED | System-versioning start timestamp. Auto-managed by SQL Server temporal tables. |
| 18 | ValidTo | datetime2(7) | NO | (system-managed) | CODE-BACKED | System-versioning end timestamp. 9999-12-31 for current version. Old versions move to History.MoneyBusTransactions on UPDATE. |
| 19 | CreditorReferenceID | varchar(100) | YES | - | CODE-BACKED | Provider-side reference ID for the credit leg. Populated by TransactionUpdate after credit initiation. Used for reconciliation with the credit provider. |
| 20 | DebitorReferenceID | varchar(100) | YES | - | CODE-BACKED | Provider-side reference ID for the debit leg. Populated by TransactionUpdate after debit initiation. Used for reconciliation with the debit provider. |
| 21 | FlowID | int | YES | - | CODE-BACKED | Business flow classifier: 1=Open position (buy), 2=Close position (sell), 3=Deposit/withdrawal. Determines which pipeline logic is applied. ~42% flow 1, ~43% flow 2, ~15% flow 3. NULL/0 for legacy transactions. |
| 22 | ExtraData | nvarchar(4000) | YES | - | CODE-BACKED | JSON metadata carrying rich trading context. For Open flows: units, leverage, instrumentName, isBuy, isReal. For Close flows: positionId, orderId, action="Close". Always contains creditorData/debitorData with per-side Amount/Currency/CurrencyId. |
| 23 | CreditorBaseExchangeRate | decimal(16,8) | YES | - | CODE-BACKED | Market exchange rate for converting to the creditor's currency. Used with CreditorExchangeFee to compute the effective CreditorExchangeRate. |
| 24 | CreditorExchangeFee | decimal(16,8) | YES | - | CODE-BACKED | Fee/spread applied to the creditor-side currency conversion, expressed as a rate adjustment. |
| 25 | CreditorExchangeRate | decimal(16,8) | YES | - | CODE-BACKED | Effective exchange rate applied to the creditor side (base rate adjusted by fee). Creditor amount = Amount * CreditorExchangeRate (approximately). |
| 26 | DebitorBaseExchangeRate | decimal(16,8) | YES | - | CODE-BACKED | Market exchange rate for the debitor's currency conversion. |
| 27 | DebitorExchangeFee | decimal(16,8) | YES | - | CODE-BACKED | Fee/spread applied to the debitor-side currency conversion. |
| 28 | DebitorExchangeRate | decimal(16,8) | YES | - | CODE-BACKED | Effective exchange rate applied to the debitor side. Debitor amount = Amount * DebitorExchangeRate (approximately). |
| 29 | HoldReferenceID | varchar(100) | YES | - | CODE-BACKED | Provider-side reference ID for the hold/reserve operation. Used to release or settle held funds. Populated during HoldInitiated step. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GroupID | MoneyBus.TransactionsGroup | Implicit FK | Links this transaction to its parent group for multi-leg operations |
| CreditorTypeID | Dictionary.AccountTypes | Implicit Lookup | Account type receiving funds |
| DebitorTypeID | Dictionary.AccountTypes | Implicit Lookup | Account type sending funds |
| StatusID | Dictionary.TransactionStatuses | Implicit Lookup | High-level lifecycle state |
| StatusReasonID | Dictionary.TransactionStatusReasons | Implicit Lookup | Detailed pipeline step |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MoneyBus.Containers | TransactionID | Implicit FK | Links container/metadata blobs to the parent transaction |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.Transactions (table)
└── MoneyBus.TransactionsGroup (table) [via GroupID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.TransactionsGroup | Table | GroupID references TransactionsGroup.ID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.Containers | Table | TransactionID references Transactions.ID |
| MoneyBus.TransactionAdd | Stored Procedure | Writer - creates single transaction |
| MoneyBus.TransactionGet | Stored Procedure | Reader - retrieves by ID with partition optimization |
| MoneyBus.TransactionUpdate | Stored Procedure | Modifier - updates status, exchange rates, references |
| MoneyBus.TransactionsGetByParams | Stored Procedure | Reader - retrieves by GCID + creditor/debitor type + optional status |
| MoneyBus.TransactionsAndGroupAdd | Stored Procedure | Writer - batch inserts transactions with group |
| MoneyBus.UserTransactionsGet | Stored Procedure | Reader - retrieves user's transactions with time/status filters |
| MoneyBus.ALERT_ConsecutiveTransactionFailuresAlert | Stored Procedure | Reader - scans last 24h for consecutive failure patterns |
| History.MoneyBusTransactions | Table | System-versioning history table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Transactions | CLUSTERED PK | ID ASC, PartitionCol ASC | - | - | Active (DATA_COMPRESSION=PAGE, partitioned on PS_Transactions) |
| IX_Transactions_Created | NONCLUSTERED | Created ASC | - | - | Active |
| IX_Transactions_GCID | NONCLUSTERED | GCID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Transactions | PRIMARY KEY | Composite clustered key (ID, PartitionCol) - partitioned across 100 buckets |
| DF_Transactions_Created | DEFAULT | GETDATE() for Created |
| DF_Transactions__Modified | DEFAULT | GETDATE() for Modified |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.MoneyBusTransactions |

---

## 8. Sample Queries

### 8.1 Get transaction with all lookups resolved (partition-optimized)
```sql
SELECT t.ID, t.GCID, t.Amount, t.CurrencyID, t.FlowID,
       ct.Name AS CreditorType, dt.Name AS DebitorType,
       ts.Name AS Status, tsr.Name AS StatusReason,
       t.ExtraData
FROM MoneyBus.Transactions t WITH (NOLOCK)
JOIN Dictionary.AccountTypes ct WITH (NOLOCK) ON ct.ID = t.CreditorTypeID
JOIN Dictionary.AccountTypes dt WITH (NOLOCK) ON dt.ID = t.DebitorTypeID
JOIN Dictionary.TransactionStatuses ts WITH (NOLOCK) ON ts.ID = t.StatusID
LEFT JOIN Dictionary.TransactionStatusReasons tsr WITH (NOLOCK) ON tsr.ID = t.StatusReasonID
WHERE t.ID = @TransactionID AND t.PartitionCol = @TransactionID % 100;
```

### 8.2 Find all transactions in a group with their roles
```sql
SELECT t.ID, t.CreditorTypeID, t.DebitorTypeID, t.Amount, t.CurrencyID, t.StatusID,
       ct.Name AS CreditTo, dt.Name AS DebitFrom
FROM MoneyBus.Transactions t WITH (NOLOCK)
JOIN Dictionary.AccountTypes ct WITH (NOLOCK) ON ct.ID = t.CreditorTypeID
JOIN Dictionary.AccountTypes dt WITH (NOLOCK) ON dt.ID = t.DebitorTypeID
WHERE t.GroupID = @GroupID
ORDER BY t.ID;
```

### 8.3 View transaction history (all state changes) using temporal query
```sql
SELECT ID, StatusID, StatusReasonID, Modified, ValidFrom, ValidTo
FROM MoneyBus.Transactions
FOR SYSTEM_TIME ALL
WHERE ID = @TransactionID AND PartitionCol = @TransactionID % 100
ORDER BY ValidFrom;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 29 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.Transactions | Type: Table | Source: MoneyBusDB/MoneyBus/Tables/MoneyBus.Transactions.sql*
