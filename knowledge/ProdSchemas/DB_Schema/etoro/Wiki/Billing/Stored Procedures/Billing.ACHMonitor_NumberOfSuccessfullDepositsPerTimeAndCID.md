# Billing.ACHMonitor_NumberOfSuccessfullDepositsPerTimeAndCID

> ACH fraud monitoring probe that returns customer IDs with a high number of SUCCESSFUL ACH deposits within a rolling hour window, used to detect customers with abnormally high approved deposit counts.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NumberOfHours, @NumberToTrigger input; returns CID + count result set |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.ACHMonitor_NumberOfSuccessfullDepositsPerTimeAndCID` is a fraud detection probe focused on SUCCESSFUL ACH deposits (PaymentStatusID=2 = Approved). Unlike `ACHMonitor_NumberOfAllDepositsPerTimeAndCID` which counts all attempts, this procedure only counts approved deposits. This targets a different fraud pattern: customers who have successfully completed an abnormally high number of ACH deposits within a short window.

The procedure uses an hourly window (`@NumberOfHours`) rather than minutes, reflecting that successful ACH processing takes more time than mere submission. It returns CID + count pairs for customers meeting the threshold.

---

## 2. Business Logic

### 2.1 Rolling Hour Window for Successful Deposits

**What**: Counts approved ACH deposits per customer in a rolling hour window.

**Columns/Parameters Involved**: `@NumberOfHours`, `@NumberToTrigger`, `D.PaymentStatusID`

**Rules**:
- Window: `PaymentDate > DATEADD(HOUR, -@NumberOfHours, GETDATE())`.
- Filter: FundingTypeID=29 AND PaymentStatusID=2 (Approved/Successful only).
- GROUP BY CID; HAVING COUNT(*) >= @NumberToTrigger.
- PaymentStatusID=2 = Approved (from Dictionary.PaymentStatus).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NumberOfHours | INT | NO | - | CODE-BACKED | Rolling time window in hours. Successful ACH deposits with PaymentDate after DATEADD(HOUR, -@NumberOfHours, GETDATE()) are counted. Example: 50 (from inline comment - ~2 days). |
| 2 | @NumberToTrigger | SMALLINT | NO | - | CODE-BACKED | Alert threshold. Customers with >= this many successful ACH deposits in the window are returned. Example: 1. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Successful deposits | Billing.Deposit | READER | Counts approved ACH deposits per customer (PaymentStatusID=2) |
| FundingTypeID filter | Billing.Funding | JOIN | Filters to ACH (FundingTypeID=29) |

### 5.2 Referenced By (other objects point to this)

No callers found. Called by external monitoring agent or job.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.ACHMonitor_NumberOfSuccessfullDepositsPerTimeAndCID (procedure)
|- Billing.Deposit (table) [leaf]
|- Billing.Funding (table) [leaf]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Counts approved ACH deposits per customer in time window |
| Billing.Funding | Table | JOINed to filter FundingTypeID=29 (ACH) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

SET NOCOUNT ON. PaymentStatusID=2 hardcoded (Approved). Uses HOUR not MINUTE window. Note: typo in procedure name ("Successfull" with double L).

---

## 8. Sample Queries

### 8.1 Run the probe for 24 hours, threshold 3

```sql
EXEC Billing.ACHMonitor_NumberOfSuccessfullDepositsPerTimeAndCID
    @NumberOfHours = 24,
    @NumberToTrigger = 3
```

### 8.2 Manual equivalent

```sql
SELECT D.CID, COUNT(*) AS SuccessfulDeposits
FROM Billing.Deposit WITH (NOLOCK) AS D
INNER JOIN Billing.Funding WITH (NOLOCK) AS F ON D.FundingID = F.FundingID
WHERE F.FundingTypeID = 29
  AND D.PaymentDate > DATEADD(HOUR, -24, GETDATE())
  AND D.PaymentStatusID = 2
GROUP BY D.CID
HAVING COUNT(*) >= 3
ORDER BY SuccessfulDeposits DESC
```

### 8.3 Compare successful vs failed ACH deposits per customer in last 24h

```sql
SELECT
    D.CID,
    SUM(CASE WHEN D.PaymentStatusID = 2 THEN 1 ELSE 0 END) AS Successful,
    SUM(CASE WHEN D.PaymentStatusID <> 2 THEN 1 ELSE 0 END) AS Failed
FROM Billing.Deposit WITH (NOLOCK) AS D
INNER JOIN Billing.Funding WITH (NOLOCK) AS F ON D.FundingID = F.FundingID
WHERE F.FundingTypeID = 29
  AND D.PaymentDate > DATEADD(HOUR, -24, GETDATE())
GROUP BY D.CID
ORDER BY Successful DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.ACHMonitor_NumberOfSuccessfullDepositsPerTimeAndCID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.ACHMonitor_NumberOfSuccessfullDepositsPerTimeAndCID.sql*
