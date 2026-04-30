# Billing.DepositRollback

> Executes a deposit rollback (Chargeback, Refund, RefundAsChargeback, or their reversals) - updates deposit status, records tracking data in DepositRollbackTracking, debits/credits the customer balance via Customer.SetBalance, and appends a cancellation action to History.DepositAction.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE Billing.Deposit + INSERT Billing.DepositRollbackTracking + EXEC Customer.SetBalance |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DepositRollback` is the single-deposit rollback procedure used by back-office operations and the Payments API when a deposit must be reversed. The supported rollback types are: Chargeback (PaymentStatusID=11), Refund (12), RefundAsChargeback (26), ChargebackReversal (37), RefundReversal (38), and type 39 (introduced more recently), plus PaymentStatusID=2 which "cancels" a previously applied rollback (reverting the deposit back to Approved).

The procedure was originally in the BackOffice schema (`[BackOffice].[DepositRollback]`) and was moved to the Billing schema in PAYIL-3480 (20/01/2022) as part of a broader initiative to decouple the Payments domain from the BackOffice monolith and migrate toward microservices via the Mass Operation Service (MOS) and Payments API.

For each rollback, the SP: updates the deposit status, inserts a full tracking record into `Billing.DepositRollbackTracking`, calls `Customer.SetBalance` to adjust the customer's account by the rollback amount, and appends an audit action to `History.DepositAction`. For "Cancel Rollback" (PaymentStatusID=2), it additionally marks the previous tracking records as cancelled before inserting the new one.

The Confluence Mass Deposit Rollback design doc (OPSE-269, PAYIL-3416) describes planned migration of this logic to Payments API for bulk (mass) rollback scenarios via the MOS. The SP supports individual rollbacks; bulk operations send individual messages via Service Bus that result in individual calls to this SP or its Payments API equivalent.

---

## 2. Business Logic

### 2.1 Input Validation

**What**: Validates the rollback type and deposit existence before any data changes.

**Columns/Parameters Involved**: `@PaymentStatusID`, `@DepositID`

**Rules**:
- Allowed @PaymentStatusID values: 2 (Approved/Cancel Rollback), 11 (Chargeback), 12 (Refund), 26 (RefundAsChargeback), 37 (ChargebackReversal), 38 (RefundReversal), 39.
- Any other value -> RAISERROR(60025, 'invalid payment status passed') + RETURN 60025.
- Checks `EXISTS (SELECT 1 FROM Billing.Deposit WHERE DepositID = @DepositID)`.
- If deposit not found -> RAISERROR(60025, 'deposit does not exist') + RETURN 60025.

### 2.2 State Load and Default Calculation

**What**: Loads current deposit state and computes defaults for optional parameters.

**Columns/Parameters Involved**: `@OldPaymentStatusID`, `@ExchangeRate`, `@RollbackAmountInUSD`

**Rules**:
- `@SessionID`: if not provided, inherits from `Billing.Deposit.SessionID`.
- `@ExchangeRate`: if NULL or 0, uses `Billing.Deposit.ExchangeRate` (deposit's stored rate). Otherwise uses provided value. Added PAYIL-3976 (12/04/2022).
- `@RollbackAmountInUSD`: if NULL or 0, calculated as `@RollbackAmountInCurrency * @ExchangeRate`. Added PAYIL-4068 (13/04/2022).
- Loads: `ExchangeFee`, `BaseExchangeRate`, `CurrencyID` from the deposit for tracking record.

### 2.3 Cancel Rollback Guard

**What**: Prevents re-approving an already-approved deposit via the PaymentStatusID=2 path.

**Columns/Parameters Involved**: `@OldPaymentStatusID`, `@PaymentStatusID`

**Rules**:
- If `@OldPaymentStatusID = 2 (Approved)` AND `@PaymentStatusID = 2 (Cancel Rollback)`: RAISERROR with message 'Deposit ID {id} has already been approved - cannot cancel rollback.' + RETURN 60025.
- This guard prevents an operator accidentally passing PaymentStatusID=2 for a deposit that was never rolled back.

### 2.4 Deposit Status Update

**What**: Sets the new deposit status and clears fields that are invalidated by the rollback.

**Columns/Parameters Involved**: `Billing.Deposit.PaymentStatusID`, `ClearingHouseEffectiveDate`, `RefundVerificationCode`

**Rules**:
- `SET PaymentStatusID = @PaymentStatusID`.
- `SET ClearingHouseEffectiveDate = NULL` - clearing date is invalidated on rollback.
- `SET RefundVerificationCode = NULL` - verification code is cleared.
- `SET SessionID = @SessionID` - updated with caller's session (or inherited value).

### 2.5 Audit Action Insert

**What**: Creates a cancellation action record in History.DepositAction.

**Columns/Parameters Involved**: `History.DepositAction.PaymentActionStatusID`, `PaymentActionTypeID`

**Rules**:
- `PaymentActionStatusID = 3 (Closed)`, `PaymentActionTypeID = 7 (Cancel)`.
- `PaymentStatusID = @PaymentStatusID` - the new rollback status.
- ExchangeRate, ApprovalNumber, AuthCode all NULL in this action row (not applicable for rollback).
- `ClearingHouseEffectiveDate = NULL`.

### 2.6 DepositRollbackTracking Maintenance

**What**: Records the rollback in the tracking table, cancelling prior records if this is a "Cancel Rollback".

**Columns/Parameters Involved**: `Billing.DepositRollbackTracking`, `@PaymentStatusID`

**Rules**:
- **Cancel Rollback** (`@PaymentStatusID = 2`): first UPDATE existing tracking rows to `IsCanceled=1` for this DepositID WHERE IsCanceled=0. This marks the prior rollback as cancelled.
- All cases: INSERT new tracking row with `IsCanceled=0` (the new rollback event).
- Tracking fields captured: CID, DepositID, PaymentStatusID, TotalRollbackAmountInUSD, TotalRollbackAmountInCurrency, RollbackAmountInUSD, RollbackAmountInCurrency, CurrencyID, ExchangeRate, BaseExchangeRate, ExchangeFee, ReferenceNumber, Comments, RollbackDate, CreateDate (=@Now), ModificationDate (=@Now), ManagerID, IsCanceled=0, RollbackReasonID.
- `@RollbackID = SCOPE_IDENTITY()` - the new tracking row ID, passed to Customer.SetBalance.

### 2.7 CreditTypeID Resolution

**What**: Maps the payment status to the correct credit type for the balance movement.

**Columns/Parameters Involved**: `@PaymentStatusID`, `@OldPaymentStatusID`, `@CreditTypeID`

**Rules**:
- Primary mapping from `@PaymentStatusID`:
  - 11 (Chargeback) -> CreditTypeID = 11
  - 12 (Refund) -> CreditTypeID = 12
  - 26 (RefundAsChargeback) -> CreditTypeID = 16
  - 37 (ChargebackReversal) -> CreditTypeID = 11
  - 38 (RefundReversal) -> CreditTypeID = 12
  - 39 -> CreditTypeID = 32
- Fallback to `@OldPaymentStatusID` using the same map (for @PaymentStatusID=2 "Cancel Rollback" case, where the old status indicates what type of rollback is being cancelled).

### 2.8 Balance Adjustment via Customer.SetBalance

**What**: Adjusts the customer's account balance to reflect the rollback amount.

**Columns/Parameters Involved**: `@Amount`, `@CreditTypeID`, `Customer.SetBalance`

**Rules**:
- `@Amount = CAST(@RollbackAmountInUSD * 100 AS INT)` - converts to integer cents (same convention as DepositProcess).
- `EXEC Customer.SetBalance @CID, @Payment=@Amount, @CreditTypeID, @Description=@Comments, @ManagerID, @DepositID, @DepositRollbackID=@RollbackID`.
- If Customer.SetBalance returns non-zero -> RAISERROR (the error message text still references "BackOffice.DepositRollback" - a stale reference from before the schema move).
- For Chargebacks and Refunds: this DEBITS the customer (removes the previously credited deposit amount).
- For Reversals: this CREDITS the customer back (restores funds removed by the original chargeback/refund).

```
Input validation (status + deposit existence)
  -> Load deposit state + compute defaults (@ExchangeRate, @RollbackAmountInUSD)
  -> Cancel Rollback guard (if both old and new status = 2)

