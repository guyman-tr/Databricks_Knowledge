# Trade.PayInterest

> Pays monthly interest to a customer's balance (idempotency-guarded), calling Customer.SetBalanceCompensation with CompensationReasonID=57 and recording the payment in History.InterestPaymentsLog.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InterestMonthlyID + @CID + @MonthOfInterest (payment dedup key) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

eToro pays interest to customers who maintain eligible balances (e.g., cash interest programs). This procedure processes a single monthly interest payment for one customer. The interest amount is pre-calculated by the caller and passed as `@Payment`.

The procedure is idempotent: before applying the payment, it checks `History.InterestPaymentsLog` using a two-field OR condition - either the `@InterestMonthlyID` was already paid (prevents re-paying the exact same interest record) OR the same `@CID + @MonthOfInterest` combination was already paid (prevents double-paying the same month for the same customer even if the InterestMonthlyID differs). If either match is found, the procedure silently exits with no error.

The `@ErrOut OUTPUT` parameter captures error context without RAISERROR, allowing the caller to handle failures without exception propagation.

Data flow: Check idempotency -> BEGIN TRAN -> Customer.SetBalanceCompensation -> INSERT History.InterestPaymentsLog -> COMMIT. On error: ROLLBACK, set @ErrOut, return @ErrOut as result set.

---

## 2. Business Logic

### 2.1 Double-Payment Prevention (Dual Idempotency Check)

**What**: Skips payment if the interest has already been paid by InterestMonthlyID OR by CID+Month.

**Columns/Parameters Involved**: `History.InterestPaymentsLog.InterestMonthlyID`, `History.InterestPaymentsLog.CID`, `History.InterestPaymentsLog.MonthOfInterest`

**Rules**:
- IF NOT EXISTS (SELECT 1 FROM History.InterestPaymentsLog WHERE (InterestMonthlyID=@InterestMonthlyID) OR (CID=@CID AND MonthOfInterest=@MonthOfInterest))
- If either condition matches: entire BEGIN TRY block is skipped (no payment, no log, no error)
- OR logic: prevents both exact-record replay AND same-month double-pay scenarios
- Silent skip: procedure exits normally with no output - caller must check log if confirmation needed

### 2.2 Balance Compensation Application

**What**: Credits the interest payment to the customer's balance via the compensation path.

**Columns/Parameters Involved**: `@CID`, `@Payment`, `@Description`, `@CompensationReasonID=57`

**Rules**:
- EXEC Customer.SetBalanceCompensation
  - @CID = @CID
  - @Payment = @Payment (pre-calculated interest amount in account currency)
  - @Description = @Description (caller-provided, e.g. 'Monthly interest for March 2026')
  - @CompensationReasonID = 57 (hard-coded - Interest payment reason)
  - @MoveMoneyReasonID = 0 (no money movement reason)
  - @ErrOut = @ErrOut OUTPUT (captures any balance error)
  - @InterestMonthlyID = @InterestMonthlyID (passed through for audit linking)
- This is a compensation (not a fee/clame): uses the SetBalanceCompensation path (vs SetBalanceClameFee for fees)

### 2.3 Payment Log Recording

**What**: Records the successful payment to prevent future duplicate processing.

**Columns/Parameters Involved**: `History.InterestPaymentsLog.CID`, `History.InterestPaymentsLog.MonthOfInterest`, `History.InterestPaymentsLog.InterestMonthlyID`

**Rules**:
- INSERT INTO History.InterestPaymentsLog (CID, MonthOfInterest, InterestMonthlyID)
- Inserted within the same transaction as SetBalanceCompensation
- If this insert fails, the transaction rolls back (balance change reversed)

### 2.4 Error Handling via @ErrOut OUTPUT

**What**: Returns error details without raising exceptions.

**Columns/Parameters Involved**: `@ErrOut OUTPUT`

