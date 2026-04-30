# Billing.CheckFundingTypeLimit

> Validates a proposed deposit amount against the payment method's configured daily/weekly/monthly transaction count and amount limits from Billing.FundingTypeLimit, returning @CheckResult=0 if the deposit is within all limits or a specific violation code (1-6) if any limit is exceeded.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CheckResult OUTPUT: 0=OK, 1=MonthlyTxnCount, 2=MonthlyAmount, 3=WeeklyTxnCount, 4=WeeklyAmount, 5=DailyTxnCount, 6=DailyAmount |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CheckFundingTypeLimit` enforces per-payment-method deposit velocity limits. Before approving a deposit, the payment system checks whether the customer has already hit the configured limits for that specific funding type (e.g., credit card, PayPal, wire transfer) within the current day, week, or month.

The check has six possible violations, checked in priority order:
1. Monthly transaction count limit
2. Monthly cumulative amount limit
3. Weekly transaction count limit
4. Weekly cumulative amount limit
5. Daily transaction count limit
6. Daily cumulative amount limit

If all six checks pass, @CheckResult=0 (approved). The first failing check sets @CheckResult to the corresponding violation code and the procedure exits. This allows the caller to return a specific rejection reason to the customer.

Note: `Billing.FundingTypeLimit` currently has 0 rows (no limits configured), so in practice this procedure always returns @CheckResult=0. The infrastructure exists for future enforcement.

---

## 2. Business Logic

### 2.1 Limit Enforcement Flow

**What**: Loads current period deposit totals and compares against configured FundingType limits.

**Columns/Parameters Involved**: `@CID`, `@FundingTypeID`, `@Amount`, `@CheckResult`

**Rules**:
1. **Load history**: Queries `Billing.Deposit` and `Billing.Payment` for the customer's deposits with the given FundingTypeID, filtered to the current calendar month, week (Monday-based), and day.
2. **Load limits**: Reads from `Billing.FundingTypeLimit` for the given FundingTypeID. If no row exists (currently always true - 0 rows), all limits default to NULL, and all limit checks pass (NULL > any value = NULL = not exceeded).
3. **Monthly transaction count**: If (existing monthly deposit count + 1) > MonthlyTransactionLimit -> @CheckResult=1, RETURN.
4. **Monthly amount**: If (existing monthly amount + @Amount) > MonthlyAmountLimit -> @CheckResult=2, RETURN.
5. **Weekly transaction count**: If (existing weekly deposit count + 1) > WeeklyTransactionLimit -> @CheckResult=3, RETURN.
6. **Weekly amount**: If (existing weekly amount + @Amount) > WeeklyAmountLimit -> @CheckResult=4, RETURN.
7. **Daily transaction count**: If (existing daily deposit count + 1) > DailyTransactionLimit -> @CheckResult=5, RETURN.
8. **Daily amount**: If (existing daily amount + @Amount) > DailyAmountLimit -> @CheckResult=6, RETURN.
9. **All pass**: @CheckResult=0, RETURN.

