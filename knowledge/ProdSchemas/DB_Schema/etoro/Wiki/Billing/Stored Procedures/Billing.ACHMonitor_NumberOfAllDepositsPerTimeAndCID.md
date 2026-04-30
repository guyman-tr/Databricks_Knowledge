# Billing.ACHMonitor_NumberOfAllDepositsPerTimeAndCID

> ACH fraud monitoring probe that returns customer IDs with a high volume of ACH deposit attempts (any status) within a rolling time window, used to detect customers submitting unusually many deposit requests.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NumberOfMinutes, @NumberToTrigger input; returns CID + count result set |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.ACHMonitor_NumberOfAllDepositsPerTimeAndCID` is a fraud detection probe that identifies customers who have submitted an unusually high number of ACH deposit attempts within a rolling time window, regardless of whether those attempts were successful. By counting ALL deposit records (any PaymentStatus), it catches patterns where a customer repeatedly attempts deposits - potentially indicating fraud, retry storms, or account testing behavior.

The procedure filters to ACH deposits (FundingTypeID=29) only and uses `Billing.Deposit.PaymentDate` as the timestamp. It returns a result set of (CID, count) pairs for customers meeting or exceeding the threshold, or an empty result set if no customers trigger the alert.

---

## 2. Business Logic

### 2.1 Rolling Window Count Per Customer

**What**: Counts all ACH deposit attempts per customer in the time window.

**Columns/Parameters Involved**: `@NumberOfMinutes`, `@NumberToTrigger`

**Rules**:
- Window: `PaymentDate > DATEADD(MINUTE, -@NumberOfMinutes, GETDATE())`.
- Filter: FundingTypeID=29 (ACH) only. ALL payment statuses included (pending, failed, approved).
- GROUP BY CID; HAVING COUNT(*) >= @NumberToTrigger.
- Returns: CID, count. Empty set = no alert.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NumberOfMinutes | INT | NO | - | CODE-BACKED | Size of the rolling time window in minutes. Deposits with PaymentDate after DATEADD(MINUTE, -@NumberOfMinutes, GETDATE()) are counted. Example: 10000 (from inline comment - ~7 days). |
| 2 | @NumberToTrigger | SMALLINT | NO | - | CODE-BACKED | Alert threshold: customers with >= this many ACH deposit attempts in the window are returned. Example: 1 (any single deposit triggers return - useful for testing the probe). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Deposits | Billing.Deposit | READER | Counts all ACH deposit attempts per customer |
| FundingTypeID filter | Billing.Funding | JOIN | Filters to ACH (FundingTypeID=29) |

### 5.2 Referenced By (other objects point to this)

No callers found. Called by external monitoring agent or job.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.ACHMonitor_NumberOfAllDepositsPerTimeAndCID (procedure)
|- Billing.Deposit (table) [leaf]
|- Billing.Funding (table) [leaf]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Primary data source: counts all deposit records per customer in time window |
| Billing.Funding | Table | JOINed to filter FundingTypeID=29 (ACH) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

SET NOCOUNT ON. Counts ALL statuses (no PaymentStatusID filter). Uses PaymentDate (not ModificationDate).

---

## 8. Sample Queries

### 8.1 Run the probe with a 24-hour window

```sql
EXEC Billing.ACHMonitor_NumberOfAllDepositsPerTimeAndCID
    @NumberOfMinutes = 1440,
    @NumberToTrigger = 5
```

### 8.2 Manual equivalent query

```sql
SELECT D.CID, COUNT(*) AS TotalAttempts
FROM Billing.Deposit WITH (NOLOCK) AS D
INNER JOIN Billing.Funding WITH (NOLOCK) AS F ON D.FundingID = F.FundingID
WHERE F.FundingTypeID = 29
  AND D.PaymentDate > DATEADD(MINUTE, -1440, GETDATE())
GROUP BY D.CID
HAVING COUNT(*) >= 5
ORDER BY TotalAttempts DESC
```

### 8.3 Compare all deposits vs successful-only for high-volume customers

```sql
SELECT
    D.CID,
    COUNT(*) AS AllAttempts,
    SUM(CASE WHEN D.PaymentStatusID = 2 THEN 1 ELSE 0 END) AS SuccessfulAttempts
FROM Billing.Deposit WITH (NOLOCK) AS D
INNER JOIN Billing.Funding WITH (NOLOCK) AS F ON D.FundingID = F.FundingID
WHERE F.FundingTypeID = 29
  AND D.PaymentDate > DATEADD(HOUR, -24, GETDATE())
GROUP BY D.CID
HAVING COUNT(*) >= 3
ORDER BY AllAttempts DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.ACHMonitor_NumberOfAllDepositsPerTimeAndCID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.ACHMonitor_NumberOfAllDepositsPerTimeAndCID.sql*
