# Billing.ACHMonitor_CheckNewAccountsPerTime

> ACH monitoring stored procedure that counts new ACH funding accounts created within a rolling time window and returns an alert message if the count meets or exceeds a specified threshold, used for real-time detection of abnormal account creation rates.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NumOfMinutes, @NumToAlert input; conditional result set (message row) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.ACHMonitor_CheckNewAccountsPerTime` is a real-time fraud detection probe that monitors the rate of new ACH bank account links. It queries `Billing.CustomerToFunding` for ACH accounts (FundingTypeID=29) created in the last @NumOfMinutes minutes. If the count of new accounts reaches or exceeds @NumToAlert, the procedure returns a single-row result set with a descriptive alert message.

The procedure exists to detect abnormal spikes in ACH account creation - a potential indicator of fraud, bot activity, or a platform abuse campaign. When the threshold is exceeded, the message can be consumed by a monitoring agent, job, or alert system.

The procedure returns an empty result set (no rows) when the threshold is NOT met, allowing calling systems to treat "no rows returned" as "all clear".

---

## 2. Business Logic

### 2.1 Threshold-Based Alert Logic

**What**: Returns an alert only when new ACH accounts in the time window meet or exceed the threshold.

**Columns/Parameters Involved**: `@NumOfMinutes`, `@NumToAlert`

**Rules**:
- Query `Billing.CustomerToFunding` for records where `Occurred > DATEADD(MINUTE, -@NumOfMinutes, GETDATE())`.
- Filter to ACH accounts via JOIN to `Billing.Funding` WHERE `FundingTypeID = 29`.
- Use HAVING COUNT(*) >= @NumToAlert to only return rows when threshold met.
- If threshold met: returns one row with message `'Number of new ACH accounts that werere created during the last {N} minutes was {count}'`.
- If threshold not met: returns zero rows.

**Diagram**:
```
COUNT(new ACH accounts in last @NumOfMinutes minutes) >= @NumToAlert?
  YES: Return "Number of new ACH accounts... was {count}"
  NO:  Return empty result set (no alert)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NumOfMinutes | SMALLINT | NO | - | CODE-BACKED | Size of the rolling time window in minutes. New ACH accounts created after `DATEADD(MINUTE, -@NumOfMinutes, GETDATE())` are counted. Example: 1000 (from inline comment) monitors the last ~16 hours. |
| 2 | @NumToAlert | INT | NO | - | CODE-BACKED | Alert threshold. If the count of new ACH accounts in the time window is >= this value, an alert message is returned. Example: 1 (minimum threshold; any new account triggers an alert). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeID=29 | Billing.CustomerToFunding | JOIN | Counts new ACH account linkages by creation time (Occurred) |
| FundingTypeID filter | Billing.Funding | JOIN | Filters to ACH funding type (FundingTypeID=29) |

### 5.2 Referenced By (other objects point to this)

No callers found in SSDT. Called by external monitoring agent or scheduled job.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.ACHMonitor_CheckNewAccountsPerTime (procedure)
|- Billing.CustomerToFunding (table) [leaf]
|- Billing.Funding (table) [leaf]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerToFunding | Table | Queried for new ACH account links; filtered by Occurred timestamp |
| Billing.Funding | Table | JOINed to filter FundingTypeID=29 (ACH) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

SET NOCOUNT ON. Uses CTE with HAVING to conditionally produce output. Note: typo in message string ("werere" instead of "were") is in the source code.

---

## 8. Sample Queries

### 8.1 Check for alert with default-like parameters

```sql
EXEC Billing.ACHMonitor_CheckNewAccountsPerTime @NumOfMinutes = 60, @NumToAlert = 10
```

### 8.2 Check new ACH account rate manually

```sql
SELECT COUNT(*) AS NewACHAccounts
FROM Billing.CustomerToFunding WITH (NOLOCK) AS CTF
INNER JOIN Billing.Funding WITH (NOLOCK) AS F ON F.FundingID = CTF.FundingID
WHERE CTF.Occurred > DATEADD(MINUTE, -60, GETDATE())
  AND F.FundingTypeID = 29
```

### 8.3 Time series of new ACH accounts per hour

```sql
SELECT
    DATEPART(HOUR, CTF.Occurred) AS Hour,
    COUNT(*) AS NewAccounts
FROM Billing.CustomerToFunding WITH (NOLOCK) AS CTF
INNER JOIN Billing.Funding WITH (NOLOCK) AS F ON F.FundingID = CTF.FundingID
WHERE CTF.Occurred >= CAST(GETDATE() AS DATE)
  AND F.FundingTypeID = 29
GROUP BY DATEPART(HOUR, CTF.Occurred)
ORDER BY Hour
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.ACHMonitor_CheckNewAccountsPerTime | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.ACHMonitor_CheckNewAccountsPerTime.sql*
