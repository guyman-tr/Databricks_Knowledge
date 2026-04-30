# Billing.CheckCustomerForFistPayment

> Checks whether a customer has ever made a successful deposit (PaymentStatusID=2 in Billing.Deposit), returning a result set with 1 (has prior deposit) or 0 (no prior deposit); used to distinguish first-time depositors from returning depositors.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN @@ERROR; result set with single integer column (1=has deposit, 0=no deposit) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CheckCustomerForFistPayment` (note: "Fist" is a typo for "First" in the original procedure name) determines whether a given customer has previously made a successful deposit. This distinction matters for:
- **Bonus eligibility**: First-deposit bonuses apply only to customers with no prior successful deposits
- **Conversion tracking**: Marketing tracks the "first deposit" event as a key activation milestone
- **Fraud scoring**: Payment risk models treat first-time depositors differently from returning customers

The procedure checks `Billing.Deposit` for any row with the given CID and `PaymentStatusID=2` (Approved/Successful). A result of 1 means the customer has previously deposited; 0 means this would be their first deposit.

---

## 2. Business Logic

### 2.1 First-Deposit Check

**What**: Determines if the customer has any approved deposit on record.

**Rules**:
- `SELECT @CheckResult = CASE WHEN EXISTS(...) THEN 1 ELSE 0 END`
- EXISTS subquery: `SELECT 1 FROM Billing.Deposit WHERE CID = @CID AND PaymentStatusID = 2`
- PaymentStatusID=2 = Approved/Successful deposit (as documented in Billing.Deposit).
- `SELECT @CheckResult` - returns a result set with the single value.
- RETURN @@ERROR.

**Result Set**:
| Value | Meaning |
|-------|---------|
| 1 | Customer has at least one approved deposit - NOT a first-time depositor |
| 0 | Customer has no approved deposits - this IS their first deposit |

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID to check for prior deposits. Compared against Billing.Deposit.CID with PaymentStatusID=2 filter. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Billing.Deposit | READER | EXISTS check for CID + PaymentStatusID=2 (approved deposits) |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in Billing schema SP files. Called from application code during deposit flow for first-deposit detection.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CheckCustomerForFistPayment (procedure)
+-- Billing.Deposit (table)   [READ - EXISTS check for CID with PaymentStatusID=2]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | READ - EXISTS check for at least one approved (PaymentStatusID=2) deposit by this CID |

### 6.2 Objects That Depend On This

No dependents found in Billing schema SP files.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **Name typo**: The procedure name contains "Fist" instead of "First" - this is a long-standing typo in the original code and cannot be changed without updating all callers.
- **PaymentStatusID=2 = Approved**: Only counts deposits that successfully completed. Pending (1), failed (3+), or reversed deposits do not count as prior payments for this check.
- **EXISTS for efficiency**: Uses EXISTS (not COUNT) so SQL Server short-circuits on the first matching row. With Billing.Deposit potentially having millions of rows, this is important for performance.
- **Result set not OUTPUT**: Returns the check result as a result set rather than an OUTPUT parameter. Callers must consume the result set to get the value.

---

## 8. Sample Queries

### 8.1 Check if a customer has prior deposits
```sql
EXEC Billing.CheckCustomerForFistPayment @CID = 100001;
-- Returns: 1 (has prior deposit) or 0 (first-time depositor)
```

### 8.2 Verify directly in Billing.Deposit
```sql
SELECT TOP 1 CID, PaymentStatusID, CreationDate
FROM Billing.Deposit WITH (NOLOCK)
WHERE CID = 100001
  AND PaymentStatusID = 2
ORDER BY CreationDate;
-- Returns row if customer has prior approved deposit
```

### 8.3 Count approved deposits per customer
```sql
SELECT CID, COUNT(*) AS DepositCount, MIN(CreationDate) AS FirstDepositDate
FROM Billing.Deposit WITH (NOLOCK)
WHERE PaymentStatusID = 2
  AND CID = 100001
GROUP BY CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CheckCustomerForFistPayment | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CheckCustomerForFistPayment.sql*
