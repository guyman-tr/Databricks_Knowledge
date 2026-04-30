# Billing.ACHMonitor_ToManyAccountsPerTimeAndCID

> ACH fraud monitoring probe that returns customer IDs linking too many ACH bank accounts within a short time window, used to detect rapid account-farming behavior with configurable time and count thresholds (defaults: 5 accounts in 1 minute).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NumberOfMinutes=1, @NumberToTrigger=5 input; returns CID + count result set |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.ACHMonitor_ToManyAccountsPerTimeAndCID` detects customers who are linking ACH bank accounts at an abnormally high rate - an indicator of account farming, synthetic identity fraud, or money mule networks. The default threshold (5 accounts in 1 minute) is deliberately aggressive, designed to catch real-time abuse.

The procedure monitors `Billing.CustomerToFunding.Occurred` - the timestamp when a customer linked a new funding account. Unlike `ACHMonitor_CheckNewAccountsPerTime` (which monitors global system-wide counts), this procedure returns per-customer breakdowns, identifying WHICH customers are the source of the spike.

The procedure uses WITH(NOLOCK) on both tables, making it safe to run frequently as a real-time probe without impacting transaction throughput.

---

## 2. Business Logic

### 2.1 Per-Customer Account Linking Rate

**What**: Counts ACH accounts linked per customer in a rolling minute window.

**Columns/Parameters Involved**: `@NumberOfMinutes`, `@NumberToTrigger`, `CTF.Occurred`

**Rules**:
- Window: `CTF.Occurred >= DATEADD(MINUTE, -@NumberOfMinutes, GETDATE())` (inclusive-start, unlike CheckNewAccountsPerTime which uses >).
- Filter: FundingTypeID=29 (ACH only - does NOT include PWMB/32).
- GROUP BY CID; HAVING COUNT(*) >= @NumberToTrigger.
- Default @NumberOfMinutes=1, @NumberToTrigger=5: alert if any customer links 5+ ACH accounts in 1 minute.

**Diagram**:
```
For each CID: COUNT(new ACH accounts in last @NumberOfMinutes minutes) >= @NumberToTrigger?
  YES: Include in result set (CID, NumOfAccounts)
  NO:  Exclude

Default: 5 accounts in 1 minute = alert
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NumberOfMinutes | INT | YES | 1 | CODE-BACKED | Rolling time window in minutes. Default: 1 minute. New ACH account links with Occurred >= DATEADD(MINUTE, -@NumberOfMinutes, GETDATE()) are counted. Short window designed for real-time fraud detection. |
| 2 | @NumberToTrigger | SMALLINT | YES | 5 | CODE-BACKED | Per-customer alert threshold. Default: 5 accounts per window. Customers with >= this many new ACH accounts in the window are returned. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| New account links | Billing.CustomerToFunding | READER | Counts ACH account links per customer by Occurred timestamp |
| FundingTypeID filter | Billing.Funding | JOIN | Filters to ACH (FundingTypeID=29 only) |

### 5.2 Referenced By (other objects point to this)

No callers found. Called by external real-time monitoring agent or job.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.ACHMonitor_ToManyAccountsPerTimeAndCID (procedure)
|- Billing.Funding (table) [leaf]
|- Billing.CustomerToFunding (table) [leaf]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerToFunding | Table | Counts new ACH account links per customer; both WITH(NOLOCK) |
| Billing.Funding | Table | JOINed to filter FundingTypeID=29 (ACH only) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

SET NOCOUNT ON. Both tables use WITH(NOLOCK). Default parameters defined. ACH-only (29), does not include PWMB (32) unlike some other ACHMonitor procedures. Uses >= for time comparison (inclusive).

---

## 8. Sample Queries

### 8.1 Run with defaults (5 accounts in 1 minute)

```sql
EXEC Billing.ACHMonitor_ToManyAccountsPerTimeAndCID
```

### 8.2 Run with custom thresholds

```sql
EXEC Billing.ACHMonitor_ToManyAccountsPerTimeAndCID
    @NumberOfMinutes = 5,
    @NumberToTrigger = 3
```

### 8.3 Manual equivalent - top account-linkers in last hour

```sql
SELECT
    CTF.CID,
    COUNT(*) AS NumAccounts
FROM Billing.Funding WITH (NOLOCK) AS F
INNER JOIN Billing.CustomerToFunding WITH (NOLOCK) AS CTF ON F.FundingID = CTF.FundingID
WHERE CTF.Occurred >= DATEADD(MINUTE, -60, GETDATE())
  AND F.FundingTypeID = 29
GROUP BY CTF.CID
ORDER BY NumAccounts DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.ACHMonitor_ToManyAccountsPerTimeAndCID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.ACHMonitor_ToManyAccountsPerTimeAndCID.sql*
