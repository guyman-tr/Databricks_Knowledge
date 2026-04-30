# Billing.UpdateWithdrawStatus

> Status-change guard for Billing.Withdraw: validates allowed transitions (blocks Processed from any change, blocks Cancelled from re-opening), then delegates the actual update to Billing.UpsertWithdraw via TVP.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawID + @CashoutStatusID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.UpdateWithdrawStatus` is the safe status-transition entry point for a withdrawal (cashout) record. Business rules forbid certain transitions - a fully processed withdrawal must remain processed, and a cancelled withdrawal cannot be re-opened as pending, approved, processed, or rejected. This procedure enforces those guards before delegating the write to `Billing.UpsertWithdraw`.

The procedure accepts the target `@WithdrawID` and `@CashoutStatusID` (the new status to apply), checks whether the current status allows the transition, raises a RAISERROR if not, and on success builds a minimal `Billing.TBL_Withdraw` TVP containing only the WithdrawID and new CashoutStatusID before calling `EXEC Billing.UpsertWithdraw`. UpsertWithdraw handles the actual UPDATE on `Billing.Withdraw` and the audit log write to `History.WithdrawAction`.

Change history:
- FB:52757, Ran Ovadia 09/10/18: Added guard blocking re-opening of already-processed cashouts.
- Adi 03/07/19: Added transaction and error handling (TRY/CATCH).
- DBA-648, Shay Oren 23/09/2021: Refactored from direct UPDATE + INSERT history to delegating via `Billing.UpsertWithdraw` procedure.

Business context: A Confluence HLD ("Reverse Partially Processed Withdrawals") references this SP as needing extension to allow transition from "PartiallyProcessed" (status 6) to "Processed" (status 3) for partial reversal scenarios - indicating the SP is maintained as the authorized status-change pathway.

---

## 2. Business Logic

### 2.1 Existence Check

**What**: Validates the withdrawal record exists before any state inspection.

**Rules**:
- `IF NOT EXISTS (SELECT * FROM Billing.Withdraw WHERE WithdrawID = @WithdrawID)` -> RAISERROR 'There is no record that matches the WithdrawID that was passed' (severity 16) + RETURN 16
- Silent abort if record does not exist; no 0-row update - the error is raised explicitly

### 2.2 Status Transition Guards

**What**: Two sequential guards prevent illegal state transitions before the write is attempted.

**Columns/Parameters Involved**: `@WithdrawID`, `@CashoutStatusID`, `Billing.Withdraw.CashoutStatusID`

**Rules**:
- **Guard 1** (FB:52757): If current CashoutStatusID = 3 (Processed) -> RAISERROR 'Withdraw was already processed and cannot be changed' + RETURN 16. A processed withdrawal is terminal; no further status changes are permitted regardless of target status.
- **Guard 2**: If current CashoutStatusID = 4 (Cancelled) AND target @CashoutStatusID IN (1, 2, 3, 5) -> RAISERROR 'Withdraw is in canceled status and cannot be processed' + RETURN 16. A cancelled withdrawal cannot be re-activated to Pending, Approved, Processed, or Rejected. Transitions to 4 (self), 6 (PartiallyProcessed), or higher values are not blocked by this guard.

**CashoutStatusID values (Billing.Withdraw lifecycle)**:

| Value | Meaning | Guard Behavior |
|-------|---------|----------------|
| 1 | Pending/Requested | Allowed target from most states |
| 2 | Approved | Allowed target from most states |
| 3 | Processed | Guard 1: source blocks all changes; target is blocked from Cancelled |
| 4 | Cancelled | Target is blocked from Cancelled (guard 2) |
| 5 | Rejected | Blocked as target from Cancelled |
| 6 | PartiallyProcessed | Not blocked by guard 2; used in partial reversal flow |

**Diagram**:
```
EXEC UpdateWithdrawStatus @WithdrawID=X, @CashoutStatusID=Y

  1. EXISTS check -> RAISERROR if not found
  2. Get @CurrentStatusID from Billing.Withdraw

  IF @CurrentStatusID = 3       -> RAISERROR (Guard 1 - Processed, terminal)
  IF @CurrentStatusID = 4
     AND Y IN (1,2,3,5)         -> RAISERROR (Guard 2 - Cancelled, no re-open)

  BEGIN TRAN
    INSERT @Info TVP: (WithdrawID=X, CashoutStatusID=Y)
    EXEC Billing.UpsertWithdraw @Info
  COMMIT TRAN
