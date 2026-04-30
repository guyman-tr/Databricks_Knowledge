# Trade.MirrorsReopen

> Batch orchestrator that reopens a set of closed CopyTrader mirrors associated with a reopen operation, iterating via cursor and calling Trade.MirrorReopen for each one.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ReopenOperationID (the reopen batch to process) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a CopyTrader mirror relationship is closed (e.g. a user stops copying a Popular Investor), all associated positions are closed. The "reopen" feature (RD 6136, April 2018) allows those mirrors to be reopened - effectively resuming the copy relationship and re-entering positions. `Trade.MirrorsReopen` is the batch entry point that processes a `ReopenOperationID`: it finds all mirrors flagged for reopening under that operation (where ReopenTypeID = 2) and calls `Trade.MirrorReopen` for each one.

The procedure exists because mirror reopening can involve many individual mirror records that must each be processed in sequence. The cursor pattern allows per-mirror error isolation - if one mirror fails to reopen, the batch continues for the remaining mirrors without aborting.

Data flow: A `ReopenOperationID` is created upstream and records are written to `Trade.MirrorToReopen`. This procedure reads those records (joined to `Trade.ReopenOperation` for operation-level metadata), calls `Trade.MirrorReopen` for each one within a TRY/CATCH, and finally marks the operation as executed (`IsExecuted = 1`).

---

## 2. Business Logic

### 2.1 Mirror Batch Reopening

**What**: Iterates over all mirrors queued for reopening under a specific ReopenOperationID and reopens each one.

**Columns/Parameters Involved**: `Trade.MirrorToReopen.ClosedMirrorID`, `Trade.MirrorToReopen.CID`, `Trade.MirrorToReopen.ValidateUserBalance`, `Trade.MirrorToReopen.AllowUpdateMirrorSL`, `Trade.ReopenOperation.ReopenTypeID`

**Rules**:
- Only processes records where `ReopenTypeID = 2` (specific reopen type within the operation)
- Ordered by ClosedMirrorID ASC for deterministic processing
- Each mirror is processed by calling `Trade.MirrorReopen` with ClosedMirrorID, CID, ValidateUserBalance, and AllowUpdateMirrorSL
- Per-mirror TRY/CATCH: failures are silently caught (no error is recorded or returned)
- After all mirrors processed: `Trade.ReopenOperation.IsExecuted` is set to 1 regardless of individual mirror success/failure

**Diagram**:
```
@ReopenOperationID
  -> Cursor: MirrorToReopen JOIN ReopenOperation WHERE ReopenOperationID=@id AND ReopenTypeID=2
  -> For each (ClosedMirrorID, CID, ValidateUserBalance, AllowUpdateMirrorSL):
       TRY: EXEC Trade.MirrorReopen ...
       CATCH: (silent - no error tracking)
  -> UPDATE ReopenOperation SET IsExecuted=1 WHERE ReopenOperationID=@id AND ReopenTypeID=2
```

### 2.2 Operation Completion Mark

**What**: Marks the reopen operation as fully executed after all mirrors are processed.

**Columns/Parameters Involved**: `Trade.ReopenOperation.IsExecuted`, `Trade.ReopenOperation.ReopenTypeID`

**Rules**:
- `IsExecuted = 1` is set unconditionally after the cursor completes
- This update is scoped to `ReopenTypeID = 2` (same scope as the cursor)
- The operation is considered "executed" even if some individual mirrors failed (since errors are caught silently)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ReopenOperationID | INT | NO | - | CODE-BACKED | Identifies the batch reopen operation to execute. Joins to Trade.MirrorToReopen and Trade.ReopenOperation to retrieve the list of mirrors to reopen, filtered to ReopenTypeID = 2. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ReopenOperationID | Trade.MirrorToReopen | JOIN (READ) | Source of mirrors to reopen - provides ClosedMirrorID, CID, ValidateUserBalance, AllowUpdateMirrorSL |
| @ReopenOperationID | Trade.ReopenOperation | JOIN (READ/WRITE) | Reads ReopenTypeID; updated IsExecuted=1 after processing |
| Internal | Trade.MirrorReopen | EXEC (CALL) | Per-mirror reopen handler - processes each ClosedMirrorID |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.MirrorsReopen (procedure)
+-- Trade.MirrorToReopen (table) [READ - mirrors queued for reopening]
+-- Trade.ReopenOperation (table) [READ/WRITE - operation metadata, IsExecuted flag]
+-- Trade.MirrorReopen (procedure) [EXEC - individual mirror reopen]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.MirrorToReopen | Table | Cursor source - provides the list of mirrors to process for the given ReopenOperationID and ReopenTypeID=2 |
| Trade.ReopenOperation | Table | Joined for ReopenTypeID filter; updated to IsExecuted=1 after batch completes |
| Trade.MirrorReopen | Stored Procedure | Called per mirror to perform the actual reopen logic (already documented in Batch 44) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ReopenTypeID = 2 filter | Business scope | Only mirrors of ReopenTypeID=2 are processed - other reopen types handled by different procedures |
| Silent CATCH | Error handling | Per-mirror failures are caught and discarded - the batch never aborts mid-run due to a single mirror failure |

---

## 8. Sample Queries

### 8.1 Check pending reopen operations for a given ID
```sql
SELECT
    mtr.ClosedMirrorID,
    mtr.CID,
    mtr.ValidateUserBalance,
    mtr.AllowUpdateMirrorSL,
    ro.ReopenTypeID,
    ro.IsExecuted
FROM Trade.MirrorToReopen mtr WITH (NOLOCK)
JOIN Trade.ReopenOperation ro WITH (NOLOCK)
    ON mtr.ReopenOperationID = ro.ReopenOperationID
WHERE mtr.ReopenOperationID = 12345
  AND ro.ReopenTypeID = 2
ORDER BY mtr.ClosedMirrorID ASC;
```

### 8.2 Check if a reopen operation has been executed
```sql
SELECT
    ReopenOperationID,
    ReopenTypeID,
    IsExecuted
FROM Trade.ReopenOperation WITH (NOLOCK)
WHERE ReopenOperationID = 12345;
```

### 8.3 Execute a reopen operation
```sql
EXEC Trade.MirrorsReopen @ReopenOperationID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (1,5,8,9B,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (MirrorReopen) | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.MirrorsReopen | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.MirrorsReopen.sql*
