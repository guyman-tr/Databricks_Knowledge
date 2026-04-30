# Trade.SetAdminPositionState

> Implements the AdminPositionLog state machine for transitions to State=2 (in-progress) and State=4 (failed) with idempotency guards, returning a BIT output indicating whether the transition was applied or rejected due to a concurrent state change.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RequestID UNIQUEIDENTIFIER, @AdminPositionID BIGINT, @NewState INT - identify and drive the transition |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Admin positions are manual trading operations initiated by eToro operations staff, tracked in `Trade.AdminPositionLog`. Each entry progresses through states: 1=pending, 2=in-progress, 3=done, 4=failed. This procedure is the **controlled state transition handler** for the in-progress (2) and failure (4) states.

The procedure is designed for a **distributed execution environment** where multiple agents may race to process the same request. The idempotency guard checks whether the RequestID+CID combination is already in State 2 or 3 (processing or done) before attempting a transition. If a concurrent agent already claimed the request, this procedure returns `@Res=0` and does nothing, preventing double-processing.

For the State=2 transition, the procedure also validates that exactly one pending entry (State=1) exists for the given RequestID - ambiguous states (0 or >1 pending) return `@Res=0` without making changes.

The transaction ensures the check-then-update is atomic, preventing race conditions between the SELECT and the UPDATE.

---

## 2. Business Logic

### 2.1 Concurrent Processing Guard

**What**: Prevents duplicate processing if another agent already claimed the request.

**Columns/Parameters Involved**: `Trade.AdminPositionLog.State`, `AdminPositionRequestID`, `CID`

**Rules**:
- Pre-check: SELECT AdminPositionRequestIDs WHERE CID=@CID AND AdminPositionRequestID=@RequestID AND State IN (2,3) -> #processedItemsByRequestID
- If #processedItemsByRequestID has rows -> request is already in progress or done -> @Res=0, skip transition (for BOTH NewState=2 and NewState=4)

### 2.2 Transition to State=2 (In-Progress)

**What**: Claims a pending admin position for execution, with exactly-one validation.

**Columns/Parameters Involved**: `State`, `AdminPositionRequestID`, `AdminPositionID`

**Rules** (only if #processedItemsByRequestID is empty):
- Count entries WHERE CID=@CID AND AdminPositionRequestID=@RequestID AND State=1
- If count > 1: @Res=0 (ambiguous - multiple pending entries for same request)
- If count = 0: @Res=0 (no pending entry found)
- If count = 1: UPDATE State=2 WHERE CID=@CID AND AdminPositionRequestID=@RequestID AND AdminPositionID=@AdminPositionID -> @Res=1

### 2.3 Transition to State=4 (Failed)

**What**: Marks all entries for a RequestID as failed with an error code.

**Rules** (only if #processedItemsByRequestID is empty):
- UPDATE State=4, ErrorCode=@ErrorCode WHERE CID=@CID AND AdminPositionRequestID=@RequestID
- Sets @Res=1 (does not validate count; applies to all matching rows for this RequestID)

**Diagram**:
```
Input: @CID, @RequestID, @AdminPositionID, @NewState, @ErrorCode

BEGIN TRAN:
  Check: AdminPositionLog[CID=@CID, RequestID=@RequestID, State IN (2,3)]?
    YES -> @Res=0, COMMIT, return (already processed/in-progress)

  IF @NewState = 2:
    Count State=1 entries for CID+RequestID:
      count > 1 -> @Res=0 (ambiguous)
      count = 0 -> @Res=0 (not found)
      count = 1 -> UPDATE State=2 WHERE ...AND AdminPositionID=@AdminPositionID
                   @Res=1

  ELSE IF @NewState = 4:
    UPDATE State=4, ErrorCode WHERE CID+RequestID
    @Res=1

COMMIT
```

**State reference**:
| State | Meaning |
|-------|---------|
| 1 | Pending - awaiting processing |
| 2 | In-progress - claimed by an execution agent |
| 3 | Done - successfully completed |
| 4 | Failed - terminal failure |

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | The customer ID whose AdminPositionLog entries are being updated. Used with @RequestID for all queries to scope to the correct customer. |
| 2 | @RequestID | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | The unique request identifier for this admin position batch. Multiple AdminPositionLog entries can share the same RequestID. Used for idempotency checks and state transitions. |
| 3 | @AdminPositionID | BIGINT | NO | - | CODE-BACKED | The specific AdminPositionLog entry to transition to State=2. Only used in the NewState=2 path; ignored for NewState=4 transitions which update all entries for the RequestID. |
| 4 | @NewState | INT | NO | - | CODE-BACKED | The target state. Only 2 (in-progress) and 4 (failed) are handled. Other values produce no update and @Res=0 (no ELSE branch). |
| 5 | @ErrorCode | INT | YES | NULL | CODE-BACKED | Error code to store with State=4 (failed) transitions. NULL for State=2 transitions. Stored in AdminPositionLog.ErrorCode for diagnostics. |
| 6 | @Res | BIT OUTPUT | NO | - | CODE-BACKED | Returns 1 if the state transition was applied successfully; 0 if rejected (request already processed, ambiguous pending entries, not found, or unsupported NewState). Caller must check this value. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Pre-check + UPDATE | Trade.AdminPositionLog | Modifier | Reads for idempotency check; updates State (and ErrorCode for NewState=4) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - called by admin position execution pipeline to manage state transitions.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SetAdminPositionState (procedure)
|- Trade.AdminPositionLog (table - read for guard + update target)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.AdminPositionLog | Table | Pre-check for State IN(2,3) idempotency; count of State=1 entries; UPDATE target |

### 6.2 Objects That Depend On This

No dependents found - called by admin position execution services.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Idempotency guard | Safety | State IN (2,3) pre-check prevents double-processing in concurrent environment |
| Exactly-one validation | Logic | State=2 only applied if exactly 1 pending entry exists for RequestID |
| Transaction | Safety | BEGIN TRANSACTION wraps check + update; prevents TOCTOU race |
| No State=3 transition | Logic | State=3 (done) is NOT handled here - set by a different procedure after successful execution |
| @Res output | Contract | Caller MUST check @Res=1 before assuming transition was applied |
| Unsupported NewState | Logic | Only 2 and 4 are handled; any other NewState value results in @Res not set (implicitly NULL/unset) |

---

## 8. Sample Queries

### 8.1 Transition an admin position to in-progress

```sql
DECLARE @Result BIT
EXEC Trade.SetAdminPositionState
    @CID = 12345,
    @RequestID = '550E8400-E29B-41D4-A716-446655440000',
    @AdminPositionID = 987654,
    @NewState = 2,
    @ErrorCode = NULL,
    @Res = @Result OUTPUT

SELECT @Result AS TransitionApplied  -- 1=success, 0=rejected
```

### 8.2 Mark a request as failed

```sql
DECLARE @Result BIT
EXEC Trade.SetAdminPositionState
    @CID = 12345,
    @RequestID = '550E8400-E29B-41D4-A716-446655440000',
    @AdminPositionID = 987654,
    @NewState = 4,
    @ErrorCode = 2001,
    @Res = @Result OUTPUT

SELECT @Result AS TransitionApplied
```

### 8.3 Check current state distribution for a request

```sql
SELECT State, COUNT(*) AS Count
FROM Trade.AdminPositionLog WITH (NOLOCK)
WHERE AdminPositionRequestID = '550E8400-E29B-41D4-A716-446655440000'
GROUP BY State
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SetAdminPositionState | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SetAdminPositionState.sql*