```

### 2.3 Delegation to UpsertWithdraw

**What**: After passing the guards, the update is performed by building a minimal TVP and calling UpsertWithdraw - not by directly modifying tables.

**Rules**:
- TVP `@Info` is of type `Billing.TBL_Withdraw` with only two fields populated: `WithdrawID` and `CashoutStatusID`; all other TVP columns remain NULL
- `EXEC Billing.UpsertWithdraw @Info` handles the UPDATE on `Billing.Withdraw` and the audit INSERT into `History.WithdrawAction` (including ModificationDate update and ManagerID/Comment preservation)
- The old approach (now commented out in the DDL) directly inserted into `History.WithdrawAction` and updated `Billing.Withdraw` - replaced by DBA-648 to centralize write logic

### 2.4 Transaction and Error Handling

**What**: Wraps the UpsertWithdraw call in a transaction with nested-transaction-safe CATCH.

**Rules**:
- BEGIN TRAN / COMMIT TRAN wraps the EXEC Billing.UpsertWithdraw call
- CATCH: IF @@TRANCOUNT = 1 -> ROLLBACK (outermost, this transaction owns it); IF @@TRANCOUNT > 1 -> COMMIT (preserve outer transaction); THROW re-propagates the error

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | INT | NO | - | CODE-BACKED | PK of `Billing.Withdraw`. Identifies the withdrawal record to update. Validated for existence before any status check. |
| 2 | @CashoutStatusID | INT | NO | - | CODE-BACKED | The new cashout status to apply: 1=Pending, 2=Approved, 3=Processed, 4=Cancelled, 5=Rejected, 6=PartiallyProcessed. Subject to transition guards before being applied. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawID | Billing.Withdraw | READ (existence + status check) | Checks existence and reads current CashoutStatusID before applying guards |
| @Info TVP | Billing.UpsertWithdraw | EXEC | Delegates the actual write (Withdraw UPDATE + history INSERT) to UpsertWithdraw |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Withdrawal Service (application) | api/v1/withdrawal/* | Application call | Called by the Withdrawal Service to transition cashout status |
| Back Office (application) | Cashout tools | Application call | Back Office operators use this to cancel or approve pending withdrawals |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdateWithdrawStatus (procedure)
+-- Billing.Withdraw (table) [READ - existence + current status check]
+-- Billing.UpsertWithdraw (procedure) [EXEC - actual write + history]
    +-- Billing.Withdraw (table) [UPDATE via UpsertWithdraw]
    +-- History.WithdrawAction (table) [INSERT via UpsertWithdraw]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | Read: existence check + current CashoutStatusID read for guard evaluation |
| Billing.UpsertWithdraw | Stored Procedure | Exec: delegated write path for the approved status transition |
| Billing.TBL_Withdraw | User Defined Type | TVP type for passing @WithdrawID + @CashoutStatusID to UpsertWithdraw |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Withdrawal Service (application) | Application | Calls via API to change withdrawal status with business rule enforcement |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Guard 1: Processed terminal | Business Rule | CashoutStatusID=3 cannot be changed to any status |
| Guard 2: Cancelled no re-open | Business Rule | CashoutStatusID=4 cannot transition to 1, 2, 3, or 5 |
| Existence required | Validation | Raises error if @WithdrawID not found - no silent 0-row update |
| Nested transaction safe | Design | CATCH commits (not rolls back) when @@TRANCOUNT > 1 to preserve outer transactions |

---

## 8. Sample Queries

### 8.1 Approve a pending withdrawal
```sql
EXEC Billing.UpdateWithdrawStatus
    @WithdrawID      = 98765,
    @CashoutStatusID = 2;  -- Approved
```

### 8.2 Cancel a withdrawal (from Pending or Approved)
```sql
EXEC Billing.UpdateWithdrawStatus
    @WithdrawID      = 98765,
    @CashoutStatusID = 4;  -- Cancelled
```

### 8.3 Verify current status before calling
```sql
SELECT
    w.WithdrawID,
    w.CashoutStatusID,
    CASE w.CashoutStatusID
        WHEN 1 THEN 'Pending'
        WHEN 2 THEN 'Approved'
        WHEN 3 THEN 'Processed'
        WHEN 4 THEN 'Cancelled'
        WHEN 5 THEN 'Rejected'
        WHEN 6 THEN 'PartiallyProcessed'
        ELSE 'Unknown'
    END AS StatusLabel,
    w.ModificationDate
FROM Billing.Withdraw w WITH (NOLOCK)
WHERE w.WithdrawID = 98765;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HLD: Reverse Partially Processed Withdrawals](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/12010390722) | Confluence | UpdateWithdrawStatus identified as the authorized status-change SP; planned extension to allow PartiallyProcessed (status 6) -> Processed (status 3) transition for partial reversal flow |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed (UpsertWithdraw) | App Code: skipped (no Billing repos) | Corrections: 0 applied*
*Object: Billing.UpdateWithdrawStatus | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpdateWithdrawStatus.sql*
