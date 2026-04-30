# Billing.DD_ACHMonitor_ToManyAccountsPerTimeAndCID

> DataDog monitoring check that fires an alert when any individual customer registers too many ACH accounts within a short time window, detecting per-CID account creation velocity that may indicate fraud or misuse.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 1-row result: value (0=OK, 1=alert) + desc (CSV of CID,count pairs) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DD_ACHMonitor_ToManyAccountsPerTimeAndCID` is a DataDog synthetic monitor procedure that detects when a single customer registers multiple ACH bank accounts in a very short time window (measured in minutes, defaulting to 1 minute). If any individual customer creates ACH account links at or above the threshold (default: 5 accounts), the procedure returns `value=1` and identifies the offending customers.

This procedure is the per-customer counterpart to `DD_ACHMonitor_CheckNewAccountsPerTime` (which tracks total ACH account registrations across all customers). A customer rapidly cycling through multiple ACH accounts is a distinct fraud pattern: attempting to find accounts with sufficient funds, evading per-account limits, or probing for valid account numbers. The minute-based window (vs. the hour-based windows in deposit monitors) reflects the near-real-time nature of this abuse pattern.

Has default parameter values (unlike the other ACH monitors), meaning DataDog can call it without arguments if the defaults match the desired configuration: 1 minute window, alert at 5 or more accounts per customer.

---

## 2. Business Logic

### 2.1 DataDog Monitor Return Pattern

**What**: Standard DataDog DB monitor result format - one row with value flag and optional message.

**Columns/Parameters Involved**: `@NumberOfMinutes`, `@NumberToTrigger`, `value`, `desc`

**Rules**:
- DataDog calls the procedure on a schedule; default parameters allow zero-argument calls
- `value=0` = healthy; `value=1` = at least one CID registered >= @NumberToTrigger ACH accounts in the window
- `desc` contains a comma-separated string of `CID,numAccounts` pairs for violating customers
- Example `desc`: `"12345,6,99876,8"` means CID 12345 added 6 ACH accounts and CID 99876 added 8 in the last minute
- NULL `desc` when `value=0`

**Diagram**:
```
@NumberOfMinutes=1 (default), @NumberToTrigger=5 (default)
          |
          v
  GROUP BY CID WHERE ACH accounts (FundingTypeID=29)
  CTF.Occurred >= (now - 1 minute)
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

### 2.2 Per-CID Account Registration Velocity (Minute-Scale)

**What**: Minute-scale detection of per-customer ACH account creation bursts - the tightest window in the ACH monitor suite.

**Columns/Parameters Involved**: `Billing.CustomerToFunding.CID`, `Billing.CustomerToFunding.Occurred`, `Billing.Funding.FundingTypeID`

**Rules**:
- Uses `>=` on Occurred (vs. `>` in `DD_ACHMonitor_CheckNewAccountsPerTime`) - minor boundary difference
- Both tables use WITH (NOLOCK) hints for reduced locking overhead - appropriate for a monitoring-only read
- The minute-scale window is intentional: legitimate ACH account registration is slow (user manually enters bank details), so multiple accounts in one minute is inherently suspicious
- Window is a rolling lookback from GETDATE() - not a fixed clock interval

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NumberOfMinutes | INT | NO | 1 | CODE-BACKED | Rolling lookback window in minutes. Default of 1 minute reflects the very short time scale at which per-customer ACH account bursts are suspicious. DataDog configurations may override to a wider window for less sensitive monitoring. |
| 2 | @NumberToTrigger | SMALLINT | NO | 5 | CODE-BACKED | Per-CID alert threshold: minimum number of ACH accounts a single customer must register in the window to trigger an alert. Default of 5 accounts per minute is highly anomalous for legitimate users. |
| 3 | value (output) | INT | NO | - | CODE-BACKED | DataDog monitor result: 1 = at least one CID registered >= @NumberToTrigger ACH accounts in the window; 0 = all customers are below threshold. |
| 4 | desc (output) | VARCHAR | YES | - | CODE-BACKED | Comma-separated string of `CID,numAccounts` pairs for every customer that exceeded the threshold. Format: "CID1,count1,CID2,count2,...". NULL when value=0. Used by the alert team to identify which specific customers triggered the monitor. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeID filter | Billing.Funding | Lookup JOIN | Joins to Billing.Funding on FundingID; filters to FundingTypeID=29 (ACH). See [Billing.Funding](../Tables/Billing.Funding.md). |
| Occurred filter | Billing.CustomerToFunding | Read | Reads CustomerToFunding.CID and Occurred to measure per-customer ACH account creation velocity. See [Billing.CustomerToFunding](../Tables/Billing.CustomerToFunding.md). |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called externally by DataDog synthetic monitors.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DD_ACHMonitor_ToManyAccountsPerTimeAndCID (procedure)
├── Billing.Funding (table)
└── Billing.CustomerToFunding (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | INNER JOIN on FundingID; filtered to FundingTypeID=29 (ACH) |
| Billing.CustomerToFunding | Table | Primary source; provides CID and Occurred timestamp for per-customer ACH account registration velocity |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DataDog Synthetic Monitor | External | Calls this procedure on a schedule to monitor per-customer ACH account creation bursts |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Run with defaults (1 minute window, alert at 5 accounts per customer)

```sql
EXEC Billing.DD_ACHMonitor_ToManyAccountsPerTimeAndCID;
```

### 8.2 Widen window to 5 minutes, lower threshold to 3

```sql
EXEC Billing.DD_ACHMonitor_ToManyAccountsPerTimeAndCID
    @NumberOfMinutes = 5,
    @NumberToTrigger = 3;
```

### 8.3 Manually identify customers with multiple ACH registrations in the last 5 minutes

```sql
SELECT CTF.CID,
       COUNT(*) AS NumACHAccounts,
       MIN(CTF.Occurred) AS FirstOccurred,
       MAX(CTF.Occurred) AS LastOccurred
FROM Billing.Funding F WITH (NOLOCK)
    INNER JOIN Billing.CustomerToFunding CTF WITH (NOLOCK)
        ON F.FundingID = CTF.FundingID
WHERE CTF.Occurred >= DATEADD(MINUTE, -5, GETDATE())
  AND F.FundingTypeID = 29
GROUP BY CTF.CID
HAVING COUNT(*) >= 3
ORDER BY NumACHAccounts DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 applicable)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DD_ACHMonitor_ToManyAccountsPerTimeAndCID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DD_ACHMonitor_ToManyAccountsPerTimeAndCID.sql*
