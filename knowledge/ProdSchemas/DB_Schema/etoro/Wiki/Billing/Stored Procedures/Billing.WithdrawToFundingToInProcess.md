# Billing.WithdrawToFundingToInProcess

> Transitions a WithdrawToFunding leg from Pending (status 1) to InProcess (status 2); validates the pending state first, then updates the WTF record and writes a history row in a single transaction.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ID INT - the Billing.WithdrawToFunding.ID to transition |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure advances a WithdrawToFunding payment leg from the initial Pending state to the InProcess state, signaling that the Cashout Service has picked up the leg and is actively attempting the payment. The transition from 1 (Pending) to 2 (InProcess) is a key state change in the withdrawal lifecycle: it locks the leg from being picked up by another worker and records who began processing it.

Unlike the more complex settlement SPs (`WithdrawToFundingProcess`, `WithdrawToFundingReject`, `WithdrawToFundingReverse`), this procedure uses **direct UPDATE/INSERT** rather than the `UpdateWithdraw2Funding` TVP abstraction pattern. It was created in July 2019 (Adi) - before the DBA-648 refactoring that introduced the TVP abstraction in September 2021.

The pre-flight guard ensures idempotency-protection: only a WTF record in `CashoutStatusID=1` (Pending) can be transitioned. If the record has already been picked up (status 2) or completed (status 3+), the call fails immediately with a descriptive RAISERROR rather than silently overwriting the status.

---

## 2. Business Logic

### 2.1 Pending-State Guard

**What**: Ensures the WTF leg is still in Pending status before any modification.

**Columns/Parameters Involved**: `Billing.WithdrawToFunding.CashoutStatusID`, `@ID`

**Rules**:
- `IF NOT EXISTS (SELECT * FROM Billing.WithdrawToFunding WHERE ID=@ID AND CashoutStatusID=1)` -> RAISERROR('Withdraw to funding is not in pending status', 16, 1) + RETURN
- Blocks transitions if: record doesn't exist; record is already InProcess (2), Processed (3), Cancelled (4), or Rejected (7)
- No separate existence check - a missing ID fails the same way as a non-pending ID (same error message)

### 2.2 Status Transition: Pending (1) -> InProcess (2)

**What**: Sets the WTF record to InProcess and captures a history snapshot.

**Columns/Parameters Involved**: `CashoutStatusID=2`, `ModificationDate`, `History.WithdrawToFundingAction`

**Rules**:
- `UPDATE Billing.WithdrawToFunding SET CashoutStatusID=2, ModificationDate=GETUTCDATE() WHERE ID=@ID`
- **Note**: ManagerID is NOT updated on the WTF record (only history gets `@ManagerID`) - the original ManagerID from record creation is preserved
- `INSERT INTO History.WithdrawToFundingAction` reads back the WTF row (post-update, so CashoutStatusID=2 in history) and adds: `CashoutActionStatusID=2` (processed), `@ManagerID`, `@Remark`, `BW2F_ID=@ID`
- Both writes in a named transaction: `BEGIN TRANSACTION WithdrawToFundingToInProcess`

**Diagram**:
```
Pre-flight: WTF ID=@ID must have CashoutStatusID=1
  Else: RAISERROR('not in pending status')

BEGIN TRANSACTION WithdrawToFundingToInProcess:
  UPDATE Billing.WithdrawToFunding
    SET CashoutStatusID=2, ModificationDate=GETUTCDATE()
    WHERE ID=@ID

  INSERT History.WithdrawToFundingAction
    SELECT WithdrawID, FundingID, CashoutStatusID[=2],
           2 AS CashoutActionStatusID,
           ProcessCurrencyID, @ManagerID, Amount, WithdrawData,
           GETUTCDATE(), @Remark, @ID AS BW2F_ID
    FROM Billing.WithdrawToFunding WHERE ID=@ID
    -- reads back updated row (CashoutStatusID=2 already)
COMMIT
```

### 2.3 Nested Transaction Handling

**What**: Error handler distinguishes nested from top-level transactions.

**Rules**:
- `IF @@TRANCOUNT=1` -> ROLLBACK (this is the top-level transaction)
- `IF @@TRANCOUNT>1` -> COMMIT (inside a nested transaction - let the outer caller decide rollback)
- `THROW` re-raises the original error to the caller

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | int | NO | - | CODE-BACKED | Input parameter. `Billing.WithdrawToFunding.ID` - the WTF payment leg to transition. Must currently have CashoutStatusID=1 (Pending). |
| 2 | @ManagerID | int | NO | - | CODE-BACKED | Input parameter. Manager or service initiating the InProcess transition. Written to `History.WithdrawToFundingAction.ManagerID` only - NOT updated on `Billing.WithdrawToFunding.ManagerID`. |
| 3 | @Remark | varchar(255) | YES | - | CODE-BACKED | Input parameter. Optional note for the status transition. Written to `History.WithdrawToFundingAction.Remark`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (Guard + UPDATE) | Billing.WithdrawToFunding | Read + Write | Guard reads CashoutStatusID; UPDATE sets it to 2 |
| (INSERT) | History.WithdrawToFundingAction | Write | Snapshot of WTF state post-update + manager/remark |

### 5.2 Referenced By (other objects point to this)

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawAndWithdrawToFundingAdd | Stored Procedure | Calls to advance a newly created WTF leg from Pending to InProcess |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawToFundingToInProcess (procedure)
|- Billing.WithdrawToFunding (table) -- guard read + status update
+-- History.WithdrawToFundingAction (table) -- history insert
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Pre-flight guard (CashoutStatusID=1 check) + UPDATE CashoutStatusID=2 + SELECT for history snapshot |
| History.WithdrawToFundingAction | Table | INSERT destination for status transition audit record |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawAndWithdrawToFundingAdd | Stored Procedure | Calls to set WTF to InProcess after creation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute the InProcess transition

```sql
EXEC Billing.WithdrawToFundingToInProcess
    @ID        = 12345,
    @ManagerID = -1,
    @Remark    = 'Picked up by cashout service worker';
```

### 8.2 Find WTF legs currently in Pending status (eligible for this SP)

```sql
SELECT TOP 20
    wtf.ID,
    wtf.WithdrawID,
    wtf.FundingID,
    wtf.CashoutStatusID,   -- 1 = Pending
    wtf.ModificationDate
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
WHERE wtf.CashoutStatusID = 1
ORDER BY wtf.ModificationDate;
```

### 8.3 Verify status transition in history

```sql
SELECT
    wfa.BW2F_ID         AS WTF_ID,
    wfa.WithdrawID,
    wfa.CashoutStatusID, -- should be 2
    wfa.ManagerID,
    wfa.ModificationDate,
    wfa.Remark
FROM History.WithdrawToFundingAction wfa WITH (NOLOCK)
WHERE wfa.BW2F_ID = 12345
  AND wfa.CashoutStatusID = 2
ORDER BY wfa.ModificationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawToFundingToInProcess | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawToFundingToInProcess.sql*
