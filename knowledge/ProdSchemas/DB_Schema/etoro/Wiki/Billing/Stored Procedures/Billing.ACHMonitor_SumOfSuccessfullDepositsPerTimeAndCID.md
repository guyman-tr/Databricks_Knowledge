# Billing.ACHMonitor_SumOfSuccessfullDepositsPerTimeAndCID

> ACH fraud monitoring probe that returns customer IDs whose total successful ACH deposit amount within a rolling hour window exceeds a monetary threshold, used to detect customers with abnormally large approved deposit volumes.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NumberOfHours, @NumberToTrigger input; returns CID + Amount result set |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.ACHMonitor_SumOfSuccessfullDepositsPerTimeAndCID` is a monetary fraud detection probe that monitors the total dollar amount of successful ACH deposits per customer within a rolling hour window. Where `ACHMonitor_NumberOfSuccessfullDepositsPerTimeAndCID` checks for suspicious deposit COUNTS, this procedure checks for suspicious deposit AMOUNTS - catching customers with large cumulative ACH volumes even if the individual count is low.

The procedure uses `@NumberToTrigger` as a monetary threshold (INT type, representing a dollar amount) rather than a count. Customers whose successful ACH deposit sum meets or exceeds this threshold within the window are returned.

---

## 2. Business Logic

### 2.1 Rolling Hour Window for Total Amount

**What**: Sums successful ACH deposit amounts per customer in a rolling hour window.

**Columns/Parameters Involved**: `@NumberOfHours`, `@NumberToTrigger`, `D.PaymentStatusID`, `D.Amount`

**Rules**:
- Window: `PaymentDate > DATEADD(HOUR, -@NumberOfHours, GETDATE())`.
- Filter: FundingTypeID=29 AND PaymentStatusID=2 (Approved only).
- GROUP BY CID; HAVING SUM(Amount) >= @NumberToTrigger.
- @NumberToTrigger is monetary (INT dollars/units), not a count.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NumberOfHours | INT | NO | - | CODE-BACKED | Rolling time window in hours. ACH deposits with PaymentDate after DATEADD(HOUR, -@NumberOfHours, GETDATE()) are included in the sum. |
| 2 | @NumberToTrigger | INT | NO | - | CODE-BACKED | Monetary threshold. Customers whose total successful ACH deposit amount (SUM of Amount) in the window is >= this value are returned. Represents a currency amount (INT, likely USD). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Deposit amounts | Billing.Deposit | READER | Sums Amount for approved ACH deposits per customer |
| FundingTypeID filter | Billing.Funding | JOIN | Filters to ACH (FundingTypeID=29) |

### 5.2 Referenced By (other objects point to this)

No callers found. Called by external monitoring agent or job.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.ACHMonitor_SumOfSuccessfullDepositsPerTimeAndCID (procedure)
|- Billing.Deposit (table) [leaf]
|- Billing.Funding (table) [leaf]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Sums Amount for approved ACH deposits per customer in time window |
| Billing.Funding | Table | JOINed to filter FundingTypeID=29 (ACH) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

SET NOCOUNT ON. PaymentStatusID=2 hardcoded. @NumberToTrigger is INT (monetary, not count). Note: typo in procedure name ("Successfull" with double L).

---

## 8. Sample Queries

### 8.1 Run the probe for 48 hours, USD 50000 threshold

```sql
EXEC Billing.ACHMonitor_SumOfSuccessfullDepositsPerTimeAndCID
    @NumberOfHours = 48,
    @NumberToTrigger = 50000
```

### 8.2 Manual equivalent

```sql
SELECT D.CID, SUM(D.Amount) AS TotalDeposited
FROM Billing.Deposit WITH (NOLOCK) AS D
INNER JOIN Billing.Funding WITH (NOLOCK) AS F ON D.FundingID = F.FundingID
WHERE F.FundingTypeID = 29
  AND D.PaymentDate > DATEADD(HOUR, -48, GETDATE())
  AND D.PaymentStatusID = 2
GROUP BY D.CID
HAVING SUM(D.Amount) >= 50000
ORDER BY TotalDeposited DESC
```

### 8.3 Top ACH depositors by amount in last 24 hours

```sql
SELECT TOP 20
    D.CID,
    COUNT(*) AS DepositCount,
    SUM(D.Amount) AS TotalAmount,
    AVG(D.Amount) AS AvgAmount
FROM Billing.Deposit WITH (NOLOCK) AS D
INNER JOIN Billing.Funding WITH (NOLOCK) AS F ON D.FundingID = F.FundingID
WHERE F.FundingTypeID = 29
  AND D.PaymentDate > DATEADD(HOUR, -24, GETDATE())
  AND D.PaymentStatusID = 2
GROUP BY D.CID
ORDER BY TotalAmount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.ACHMonitor_SumOfSuccessfullDepositsPerTimeAndCID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.ACHMonitor_SumOfSuccessfullDepositsPerTimeAndCID.sql*
