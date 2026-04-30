# Trade.ReopenOperationCancel

> Cancels a pending reopen operation by marking it as canceled (IsExecuted=2) in Trade.ReopenOperation and archiving any unexecuted child records to history tables.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ReopenOperationID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ReopenOperationCancel terminates a pending reopen operation that has not yet been executed. It marks the parent Trade.ReopenOperation row as IsExecuted=2 (canceled) and is intended to archive the child position or mirror rows from the live queue tables (Trade.PositionToReopen or Trade.MirrorToReopen) into history tables with a "Reopen Operation Canceled" reason.

This procedure exists to provide a clean cancellation path in the reopen workflow. When a reopen operation is no longer needed (e.g., the original error was resolved by other means, approval was denied, or the operation was created in error), it must be marked as canceled so it is not inadvertently executed. The history archive provides audit trail of what was canceled.

Data flow: Called by back-office tools when an operator decides not to proceed with a reopen operation. The caller must supply both @ReopenOperationID and @ReopenOperationType so the procedure knows which child table to clean up. However, see Business Logic section for a known code defect.

---

## 2. Business Logic

### 2.1 Child Record Archival by Type

**What**: Depending on the reopen type, pending child records are archived to history tables before the parent is marked as canceled.

**Columns/Parameters Involved**: `@ReopenOperationID`, `@ReopenOperationType`

**Rules**:
- @ReopenOperationType = 1 (Position): DELETE from Trade.PositionToReopen, OUTPUT to History.PositionToReopen with Result=0 and FailReason='Reopen Operation Canceled'.
- @ReopenOperationType = 2 (Mirror): DELETE from Trade.MirrorToReopen, OUTPUT to History.MirrorToReopen with Result=0 and FailReason='Reopen Operation Canceled'.
- After child records are archived (or skipped if none exist): UPDATE Trade.ReopenOperation SET IsExecuted=2 WHERE ReopenOperationID=@ReopenOperationID.
- IsExecuted=2 is the canceled state (per Trade.ReopenOperation lifecycle: 0=pending, 1=executed, 2=canceled).

### 2.2 CODE DEFECT - Conditional Logic Bug

**What**: The IF conditions compare @ReopenOperationID against literal values 1 and 2, instead of comparing @ReopenOperationType. This means the child-record archive logic NEVER runs for most operations.

**Columns/Parameters Involved**: `@ReopenOperationID`, `@ReopenOperationType`

**Rules**:
- The code reads: `IF (@ReopenOperationID = 1)` with comment "--Reopen Position" and `IF (@ReopenOperationID = 2)` with comment "--Reopen Mirror"
- The intent was: `IF (@ReopenOperationType = 1)` and `IF (@ReopenOperationType = 2)` (based on comments and the parameter name @ReopenOperationType)
- In practice: @ReopenOperationID is an IDENTITY value that is almost never 1 or 2. So the DELETE/OUTPUT blocks are dead code for all practical purposes.
- The only reliable effect of this procedure is: UPDATE Trade.ReopenOperation SET IsExecuted=2 (which runs unconditionally).
- Child records (Trade.PositionToReopen, Trade.MirrorToReopen) are NOT cleaned up for operations with ID > 2. This is a known defect from the 2018 RD 6136 implementation.

