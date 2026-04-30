# Billing.SecondAttemptDepositMonitoring

> Monitoring metric SP that counts customers who failed on BOTH their first and second consecutive deposit attempts within the last 160 minutes, used to detect payment provider issues or systematic deposit friction.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns COUNT of second-consecutive-fail deposits in the last 160 min |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a customer's deposit is declined twice in a row, it indicates either a persistent issue with the payment method, a provider outage, or systematic friction in the checkout flow. `Billing.SecondAttemptDepositMonitoring` returns a single integer (the count of customers in this state within the last 160 minutes) as a monitoring signal.

The procedure was modified on 26/12/2021 (DBA-876, Katem) to change its meaning: the original version checked whether a customer succeeded on the second attempt; the new version counts customers who *failed again* on the second attempt (both attempt 1 and attempt 2 = 'Decline'). The output column is named `Value`, indicating integration with a monitoring/alerting framework that expects a scalar metric.

**Important quirk**: The `@FromDate` and `@ToDate` parameters are declared but never used. The WHERE clause uses `ISNULL(null, DATEADD(MINUTE, -160, GETUTCDATE()))` instead of `ISNULL(@FromDate, ...)`, so the time window is always the fixed 160-minute lookback regardless of parameters passed by the caller. This appears to be a coding bug left from the DBA-876 modification.

---

## 2. Business Logic

### 2.1 Consecutive-Decline Detection

**What**: Uses ROW_NUMBER + LAG windowed functions to identify customers whose first two deposit attempts in the window both resulted in 'Decline'.

**Columns/Parameters Involved**: `@FromDate`, `@ToDate` (declared but unused), `PaymentStatus`, `PreviousAttempt`, `AttemptNum`

**Rules**:
- Fixed lookback window: last 160 minutes from GETUTCDATE() (parameters @FromDate/@ToDate are ignored due to ISNULL(null,...) pattern).
- CTE `Deposit_Attempts`:
  - ROW_NUMBER() OVER (PARTITION BY CID ORDER BY ModificationDate) = AttemptNum (per-customer sequential attempt number in the window).
  - LAG(DPS.Name, 1, '') OVER (PARTITION BY CID ORDER BY ModificationDate) = PreviousAttempt (prior deposit status, '' for first attempt).
- Filter: PaymentStatus = 'Decline' AND PreviousAttempt = 'Decline' AND AttemptNum = 2.
  - AttemptNum=2: Only the second deposit attempt per customer (not any subsequent).
  - Both PaymentStatus and PreviousAttempt = 'Decline': Both the 2nd and 1st attempts failed.
- Returns: COUNT(*) AS Value (count of customers with two consecutive declines).
- RETURN value: 1 if COUNT > 0, 0 if COUNT = 0 (for monitoring framework check: is the metric populated?).

