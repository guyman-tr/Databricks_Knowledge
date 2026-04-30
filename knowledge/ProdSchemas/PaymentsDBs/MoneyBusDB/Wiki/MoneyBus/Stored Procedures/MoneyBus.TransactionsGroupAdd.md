# MoneyBus.TransactionsGroupAdd

> Creates a new transaction group record for grouping related money transfer legs under a single logical operation, returning the auto-generated group ID.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Stored Procedure |
| **Key Identifier** | OUTPUT @ID - returns the new TransactionsGroup.ID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MoneyBus.TransactionsGroupAdd creates a single record in MoneyBus.TransactionsGroup to establish a logical grouping container for related transactions. This is the standalone group creation path - when the application needs to create the group first and then add transactions separately (as opposed to TransactionsAndGroupAdd which does both atomically).

This procedure exists to support the two-phase group+transaction creation pattern where the caller first creates a group, receives the ID, and then adds individual transactions referencing that group via TransactionAdd. This approach is used when transactions are added incrementally rather than as a pre-built batch.

The caller provides the GCID (customer), optional ReferenceID (for idempotency via the GCID+ReferenceID unique constraint), and optional InitiatorAccountTypeId. The procedure returns the new group ID via the OUTPUT parameter.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple INSERT with default timestamp handling.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | bigint OUTPUT | NO | - | CODE-BACKED | Output parameter returning the auto-generated IDENTITY value (SCOPE_IDENTITY()) of the newly created TransactionsGroup record. Callers use this to set GroupID on subsequent TransactionAdd calls. |
| 2 | @Created | datetime | YES | GETUTCDATE() | CODE-BACKED | Optional creation timestamp. If NULL, defaults to GETUTCDATE(). Allows the caller to provide a specific timestamp for back-dated operations. |
| 3 | @ReferenceID | nvarchar(500) | YES | NULL | CODE-BACKED | External reference identifier (typically a UUID). Combined with GCID in a unique constraint on TransactionsGroup to ensure idempotent group creation. |
| 4 | @GCID | bigint | NO | - | CODE-BACKED | Global Customer ID identifying the user who owns this transaction group. Required. Part of the unique constraint with ReferenceID. |
| 5 | @InitiatorAccountTypeId | int | YES | NULL | CODE-BACKED | Account type that initiated the transfer: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. See [Account Type](../../_glossary.md#account-type). (Dictionary.AccountTypes). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (INSERT target) | MoneyBus.TransactionsGroup | Writer | Inserts a new group record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.TransactionsGroupAdd (procedure)
└── MoneyBus.TransactionsGroup (table) [INSERT INTO]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.TransactionsGroup | Table | INSERT INTO - creates new group records |

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

### 8.1 Create a group and then add a transaction
```sql
DECLARE @GroupID BIGINT;
EXEC MoneyBus.TransactionsGroupAdd
    @ID = @GroupID OUTPUT,
    @GCID = 12345,
    @ReferenceID = 'DEP-2026-001',
    @InitiatorAccountTypeId = 3;

SELECT @GroupID AS NewGroupID;
```

### 8.2 Create a group with explicit timestamp
```sql
DECLARE @GroupID BIGINT;
EXEC MoneyBus.TransactionsGroupAdd
    @ID = @GroupID OUTPUT,
    @Created = '2026-04-15 12:00:00',
    @GCID = 67890,
    @ReferenceID = 'BACKFILL-001';
```

### 8.3 Minimal call (only required parameters)
```sql
DECLARE @GroupID BIGINT;
EXEC MoneyBus.TransactionsGroupAdd @ID = @GroupID OUTPUT, @GCID = 11111;
SELECT @GroupID AS NewGroupID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.TransactionsGroupAdd | Type: Stored Procedure | Source: MoneyBusDB/MoneyBus/Stored Procedures/MoneyBus.TransactionsGroupAdd.sql*
