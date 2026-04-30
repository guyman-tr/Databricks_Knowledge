# Billing.ManualPaymentProcess

> Back-office manual approval of a legacy Billing.Payment: validates the payment state, then atomically calls PaymentUpdate (Pending->Approved) and AmountAdd (credits the USD-converted amount to the customer's account) under a single transaction.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PaymentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.ManualPaymentProcess` is the back-office tool for manually approving a legacy `Billing.Payment` deposit that was initiated before January 2011 (when the platform was migrated to `Billing.Deposit`/`Billing.Funding`). When a manager reviews a legacy pending payment and decides to approve it, this procedure orchestrates the full approval: it validates the payment state, transitions it to Approved status, and credits the USD-equivalent amount to the customer's account.

The procedure enforces three safeguards before processing:
1. The payment must exist
2. It must not already be credited (History.Credit deduplication guard)
3. It must not already be in Approved status

Execution is split into two separate TRY/CATCH blocks: one for validation (no transaction), one for execution (within a transaction). An important design quirk: if validation fails and raises an error, the second execution block still runs due to SQL Server's batch continuation behavior after CATCH-block RAISERROR at severity 16. However, in practice the subsequent calls on an invalid payment ID would fail silently (UPDATE affects 0 rows) or raise their own errors.

The credit amount formula `ROUND(Amount * ExchangeRate, 0)` converts the stored local-currency amount to a USD-equivalent integer for `Billing.AmountAdd`. The audit trail includes the reason string 'Manual transaction processing from BackOffice' stamped in both History.Payment and History.Credit.

`Billing.Payment` was frozen in January 2011. This procedure therefore applies only to the historical pre-2011 payment dataset.

---

## 2. Business Logic

### 2.1 Validation Phase (Pre-Transaction)

**What**: Three guards must all pass before the execution transaction begins.

**Parameters Involved**: `@PaymentID`

**Rules**:
- **Guard 1 - Exists**: `IF NOT EXISTS (SELECT 1 FROM Billing.Payment WHERE PaymentID=@PaymentID)` -> RAISERROR(60025, 'Invalid Payment')
- **Guard 2 - Not Already Credited**: `IF EXISTS (SELECT 1 FROM History.Credit WHERE CreditTypeID=1 AND PaymentID=@PaymentID)` -> RAISERROR(60025, 'Payment Already Processed')
  - CreditTypeID=1 = Deposit credit - checks if the payment was already turned into a credit
- **Guard 3 - Not Already Approved**: After SELECT @PaymentStatusID, if @PaymentStatusID=2 -> RAISERROR('The payment has already been aproved') [note: typo preserved from source]
- Side reads: `@CID`, `@PaymentStatusID`, `@Amount = ROUND(Amount*ExchangeRate, 0)` from Billing.Payment

### 2.2 Execution Phase (Atomic Transaction)

**What**: Two procedure calls in a single transaction to atomically approve and credit the payment.

**Parameters Involved**: `@PaymentID`, `@PaymentStatusID`, `@CID`, `@Amount`, `@ManagerID`

**Rules**:
- **Step 1**: `EXEC Billing.PaymentUpdate @PaymentID, @PaymentStatusID, 2, NULL, @PaymentHistoryID OUTPUT, 'Manual transaction processing from BackOffice'`
  - Transitions payment from current status (@PaymentStatusID) to 2 (Approved)
  - @ModificationDate=NULL defaults to GETDATE() inside PaymentUpdate
  - Returns @Answer: 0=success, non-zero=error -> RAISERROR(60025) on failure
- **Step 2**: `EXEC Billing.AmountAdd @CID, 1, 1, @Amount, NULL, @ManagerID, 'Manual transaction processing from BackOffice', @PaymentID`
  - @CurrencyID=1 (USD)
  - @CreditTypeID=1 (Deposit)
  - @Amount = ROUND(Payment.Amount * Payment.ExchangeRate, 0) - local currency -> USD in whole units
  - @PositionID=NULL (no position linkage)
  - @ManagerID: identifies the back-office manager performing the approval
  - Returns @Answer: 0=success, non-zero=error -> RETURN @Answer on failure
- COMMIT on success, RETURN 0

### 2.3 Amount Conversion Formula

**What**: Converts the stored payment amount to USD for the credit operation.

**Rules**:
- `@Amount = ROUND(Amount * ExchangeRate, 0)` - rounds to nearest integer
- Payment.Amount: stored in local currency (possibly in cents - consistent with other legacy procedures dividing by 100)
- Payment.ExchangeRate: dtPrice (decimal(16,8)) FX rate to USD
- Result is passed directly to AmountAdd as integer USD units

### 2.4 Error Handling Quirk (Two Separate TRY/CATCH Blocks)

**What**: Validation and execution have separate TRY/CATCH blocks, creating an important behavioral edge case.

**Rules**:
- Validation TRY/CATCH (lines 25-56): validation only, no transaction
  - CATCH: re-RAISERROR with full diagnostic message (procedure, message, number, line)
  - After CATCH re-RAISERROR: execution CONTINUES to the second TRY block (SQL Server severity 16 does not terminate the batch)
  - If validation fails: second block still executes with potentially NULL/invalid @CID, @Amount, @PaymentStatusID
  - In practice: PaymentUpdate with NULL @PreviousPaymentStatusID -> guard NULL!=2 is FALSE -> UPDATE affects 0 rows (no error). AmountAdd with NULL @CID may fail with its own error.
- Execution TRY/CATCH (lines 59-107): ROLLBACK at @@TRANCOUNT=1, COMMIT at @@TRANCOUNT>1, RAISERROR with diagnostic
- RETURN 0 only reached on full success; RETURN @Answer on AmountAdd failure

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentID | INTEGER | NO | - | CODE-BACKED | PK of Billing.Payment to approve. Validated for existence before processing. Must not already be credited or approved. |
| 2 | @ManagerID | INTEGER | NO | - | CODE-BACKED | Back-office manager ID performing the approval. Passed to Billing.AmountAdd as the authorizing manager. Stored in History.Credit for audit trail. |
| 3 | RETURN value | INTEGER | - | - | CODE-BACKED | 0=success. 60025=validation failure (payment not found, already processed, or already approved). Non-zero=error code from Billing.AmountAdd if it fails. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT (validation) | [Billing.Payment](../Tables/Billing.Payment.md) | READ | Checks existence; reads CID, PaymentStatusID, Amount, ExchangeRate |
| SELECT (validation) | History.Credit | READ | Checks for existing credit (deduplication guard) |
| EXEC | [Billing.PaymentUpdate](Billing.PaymentUpdate.md) | EXEC caller | Transitions payment status to Approved (2) with audit |
| EXEC | Billing.AmountAdd | EXEC caller | Credits USD-converted amount to customer's account |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Back-office application (external) | @PaymentID, @ManagerID | EXEC caller | Called by back-office operators to manually approve legacy payments |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.ManualPaymentProcess (procedure)
├── Billing.Payment (table) - validation reads
├── History.Credit (table) - deduplication check
├── Billing.PaymentUpdate (procedure) - status transition
│   ├── Billing.Payment (table)
│   ├── History.Payment (table)
│   └── Billing.Terminal (table)
└── Billing.AmountAdd (procedure) - credit creation
    └── History.Credit (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Billing.Payment](../Tables/Billing.Payment.md) | Table | SELECT - existence check + read CID, PaymentStatusID, Amount, ExchangeRate |
| History.Credit | Table | SELECT - deduplication guard (CreditTypeID=1, PaymentID) |
| [Billing.PaymentUpdate](Billing.PaymentUpdate.md) | Procedure | EXEC - status transition to Approved (2) with audit |
| Billing.AmountAdd | Procedure | EXEC - credits USD amount to customer account |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Back-office application (external) | Application | Called to manually approve legacy Billing.Payment deposits |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Two separate TRY/CATCH blocks: validation (no transaction) and execution (transaction). Error 60025 used for multiple validation failures. RAISERROR in the validation CATCH does not terminate the batch - the execution block runs regardless (SQL Server severity-16 behavior). Amount conversion: ROUND(Amount*ExchangeRate, 0). History.Credit CreditTypeID=1 guard prevents double-crediting. Target table Billing.Payment frozen since 2011-01-16.

---

## 8. Sample Queries

### 8.1 Manually approve a legacy payment

```sql
DECLARE @Err INTEGER;
EXEC @Err = Billing.ManualPaymentProcess
    @PaymentID = 12345,
    @ManagerID = 101;  -- back-office manager
SELECT @Err AS ErrorCode;
```

### 8.2 Find pending legacy payments eligible for manual approval

```sql
SELECT
    bp.PaymentID,
    bp.CID,
    bp.Amount,
    bp.ExchangeRate,
    ROUND(bp.Amount * bp.ExchangeRate, 0) AS AmountUSD,
    bp.PaymentDate,
    ft.Name AS FundingType,
    ps.Name AS CurrentStatus
FROM Billing.Payment bp WITH (NOLOCK)
INNER JOIN Dictionary.FundingType ft WITH (NOLOCK) ON ft.FundingTypeID = bp.FundingTypeID
INNER JOIN Dictionary.PaymentStatus ps WITH (NOLOCK) ON ps.PaymentStatusID = bp.PaymentStatusID
WHERE bp.PaymentStatusID <> 2  -- not already Approved
  AND NOT EXISTS (
    SELECT 1 FROM History.Credit hc WITH (NOLOCK)
    WHERE hc.CreditTypeID = 1 AND hc.PaymentID = bp.PaymentID
  )
ORDER BY bp.PaymentDate;
```

### 8.3 Check approval history for a legacy payment

```sql
SELECT
    hp.PaymentHistoryID,
    hp.ModificationDate,
    hp.PreviousPaymentStatusID,
    hp.ChangedToPaymentStatusID,
    hp.Reason
FROM History.Payment hp WITH (NOLOCK)
WHERE hp.PaymentID = 12345
  AND hp.ChangedToPaymentStatusID = 2  -- Approved
ORDER BY hp.ModificationDate;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.1/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.ManualPaymentProcess | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.ManualPaymentProcess.sql*