**Diagram**:
```
Billing.Deposit (last 160 min)
  |
  +-- ROW_NUMBER() per CID (AttemptNum) + LAG() for PreviousAttempt
  |
  WHERE AttemptNum=2 AND PaymentStatus='Decline' AND PreviousAttempt='Decline'
  |
  SELECT COUNT(*) AS [Value]   -- monitoring metric: # of double-decline customers
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromDate | DATETIME | YES | NULL | CODE-BACKED | Declared but UNUSED. The WHERE clause uses ISNULL(null,...) not ISNULL(@FromDate,...) so this parameter has no effect. Likely a bug from DBA-876 refactor. |
| 2 | @ToDate | DATETIME | YES | NULL | CODE-BACKED | Declared but UNUSED. Same issue as @FromDate. Time window is always the last 160 minutes. |

**Output Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | Value | INT | NO | - | CODE-BACKED | Count of customers who had exactly 2 consecutive 'Decline' deposits in the last 160 minutes. Used as a monitoring metric. Zero means no double-decline customers detected. |

**RETURN value**:

| # | Element | Type | Description |
|---|---------|------|-------------|
| 4 | Return code | INT | 1 if Value > 0 (rows returned by COUNT), 0 if 0 rows (i.e., COUNT = 0 means no double-decline customers). Note: COUNT(*) always returns 1 row, so RETURN is always 1. Likely legacy behavior. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Deposit data | Billing.Deposit | READ | Source of deposit attempts (last 160 min, all payment types) |
| Customer join | Customer.Customer | READ | Resolves CID for partitioning |
| Country filter | Dictionary.Country | READ | Joined on CountryID but country is not used in output; likely legacy join |
| Payment status | Dictionary.PaymentStatus | READ | Resolves PaymentStatusID to name ('Decline', etc.) |
| Funding details | Billing.Funding | READ | Links deposit to funding record for FundingTypeID |
| Funding type name | Dictionary.FundingType | READ | Resolves FundingTypeID to name (included in CTE but not in final SELECT) |

### 5.2 Referenced By (other objects point to this)

No SQL callers found. Called by external monitoring/alerting job (likely a scheduled monitoring framework that polls scalar metrics).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.SecondAttemptDepositMonitoring (procedure)
├── Billing.Deposit (table)
├── Customer.Customer (table)
├── Dictionary.Country (table)
├── Dictionary.PaymentStatus (table)
├── Billing.Funding (table)
└── Dictionary.FundingType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Primary source of deposit attempts |
| Customer.Customer | Table | CID partition join |
| Dictionary.Country | Table | Joined but not referenced in output (legacy join) |
| Dictionary.PaymentStatus | Table | Maps PaymentStatusID -> Name for 'Decline' filter |
| Billing.Funding | Table | Links deposit to funding record |
| Dictionary.FundingType | Table | Maps FundingTypeID -> Name (CTE only, not in final SELECT) |

### 6.2 Objects That Depend On This

No SQL dependents. External monitoring framework consumer.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| AttemptNum=2 | Business filter | Exactly the 2nd attempt per customer in the window. Ignores 3rd, 4th, etc. |
| Fixed 160-minute window | Hardcoded | DATEADD(MINUTE,-160,GETUTCDATE()) regardless of @FromDate/@ToDate params. |
| PreviousAttempt='' default | Window function | LAG default '' means attempt #1 is never flagged as "previous Decline." |
| @FromDate/@ToDate unused | Bug | Parameters accepted but ISNULL(null,...) used instead of ISNULL(@FromDate,...). Caller cannot override the time window. |

---

## 8. Sample Queries

### 8.1 Run the monitoring check

```sql
EXEC Billing.SecondAttemptDepositMonitoring
-- Returns Value = count of customers with 2 consecutive Declines in last 160 min
```

### 8.2 Reproduce the CTE logic manually with date range

```sql
;WITH Deposit_Attempts AS (
    SELECT ROW_NUMBER() OVER (PARTITION BY CC.CID ORDER BY BD.ModificationDate) AS AttemptNum,
           BD.ModificationDate, CC.CID, BD.DepositID,
           DPS.Name AS PaymentStatus,
           LAG(DPS.Name, 1, '') OVER (PARTITION BY CC.CID ORDER BY BD.ModificationDate) AS PreviousAttempt,
           DFT.Name AS FundingType
    FROM Billing.Deposit BD WITH (NOLOCK)
    JOIN Customer.Customer CC WITH (NOLOCK) ON BD.CID = CC.CID
    JOIN Dictionary.PaymentStatus DPS ON BD.PaymentStatusID = DPS.PaymentStatusID
    JOIN Billing.Funding BF WITH (NOLOCK) ON BF.FundingID = BD.FundingID
    JOIN Dictionary.FundingType DFT ON DFT.FundingTypeID = BF.FundingTypeID
    WHERE BD.ModificationDate >= DATEADD(MINUTE, -160, GETUTCDATE())
)
SELECT CID, DepositID, AttemptNum, PaymentStatus, PreviousAttempt, FundingType
FROM Deposit_Attempts
WHERE PaymentStatus = 'Decline' AND PreviousAttempt = 'Decline' AND AttemptNum = 2
ORDER BY ModificationDate DESC
```

### 8.3 Check current PaymentStatus values for context

```sql
SELECT PaymentStatusID, Name
FROM Dictionary.PaymentStatus WITH (NOLOCK)
ORDER BY PaymentStatusID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. DBA-876 (Jira) is referenced in the SQL comment (26/12/2021, Katem) as the change that modified the procedure to count second-failed-attempts instead of second-successful-attempts.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.8/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: skipped | Corrections: 0 applied*
*Object: Billing.SecondAttemptDepositMonitoring | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.SecondAttemptDepositMonitoring.sql*
