# MoneyBus.TransactionsTable_New

> Table-valued parameter type that mirrors the MoneyBus.Transactions table structure, used to pass a batch of transaction records into stored procedures for atomic multi-transaction inserts.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | ID (BIGINT) - mirrors Transactions.ID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MoneyBus.TransactionsTable_New is a table-valued parameter type that mirrors the column structure of MoneyBus.Transactions. It enables atomic batch insertion of multiple transaction records in a single database call, ensuring that a group of related transactions (e.g., a debit from one account and a credit to another) are created together within the same database operation.

This type exists to support the "transactions and group" creation pattern where the application needs to insert multiple transactions belonging to the same TransactionsGroup in a single atomic operation. Without it, the application would need to make individual TransactionAdd calls, losing atomicity and creating a window where partial transaction sets could exist.

The application populates a collection of transaction records (each with creditor/debitor types, amounts, currencies, exchange rates, etc.) and passes the entire batch to TransactionsAndGroupAdd. That procedure creates the group first, then bulk-inserts all transactions with the new GroupID, and returns the inserted records with their auto-generated IDs.

---

## 2. Business Logic

### 2.1 Batch Transaction Creation Pattern

**What**: Enables atomic insertion of multiple related transactions as a single unit of work.

**Columns/Parameters Involved**: `ID`, `GroupID`, `CreditorTypeID`, `DebitorTypeID`, `StatusID`, `Amount`, `CurrencyID`

**Rules**:
- The ID column is nullable in the type (unlike the Transactions table) because IDs are assigned by IDENTITY during INSERT - the caller does not provide them
- GroupID is nullable in the type because the procedure assigns the GroupID after creating the TransactionsGroup
- All monetary columns (Amount, exchange rates) must be pre-calculated by the application before passing to the type
- The procedure outputs the same type structure back with the assigned IDs, allowing the caller to map back to its domain objects