**Rules**:
- CATCH: ROLLBACK TRANSACTION
- IF @ErrOut IS NULL: SET @ErrOut = ERROR_MESSAGE() (only if SetBalanceCompensation didn't already populate it)
- SELECT @ErrOut (returns as result set for callers that read result sets)
- Caller checks @ErrOut IS NOT NULL to detect failure

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to credit the interest payment. Used in idempotency check (CID+MonthOfInterest), SetBalanceCompensation call, and InterestPaymentsLog insert. |
| 2 | @Payment | INT | NO | - | CODE-BACKED | Pre-calculated interest amount to credit to the customer's balance. Passed as-is to Customer.SetBalanceCompensation. Note: INT type (cents or basis units, not MONEY). |
| 3 | @Description | VARCHAR(255) | NO | - | CODE-BACKED | Human-readable description for the interest payment. Passed to SetBalanceCompensation for the balance event description. Typically includes the month/period reference. |
| 4 | @ErrOut | NVARCHAR(4000) | YES | NULL OUTPUT | CODE-BACKED | OUTPUT: error message on failure. May be pre-populated by SetBalanceCompensation (checked before overwrite). Also returned as a result set via SELECT @ErrOut in CATCH. |
| 5 | @InterestMonthlyID | BIGINT | NO | - | CODE-BACKED | Primary key of the interest record being paid (from an interest calculation table). Used for exact-ID idempotency check and passed to SetBalanceCompensation for audit linking. |
| 6 | @MonthOfInterest | DATE | NO | - | CODE-BACKED | The month for which interest is being paid. Used in the dual idempotency check (CID+MonthOfInterest) and stored in History.InterestPaymentsLog to prevent double-paying the same customer for the same month. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InterestMonthlyID/@CID/@MonthOfInterest | History.InterestPaymentsLog | READ + INSERT | Idempotency check (READ) and payment record (INSERT) - both within same transaction |
| @CID/@Payment | Customer.SetBalanceCompensation | EXEC (CALL) | Credits interest amount to customer balance with CompensationReasonID=57 |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PayInterest (procedure)
+-- History.InterestPaymentsLog (table) [READ + INSERT - idempotency check and payment audit]
+-- Customer.SetBalanceCompensation (procedure) [EXEC - balance credit with CompensationReasonID=57]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.InterestPaymentsLog | Table | Pre-check for duplicate payment; INSERT after successful payment to prevent future duplicates |
| Customer.SetBalanceCompensation | Stored Procedure | Credits interest payment to customer balance (CompensationReasonID=57, MoveMoneyReasonID=0) |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CompensationReasonID=57 | Design constant | Hard-coded reason code for interest payments in the compensation system |
| MoveMoneyReasonID=0 | Design constant | No money movement reason for interest (pure compensation) |
| Dual idempotency (InterestMonthlyID OR CID+Month) | Business rule | Prevents replay of exact record AND prevents double-paying same month |
| @ErrOut IS NULL check before overwrite | Error handling | Preserves SetBalanceCompensation's error if it populated @ErrOut before the transaction failed |
| @Payment is INT (not MONEY) | Note | Payment amount uses INT type - likely represents smallest currency units or a specific scale agreed with the caller |

---

## 8. Sample Queries

### 8.1 Pay monthly interest for a customer
```sql
DECLARE @ErrOut NVARCHAR(4000);

EXEC Trade.PayInterest
    @CID              = 111222,
    @Payment          = 1500,       -- e.g. 15.00 in cents or per agreed scale
    @Description      = 'Monthly interest - March 2026',
    @ErrOut           = @ErrOut OUTPUT,
    @InterestMonthlyID = 9876543,
    @MonthOfInterest  = '2026-03-01';

IF @ErrOut IS NOT NULL
    PRINT 'Error: ' + @ErrOut;
```

### 8.2 Check if a customer has received interest for a specific month
```sql
SELECT
    InterestMonthlyID,
    CID,
    MonthOfInterest
FROM History.InterestPaymentsLog WITH (NOLOCK)
WHERE CID = 111222
  AND MonthOfInterest = '2026-03-01';
```

### 8.3 Check recent interest payments for a customer
```sql
SELECT TOP 12
    InterestMonthlyID,
    CID,
    MonthOfInterest
FROM History.InterestPaymentsLog WITH (NOLOCK)
WHERE CID = 111222
ORDER BY MonthOfInterest DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (1,5,8,9B,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (SetBalanceCompensation) | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PayInterest | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PayInterest.sql*
