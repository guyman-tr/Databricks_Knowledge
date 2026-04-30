# Billing.RedeemPayoutProcess_UpdateStatus

> Atomic orchestration of a redeem processing step completion: optionally releases a processing lock (via RedeemPayoutProcess_Abort) and then updates the redeem's status (via RedeemStatusUpdate), all within a single transaction.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ProcessID + @RedeemID + @PositionID + @RedeemStatusID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a payout processing step completes (successfully or not), two things must happen atomically: (1) release the processing lock on the `Billing.RedeemPayoutProcess` record, and (2) advance the redeem's status. `Billing.RedeemPayoutProcess_UpdateStatus` is the transactional orchestrator that does both in a single atomic unit.

If @RedeemProcessType is provided (non-null), it calls `Billing.RedeemPayoutProcess_Abort` to clear the InClosePositionProcess or InTransferUnitsProcess flag. It then always calls `Billing.RedeemStatusUpdate` to apply the new status (validated through the state machine). Everything runs in a TRY/CATCH transaction with ROLLBACK on failure.

Fix RD-6556 (07/05/2019): the @@ROWCOUNT check after the abort call was moved inside the `IF (@RedeemProcessType is not null)` block to prevent false errors when the abort is skipped.

---

## 2. Business Logic

### 2.1 Lock Release + Status Update Orchestration

**What**: Two-step atomic completion of a processing phase.

**Columns/Parameters Involved**: `@RedeemProcessType`, `@CorrelationID`, `@ProcessID`, `@RedeemStatusID`

**Rules**:
- If `@RedeemProcessType IS NOT NULL`: calls `Billing.RedeemPayoutProcess_Abort` with a single-item IDs TVP containing @ProcessID. Raises error if abort returned 0 rows (process not found or correlation mismatch).
- Always: calls `Billing.RedeemStatusUpdate` for @RedeemID + @PositionID + @RedeemStatusID + @RedeemReasonID.
- Wrapped in BEGIN TRAN / COMMIT. ROLLBACK on any error in CATCH.
- Typical call patterns:
  - Close-position success: @RedeemProcessType=1, @RedeemStatusID=6 (PositionClosed)
  - Transfer-units success: @RedeemProcessType=2, @RedeemStatusID=8 (or final completed)
  - Status-only update (no lock to release): @RedeemProcessType=NULL

**Diagram**:
```
BEGIN TRAN
  IF @RedeemProcessType IS NOT NULL:
    EXEC RedeemPayoutProcess_Abort @ProcessID, @CorrelationID, @RedeemProcessType
    IF @@ROWCOUNT = 0 --> RAISERROR (abort failed)
  EXEC RedeemStatusUpdate @RedeemID, @PositionID, @RedeemStatusID, @RedeemReasonID
COMMIT
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProcessID | INT | NO | - | CODE-BACKED | Billing.RedeemPayoutProcess.RedeemPayoutProcessID. Used to build the IDs TVP passed to RedeemPayoutProcess_Abort. |
| 2 | @RedeemID | INT | NO | - | CODE-BACKED | Billing.Redeem.RedeemID. Passed to RedeemStatusUpdate. |
| 3 | @PositionID | BIGINT | NO | - | CODE-BACKED | Trading position ID. Passed to RedeemStatusUpdate as a safety key check. |
| 4 | @RedeemStatusID | INT | NO | - | CODE-BACKED | Target status for the redeem. Validated against Dictionary.RedeemStatusStateMachine inside RedeemStatusUpdate. |
| 5 | @RedeemReasonID | INT | YES | NULL | CODE-BACKED | Optional reason code for the status change. Passed through to RedeemStatusUpdate. |
| 6 | @RedeemProcessType | INT | YES | NULL | CODE-BACKED | Which processing lock to release: 1 = InClosePositionProcess, 2 = InTransferUnitsProcess. NULL = no lock to release (pure status update). |
| 7 | @CorrelationID | VARCHAR(36) | YES | NULL | CODE-BACKED | Correlation ID of the current processing session. Passed to RedeemPayoutProcess_Abort to match the lock. Only relevant when @RedeemProcessType is not null. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ProcessID, @CorrelationID, @RedeemProcessType | Billing.RedeemPayoutProcess_Abort | EXEC callee | Releases processing lock (conditional on @RedeemProcessType) |
| @RedeemID, @PositionID, @RedeemStatusID | Billing.RedeemStatusUpdate | EXEC callee | State machine validated status update |

### 5.2 Referenced By (other objects point to this)

No SQL callers found. Called by the automated payout service when a processing step (close-position or transfer-units) completes.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.RedeemPayoutProcess_UpdateStatus (procedure)
├── Billing.RedeemPayoutProcess_Abort (procedure)
│     └── Billing.RedeemPayoutProcess (table)
└── Billing.RedeemStatusUpdate (procedure)
      ├── Billing.Redeem (table)
      └── Dictionary.RedeemStatusStateMachine (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.RedeemPayoutProcess_Abort | Procedure | EXEC to release InClosePositionProcess or InTransferUnitsProcess lock |
| Billing.RedeemStatusUpdate | Procedure | EXEC for state-machine validated status update |
| BackOffice.IDs | User Defined Type | TVP for passing @ProcessID to RedeemPayoutProcess_Abort |

### 6.2 Objects That Depend On This

No SQL dependents found. Called by external payout processing services.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TRY/CATCH transaction | Atomicity | Both the abort and the status update are atomic. Rollback on any failure. |
| @@ROWCOUNT check | Validation | After abort call, checks that at least 1 row was affected - ensures the lock was actually held. |

---

## 8. Sample Queries

### 8.1 Complete a close-position step (advance to PositionClosed status 6)

```sql
EXEC Billing.RedeemPayoutProcess_UpdateStatus
    @ProcessID = 1001,
    @RedeemID = 501,
    @PositionID = 9876543210,
    @RedeemStatusID = 6,   -- PositionClosed
    @RedeemProcessType = 1, -- Release InClosePositionProcess
    @CorrelationID = 'd4e5f6a7-4567-8901-defa-123456789012'
```

### 8.2 Complete a transfer-units step

```sql
EXEC Billing.RedeemPayoutProcess_UpdateStatus
    @ProcessID = 1001,
    @RedeemID = 501,
    @PositionID = 9876543210,
    @RedeemStatusID = 8,   -- TransferUnitsDone (example)
    @RedeemProcessType = 2, -- Release InTransferUnitsProcess
    @CorrelationID = 'c3d4e5f6-3456-7890-cdef-012345678901'
```

### 8.3 Status-only update (no lock release needed)

```sql
EXEC Billing.RedeemPayoutProcess_UpdateStatus
    @ProcessID = 1002,
    @RedeemID = 502,
    @PositionID = 9876543211,
    @RedeemStatusID = 25,  -- NegativeBalance
    @RedeemProcessType = NULL,
    @CorrelationID = NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 callees analyzed (RedeemPayoutProcess_Abort, RedeemStatusUpdate) | App Code: skipped | Corrections: 0 applied*
*Object: Billing.RedeemPayoutProcess_UpdateStatus | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.RedeemPayoutProcess_UpdateStatus.sql*
