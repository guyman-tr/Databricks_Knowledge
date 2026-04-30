# Trade.SetAdminPositionFailInfo

> Marks an AdminPositionLog entry as failed (State=4) by OrderID, recording the failure reason, error code, and execution timestamp; raises an error if no matching entry is found.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID BIGINT - the order being marked as failed in AdminPositionLog |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Admin positions are manual position operations created by eToro operations staff, tracked in `Trade.AdminPositionLog`. Each admin position request goes through a state lifecycle (1=pending, 2=in-progress, 3=done, 4=failed).

This procedure handles the **failure path**: when an admin position operation encounters an error during execution, this procedure is called to record the failure details and move the entry to terminal state 4. It captures:
- **FailReason**: Human-readable description of why it failed
- **ErrorCode**: Numeric error code for categorization/monitoring
- **ExecutionOccurred**: Timestamp of when the failure was detected

If no matching `AdminPositionLog` entry exists for the given OrderID, the procedure raises an error to signal to the caller that the update was a no-op (which would indicate a data integrity issue).

This procedure is simpler than `Trade.SetAdminPositionState` - it targets by `OrderID` (not RequestID), does not check for already-processed state, and always writes the failure data. It is intended for use when the order execution itself has returned an error code.

---

## 2. Business Logic

### 2.1 Failure State Transition

**What**: Marks the AdminPositionLog entry as failed with diagnostic information.

**Columns/Parameters Involved**: `Trade.AdminPositionLog.State`, `Trade.AdminPositionLog.FailReason`, `Trade.AdminPositionLog.ErrorCode`, `Trade.AdminPositionLog.ExecutionOccurred`

**Rules**:
- UPDATE Trade.AdminPositionLog WHERE OrderID = @OrderID
- Sets State = 4 (failed)
- Sets FailReason = @FailReason (descriptive error message)
- Sets ErrorCode = @ErrorCode (numeric error code)
- Sets ExecutionOccurred = GETUTCDATE() (timestamp of failure)
- If @@rowcount = 0 -> RAISERROR: 'SP Trade.SetAdminPositionFailInfo, Trade.AdminPositionLog entry not found'

**State reference**:
| State | Meaning |
|-------|---------|
| 1 | Pending |
| 2 | In-progress |
| 3 | Done (success) |
| 4 | Failed (terminal) |

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | BIGINT | NO | - | CODE-BACKED | The order ID that identifies the AdminPositionLog entry to mark as failed. This is the execution order ID returned when the admin position was submitted. |
| 2 | @FailReason | VARCHAR(MAX) | NO | - | CODE-BACKED | Human-readable description of why the admin position failed. Stored in AdminPositionLog.FailReason for ops team review. |
| 3 | @ErrorCode | INT | NO | - | CODE-BACKED | Numeric error code categorizing the failure. Stored in AdminPositionLog.ErrorCode and used for monitoring/alerting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE | Trade.AdminPositionLog | Modifier | Sets State=4, FailReason, ErrorCode, ExecutionOccurred for the failed order |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - called by admin position execution pipeline when an order fails.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SetAdminPositionFailInfo (procedure)
|- Trade.AdminPositionLog (table - update target)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.AdminPositionLog | Table | Updated to State=4 with failure details; RAISERROR if no matching OrderID |

### 6.2 Objects That Depend On This

No dependents found in this phase - called by admin position execution services on failure.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Entry must exist | Validation | @@ROWCOUNT=0 -> RAISERROR - ensures OrderID maps to a real entry |
| No state check | Logic | Unlike SetAdminPositionState, this does NOT check current state before updating - always overwrites with State=4 |

---

## 8. Sample Queries

### 8.1 Mark an admin position as failed

```sql
EXEC Trade.SetAdminPositionFailInfo
    @OrderID = 987654321,
    @FailReason = 'Insufficient margin to execute position',
    @ErrorCode = 1042
```

### 8.2 Check recent failed admin positions

```sql
SELECT OrderID, CID, AdminPositionRequestID, State,
    FailReason, ErrorCode, ExecutionOccurred
FROM Trade.AdminPositionLog WITH (NOLOCK)
WHERE State = 4
ORDER BY ExecutionOccurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SetAdminPositionFailInfo | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SetAdminPositionFailInfo.sql*
