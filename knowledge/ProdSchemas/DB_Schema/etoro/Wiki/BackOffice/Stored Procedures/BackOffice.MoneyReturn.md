# BackOffice.MoneyReturn

> Processes a customer payment return (chargeback, refund, or chargeback-as-refund) by updating the payment record, logging the status change to history, and adjusting the customer's balance.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Orchestrates: UPDATE Billing.Payment + INSERT History.Payment + EXEC Customer.SetBalance |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.MoneyReturn` is the back-office procedure for reversing a payment. When a customer's deposit must be returned - because it is a chargeback (card issuer reversal), a refund (customer request), or a chargeback processed as a refund (hybrid type) - a back-office manager calls this procedure to execute the three-step return workflow atomically.

The procedure exists to coordinate three distinct systems: the Billing.Payment ledger (status update), the History.Payment audit log (immutable change record), and the Customer balance engine (actual money movement). Without this orchestration layer, each system would need to be updated independently, risking inconsistent state if any step fails.

Data flow: Manager selects a PaymentID and return type. If amount is not supplied, the procedure derives it from the payment record (converting from cents to dollars using exchange rate). It maps the return type to a CreditTypeID for balance adjustment. It then executes within a TRY/CATCH transaction: (1) updates Billing.Payment to status 2 (returned), (2) logs the status change to History.Payment, (3) calls Customer.SetBalance with the return amount in cents and the appropriate credit type.

---

## 2. Business Logic

### 2.1 Return Type to Credit Type Mapping

**What**: The caller specifies the return flavor (11=chargeback, 12=refund, 26=chargebackAsRefund), which maps to a different CreditTypeID used in Customer.SetBalance.

**Columns/Parameters Involved**: `@PaymentStatusID`, internal `@CreditTypeID`

**Rules**:
- Valid inputs: 11 (chargeback), 12 (refund), 26 (chargeback processed as refund). Any other value raises error 60025.
- CreditTypeID mapping: 11 -> 11 (chargeback credit), 12 -> 12 (refund credit), 26 -> 16 (chargeback-as-refund credit type).
- The CreditTypeID is captured BEFORE the status override in step 2.2 below. It preserves the original return intent for Customer.SetBalance even after the payment status is normalized.

**Diagram**:
```
@PaymentStatusID input     CreditTypeID passed to Customer.SetBalance
     11 (chargeback)   ->   11
     12 (refund)       ->   12
     26 (CB as refund) ->   16
     Other             ->   RAISERROR 60025
```

### 2.2 Payment Status Override to 2

**What**: Despite accepting 11, 12, or 26, the actual status written to Billing.Payment is always 2 for positive-amount returns.

**Columns/Parameters Involved**: `@PaymentStatusID`, `@Amount`

**Rules**:
- After the CreditTypeID mapping, if (@PaymentStatusID != 2 AND @Amount > 0): SET @PaymentStatusID = 2.
- For all normal use cases (valid status 11/12/26, positive amount), this overrides @PaymentStatusID to 2.
- Billing.Payment.PaymentStatusID = 2 means "cancelled/rolled back" in the payment ledger.
- History.Payment also receives ChangedToPaymentStatusID = 2 (the overridden value).
- The specific return intent (chargeback vs refund) is preserved ONLY in the CreditTypeID passed to Customer.SetBalance.
- The comment "cancel rollback" in the code indicates this maps return operations to the general "cancelled" state in Billing.Payment.

### 2.3 Amount Derivation and Unit Conversion

**What**: Amount is stored in cents in Billing.Payment but passed in dollars to Customer.SetBalance (which expects cents).

**Columns/Parameters Involved**: `@Amount`, `Billing.Payment.Amount`, `Billing.Payment.ExchangeRate`

**Rules**:
- If @Amount IS NULL: read CAST(Amount/100.0 * ExchangeRate AS MONEY) from Billing.Payment. This divides stored cents by 100 (to get dollars) then multiplies by exchange rate (for multi-currency payments).
- Before calling Customer.SetBalance: SET @Amount = CAST(@Amount * 100 AS INTEGER) - converts back to cents. Customer.SetBalance expects amounts in cents.
- Callers may override the amount by passing a non-NULL @Amount directly (already in dollars).

### 2.4 Error Handling Pattern

**What**: TRY/CATCH wraps the three-step transaction. A mixed transaction count check handles nested transaction scenarios.