BEGIN TRANSACTION:
  -> UPDATE Billing.Deposit (status, clear clearing fields)
  -> INSERT History.DepositAction (ActionStatus=3/Closed, ActionType=7/Cancel)
  -> If PaymentStatusID=2: UPDATE DepositRollbackTracking SET IsCanceled=1 (cancel prior)
  -> INSERT Billing.DepositRollbackTracking (new tracking row, IsCanceled=0)
  -> Map @PaymentStatusID -> @CreditTypeID (11/12/16/32)
  -> EXEC Customer.SetBalance (@Amount in cents, @CreditTypeID, @DepositRollbackID)
COMMIT
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INT | NO | - | CODE-BACKED | PK of the deposit to roll back. FK to Billing.Deposit.DepositID. Validated to exist before processing. |
| 2 | @PaymentStatusID | INT | NO | - | CODE-BACKED | Target rollback type. Allowed: 2 (Cancel Rollback/Approved), 11 (Chargeback), 12 (Refund), 26 (RefundAsChargeback), 37 (ChargebackReversal), 38 (RefundReversal), 39. Any other value raises error 60025. |
| 3 | @RollbackAmountInUSD | MONEY | YES | NULL | CODE-BACKED | Rollback amount in USD. If NULL or 0, calculated automatically as @RollbackAmountInCurrency * @ExchangeRate (added PAYIL-4068). Written to Billing.DepositRollbackTracking. Passed to Customer.SetBalance as integer cents. |
| 4 | @RollbackAmountInCurrency | MONEY | YES | NULL | CODE-BACKED | Rollback amount in the deposit's original currency. Used to compute @RollbackAmountInUSD if not provided. Written to Billing.DepositRollbackTracking. |
| 5 | @TotalRollbackAmountInUSD | MONEY | YES | NULL | CODE-BACKED | Total cumulative rollback amount in USD (may differ from @RollbackAmountInUSD for partial rollbacks). Written to Billing.DepositRollbackTracking. |
| 6 | @TotalRollbackAmountInCurrency | MONEY | YES | NULL | CODE-BACKED | Total cumulative rollback amount in original currency. Written to Billing.DepositRollbackTracking. |
| 7 | @ReferenceNumber | VARCHAR(50) | YES | NULL | CODE-BACKED | External reference number (e.g., gateway chargeback ID, bank reference). Written to Billing.DepositRollbackTracking.ReferenceNumber. Per Confluence, mandatory for mass rollback CSV input. |
| 8 | @Comments | VARCHAR(255) | YES | NULL | CODE-BACKED | Free-text reason/notes for the rollback. Written to Billing.DepositRollbackTracking.Comments and passed as @Description to Customer.SetBalance for the balance change audit trail. |
| 9 | @RollbackDate | DATETIME | YES | NULL | CODE-BACKED | The effective date of the rollback event (may differ from processing date, e.g., the date the bank initiated the chargeback). Written to Billing.DepositRollbackTracking.RollbackDate. |
| 10 | @ManagerID | INT | YES | NULL | CODE-BACKED | ID of the back-office manager or system user performing the rollback. Written to Billing.DepositRollbackTracking and History.DepositAction. Passed to Customer.SetBalance for balance audit. |
| 11 | @SessionID | BIGINT | YES | NULL | CODE-BACKED | Web/app session ID. If NULL, inherits from Billing.Deposit.SessionID. Written to Billing.Deposit and History.DepositAction. |
| 12 | @RollbackReasonID | INT | YES | NULL | CODE-BACKED | Reason code for the rollback. FK to a rollback reason lookup. Per Confluence, mandatory when reasons exist for the rollback type. Written to Billing.DepositRollbackTracking. |
| 13 | @ExchangeRate | dtPrice | YES | NULL | CODE-BACKED | FX rate for amount conversion. If NULL or 0, uses the rate stored on the deposit at time of approval. Used to compute @RollbackAmountInUSD if not provided. Written to Billing.DepositRollbackTracking. Added PAYIL-3976. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID | Billing.Deposit | READ + MODIFIER (UPDATE) | Validates existence; loads CID, ExchangeRate, status, CurrencyID; updates PaymentStatusID + clears ClearingHouseEffectiveDate + RefundVerificationCode. |
| @DepositID | History.DepositAction | WRITER (INSERT) | Appends cancellation audit record: ActionStatus=3/Closed, ActionType=7/Cancel, new PaymentStatusID. |
| @DepositID | Billing.DepositRollbackTracking | READ + WRITER (INSERT + conditional UPDATE) | For Cancel Rollback: marks prior rows IsCanceled=1. All cases: inserts new tracking row. |
| @CID | Customer.SetBalance | EXEC (cross-schema) | Adjusts customer account balance: @Amount (in cents), @CreditTypeID (maps rollback type), @DepositRollbackID. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Back-office application (BO_User) | @DepositID | EXEC | Single-deposit rollback via BO UI. Originally called [BackOffice].[DepositRollback] before schema move (PAYIL-3480). |
| Payments API / Mass Operation Service | @DepositID | EXEC | Bulk rollbacks via MOS send per-deposit messages -> Payments API calls this SP. (Source: Confluence OPSE-269, PAYIL-3416 - VERIFIED) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DepositRollback (procedure)
+-- Billing.Deposit (table) [READ + UPDATE]
+-- History.DepositAction (table) [cross-schema, INSERT]
+-- Billing.DepositRollbackTracking (table) [INSERT + conditional UPDATE]
+-- Customer.SetBalance (procedure) [cross-schema, EXEC]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | READ (load state) + UPDATE (PaymentStatusID + cleared fields). |
| History.DepositAction | Table (cross-schema) | INSERT - cancellation audit record. |
| Billing.DepositRollbackTracking | Table | INSERT new tracking row; UPDATE prior rows to IsCanceled=1 on Cancel Rollback. |
| Customer.SetBalance | Stored Procedure (cross-schema) | EXEC - adjusts customer balance by rollback amount. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Back-office application | External | EXEC for individual rollbacks via BO_User permissions. |
| Payments API / Mass Operation Service | External service | EXEC for bulk rollback operations. (Source: Confluence) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Rollback type to CreditTypeID mapping**:
| @PaymentStatusID | Rollback Type | CreditTypeID |
|-----------------|---------------|-------------|
| 11 | Chargeback | 11 |
| 12 | Refund | 12 |
| 26 | RefundAsChargeback | 16 |
| 37 | ChargebackReversal | 11 |
| 38 | RefundReversal | 12 |
| 39 | (new type) | 32 |
| 2 | Cancel Rollback | mapped from @OldPaymentStatusID |

