# Billing.DD_ACHMonitor_NumberOfSuccessfullDepositsPerTimeAndCID

> DataDog monitoring check that fires an alert when any individual customer completes an unusually high number of successful ACH deposits within a time window, detecting per-CID deposit velocity anomalies.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 1-row result: value (0=OK, 1=alert) + desc (CSV of CID,count pairs) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DD_ACHMonitor_NumberOfSuccessfullDepositsPerTimeAndCID` is a DataDog synthetic monitor procedure. It counts the number of successfully approved ACH deposits (`PaymentStatusID=2`) per individual customer (`CID`) within a rolling time window measured in hours. If any customer reaches or exceeds the configured deposit-count threshold, the procedure returns `value=1` and includes a comma-separated list identifying each affected customer along with their deposit count.

The procedure addresses a specific fraud vector: a single customer making an abnormally large number of ACH deposits in a short period. This differs from the companion procedure `DD_ACHMonitor_CheckNewAccountsPerTime` (which tracks total new account registrations, not deposit activity) and `DD_ACHMonitor_SumOfSuccessfullDepositsPerTimeAndCID` (which tracks the total deposited amount rather than deposit count). Together, they form a three-dimensional ACH velocity monitoring suite.

DataDog calls this procedure on a scheduled interval and interprets the result: `value=0` means normal traffic, `value=1` means at least one customer has exceeded the threshold and an alert is raised for the payments risk team to investigate.

---

## 2. Business Logic

### 2.1 DataDog Monitor Return Pattern

**What**: Standard DataDog DB monitor result format - one row with value flag and optional message.

**Columns/Parameters Involved**: `@NumberOfHours`, `@NumberToTrigger`, `value`, `desc`

**Rules**:
- DataDog calls the procedure with its configured threshold parameters
- `value=0` = healthy, no per-CID alert; `value=1` = at least one CID exceeded the threshold
- `desc` contains a comma-separated string of `CID,count` pairs for every CID at or over threshold
- NULL `desc` when `value=0`; populated aggregate string when `value=1`
- Example `desc` when alerting: `"12345,8,67890,12"` means CID 12345 made 8 ACH deposits and CID 67890 made 12

**Diagram**:
```
@NumberOfHours=24, @NumberToTrigger=5
          |
          v
  GROUP BY CID WHERE ACH deposits (FundingTypeID=29)
  PaymentDate > (now - 24h) AND PaymentStatusID=2
          |
    HAVING COUNT(*) >= 5
          |
    +-----+-----+
    |             |
  No CIDs      CIDs found
  in CTE          |
    |          value=1
  value=0      desc="CID1,count1,CID2,count2,..."
  desc=NULL
```

### 2.2 Per-CID Deposit Count Velocity

**What**: Aggregate deposit count check scoped to individual customers - not global totals.

**Columns/Parameters Involved**: `Billing.Deposit.CID`, `Billing.Deposit.PaymentDate`, `Billing.Deposit.PaymentStatusID`, `Billing.Funding.FundingTypeID`

**Rules**:
- Only ACH (FundingTypeID=29) deposits are included
- Only approved deposits are counted (PaymentStatusID=2 = Approved per `Dictionary.PaymentStatus`)
- Each CID's count is independent - the alert fires if ANY single CID breaches the threshold, not if the total count does
- The `desc` output identifies which specific customers triggered the alert, enabling rapid investigation
- Uses GETDATE() (server local time) not GETUTCDATE() - this is consistent across the ACH monitor suite

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NumberOfHours | INT | NO | - | CODE-BACKED | Rolling lookback window in hours. The procedure examines ACH deposit activity from `GETDATE() - @NumberOfHours` to now. Typical configurations use 24 (1 day) or 168 (1 week). |
| 2 | @NumberToTrigger | SMALLINT | NO | - | CODE-BACKED | Per-CID alert threshold: minimum number of successful ACH deposits by a single customer in the window that triggers an alert. Any CID reaching this count causes `value=1`. |
| 3 | value (output) | INT | NO | - | CODE-BACKED | DataDog monitor result: 1 = at least one CID has >= @NumberToTrigger successful ACH deposits in the window; 0 = all customers are below threshold. DataDog interprets 1 as an alert state. |
| 4 | desc (output) | VARCHAR | YES | - | CODE-BACKED | Comma-separated string of `CID,count` pairs for every customer that breached the threshold. Format: "CID1,count1,CID2,count2,...". NULL when value=0. Enables direct identification of affected customers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeID filter | Billing.Funding | Lookup JOIN | Joins to Billing.Funding on FundingID; filters to FundingTypeID=29 (ACH). See [Billing.Funding](../Tables/Billing.Funding.md). |
| PaymentStatusID filter | Billing.Deposit | Read | Reads Billing.Deposit with PaymentStatusID=2 (Approved) to count only successful deposits. See [Billing.Deposit](../Tables/Billing.Deposit.md). |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called externally by DataDog synthetic monitors.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DD_ACHMonitor_NumberOfSuccessfullDepositsPerTimeAndCID (procedure)
├── Billing.Deposit (table)
└── Billing.Funding (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Primary source; provides CID, FundingID, PaymentDate, PaymentStatusID, Amount for ACH deposit analysis |
| Billing.Funding | Table | INNER JOIN on FundingID; filtered to FundingTypeID=29 (ACH) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DataDog Synthetic Monitor | External | Calls this procedure on a schedule to monitor ACH deposit count velocity per customer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Run the check with standard 24-hour window, alert at 5 deposits per customer

```sql
EXEC Billing.DD_ACHMonitor_NumberOfSuccessfullDepositsPerTimeAndCID
    @NumberOfHours = 24,
    @NumberToTrigger = 5;
```

### 8.2 Tighter 1-hour window for real-time fraud detection

```sql
EXEC Billing.DD_ACHMonitor_NumberOfSuccessfullDepositsPerTimeAndCID
    @NumberOfHours = 1,
    @NumberToTrigger = 3;
```

### 8.3 Manually inspect customers with high ACH deposit counts in the last 24 hours

```sql
SELECT D.CID,
       COUNT(*) AS SuccessfulACHDeposits,
       SUM(D.Amount) AS TotalDepositAmount,
       MIN(D.PaymentDate) AS FirstDeposit,
       MAX(D.PaymentDate) AS LastDeposit
FROM Billing.Deposit D WITH (NOLOCK)
    INNER JOIN Billing.Funding F WITH (NOLOCK)
        ON D.FundingID = F.FundingID
WHERE F.FundingTypeID = 29
  AND D.PaymentDate > DATEADD(HOUR, -24, GETDATE())
  AND D.PaymentStatusID = 2
GROUP BY D.CID
HAVING COUNT(*) >= 5
ORDER BY SuccessfulACHDeposits DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 applicable)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DD_ACHMonitor_NumberOfSuccessfullDepositsPerTimeAndCID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DD_ACHMonitor_NumberOfSuccessfullDepositsPerTimeAndCID.sql*
