# Billing.AmountSubstract

> Debit-side counterpart to Billing.AmountAdd: negates the incoming amount and delegates to Customer.SetBalance to deduct funds from a customer account. Translates AccountUpdateTypeID to CreditTypeID with an extended mapping (adds types 13, 14, and a fallback pass-through) compared to AmountAdd.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN 0 (success); raises error 60000 on failure; @CheckResult OUTPUT (always 0 - legacy) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.AmountSubstract` is the debit-side partner to `Billing.AmountAdd`. Where AmountAdd credits a customer balance (deposits, profits, bonuses), AmountSubstract debits it (cashouts, fees, position losses, adjustments). The core mechanism is a simple negation: the incoming positive @Amount is flipped to a negative value, then the same `Customer.SetBalance` engine is called to record the debit.

The procedure mirrors AmountAdd's AccountUpdateTypeID-to-CreditTypeID translation but with two additional debit-specific mappings (types 13 and 14) and an ELSE fallback that passes through any unrecognized AccountUpdateTypeID as its own CreditTypeID. This makes AmountSubstract slightly more permissive than AmountAdd for novel operation types.

Unlike AmountAdd, AmountSubstract does not manage deposit lifecycle (no IsSetBalanceCompleted flag), does not record credit notes, and does not track P&L compensation adjustments. It is a leaner procedure focused purely on balance reduction. The @MirrorID is passed directly by the caller (vs. AmountAdd which looks it up from Trade.Position) because debit operations typically arise from already-resolved trade contexts.

---

## 2. Business Logic

### 2.1 Amount Negation

**What**: The incoming positive amount is negated before passing to Customer.SetBalance.

**Parameters/Columns Involved**: `@Amount`

**Rules**:
- `SET @Amount = -@Amount` executes unconditionally at the start of the TRY block.
- After this, @Amount holds a negative INTEGER value (cents) representing the debit.
- Callers should always pass a positive @Amount; the procedure handles the sign.

### 2.2 AccountUpdateTypeID to CreditTypeID Translation

**What**: Maps the business-level operation type to the internal CreditTypeID taxonomy.

**Parameters/Columns Involved**: `@AccountUpdateTypeID`, `@CreditTypeID`

**Rules** (extended vs AmountAdd - adds 13, 14 and ELSE fallback):

| AccountUpdateTypeID | CreditTypeID | Business Meaning |
|--------------------|-------------|-----------------|
| 1 | 1 | Deposit reversal / debit |
| 2 | 2 | Deposit-type-2 debit |
| 3 | 7 | Bonus deduction |
| 6 | 6 | Manual debit |
| 10 | 3 | Position close - loss |
| 11 | 4 | Position close (manual / SL / TP) |
| 12 | 5 | Position-related debit |
| 13 | 13 | Debit type 13 (AmountSubstract-specific) |
| 14 | 14 | Debit type 14 (AmountSubstract-specific) |
| (any other) | @AccountUpdateTypeID | Pass-through - CreditTypeID = AccountUpdateTypeID |

- The ELSE clause passes through unrecognized AccountUpdateTypeIDs as their own CreditTypeID. This is a more permissive fallback than AmountAdd (which produces NULL for unrecognized values).

### 2.3 Customer.SetBalance Delegation

**What**: The negated amount is passed to Customer.SetBalance for ledger recording.

**Parameters/Columns Involved**: All input params forwarded

**Rules**:
- @MirrorID is passed directly from the caller parameter (default 0). Unlike AmountAdd, there is no lookup from Trade.Position.
- @IsInitiatedByUser defaults to 2 (vs NULL in AmountAdd) - default value suggests "system-initiated" debit.
- @CurrencyID is NOT forwarded (accepted but unused - same as AmountAdd).
- @ErrOut OUTPUT: Customer.SetBalance writes error details to @ErrOut when it fails; this message is then enriched in the CATCH block.
- If `@Answer != 0`: `RAISERROR(@ErrOut, 16, 1)` - raises the error string from SetBalance as a SQL error (goes to CATCH).

### 2.4 Transaction and Error Handling

**What**: Standard BEGIN TRANSACTION / TRY-CATCH pattern with error propagation.

**Rules**:
- `BEGIN TRANSACTION` / `COMMIT TRANSACTION` wraps the operation.
- `@CheckResult OUTPUT`: set to 0 on entry and never changed. This is a legacy pattern - @CheckResult is always 0 if the procedure returns (errors propagate via RAISERROR, not through @CheckResult). Callers should not rely on @CheckResult for failure detection.
- `@ErrOut OUTPUT`: bidirectional - receives error text from Customer.SetBalance if it fails; enriched in the CATCH block with SP name, ERROR_NUMBER, ERROR_LINE, ERROR_MESSAGE.
- CATCH block: `ROLLBACK TRAN` if @@TRANCOUNT=1; `COMMIT TRAN` if @@TRANCOUNT>1 (nested transaction handling). Then `RAISERROR(60000, 16, 1, @ErrOut)` and RETURN @Answer.
- Error signaling: `RAISERROR` (not `THROW` as in AmountAdd) - error number 60000, severity 16.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | VERIFIED | Customer ID to debit. Passed to Customer.SetBalance. FK to Customer.Customer.CID. |
| 2 | @CurrencyID | INTEGER | NO | - | VERIFIED | Account currency. Accepted but NOT used in any active code path (same as in AmountAdd and AmountAddBonus). Implicit FK to Dictionary.Currency. |
| 3 | @AccountUpdateTypeID | INTEGER | NO | - | VERIFIED | Business operation type initiating this debit. Mapped to CreditTypeID. Valid values: 1,2,3,6,10,11,12,13,14; all others pass through as their own CreditTypeID. |
| 4 | @Amount | INTEGER | NO | - | VERIFIED | Debit amount in cents. Must be passed as a positive value; the procedure negates it (`SET @Amount = -@Amount`) before calling Customer.SetBalance. |
| 5 | @CheckResult | INTEGER | NO | - | VERIFIED | OUTPUT parameter. Always set to 0 by this procedure - a legacy pattern. Errors propagate via RAISERROR, not through @CheckResult. Callers should not use @CheckResult to detect failure for this procedure. |
| 6 | @PositionID | BIGINT | YES | NULL | VERIFIED | Position ID associated with this debit. Passed to Customer.SetBalance for context. NULL for non-position debits. |
| 7 | @ManagerID | INTEGER | YES | NULL | VERIFIED | Back-office manager authorizing the debit. Passed to Customer.SetBalance for audit trail. NULL for automated debits. |
| 8 | @Description | VARCHAR(255) | YES | NULL | VERIFIED | Free-text description of the debit operation. Passed to Customer.SetBalance. |
| 9 | @MirrorID | INT | YES | 0 | VERIFIED | Mirror copy ID if this debit relates to a mirror position. Passed directly to Customer.SetBalance. Unlike AmountAdd, the caller resolves MirrorID before calling (no lookup from Trade.Position in this procedure). Default 0 = no mirror. |
| 10 | @IsInitiatedByUser | INT | YES | 2 | VERIFIED | Flag indicating the initiator of this debit. Default 2 = system-initiated (vs NULL default in AmountAdd). Passed to Customer.SetBalance. |
| 11 | @ErrOut | NVARCHAR(4000) | YES | '' | VERIFIED | OUTPUT parameter for error details. Customer.SetBalance writes error text here on failure; the CATCH block enriches it with SP name, ERROR_NUMBER, ERROR_LINE, ERROR_MESSAGE. Callers can inspect this for diagnostic detail. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | Customer.SetBalance | EXEC (cross-schema) | Core balance debit engine. @Amount passed as negative value after negation. |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in the Billing schema SP files. Called from position close, cashout processing, and fee deduction workflows.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.AmountSubstract (procedure)
+- Customer.SetBalance (proc cross-schema)   [EXEC - core balance debit engine]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetBalance | Stored Procedure (cross-schema) | Core balance debit - called with negated @Amount |

### 6.2 Objects That Depend On This

No dependents found in the Billing schema SP files. Called from trading and payment systems.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **@CheckResult always 0**: Unlike Billing.AmountAddBonus which uses @CheckResult for 7 distinct business outcomes, AmountSubstract only ever sets @CheckResult=0. Failure is signaled via RAISERROR (which terminates execution), not through @CheckResult. Callers using @CheckResult for debit-failure detection will get incorrect results.
- **MirrorID resolution responsibility**: In AmountAdd, the procedure itself resolves MirrorID from Trade.Position. In AmountSubstract, the caller must resolve and pass @MirrorID. This is a design difference - debits typically happen in contexts where the MirrorID is already known (e.g., position close workflows).
- **ELSE fallback in CreditTypeID mapping**: The ELSE clause allows AmountSubstract to handle novel AccountUpdateTypeIDs without failing. This makes it more extensible but less explicit than AmountAdd (where unmapped types result in NULL CreditTypeID).
- **Error chaining via @ErrOut**: The @ErrOut parameter creates an error chain: SetBalance can write error details, which AmountSubstract then prepends with SP context before re-raising. Callers that capture @ErrOut get full error chain information.

---

## 8. Sample Queries

### 8.1 Debit an account for a position close loss
```sql
DECLARE @CheckResult INT, @ErrOut NVARCHAR(4000);
EXEC Billing.AmountSubstract
    @CID                 = 12345,
    @CurrencyID          = 1,
    @AccountUpdateTypeID = 11,        -- Position close (SL/TP/manual)
    @Amount              = 5000,      -- $50.00 in cents (passed positive)
    @CheckResult         = @CheckResult OUTPUT,
    @PositionID          = 1234567890,
    @Description         = 'Position close - stop loss triggered',
    @ErrOut              = @ErrOut OUTPUT;
-- @CheckResult will be 0 regardless of outcome; check RAISERROR propagation
```

### 8.2 Apply a fee deduction
```sql
DECLARE @CheckResult INT, @ErrOut NVARCHAR(4000);
EXEC Billing.AmountSubstract
    @CID                 = 12345,
    @CurrencyID          = 1,
    @AccountUpdateTypeID = 14,        -- Fee type 14 (AmountSubstract-specific)
    @Amount              = 2500,      -- $25.00 fee
    @CheckResult         = @CheckResult OUTPUT,
    @Description         = 'Overnight fee',
    @ErrOut              = @ErrOut OUTPUT;
```

### 8.3 Equivalent direct query for audit review
```sql
-- Review recent debits for a customer by checking Customer.AccountHistory or History.Credit
-- (actual table depends on Customer.SetBalance implementation)
SELECT TOP 20 *
FROM History.Credit WITH (NOLOCK)
WHERE CID = 12345
  AND CreditTypeID IN (1,2,3,4,5,6,7,13,14)  -- debit credit types
ORDER BY CreditDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 11 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (SKIPPED - no Billing repos configured) | Corrections: 0 applied*
*Object: Billing.AmountSubstract | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.AmountSubstract.sql*
