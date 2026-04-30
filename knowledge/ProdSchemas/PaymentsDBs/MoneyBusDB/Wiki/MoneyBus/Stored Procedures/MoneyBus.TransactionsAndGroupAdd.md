# MoneyBus.TransactionsAndGroupAdd

> Atomically creates a transaction group and bulk-inserts multiple transactions from a table-valued parameter in a single operation, returning the inserted transactions with their auto-generated IDs.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns inserted transactions result set with generated IDs |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MoneyBus.TransactionsAndGroupAdd is the atomic batch creation procedure for the MoneyBus transaction system. It creates a TransactionsGroup and inserts all related transactions in a single database call, ensuring atomicity - either the entire group with all transactions is created, or nothing is. This is the primary path for multi-leg transfers where a single business operation (e.g., a deposit) creates both a debit and a credit transaction.

The caller populates a MoneyBus.TransactionsTable_New table-valued parameter with all the transactions, and the procedure: (1) creates the group, (2) captures the group ID via SCOPE_IDENTITY(), (3) bulk-inserts all transactions with the new GroupID using INSERT...SELECT FROM @TranTbl, (4) uses OUTPUT...INTO to capture the inserted rows with their auto-generated IDs, and (5) returns those rows to the caller. TRY/CATCH wraps the entire operation.

---

## 2. Business Logic

### 2.1 Atomic Group + Transactions Creation

**What**: Ensures all transactions in a multi-leg operation are created together with their parent group.

**Columns/Parameters Involved**: `@TranTbl`, `@GCID`, `@ReferenceID`, `@InitiatorAccountTypeId`

**Rules**:
- The group is created first (INSERT INTO TransactionsGroup)
- GroupID from SCOPE_IDENTITY() is injected into all transactions during the bulk INSERT
- Created/Modified columns use ISNULL(@col, GETUTCDATE()) - defaults to UTC if not provided by caller
- OUTPUT INSERTED.* captures the actual inserted values including auto-generated IDs
- The OUTPUT goes into @InsertedTranTbl (same type as input) and is returned as a result set
- TRY/CATCH with RAISERROR ensures failures propagate cleanly

**Diagram**:
```
@TranTbl (N rows, no IDs, no GroupID)
    |
    v
[1] INSERT TransactionsGroup -> @GroupID = SCOPE_IDENTITY()
    |
    v
[2] INSERT INTO Transactions (... GroupID = @GroupID ...)
    SELECT ... FROM @TranTbl
    OUTPUT INSERTED.* INTO @InsertedTranTbl
    |
    v
[3] SELECT * FROM @InsertedTranTbl (returned to caller with real IDs)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TranTbl | MoneyBus.TransactionsTable_New (TVP) | READONLY | - | CODE-BACKED | Batch of transactions to insert. All columns except ID and GroupID should be populated. See [MoneyBus.TransactionsTable_New](../User Defined Types/MoneyBus.TransactionsTable_New.md). |
| 2 | @Created | datetime | YES | NULL | CODE-BACKED | Optional group creation timestamp. Defaults to GETUTCDATE(). |
| 3 | @ReferenceID | nvarchar(500) | YES | NULL | CODE-BACKED | External reference for the group. Part of GCID+ReferenceID unique constraint on TransactionsGroup. |
| 4 | @GCID | bigint | NO | - | CODE-BACKED | Customer ID for the group. Required. |
| 5 | @InitiatorAccountTypeId | int | YES | NULL | CODE-BACKED | Account type that initiated the operation: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @TranTbl | MoneyBus.TransactionsTable_New | Parameter Type | Input batch of transactions |
| (INSERT target 1) | MoneyBus.TransactionsGroup | Writer | Creates the parent group |
| (INSERT target 2) | MoneyBus.Transactions | Writer | Bulk-inserts all transactions with the new GroupID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.TransactionsAndGroupAdd (procedure)
├── MoneyBus.TransactionsGroup (table) [INSERT INTO]
├── MoneyBus.Transactions (table) [INSERT INTO ... SELECT FROM @TranTbl]
└── MoneyBus.TransactionsTable_New (type) [@TranTbl parameter]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.TransactionsGroup | Table | INSERT INTO - creates parent group |
| MoneyBus.Transactions | Table | INSERT INTO - bulk inserts transactions |
| MoneyBus.TransactionsTable_New | User Defined Type | @TranTbl READONLY parameter + @InsertedTranTbl variable |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Create a deposit group with two legs
```sql
DECLARE @TranTbl MoneyBus.TransactionsTable_New;
INSERT INTO @TranTbl (GCID, CreditorTypeID, DebitorTypeID, StatusID, Amount, CurrencyID, StatusReasonID, FlowID)
VALUES
    (12345, 1, 3, 1, 500.00, 2, 1, 1),   -- IBAN -> Trading (deposit)
    (12345, 3, 1, 1, 500.00, 2, 1, 1);   -- Trading -> IBAN (mirror)

EXEC MoneyBus.TransactionsAndGroupAdd
    @TranTbl = @TranTbl, @GCID = 12345,
    @ReferenceID = 'DEP-2026-001', @InitiatorAccountTypeId = 3;
```

### 8.2 Create with exchange rates
```sql
DECLARE @TranTbl MoneyBus.TransactionsTable_New;
INSERT INTO @TranTbl (GCID, CreditorTypeID, DebitorTypeID, StatusID, Amount, CurrencyID,
    StatusReasonID, CreditorBaseExchangeRate, CreditorExchangeRate)
VALUES (67890, 1, 3, 1, 1000.00, 1, 1, 0.84790313, 0.84162332);

EXEC MoneyBus.TransactionsAndGroupAdd
    @TranTbl = @TranTbl, @GCID = 67890,
    @ReferenceID = 'FX-001', @InitiatorAccountTypeId = 1;
```

### 8.3 Verify the created group and transactions
```sql
-- After execution, results show inserted rows with IDs
-- Verify group:
SELECT TOP 1 * FROM MoneyBus.TransactionsGroup WITH (NOLOCK) ORDER BY ID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.TransactionsAndGroupAdd | Type: Stored Procedure | Source: MoneyBusDB/MoneyBus/Stored Procedures/MoneyBus.TransactionsAndGroupAdd.sql*
