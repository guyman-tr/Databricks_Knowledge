# Billing.DD_ACHMonitor_CheckNewAccountsPerTime

> DataDog monitoring check that fires an alert when the number of newly created ACH payment accounts exceeds a threshold within a configurable time window, enabling fraud and velocity detection for ACH onboarding.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 1-row result: value (0=OK, 1=alert) + desc (message) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DD_ACHMonitor_CheckNewAccountsPerTime` is a DataDog synthetic monitor procedure. DataDog calls it on a schedule, passing a time window (`@NumOfMinutes`) and a threshold (`@NumToAlert`). The procedure counts how many new ACH (Automated Clearing House) payment accounts were linked to customers during that window. If the count meets or exceeds the alert threshold, it returns `value=1` with a human-readable message; otherwise it returns `value=0` with no message.

The procedure exists to detect anomalous spikes in ACH account registration velocity - a pattern associated with fraud rings, account takeover campaigns, or system misconfigurations that create payment accounts in bulk. Catching this early allows the payments and risk teams to intervene before funds are moved.

ACH (FundingTypeID=29) is a US bank-transfer payment method. A "new account" in this context means a new row in `Billing.CustomerToFunding` where the linked `Billing.Funding` record has `FundingTypeID=29`, and the `CustomerToFunding.Occurred` timestamp falls within the time window. The `Occurred` column records when the customer-to-funding link was established (not when the underlying bank account was opened).

---

## 2. Business Logic

### 2.1 DataDog Monitor Return Pattern

**What**: This procedure follows the standard DataDog DB monitor return pattern used by all `DD_` prefixed procedures in the Billing schema.

**Columns/Parameters Involved**: `@NumOfMinutes`, `@NumToAlert`, `value`, `desc`

**Rules**:
- DataDog calls the procedure with configured threshold values (e.g., `@NumOfMinutes=60`, `@NumToAlert=50`)
- `value=0` = healthy, no alert; `value=1` = threshold breached, alert fires
- `desc` is NULL when healthy (no alert message); populated when alert fires
- The OUTER APPLY pattern ensures exactly one row is always returned, even when the CTE has no rows

**Diagram**:
```
@NumOfMinutes=60, @NumToAlert=50
          |
          v
  COUNT new ACH accounts (FundingTypeID=29)
  WHERE Occurred > (now - 60 minutes)
          |
    +-----+-----+
    |             |
  COUNT < 50   COUNT >= 50
    |             |
  value=0      value=1
  desc=NULL    desc="Number of new ACH accounts that were
               created during the last 60 minutes was {count}"
```

### 2.2 ACH Velocity Detection

**What**: Measures the rate of new ACH payment method registrations to detect abnormal spikes.

**Columns/Parameters Involved**: `@NumOfMinutes`, `@NumToAlert`, `Billing.CustomerToFunding.Occurred`, `Billing.Funding.FundingTypeID`

**Rules**:
- Only ACH funding links are counted (`FundingTypeID = 29`)
- The time window is a rolling lookback from `GETUTCDATE()` - not a fixed interval
- The count uses `HAVING COUNT(*) >= @NumToAlert` inside the CTE, so MyCTE only returns a row when the threshold is breached
- A normal environment has low ACH account creation velocity; a spike indicates a fraud pattern or integration issue

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NumOfMinutes | SMALLINT | NO | - | CODE-BACKED | Rolling lookback window size in minutes. The procedure checks ACH account creation activity from `GETUTCDATE() - @NumOfMinutes` to now. Typical DataDog configurations use values like 60 (1 hour) or 1440 (24 hours). |
| 2 | @NumToAlert | INT | NO | - | CODE-BACKED | Alert threshold: minimum number of new ACH accounts in the window that triggers an alert. If the count reaches this number, `value=1` is returned. Set by the DataDog monitor configuration to match expected normal traffic. |
| 3 | value (output) | INT | NO | - | CODE-BACKED | DataDog monitor result flag: 1 = alert condition met (count >= @NumToAlert), 0 = no alert (count below threshold). DataDog interprets 1 as an alert state that may trigger notifications or incident creation. |
| 4 | desc (output) | NVARCHAR | YES | - | CODE-BACKED | Alert message returned when `value=1`. Format: "Number of new ACH accounts that were created during the last {N} minutes was {count}". NULL when `value=0` (no alert). Displayed in DataDog alert notifications. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeID filter | Billing.Funding | Lookup JOIN | Joins to Billing.Funding to filter only ACH payment instruments (FundingTypeID=29). See [Billing.Funding](../Tables/Billing.Funding.md). |
| Occurred filter | Billing.CustomerToFunding | Read | Reads CustomerToFunding.Occurred to measure when the customer-funding link was created, scoped to the rolling time window. See [Billing.CustomerToFunding](../Tables/Billing.CustomerToFunding.md). |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. This procedure is called externally by DataDog synthetic monitors, not by other stored procedures in the schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DD_ACHMonitor_CheckNewAccountsPerTime (procedure)
├── Billing.CustomerToFunding (table)
└── Billing.Funding (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerToFunding | Table | INNER JOIN source; provides Occurred timestamp and FundingID for new ACH link detection |
| Billing.Funding | Table | INNER JOIN on FundingID; filtered to FundingTypeID=29 (ACH) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DataDog Synthetic Monitor | External | Calls this procedure on a schedule to evaluate ACH account creation velocity |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Run the DataDog check with standard 1-hour window, alert at 50+ accounts

```sql
EXEC Billing.DD_ACHMonitor_CheckNewAccountsPerTime
    @NumOfMinutes = 60,
    @NumToAlert = 50;
```

### 8.2 Check last 24 hours with a higher threshold for capacity planning

```sql
EXEC Billing.DD_ACHMonitor_CheckNewAccountsPerTime
    @NumOfMinutes = 1440,
    @NumToAlert = 1000;
```

### 8.3 Manually query the underlying data to investigate a fired alert

```sql
SELECT COUNT(*) AS NewACHAccounts,
       MIN(CTF.Occurred) AS EarliestOccurred,
       MAX(CTF.Occurred) AS LatestOccurred
FROM Billing.CustomerToFunding CTF WITH (NOLOCK)
    INNER JOIN Billing.Funding F WITH (NOLOCK)
        ON F.FundingID = CTF.FundingID
WHERE CTF.Occurred > DATEADD(MINUTE, -60, GETUTCDATE())
  AND F.FundingTypeID = 29;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 applicable)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DD_ACHMonitor_CheckNewAccountsPerTime | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DD_ACHMonitor_CheckNewAccountsPerTime.sql*
