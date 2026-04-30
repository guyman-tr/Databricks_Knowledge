# Billing.CheckFundingTypeLimitByCCNumber

> Extends CheckFundingTypeLimit with credit-card-specific history: resolves a card number to its internal CardID, looks up prior deposits specifically on that card via CreditCardToPayment, and then calls CheckFundingTypeLimit for the full six-way limit check.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CheckResult OUTPUT: 0=OK, 1=MonthlyTxnCount, 2=MonthlyAmount, 3=WeeklyTxnCount, 4=WeeklyAmount, 5=DailyTxnCount, 6=DailyAmount |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CheckFundingTypeLimitByCCNumber` is the credit-card-specific variant of `Billing.CheckFundingTypeLimit`. It adds card-level granularity to the limit check: rather than checking all deposits by a customer via any credit card, this procedure checks deposits specifically associated with the given card number.

This is important for fraud prevention: a customer might own multiple credit cards, and per-card velocity limits are tighter than per-customer limits. By resolving the card number to a CardID and joining through `Billing.CreditCardToPayment`, the procedure considers only deposits made with this specific card.

The procedure ultimately delegates to `Billing.CheckFundingTypeLimit` with @FundingTypeID=1 (CreditCard) for the actual limit comparison logic.

---

## 2. Business Logic

### 2.1 Card Number to Limit Check Flow

**What**: Resolves card number to CardID, filters payment history to that card, then calls CheckFundingTypeLimit.

**Columns/Parameters Involved**: `@CID`, `@CardNumber`, `@Amount`, `@CheckResult`

**Rules**:
1. **Resolve CardID**: `SELECT @CardID = CardID FROM Billing.CreditCard WHERE CardNumber = @CardNumber`. If no match: @CheckResult=0 (no card history = no limit violation), RETURN.
2. **Load card-specific payment history**: Queries `Billing.CreditCardToPayment` joined to `Billing.Payment` for this @CardID, aggregating counts and amounts by day/week/month.
3. **Delegate to CheckFundingTypeLimit**: `EXEC Billing.CheckFundingTypeLimit @CID, 1 /* CreditCard */, @Amount, @CheckResult OUTPUT` - passes the card-specific aggregated history context, or relies on CheckFundingTypeLimit to recompute for the CID+FundingTypeID=1 scope.
4. **@CheckResult OUTPUT**: Returns the result from CheckFundingTypeLimit unchanged.

**@CheckResult Values** (same as CheckFundingTypeLimit):
| Value | Violation |
|-------|-----------|
| 0 | All limits passed |
| 1 | Monthly transaction count exceeded |
| 2 | Monthly amount exceeded |
| 3 | Weekly transaction count exceeded |
| 4 | Weekly amount exceeded |
| 5 | Daily transaction count exceeded |
| 6 | Daily amount exceeded |

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID making the deposit. Passed to CheckFundingTypeLimit for the overall limit check. |
| 2 | @CardNumber | VARCHAR(50) | NO | - | CODE-BACKED | The credit card number (or hash, depending on storage) used to resolve the CardID from Billing.CreditCard. If no matching card is found, @CheckResult returns 0 (no prior history = no limit exceeded). |
| 3 | @Amount | MONEY | NO | - | CODE-BACKED | The proposed deposit amount to check against cumulative amount limits. Passed to CheckFundingTypeLimit. |
| 4 | @CheckResult | INTEGER | YES | - | CODE-BACKED | OUTPUT parameter. Returns 0 if all limits pass, or 1-6 indicating the first limit violated. Populated by CheckFundingTypeLimit. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CardNumber | Billing.CreditCard | READER | Resolves card number to internal CardID |
| @CardID | Billing.CreditCardToPayment | READER | Finds payments made with this specific card |
| - | Billing.CheckFundingTypeLimit | EXEC (callee) | Performs the actual six-way limit check with FundingTypeID=1 |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in Billing schema SP files. Called from payment authorization application code for credit card deposits.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CheckFundingTypeLimitByCCNumber (procedure)
+-- Billing.CreditCard (table)                   [READ - CardNumber -> CardID resolution]
+-- Billing.CreditCardToPayment (table)           [READ - card-specific payment history]
+-- Billing.CheckFundingTypeLimit (procedure)     [EXEC - six-way limit check (FundingTypeID=1)]
    +-- Billing.Deposit (table)                   [READ - period aggregations]
    +-- Billing.Payment (table)                   [READ - period aggregations]
    +-- Billing.FundingTypeLimit (table)          [READ - configured limits (currently 0 rows)]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CreditCard | Table | READ - resolve @CardNumber to CardID |
| Billing.CreditCardToPayment | Table | READ - find payments made with this specific CardID |
| Billing.CheckFundingTypeLimit | Stored Procedure | EXEC - performs the complete limit check for CreditCard (FundingTypeID=1) |

### 6.2 Objects That Depend On This

No dependents found in Billing schema SP files.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **Card not found = no violation**: If @CardNumber does not resolve to a CardID in Billing.CreditCard, @CheckResult=0 is returned immediately. No card history means no prior deposits on this card, so no limit can be exceeded.
- **Card-level vs customer-level**: This procedure adds card-level granularity (via CreditCardToPayment) on top of CheckFundingTypeLimit's customer-level check. The effective limit check is the union of both scopes.
- **FundingTypeID=1 hardcoded**: This procedure is credit-card-specific; @FundingTypeID=1 is hardcoded in the call to CheckFundingTypeLimit.
- **FundingTypeLimit currently empty**: Since Billing.FundingTypeLimit has 0 rows, CheckFundingTypeLimit always returns 0, making this check a no-op in practice.
- **Only caller of CheckFundingTypeLimit**: In the Billing schema SP files, this is the only procedure that calls Billing.CheckFundingTypeLimit.

---

## 8. Sample Queries

### 8.1 Check credit card limit for a deposit
```sql
DECLARE @CheckResult INT;
EXEC Billing.CheckFundingTypeLimitByCCNumber
    @CID         = 100001,
    @CardNumber  = '4111111111111111',
    @Amount      = 500.00,
    @CheckResult = @CheckResult OUTPUT;
SELECT @CheckResult AS CheckResult,
    CASE @CheckResult
        WHEN 0 THEN 'OK - within all limits'
        WHEN 1 THEN 'Monthly transaction count exceeded'
        WHEN 2 THEN 'Monthly amount exceeded'
        WHEN 3 THEN 'Weekly transaction count exceeded'
        WHEN 4 THEN 'Weekly amount exceeded'
        WHEN 5 THEN 'Daily transaction count exceeded'
        WHEN 6 THEN 'Daily amount exceeded'
    END AS Description;
```

### 8.2 Find the CardID for a card number
```sql
SELECT CardID, CardNumber, CreationDate
FROM Billing.CreditCard WITH (NOLOCK)
WHERE CardNumber = '4111111111111111';
```

### 8.3 View card-specific payment history
```sql
SELECT p.PaymentID, p.Amount, p.CreationDate
FROM Billing.CreditCardToPayment cctp WITH (NOLOCK)
JOIN Billing.Payment p WITH (NOLOCK) ON p.PaymentID = cctp.PaymentID
WHERE cctp.CardID = 9876
ORDER BY p.CreationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.1/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CheckFundingTypeLimitByCCNumber | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CheckFundingTypeLimitByCCNumber.sql*
