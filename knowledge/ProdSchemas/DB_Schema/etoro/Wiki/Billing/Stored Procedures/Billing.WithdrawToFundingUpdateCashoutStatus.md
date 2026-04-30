# Billing.WithdrawToFundingUpdateCashoutStatus

> Generic WTF status transition machine - validates current state, applies allowed-transition rules, takes a pessimistic row lock, then advances to the new CashoutStatusID via UpdateWithdraw2Funding with history logging.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ID INT - the Billing.WithdrawToFunding.ID to transition |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the back-office and STP (Straight Through Processing) status transition gateway for WithdrawToFunding legs. Rather than hardcoding a single target status (like `WithdrawToFundingToInProcess` which always sets status 2), this procedure accepts both the expected current status and the desired new status, validates the transition is permitted, and applies it atomically.

The procedure enforces a **status transition state machine** with explicit allowed-transition rules for each target status. This prevents invalid transitions (e.g., jumping from Pending directly to Payment Sent) that would corrupt the withdrawal lifecycle. Each rule has been incrementally added as new workflows were introduced: the Under Review / Pending Review statuses (14, 15) were added in December 2019, the Rejected By Provider -> InProcess backflow in November 2022, and the SentToBilling (11) status in September 2025.

A key feature is the **pessimistic lock**: before applying transition guards, a no-op UPDATE (`SET CashoutStatusID=CashoutStatusID`) is executed to acquire an exclusive row lock. This prevents two concurrent callers from both reading the same current status and both succeeding their transition checks before either commits.

The error messages for invalid states are **dynamic**: they look up the current status name from `Dictionary.CashoutStatus.Name` to produce messages like "Withdraw to funding is in Pending Review status and cannot be updated to Payment Sent status" - making the errors immediately actionable for operations teams.

---

## 2. Business Logic

### 2.1 Current-State Validation

**What**: Verifies the WTF record is in the expected current status before proceeding.

**Columns/Parameters Involved**: `@ID`, `@CashoutStatusID`, `Dictionary.CashoutStatus.Name`

**Rules**:
- `IF NOT EXISTS (SELECT * FROM Billing.WithdrawToFunding WHERE ID=@ID AND CashoutStatusID=@CashoutStatusID)` -> dynamic RAISERROR using `Dictionary.CashoutStatus.Name` for the status name
- The caller must know the current status and pass it as `@CashoutStatusID` - this is both a safety check and an optimistic concurrency hint
- Separates "record not found" from "wrong status" into a single guard (cannot distinguish which failure occurred)

### 2.2 Pessimistic Row Lock

**What**: Acquires an exclusive lock on the WTF row before evaluating transition guards.

**Columns/Parameters Involved**: `Billing.WithdrawToFunding.ID`

**Rules**:
- `UPDATE Billing.WithdrawToFunding SET CashoutStatusID=CashoutStatusID WHERE ID=@ID`
- This is a no-op write (sets column to its own value) but acquires an exclusive row lock in SQL Server
- Prevents race conditions where two concurrent calls both pass the current-state check and both proceed with the transition
- Runs OUTSIDE the BEGIN TRAN block - the lock is held until transaction completion when the outer BEGIN TRAN starts

### 2.3 Allowed Transition State Machine

**What**: Enforces permitted status transitions for specific target statuses.

**Columns/Parameters Involved**: `@NewCashoutStatusID`, `@CashoutStatusID`

**Transition rules** (target -> allowed sources):

| Target Status | Target Name | Allowed From | Added |
|--------------|-------------|--------------|-------|
| 14 | Pending Review | 1 (Pending), 2 (InProcess), 15 (Under Review) | - |
| 15 | Under Review | 2 (InProcess), 14 (Pending Review) | - |
| 11 | Sent To Billing | 2 (InProcess), 14 (Pending Review) | 29.09.2025 (yaron) |
| 2 | InProcess | 14 (Pending Review), 15 (Under Review), 8 (Rejected By Provider) | 03.12.2019 (stav); 8 added 17.11.2022 (stav) |
| 6 | Payment Sent | 2 (InProcess) | - |

**Other transitions**: NOT restricted by this procedure (the current-state check in step 2.1 is the only guard for transitions not listed above). For example, transitioning to status 3 (Processed) or 4 (Cancelled) is not blocked by transition-specific rules - only the current-state guard applies.