**Diagram**:
```
Trade.ReopenOperationCancel(@ReopenOperationID, @ReopenOperationType)
    |
    +-- IF (@ReopenOperationID = 1) [ALMOST NEVER TRUE - should be @ReopenOperationType]
    |       DELETE Trade.PositionToReopen -> History.PositionToReopen (FailReason='Canceled')
    |
    +-- IF (@ReopenOperationID = 2) [ALMOST NEVER TRUE - should be @ReopenOperationType]
    |       DELETE Trade.MirrorToReopen -> History.MirrorToReopen (FailReason='Canceled')
    |
    +-- UPDATE Trade.ReopenOperation SET IsExecuted=2 [ALWAYS RUNS]
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ReopenOperationID | INT | NO | - | CODE-BACKED | The ID of the reopen operation to cancel. Used in the UPDATE WHERE clause (always runs) and mistakenly used in IF conditions instead of @ReopenOperationType. |
| 2 | @ReopenOperationType | TINYINT | NO | - | CODE-BACKED | The reopen type: 1=Position, 2=Mirror. Intended to control which child table (PositionToReopen or MirrorToReopen) gets archived. Due to a code defect, this parameter is received but NOT used in the IF conditions - the conditions compare @ReopenOperationID instead. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ReopenOperationID | Trade.ReopenOperation | Modifier (UPDATE) | Sets IsExecuted=2 (canceled) for the specified operation. Always executes. |
| @ReopenOperationID | Trade.PositionToReopen | Deleter (DELETE) | Archives position child records to History.PositionToReopen. Only runs if @ReopenOperationID=1 (code defect). |
| @ReopenOperationID | Trade.MirrorToReopen | Deleter (DELETE) | Archives mirror child records to History.MirrorToReopen. Only runs if @ReopenOperationID=2 (code defect). |
| (query) | History.PositionToReopen | Writer (INSERT via OUTPUT) | Archives canceled position records with FailReason='Reopen Operation Canceled'. |
| (query) | History.MirrorToReopen | Writer (INSERT via OUTPUT) | Archives canceled mirror records with FailReason='Reopen Operation Canceled'. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by back-office tools for reopen operation cancellation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ReopenOperationCancel (procedure)
├── Trade.ReopenOperation (table)
├── Trade.PositionToReopen (table)
├── Trade.MirrorToReopen (table)
├── History.PositionToReopen (table)
└── History.MirrorToReopen (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ReopenOperation | Table | UPDATE - sets IsExecuted=2 (canceled). |
| Trade.PositionToReopen | Table | DELETE with OUTPUT - archives position child records (conditional on defective @ReopenOperationID=1 check). |
| Trade.MirrorToReopen | Table | DELETE with OUTPUT - archives mirror child records (conditional on defective @ReopenOperationID=2 check). |
| History.PositionToReopen | Table | INSERT via OUTPUT - receives archived canceled position records. |
| History.MirrorToReopen | Table | INSERT via OUTPUT - receives archived canceled mirror records. |

### 6.2 Objects That Depend On This

No dependents found. Called directly by back-office tools.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Note: Modified in 2018 by Mor for RD 6136 (Reopen Mirror support) - the code defect was introduced at that time.

---

## 8. Sample Queries

### 8.1 Cancel a reopen operation (marks as canceled; child cleanup unreliable due to defect)

```sql
EXEC Trade.ReopenOperationCancel
    @ReopenOperationID = 42,
    @ReopenOperationType = 1;  -- 1=Position, 2=Mirror
-- IsExecuted set to 2; child records NOT removed due to code defect (unless ID=1 or ID=2)
```

### 8.2 Manually clean up child records after cancel (workaround for defect)

```sql
-- For position-type reopen operation:
DELETE ptr
OUTPUT deleted.ReopenOperationID, deleted.CID, deleted.ClosedPositionID, 0,
       deleted.RequestOccurred, 0, 'Reopen Operation Canceled'
INTO History.PositionToReopen (ReopenOperationID, CID, ClosedPositionID, LevelID,
                               RequestReopenOccurred, Result, FailReason)
FROM Trade.PositionToReopen ptr WITH (NOLOCK)
WHERE ReopenOperationID = 42;
```

### 8.3 Verify cancellation status

```sql
SELECT ReopenOperationID, IsExecuted, Occurred, UserName
FROM Trade.ReopenOperation WITH (NOLOCK)
WHERE ReopenOperationID = 42;
-- IsExecuted=2 = canceled
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ReopenOperationCancel | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ReopenOperationCancel.sql*
