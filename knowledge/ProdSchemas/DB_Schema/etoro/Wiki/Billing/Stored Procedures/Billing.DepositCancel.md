# Billing.DepositCancel

> Cancels a deposit by setting PaymentStatusID=6 (Canceled) in Billing.Deposit and recording a corresponding cancellation action in History.DepositAction, returning the new action record ID.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepositID identifies the deposit to cancel; outputs @DepositActionID of the created action |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DepositCancel` is the administrative cancellation procedure for a deposit. It transitions a deposit to `PaymentStatusID=6 (Canceled)` and creates an immutable audit record of the cancellation in `History.DepositAction`. This is the operational entry point for cancelling a deposit that was initiated but should not be processed - for example, a deposit that was created by error, a test deposit, or one that needs to be voided before settlement.

Created by Elron B. on 01/01/2023 (PAYIL-5571). The procedure sets:
- `PaymentActionStatusID=3` in the action record (represents the cancellation action status)
- `PaymentActionTypeID=7` (cancellation action type)
- `PaymentStatusID=6 (Canceled)` on both the deposit and the action record

**Important design note**: The UPDATE to `Billing.Deposit` and the INSERT to `History.DepositAction` are NOT wrapped in an explicit transaction (`BEGIN TRANSACTION`). This means if the INSERT fails after the UPDATE succeeds, the deposit will be in `Canceled` status but have no corresponding action record in the history table. The `@@ERROR` check only raises an error but does not roll back the prior UPDATE. Callers should be aware of this partial-failure risk for audit integrity.

---

## 2. Business Logic

### 2.1 Deposit Status Transition to Canceled

**What**: Updates the deposit record's status to Canceled with the current UTC timestamp.

**Columns/Parameters Involved**: `@DepositID`, `Billing.Deposit.PaymentStatusID`, `Billing.Deposit.ModificationDate`

**Rules**:
- `UPDATE Billing.Deposit SET PaymentStatusID=6, ModificationDate=@ModificationDate WHERE DepositID=@DepositID`
- PaymentStatusID=6 = 'Canceled' (from Dictionary.PaymentStatus)
- `@ModificationDate = GETUTCDATE()` - set once and reused for both UPDATE and INSERT to ensure timestamp consistency
- No validation that the deposit exists or is in a cancellable state before updating
- No validation that the deposit is not already canceled (re-canceling is silently accepted)

### 2.2 Cancellation Action Record

**What**: Inserts a history record documenting the cancellation event.

**Columns/Parameters Involved**: `History.DepositAction`, `@DepositID`, `@ManagerID`, `@DepositActionID`

**Rules**:
- Hardcoded action metadata: PaymentActionStatusID=3, PaymentActionTypeID=7, PaymentStatusID=6
- `@ManagerID` recorded if provided (identifies the ops staff member who cancelled)
- `@ModificationDate` reused from the UPDATE step (same timestamp for atomicity of the two records)
- `@DepositActionID = SCOPE_IDENTITY()` returns the new History.DepositAction identity
- On @@ERROR != 0: RAISERROR(60000) and RETURN 60000 (but the preceding UPDATE is NOT rolled back)
- On success: RETURN 0

**Diagram**:
```
@DepositID
         |
  UPDATE Billing.Deposit
  SET PaymentStatusID=6 (Canceled)
  ModificationDate=GETUTCDATE()
         |
  INSERT History.DepositAction
  (ActionStatusID=3, ActionTypeID=7, StatusID=6, ManagerID, ModificationDate)
         |
  @@ERROR != 0? -> RAISERROR(60000) -- NOTE: UPDATE already committed, no rollback
  SUCCESS?      -> @DepositActionID = SCOPE_IDENTITY(), RETURN 0
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositActionID | INT | YES (OUTPUT) | - | CODE-BACKED | OUTPUT: SCOPE_IDENTITY() of the newly created History.DepositAction cancellation record. Callers can use this to reference the specific cancellation event. |
| 2 | @DepositID | INT | NO | - | CODE-BACKED | The deposit to cancel. Must exist in Billing.Deposit. No existence validation - if the DepositID doesn't exist, the UPDATE affects 0 rows silently and the INSERT still writes an action record for the non-existent DepositID. |
| 3 | @ManagerID | INT | YES | NULL | CODE-BACKED | ID of the eToro operations staff member initiating the cancellation. NULL for system-automated cancellations. Recorded in History.DepositAction for audit purposes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID status update | Billing.Deposit | Update | Sets PaymentStatusID=6 (Canceled) and ModificationDate. See [Billing.Deposit](../Tables/Billing.Deposit.md). |
| Cancellation audit record | History.DepositAction | Write (cross-schema) | Inserts cancellation action record (ActionStatusID=3, ActionTypeID=7, StatusID=6). |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by billing operations tools and payment processing services when a deposit must be voided before settlement.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DepositCancel (procedure)
├── Billing.Deposit (table)
└── History.DepositAction (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | UPDATE target - sets PaymentStatusID=6, ModificationDate |
| History.DepositAction | Table (cross-schema) | INSERT target - cancellation action record |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing operations tools | External (App) | Administrative deposit cancellation (PAYIL-5571) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Cancel a deposit

```sql
DECLARE @ActionID INT;
EXEC Billing.DepositCancel
    @DepositActionID = @ActionID OUTPUT,
    @DepositID       = 12345678,
    @ManagerID       = 9999;   -- ops staff member ID
SELECT @ActionID AS CancellationActionID;
```

### 8.2 Verify cancellation state after calling

```sql
SELECT d.DepositID, d.PaymentStatusID, d.ModificationDate
FROM Billing.Deposit d WITH (NOLOCK)
WHERE d.DepositID = 12345678;
-- PaymentStatusID should be 6 (Canceled)

SELECT da.DepositActionID, da.PaymentActionStatusID, da.PaymentActionTypeID,
       da.PaymentStatusID, da.ManagerID, da.ModificationDate
FROM History.DepositAction da WITH (NOLOCK)
WHERE da.DepositID = 12345678
ORDER BY da.DepositActionID DESC;
```

### 8.3 Check if a deposit is already canceled before calling

```sql
SELECT DepositID, PaymentStatusID
FROM Billing.Deposit WITH (NOLOCK)
WHERE DepositID = 12345678;
-- PaymentStatusID=6 means already canceled
-- Calling DepositCancel again will write a duplicate action record
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. PAYIL-5571 (Elron B., 01/01/2023) is the originating Jira ticket for this procedure.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 applicable)*
*Sources: Atlassian: 0 Confluence + 1 Jira (PAYIL-5571) | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DepositCancel | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DepositCancel.sql*