**Diagram**:
```
CashoutStatus Transition Graph (enforced by this SP):
  1 (Pending)
    -> 14 (Pending Review)

  2 (InProcess)
    -> 14 (Pending Review)
    -> 15 (Under Review)
    -> 11 (Sent To Billing)
    -> 6 (Payment Sent)

  8 (Rejected By Provider)
    -> 2 (InProcess)         [re-try path, added Nov 2022]

  14 (Pending Review)
    -> 2 (InProcess)
    -> 15 (Under Review)
    -> 11 (Sent To Billing)

  15 (Under Review)
    -> 2 (InProcess)
    -> 14 (Pending Review)
```

### 2.4 Status Write with History

**What**: Atomically sets the new CashoutStatusID and logs the transition.

**Columns/Parameters Involved**: `@NewCashoutStatusID`, `CashoutActionStatusID=2`, `@Remark`

**Rules**:
- BEGIN TRAN starts AFTER the lock update and AFTER all transition guards
- INSERT @InfoWTF (ID, @NewCashoutStatusID, ModificationDate, CashoutActionStatusID=2, ManagerID, Remark)
- `EXECUTE [Billing].UpdateWithdraw2Funding @InfoWTF` -> updates WTF + writes `History.WithdrawToFundingAction`

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | int | NO | - | CODE-BACKED | Input parameter. `Billing.WithdrawToFunding.ID` - the WTF leg to transition. |
| 2 | @ManagerID | int | NO | - | CODE-BACKED | Input parameter. Manager or service initiating the transition. Written to `History.WithdrawToFundingAction.ManagerID`. |
| 3 | @Remark | varchar(255) | YES | - | CODE-BACKED | Input parameter. Note for the transition. Written to `History.WithdrawToFundingAction.Remark`. |
| 4 | @CashoutStatusID | int | NO | - | CODE-BACKED | Input parameter. **Expected current status** of the WTF leg. Must match the actual `CashoutStatusID` on the record (pre-flight guard 1). Also used in transition-specific guards to generate error messages. |
| 5 | @NewCashoutStatusID | int | NO | - | CODE-BACKED | Input parameter. **Target status** for the WTF leg. Validated against the allowed-transition rules for specific targets (14, 15, 11, 2, 6). Other targets are not blocked by transition rules (only the current-state guard applies). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (Guard 1) | Billing.WithdrawToFunding | Read + Lock | Current-state check + pessimistic lock (no-op UPDATE) |
| (Guards 2-5) | Dictionary.CashoutStatus | Read | Dynamic error messages - looks up Name by CashoutStatusID |
| (EXEC) | Billing.UpdateWithdraw2Funding | Procedure call | Writes @NewCashoutStatusID to WTF + history |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.WithdrawToFundingUpdateCashoutStatusForBatch | @ID, @CashoutStatusID | Procedure call | Calls this per-row within the batch; batch entry point for multi-WTF status updates |
| (application code) | - | Caller | Called from back-office status transitions, STP flows for individual WTF status updates |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawToFundingUpdateCashoutStatus (procedure)
|- Billing.WithdrawToFunding (table) -- guard + lock + update target
|- Dictionary.CashoutStatus (table) -- dynamic error messages
+-- Billing.UpdateWithdraw2Funding (procedure) -- status write + history
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Current-state guard + pessimistic lock (no-op UPDATE) |
| Dictionary.CashoutStatus | Table | Dynamic error message generation: `SELECT Name WHERE CashoutStatusID=@CashoutStatusID` |
| Billing.UpdateWithdraw2Funding | Stored Procedure | Writes @NewCashoutStatusID to WTF record + history |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFundingUpdateCashoutStatusForBatch | Stored Procedure | Calls this SP per row in a cursor loop for bulk status transitions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Transition from Pending Review to Under Review

```sql
EXEC Billing.WithdrawToFundingUpdateCashoutStatus
    @ID              = 12345,
    @ManagerID       = 999,
    @Remark          = 'Escalated to compliance team',
    @CashoutStatusID    = 14,   -- current: Pending Review
    @NewCashoutStatusID = 15;   -- target: Under Review
```

### 8.2 Re-try a Rejected By Provider leg (move back to InProcess)

```sql
EXEC Billing.WithdrawToFundingUpdateCashoutStatus
    @ID              = 12345,
    @ManagerID       = -1,
    @Remark          = 'Provider retry authorized',
    @CashoutStatusID    = 8,   -- current: Rejected By Provider
    @NewCashoutStatusID = 2;   -- target: InProcess
```

### 8.3 Check current status before calling

```sql
SELECT wtf.ID, wtf.CashoutStatusID, cs.Name AS StatusName
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
JOIN Dictionary.CashoutStatus cs WITH (NOLOCK) ON cs.CashoutStatusID = wtf.CashoutStatusID
WHERE wtf.ID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawToFundingUpdateCashoutStatus | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawToFundingUpdateCashoutStatus.sql*
