# BackOffice.DepositCancel

> Cancels, reverses, or processes a chargeback on a customer deposit by updating Billing.Deposit status, recording the action to History.DepositAction, and adjusting the customer's balance via Customer.SetBalance.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepositID - the deposit to cancel/chargeback |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.DepositCancel is the primary procedure for reversing a customer deposit in eToro's BackOffice system. It handles three types of financial reversals - chargebacks (11), refunds (12), and chargeback-as-refund (26) - and also supports "cancel rollback" (undoing a previous cancellation by restoring status to Approved=2). This is called by the DepositUser API account, which is the dedicated service account for deposit management operations.

The procedure is a compound operation: it simultaneously updates the deposit's status in `Billing.Deposit`, records the action to `History.DepositAction` for audit trail, and adjusts the customer's financial balance by calling `Customer.SetBalance`. The amount is converted from dollars to cents (×100) before the balance call. A companion `Billing.DepositCancel` procedure exists separately in the Billing schema.

The CATCH block has an unusual pattern for nested transactions: `@@TRANCOUNT=1 -> ROLLBACK`, `@@TRANCOUNT>1 -> COMMIT` (handles cases where this procedure is called from within another transaction). Error is re-raised via `Internal.CallRaiseError`.

---

## 2. Business Logic

### 2.1 PaymentStatus and CreditType Mapping

**What**: Different reversal types map to different payment statuses and balance credit types.

**Columns/Parameters Involved**: `@PaymentStatusID`, `@CreditTypeID`, `Billing.Deposit.PaymentStatusID`

**Rules**:
- Only 3 reversal statuses are accepted: 11 (Chargeback), 12 (Refund), 26 (Chargeback as Refund). All others raise error 60025.
- CreditTypeID (for Customer.SetBalance) maps as: 11->11 (Chargeback), 12->12 (Refund), 26->16 (Chargeback as Refund uses credit type 16).
- Status 2 = Approved (used in cancel rollback path).

**Diagram**:
```
@PaymentStatusID   CreditTypeID   Business Meaning
11                 11             Chargeback - bank-initiated reversal
12                 12             Refund - eToro-initiated return to customer
26                 16             Chargeback classified as refund (hybrid case)
```

### 2.2 Cancel vs Cancel Rollback (Amount Sign Logic)

**What**: The sign of @Amount determines whether this is a true cancellation or an undo of a prior cancellation.

**Columns/Parameters Involved**: `@Amount`, `@PaymentStatusID`

**Rules**:
- @Amount < 0 (negative): Standard cancel/chargeback/refund. Status set to 11, 12, or 26.
- @Amount > 0 (positive): Cancel rollback - undoing a previously cancelled deposit. @PaymentStatusID is overridden to 2 (Approved), restoring the deposit.
- Guard 1: If deposit already has status 11/12/26 AND @Amount < 0 -> RAISERROR 60025 ("cannot rollback already-rolled-back").
- Guard 2: If deposit has status 2 (Approved) AND @Amount > 0 -> RAISERROR 60025 ("already approved, cannot cancel rollback").
- If @Amount IS NULL: calculated from `Billing.Deposit.Amount * ExchangeRate`.

### 2.3 Transaction Flow and Balance Adjustment

**What**: All three operations (deposit update, history insert, balance adjust) are atomic.

**Columns/Parameters Involved**: `Billing.Deposit.*`, `History.DepositAction.*`, `Customer.SetBalance` parameters

**Rules**:
- UPDATE Billing.Deposit: PaymentStatusID, ModificationDate, ClearingHouseEffectiveDate, RefundVerificationCode, SessionID. Uses OUTPUT to capture CID and old PaymentStatusID.
- INSERT History.DepositAction: PaymentActionStatusID=3 (closed), PaymentActionTypeID=7 (cancel), plus all relevant IDs.
- @Amount converted to cents: `CAST(@Amount * 100 AS INTEGER)` before EXEC Customer.SetBalance.
- EXEC Customer.SetBalance: adjusts customer balance with CreditTypeID, Reason, ManagerID, DepositID as context.
- All three steps in BEGIN TRANSACTION / COMMIT. On failure: ROLLBACK (@@TRANCOUNT=1) or COMMIT (@@TRANCOUNT>1), then EXEC Internal.CallRaiseError.

