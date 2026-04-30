# Billing.DD_ACHMonitor_SumOfSuccessfullDepositsPerTimeAndCID

> DataDog monitoring check that fires an alert when any individual customer's total approved ACH deposit amount exceeds a threshold within a time window, detecting high-value deposit volume anomalies per customer.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 1-row result: value (0=OK, 1=alert) + desc (CSV of CID,amount pairs) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DD_ACHMonitor_SumOfSuccessfullDepositsPerTimeAndCID` is a DataDog synthetic monitor procedure. It aggregates the total dollar amount of approved ACH deposits (`PaymentStatusID=2`) per customer (`CID`) within a rolling time window (in hours). If any customer's cumulative ACH deposit total meets or exceeds the configured threshold, the procedure returns `value=1` with a comma-separated list of affected CIDs and their respective totals.

This procedure is the amount-based counterpart to `DD_ACHMonitor_NumberOfSuccessfullDepositsPerTimeAndCID` (count-based). A customer making one very large ACH deposit might not trigger the count monitor but would trigger this amount monitor. Together with the account-creation and count monitors, they form a comprehensive ACH risk monitoring suite that covers distinct fraud patterns: many small deposits, one large deposit, and bulk account creation.

DataDog uses the result to alert the payments risk team when a customer's ACH deposit volume is anomalous - potentially indicating funds laundering, account compromise, or limit evasion.

---

## 2. Business Logic

### 2.1 DataDog Monitor Return Pattern

**What**: Standard DataDog DB monitor result format - one row with value flag and optional message.

**Columns/Parameters Involved**: `@NumberOfHours`, `@NumberToTrigger`, `value`, `desc`

**Rules**:
- DataDog calls the procedure with its configured threshold parameters
- `value=0` = healthy, no amount alert; `value=1` = at least one CID exceeded the total deposit threshold
- `desc` contains a comma-separated string of `CID,amount` pairs for every customer at or over threshold
- Example `desc` when alerting: `"12345,15000,67890,22500"` means CID 12345 deposited $15,000 and CID 67890 deposited $22,500 via ACH
- NULL `desc` when `value=0`

**Diagram**:
```
@NumberOfHours=24, @NumberToTrigger=10000
          |
          v
  GROUP BY CID WHERE ACH deposits (FundingTypeID=29)
  PaymentDate > (now - 24h) AND PaymentStatusID=2
          |
    HAVING SUM(Amount) >= 10000
          |
    +-----+-----+
    |             |
  No CIDs      CIDs found
  in CTE          |
    |          value=1
  value=0      desc="CID1,total1,CID2,total2,..."
  desc=NULL
```

### 2.2 Per-CID Deposit Amount Velocity

**What**: Amount-based threshold check per individual customer - catches large-total depositors regardless of transaction frequency.

**Columns/Parameters Involved**: `Billing.Deposit.CID`, `Billing.Deposit.Amount`, `Billing.Deposit.PaymentDate`, `Billing.Deposit.PaymentStatusID`, `Billing.Funding.FundingTypeID`

**Rules**:
- Only ACH (FundingTypeID=29) deposits are included
- Only approved deposits are counted (PaymentStatusID=2 = Approved)
- The threshold is compared against the sum, not count - catches a single large ACH that the count monitor would miss
- Amount unit in `Billing.Deposit.Amount` is USD (or customer account currency); the @NumberToTrigger should be set in the same unit
- Uses GETDATE() (server local time) consistent with the other ACH monitor procedures

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NumberOfHours | INT | NO | - | CODE-BACKED | Rolling lookback window in hours. Examines ACH deposit activity from `GETDATE() - @NumberOfHours` to now. Typical configurations use 24 or 168 hours. |
| 2 | @NumberToTrigger | INT | NO | - | CODE-BACKED | Per-CID amount threshold (in USD or account currency). If a single customer's total approved ACH deposits in the window equals or exceeds this value, the alert fires. |
| 3 | value (output) | INT | NO | - | CODE-BACKED | DataDog monitor result: 1 = at least one CID's total ACH deposit amount >= @NumberToTrigger in the window; 0 = all customers are below threshold. |
| 4 | desc (output) | VARCHAR | YES | - | CODE-BACKED | Comma-separated string of `CID,amount` pairs for every customer that breached the threshold. Format: "CID1,total1,CID2,total2,...". NULL when value=0. Identifies which customers have high deposit volumes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeID filter | Billing.Funding | Lookup JOIN | Joins to Billing.Funding on FundingID; filters to FundingTypeID=29 (ACH). See [Billing.Funding](../Tables/Billing.Funding.md). |
| Amount aggregation | Billing.Deposit | Read | Reads Billing.Deposit.Amount and PaymentStatusID=2 to sum approved ACH deposit amounts per CID. See [Billing.Deposit](../Tables/Billing.Deposit.md). |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called externally by DataDog synthetic monitors.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DD_ACHMonitor_SumOfSuccessfullDepositsPerTimeAndCID (procedure)
├── Billing.Deposit (table)
└── Billing.Funding (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Primary source; provides CID, FundingID, Amount, PaymentDate, PaymentStatusID for ACH deposit amount aggregation |
| Billing.Funding | Table | INNER JOIN on FundingID; filtered to FundingTypeID=29 (ACH) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DataDog Synthetic Monitor | External | Calls this procedure on a schedule to monitor ACH deposit amount velocity per customer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Run the check with 24-hour window, alert at $10,000 per customer

```sql
EXEC Billing.DD_ACHMonitor_SumOfSuccessfullDepositsPerTimeAndCID
    @NumberOfHours = 24,
    @NumberToTrigger = 10000;
```

### 8.2 Stricter 1-hour window for high-frequency deposit detection

```sql
EXEC Billing.DD_ACHMonitor_SumOfSuccessfullDepositsPerTimeAndCID
    @NumberOfHours = 1,
    @NumberToTrigger = 5000;
```

### 8.3 Manually identify high-value ACH depositors in the last 24 hours

```sql
SELECT D.CID,
       COUNT(*) AS DepositCount,
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
HAVING SUM(D.Amount) >= 10000
ORDER BY TotalDepositAmount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 applicable)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DD_ACHMonitor_SumOfSuccessfullDepositsPerTimeAndCID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DD_ACHMonitor_SumOfSuccessfullDepositsPerTimeAndCID.sql*