**Rules**:
- CATCH checks @@TRANCOUNT = 1: ROLLBACK. @@TRANCOUNT > 1: COMMIT (partial transaction in nested context).
- On catch: raises a composite error message with procedure name, error message, error number, and line.
- Returns 60000 on generic failure.
- Error 60025: validation failure (invalid status or payment not found).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentID | int | NO | - | CODE-BACKED | ID of the Billing.Payment record to return. Must exist in Billing.Payment (validated). The payment being reversed. |
| 2 | @PaymentStatusID | int | NO | - | VERIFIED | Return type: 11=Chargeback (card issuer reversal), 12=Refund (customer request), 26=Chargeback processed as refund (hybrid). Controls which CreditTypeID (11/12/16) is passed to Customer.SetBalance. The value written to Billing.Payment is overridden to 2. |
| 3 | @ManagerID | int | NO | - | CODE-BACKED | ID of the back-office manager authorizing the return. Passed to Customer.SetBalance for audit trail. FK to BackOffice.Manager.ManagerID. |
| 4 | @Reason | varchar(255) | NO | - | CODE-BACKED | Free-text reason for the return. Written to History.Payment.Reason. Required for audit compliance. |
| 5 | @Amount | money | YES | NULL | VERIFIED | Return amount in US dollars. If NULL, derived from Billing.Payment as Amount/100.0 * ExchangeRate. Converted to cents (x100) before passing to Customer.SetBalance. Override for cases requiring a different amount than the original deposit. |
| 6 | @ClearingHouseEffectiveDate | datetime | YES | NULL | CODE-BACKED | Date the clearing house processes the return. Written to both Billing.Payment and History.Payment for reconciliation. NULL for returns not requiring clearing house coordination. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PaymentID | Billing.Payment | Modifier | Updates PaymentStatusID, ModificationDate, ClearingHouseEffectiveDate |
| @PaymentID | History.Payment | Writer | Inserts status change audit record |
| @CID (derived) | Customer.SetBalance | Callee (cross-schema) | Adjusts customer balance by return amount with credit type |

### 5.2 Referenced By (other objects point to this)

No SQL-layer callers found in BackOffice schema. Called from the BackOffice application by authorized managers processing payment returns.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.MoneyReturn (procedure)
+-- Billing.Payment (table) [UPDATE + SELECT for amount]
+-- History.Payment (table) [INSERT audit record]
+-- Customer.SetBalance (procedure) [EXEC - balance adjustment]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Payment | Table | UPDATE (payment status, dates) + SELECT (amount derivation if @Amount NULL) |
| History.Payment | Table | INSERT (status change audit log) |
| Customer.SetBalance | Stored Procedure | EXEC (balance adjustment with credit type and amount) |

### 6.2 Objects That Depend On This

No SQL-layer dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Process a chargeback for a known payment

```sql
EXEC BackOffice.MoneyReturn
    @PaymentID = 12345678,
    @PaymentStatusID = 11,  -- Chargeback
    @ManagerID = 701,
    @Reason = 'Card issuer initiated chargeback - fraud dispute',
    @Amount = NULL,         -- Use amount from payment record
    @ClearingHouseEffectiveDate = '2026-03-18';
```

### 8.2 Process a refund with explicit amount

```sql
EXEC BackOffice.MoneyReturn
    @PaymentID = 12345678,
    @PaymentStatusID = 12,  -- Refund
    @ManagerID = 701,
    @Reason = 'Customer requested refund - account closing',
    @Amount = 500.00,       -- Override: $500 USD
    @ClearingHouseEffectiveDate = NULL;
```

### 8.3 Check payment history after a return

```sql
SELECT hp.PaymentID, hp.PreviousPaymentStatusID, hp.ChangedToPaymentStatusID,
       hp.ModificationDate, hp.Reason
FROM History.Payment hp WITH (NOLOCK)
WHERE hp.PaymentID = 12345678
ORDER BY hp.ModificationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Multi-Currency Balance API](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/14028570661) | Confluence | Context: MoneyReturn is referenced in the context of the Multi-Currency Balance microservice replacing Billing SP entry-points; chargeback/refund flows are part of the balance operation landscape (MEDIUM confidence - page describes replacement, not MoneyReturn specifically) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Proc Ref Scan, Atlassian, Doc Gen)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.MoneyReturn | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.MoneyReturn.sql*