**Diagram**:
```
BEGIN TRANSACTION
  UPDATE Billing.Deposit (status, dates, SessionID) -> OUTPUT CID
  INSERT History.DepositAction (audit trail, PaymentActionStatusID=3/closed, PaymentActionTypeID=7/cancel)
  EXEC Customer.SetBalance(@CID, @Amount*100, @CreditTypeID, @Reason, @ManagerID, @DepositID)
COMMIT
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INTEGER | NO | - | CODE-BACKED | The deposit to cancel/chargeback/refund. PK of Billing.Deposit. Must exist in Billing.Deposit or error 60025 is raised. |
| 2 | @PaymentStatusID | INTEGER | NO | - | CODE-BACKED | The target cancellation type: 11=Chargeback, 12=Refund, 26=Chargeback as Refund. Value 2 (Approved) is auto-assigned internally for cancel rollback cases. Any other value raises 60025. |
| 3 | @ManagerID | INTEGER | NO | - | CODE-BACKED | BackOffice agent performing the cancellation. Written to History.DepositAction.ManagerID for audit trail. |
| 4 | @Reason | VARCHAR(255) | NO | - | CODE-BACKED | Free-text reason for the cancellation. Passed to Customer.SetBalance as the reason string for the balance adjustment. |
| 5 | @Amount | MONEY | YES | NULL | CODE-BACKED | Dollar amount to cancel/restore. Negative = standard cancellation (deduct from customer). Positive = cancel rollback (restore to customer). NULL = auto-calculated from Billing.Deposit.Amount * ExchangeRate. Converted to cents (*100) before balance call. |
| 6 | @ClearingHouseEffectiveDate | DATETIME | YES | NULL | CODE-BACKED | The effective date at the clearing house for the reversal. Written to Billing.Deposit and History.DepositAction. Relevant for chargeback reconciliation with payment processors. |
| 7 | @RefundVerificationCode | VARCHAR(50) | NO | - | CODE-BACKED | Verification code from the payment processor confirming the refund/chargeback. Written to Billing.Deposit.RefundVerificationCode. |
| 8 | @SessionID | BIGINT | YES | NULL | CODE-BACKED | The session associated with the deposit. If NULL, preserves the existing SessionID from Billing.Deposit. If provided, overrides it. Written to both Billing.Deposit and History.DepositAction. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID | Billing.Deposit | Modifier | UPDATE target - changes PaymentStatusID, ModificationDate, ClearingHouseEffectiveDate, RefundVerificationCode, SessionID. |
| @DepositID | History.DepositAction | Writer | INSERT - records the cancellation action for audit trail. |
| @CID (resolved) | Customer.SetBalance | EXEC | Called to deduct or restore the customer's account balance by @Amount * 100 (cents). |
| @PaymentStatusID=11 | Dictionary.PaymentStatus | Lookup | Status name fetched for error message when deposit is already in a reversed state. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Deposit API (DepositUser account) | EXEC | Caller | Called by the deposit management API service to process chargebacks and refunds. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.DepositCancel (procedure)
├── Billing.Deposit (table) - UPDATE status + OUTPUT
├── History.DepositAction (table) - INSERT audit record
├── Customer.SetBalance (procedure) - EXEC balance adjustment
│     └── [Customer schema balance tables]
├── Dictionary.PaymentStatus (table) - SELECT name for error message
└── Internal.CallRaiseError (procedure) - EXEC in CATCH for error propagation
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | UPDATE status + OUTPUT CID; SELECT Amount*ExchangeRate for @Amount calc; EXISTS check |
| History.DepositAction | Table | INSERT audit record (PaymentActionStatusID=3/closed, PaymentActionTypeID=7/cancel) |
| Customer.SetBalance | Procedure | EXEC - adjusts customer balance by @Amount*100 with CreditTypeID context |
| Dictionary.PaymentStatus | Table | SELECT Name WHERE PaymentStatusID for descriptive error message |
| Internal.CallRaiseError | Procedure | EXEC in CATCH - re-raises the original error with proper logging |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Deposit API (DepositUser) | External | EXEC - processes chargebacks and refunds |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PaymentStatusID whitelist | Validation | Only 11/12/26 accepted as @PaymentStatusID input. Error 60025 for others. |
| Double-cancel guard | Validation | Cannot cancel a deposit already in 11/12/26 status with a negative amount. |
| Already-approved guard | Validation | Cannot cancel-rollback a deposit already in Approved (2) status with a positive amount. |
| Amount * 100 conversion | Behavior | Customer.SetBalance receives cents, not dollars. @Amount is cast INTEGER * 100 before the EXEC. |
| Nested transaction CATCH | Convention | @@TRANCOUNT=1 -> ROLLBACK (top-level), @@TRANCOUNT>1 -> COMMIT (nested - let parent handle). Prevents orphaned transactions. |

---

## 8. Sample Queries

### 8.1 Process a chargeback on a deposit
```sql
EXEC BackOffice.DepositCancel
    @DepositID = 987654,
    @PaymentStatusID = 11,  -- Chargeback
    @ManagerID = 42,
    @Reason = 'Customer disputed charge with bank',
    @Amount = -500.00,
    @RefundVerificationCode = 'CHB-20260317-001'
```

### 8.2 Roll back a previous cancellation (restore to Approved)
```sql
EXEC BackOffice.DepositCancel
    @DepositID = 987654,
    @PaymentStatusID = 11,  -- will be overridden to 2 (Approved)
    @ManagerID = 42,
    @Reason = 'Cancellation was applied in error',
    @Amount = 500.00,   -- positive = cancel rollback
    @RefundVerificationCode = 'ROLLBACK-001'
```

### 8.3 Check deposit status and history after cancellation
```sql
SELECT d.DepositID, d.PaymentStatusID, d.ModificationDate, d.RefundVerificationCode,
       da.PaymentActionStatusID, da.PaymentActionTypeID, da.ManagerID
FROM Billing.Deposit d WITH (NOLOCK)
LEFT JOIN History.DepositAction da WITH (NOLOCK) ON da.DepositID = d.DepositID
WHERE d.DepositID = 987654
ORDER BY da.ModificationDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for this procedure.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Customer.SetBalance via EXEC) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.DepositCancel | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.DepositCancel.sql*