**@CheckResult Values**:
| Value | Violation | Description |
|-------|-----------|-------------|
| 0 | None | All limits passed - deposit is within bounds |
| 1 | MonthlyTxnCount | Too many transactions this calendar month |
| 2 | MonthlyAmount | Too much cumulative amount this calendar month |
| 3 | WeeklyTxnCount | Too many transactions this week (Monday-Sunday) |
| 4 | WeeklyAmount | Too much cumulative amount this week |
| 5 | DailyTxnCount | Too many transactions today |
| 6 | DailyAmount | Too much cumulative amount today |

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID whose deposit history is being checked. Used to query Billing.Deposit and Billing.Payment for prior transactions with the given FundingTypeID. |
| 2 | @FundingTypeID | INTEGER | NO | - | CODE-BACKED | Payment method being used for the deposit (1=CreditCard, 2=WireTransfer, 3=PayPal, etc.). Used both to filter the deposit history and to look up the corresponding limit record in Billing.FundingTypeLimit. |
| 3 | @Amount | MONEY | NO | - | CODE-BACKED | The proposed deposit amount to add to the running period totals when checking cumulative amount limits (@CheckResult=2, 4, 6). |
| 4 | @CheckResult | INTEGER | YES | - | CODE-BACKED | OUTPUT parameter. Returns 0 if all limits pass, or 1-6 indicating the first limit violated. Set to 0 on entry; only changed if a limit is exceeded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID + @FundingTypeID | Billing.Deposit | READER | Loads monthly/weekly/daily deposit counts and amounts for this customer+fundingType |
| @CID + @FundingTypeID | Billing.Payment | READER | Loads payment history for the same period aggregations |
| @FundingTypeID | Billing.FundingTypeLimit | READER | Reads the configured limits (currently 0 rows - no limits active) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.CheckFundingTypeLimitByCCNumber | EXEC | Caller | Calls this procedure after resolving CardNumber -> FundingTypeID |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CheckFundingTypeLimit (procedure)
+-- Billing.Deposit (table)            [READ - period deposit count/amount aggregation]
+-- Billing.Payment (table)            [READ - period payment count/amount aggregation]
+-- Billing.FundingTypeLimit (table)   [READ - configured limits (currently 0 rows)]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | READ - aggregates deposit count and amount by day/week/month for this CID+FundingTypeID |
| Billing.Payment | Table | READ - aggregates payment count and amount by same periods |
| Billing.FundingTypeLimit | Table | READ - loads configured transaction and amount limits per FundingTypeID (currently empty) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.CheckFundingTypeLimitByCCNumber | Stored Procedure | Caller - resolves card number to FundingTypeID then calls this procedure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **FundingTypeLimit currently empty**: Billing.FundingTypeLimit has 0 rows. All limit comparisons against NULL evaluate to NULL (not TRUE), so all checks pass. The limit enforcement infrastructure is present but dormant.
- **> vs >=**: Limit checks use strict greater-than (`>`). If the limit is 3 transactions per day, the 4th transaction fails (count+1=4 > 3). This means the limit value represents the maximum allowed count/amount.
- **Priority ordering**: Checks run monthly -> weekly -> daily and count -> amount within each period. The first failing check immediately returns - subsequent checks are not evaluated.
- **Week definition**: Week aggregation uses a Monday-based week boundary (consistent with Billing.MemberLimit behavior). `DATEPART(weekday, ...)` adjusted for Monday start.
- **Called only by CheckFundingTypeLimitByCCNumber internally**: No direct callers found in the Billing schema SP files other than the by-CC-number wrapper.

---

## 8. Sample Queries

### 8.1 Check funding type limit for a deposit
```sql
DECLARE @CheckResult INT;
EXEC Billing.CheckFundingTypeLimit
    @CID           = 100001,
    @FundingTypeID = 1,        -- CreditCard
    @Amount        = 200.00,
    @CheckResult   = @CheckResult OUTPUT;
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

### 8.2 View configured limits
```sql
SELECT FundingTypeID,
       DailyTransactionLimit, DailyAmountLimit,
       WeeklyTransactionLimit, WeeklyAmountLimit,
       MonthlyTransactionLimit, MonthlyAmountLimit
FROM Billing.FundingTypeLimit WITH (NOLOCK);
-- Currently returns 0 rows (no limits configured)
```

### 8.3 Check recent deposits for a customer+fundingType
```sql
SELECT CID, PaymentStatusID, Amount, CreationDate
FROM Billing.Deposit WITH (NOLOCK)
WHERE CID = 100001
  AND FundingTypeID = 1
  AND CreationDate >= CAST(GETDATE() AS DATE)
ORDER BY CreationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 caller analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CheckFundingTypeLimit | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CheckFundingTypeLimit.sql*