**Version history**:
- 20/01/2022 (PAYIL-3480): Moved from BackOffice schema to Billing.
- 12/04/2022 (PAYIL-3976): @ExchangeRate parameter added.
- 13/04/2022 (PAYIL-4068): Default calculation for @RollbackAmountInUSD and @ExchangeRate when NULL.

**Note**: The error message for Customer.SetBalance failure still reads "BackOffice.DepositRollback" - a stale reference from before the schema move. Functional only as a display string.

**Error codes**: 60025 for all validation failures. THROW for unexpected errors from Customer.SetBalance or other DML.

---

## 8. Sample Queries

### 8.1 Process a chargeback for a deposit

```sql
EXEC [Billing].[DepositRollback]
    @DepositID = 12345678,
    @PaymentStatusID = 11,              -- Chargeback
    @RollbackAmountInCurrency = 100.00, -- @RollbackAmountInUSD computed automatically
    @ExchangeRate = 1.0,
    @ReferenceNumber = 'CHB-2026-001',
    @Comments = 'Chargeback initiated by card issuer',
    @ManagerID = 999,
    @RollbackReasonID = 1;
```

### 8.2 Cancel a previously applied rollback

```sql
EXEC [Billing].[DepositRollback]
    @DepositID = 12345678,
    @PaymentStatusID = 2,               -- Cancel Rollback -> restore to Approved
    @RollbackAmountInCurrency = 100.00,
    @ReferenceNumber = 'CANCEL-CHB-001',
    @Comments = 'Chargeback dispute won, restoring deposit',
    @ManagerID = 999;
```

### 8.3 View rollback history for a deposit

```sql
SELECT RollbackID, DepositID, PaymentStatusID, RollbackAmountInUSD, RollbackAmountInCurrency,
       CurrencyID, ExchangeRate, ReferenceNumber, Comments, RollbackDate, CreateDate,
       ManagerID, IsCanceled, RollbackReasonID
FROM [Billing].[DepositRollbackTracking] WITH (NOLOCK)
WHERE DepositID = 12345678
ORDER BY RollbackID DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Mass Deposit Rollback](https://etoro-jira.atlassian.net/wiki/spaces/PAY/pages/11898880121) | Confluence | Confirms SP was moved from BackOffice to Billing schema (PAYIL-3480). Mass rollback via MOS (OPSE-269/PAYIL-3416) sends per-deposit Service Bus messages calling this SP or its Payments API equivalent. CSV input schema documented with mandatory/optional fields. Cross-schema concerns flagged (BackOffice.DepositRollbackTracking -> now Billing, Customer.SetBalance). |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DepositRollback | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DepositRollback.sql*