**Diagram**:
```
Application builds TransactionsTable_New
    |
    v
TransactionsAndGroupAdd
    |
    +-- 1. INSERT TransactionsGroup -> get GroupID
    |
    +-- 2. INSERT INTO Transactions SELECT FROM @TranTbl (with GroupID)
    |
    +-- 3. OUTPUT inserted rows into @InsertedTranTbl (with real IDs)
    |
    v
Return @InsertedTranTbl to caller
```

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | YES | - | CODE-BACKED | Transaction identifier. NULL on input (assigned by IDENTITY on INSERT). Populated in the output result set so the caller can map back to its domain objects. |
| 2 | GCID | bigint | YES | - | CODE-BACKED | Global Customer ID - identifies the user who owns this transaction. Passed through from the application to MoneyBus.Transactions.GCID. |
| 3 | Created | datetime | YES | - | CODE-BACKED | Transaction creation timestamp. If NULL, TransactionsAndGroupAdd defaults to GETUTCDATE(). |
| 4 | CreditorTypeID | int | YES | - | CODE-BACKED | Account type receiving funds: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. See [Account Type](../../_glossary.md#account-type). (Dictionary.AccountTypes) |
| 5 | DebitorTypeID | int | YES | - | CODE-BACKED | Account type sending funds: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. See [Account Type](../../_glossary.md#account-type). (Dictionary.AccountTypes) |
| 6 | StatusID | int | YES | - | CODE-BACKED | Transaction status: 1=InProcess, 2=Success, 3=Decline, 4=Technical, 5=Canceled. See [Transaction Status](../../_glossary.md#transaction-status). (Dictionary.TransactionStatuses) |
| 7 | GroupID | bigint | YES | - | CODE-BACKED | Transaction group identifier. NULL on input - assigned by the procedure after creating the TransactionsGroup record. Links related transactions together. |
| 8 | ReferenceID | nvarchar(500) | YES | - | CODE-BACKED | External reference identifier from the calling system. Used for idempotency and cross-system correlation. |
| 9 | Amount | money | YES | - | CODE-BACKED | Transaction amount in the currency specified by CurrencyID. Pre-calculated by the application. |
| 10 | CurrencyID | int | YES | - | CODE-BACKED | Currency of the transaction amount. Maps to an external currency reference. |
| 11 | Modified | datetime | YES | - | CODE-BACKED | Last modification timestamp. If NULL, TransactionsAndGroupAdd defaults to GETUTCDATE(). |
| 12 | CreditorAccountID | nvarchar(500) | YES | - | CODE-BACKED | Identifier of the creditor's specific account within the creditor account type. |
| 13 | DebitorAccountID | nvarchar(500) | YES | - | CODE-BACKED | Identifier of the debitor's specific account within the debitor account type. |
| 14 | StatusReasonID | int | YES | - | CODE-BACKED | Detailed sub-state within the status lifecycle: 1=Created, 2=Success, 3=Held, etc. See [Transaction Status Reason](../../_glossary.md#transaction-status-reason). (Dictionary.TransactionStatusReasons) |
| 15 | CreditorReferenceID | varchar(100) | YES | - | CODE-BACKED | Provider-side reference ID for the credit leg of the transaction. Populated after credit initiation. |
| 16 | DebitorReferenceID | varchar(100) | YES | - | CODE-BACKED | Provider-side reference ID for the debit leg of the transaction. Populated after debit initiation. |
| 17 | FlowID | int | YES | - | CODE-BACKED | Identifies the specific business flow or workflow that created this transaction. Used for routing and reporting. |
| 18 | ExtraData | nvarchar(4000) | YES | - | CODE-BACKED | JSON blob for extensible metadata that does not warrant its own column. Schema varies by flow type. |
| 19 | CreditorBaseExchangeRate | decimal(16,8) | YES | - | CODE-BACKED | Base exchange rate applied to the creditor side of the transaction. Used when creditor currency differs from the transaction currency. |
| 20 | CreditorExchangeFee | decimal(16,8) | YES | - | CODE-BACKED | Fee applied to the creditor-side currency exchange, as a rate. |
| 21 | CreditorExchangeRate | decimal(16,8) | YES | - | CODE-BACKED | Final exchange rate (base + fee) applied to the creditor side. |
| 22 | DebitorBaseExchangeRate | decimal(16,8) | YES | - | CODE-BACKED | Base exchange rate applied to the debitor side of the transaction. |
| 23 | DebitorExchangeFee | decimal(16,8) | YES | - | CODE-BACKED | Fee applied to the debitor-side currency exchange, as a rate. |
| 24 | DebitorExchangeRate | decimal(16,8) | YES | - | CODE-BACKED | Final exchange rate (base + fee) applied to the debitor side. |
| 25 | HoldReferenceID | varchar(100) | YES | - | CODE-BACKED | Provider-side reference ID for the hold/reserve operation. Used to release or settle the held funds. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. It is a structural mirror of MoneyBus.Transactions - the column definitions match that table but carry no FK constraints (table types cannot have FKs).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MoneyBus.TransactionsAndGroupAdd | @TranTbl parameter | Parameter Type | Input batch of transaction records to insert atomically with a new TransactionsGroup |
| MoneyBus.TransactionsAndGroupAdd | @InsertedTranTbl variable | Local Variable Type | Holds the OUTPUT of the INSERT with auto-generated IDs for return to caller |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.TransactionsAndGroupAdd | Stored Procedure | @TranTbl READONLY parameter + @InsertedTranTbl local variable |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (collation) | COLLATE | String columns use SQL_Latin1_General_CP1_CI_AS - ensures compatibility with the Transactions table's collation |

---

## 8. Sample Queries

### 8.1 Populate and pass a batch of two transactions
```sql
DECLARE @TranTbl MoneyBus.TransactionsTable_New;
INSERT INTO @TranTbl (GCID, CreditorTypeID, DebitorTypeID, StatusID, Amount, CurrencyID, StatusReasonID)
VALUES
    (12345, 1, 3, 1, 500.00, 1, 1),   -- Trading <- IBAN (deposit)
    (12345, 3, 1, 1, 500.00, 1, 1);   -- IBAN <- Trading (mirror)

EXEC MoneyBus.TransactionsAndGroupAdd
    @TranTbl = @TranTbl,
    @GCID = 12345,
    @ReferenceID = 'DEP-2026-001';
```

### 8.2 Populate with exchange rate data for cross-currency transfer
```sql
DECLARE @TranTbl MoneyBus.TransactionsTable_New;
INSERT INTO @TranTbl (GCID, CreditorTypeID, DebitorTypeID, StatusID, Amount, CurrencyID,
    StatusReasonID, CreditorBaseExchangeRate, CreditorExchangeRate, DebitorBaseExchangeRate, DebitorExchangeRate)
VALUES
    (67890, 1, 3, 1, 1000.00, 2, 1, 1.08500000, 1.08650000, 0.92165899, 0.92027234);

EXEC MoneyBus.TransactionsAndGroupAdd
    @TranTbl = @TranTbl,
    @GCID = 67890,
    @ReferenceID = 'FX-TRANSFER-001',
    @InitiatorAccountTypeId = 3;
```

### 8.3 Inspect the type structure
```sql
SELECT c.name, TYPE_NAME(c.system_type_id) AS data_type, c.max_length, c.is_nullable
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
WHERE tt.schema_id = SCHEMA_ID('MoneyBus') AND tt.name = 'TransactionsTable_New'
ORDER BY c.column_id;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 25 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/2*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.TransactionsTable_New | Type: User Defined Type | Source: MoneyBusDB/MoneyBus/User Defined Types/MoneyBus.TransactionsTable_New.sql*
