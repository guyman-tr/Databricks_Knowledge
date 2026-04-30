# Billing.ALERT_CheckRedeemNotProcessed

> Monitoring stored procedure that detects Redeem (withdrawal) records stuck in Approved status (RedeemStatusID=3) for an excessive number of BUSINESS days, using accurate business-day arithmetic excluding weekends, and returns a concatenated alert message with the stuck RedeemIDs if the count exceeds a configurable threshold.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DaysThreshold INT=5, @RedeemsThreshold INT=10; returns alert string |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.ALERT_CheckRedeemNotProcessed` monitors for withdrawal (Redeem) requests that have been approved but not actually processed to completion within the expected SLA window. In eToro's withdrawal flow, a Redeem record progresses through statuses: once it reaches Approved (RedeemStatusID=3), processing should begin promptly. If a batch of approved redeems sits unprocessed for more than 5 business days (default), it indicates a processing pipeline failure - funds are approved for return but haven't actually been sent.

The procedure uses **business-day arithmetic** (excluding weekends) for the age calculation, avoiding false alerts over holiday weekends. It also applies a clustering filter: only raises an alert if >= @RedeemsThreshold (default 10) are stuck on the same creation date - preventing isolated one-off cases from firing alerts.

The output is a concatenated string of affected RedeemIDs, which the caller can include in an email or monitoring notification. Unlike the ACH monitor family, this procedure returns a result set rather than directly sending email.

---

## 2. Business Logic

### 2.1 Stuck Redeem Detection

**What**: Finds Billing.Redeem records in Approved status that are older than @DaysThreshold business days, clustering by creation date.

**Columns/Parameters Involved**: `@DaysThreshold`, `@RedeemsThreshold`, `RedeemStatusID`, `CreationDate`, `RedeemID`

**Rules**:
- Filter: `RedeemStatusID = 3` (Approved - cleared for processing but not yet dispatched).
- **Business-day age**: Computed as:
  ```sql
  DATEDIFF(dd, r.CreationDate, GETDATE())
  - (DATEDIFF(wk, r.CreationDate, GETDATE()) * 2)
  - IIF(DATEPART(dw, r.CreationDate) = 1, 1, 0)   -- subtract if start is Sunday
  + IIF(DATEPART(dw, GETDATE()) = 1, 1, 0)          -- add back if end is Sunday
  ```
  This computes calendar days minus weekend days (2 per week), with Sunday-boundary corrections.
- Filter: Business-day age >= @DaysThreshold.
- **Clustering filter**: Only returns dates where COUNT(*) >= @RedeemsThreshold. This prevents individual orphaned redeems from firing the alert; requires a systemic backlog.
- Output: Concatenated string of RedeemIDs (e.g., `"12345,12346,12347"`) for the stuck batch.

**Diagram**:
```
Billing.Redeem
  WHERE RedeemStatusID = 3 (Approved)
    AND BusinessDayAge(CreationDate, TODAY) >= @DaysThreshold
  |
  GROUP BY CreationDate
    HAVING COUNT(*) >= @RedeemsThreshold
  |
  v
Concatenate RedeemIDs -> return alert string
(empty result = no alert needed)
```

### 2.2 Business-Day Arithmetic

The formula used:
```sql
DATEDIFF(dd, StartDate, EndDate)
- (DATEDIFF(wk, StartDate, EndDate) * 2)
- IIF(DATEPART(dw, StartDate) = 1, 1, 0)
+ IIF(DATEPART(dw, EndDate)   = 1, 1, 0)
```

- `DATEDIFF(wk,...)` counts week boundaries (Sunday-to-Monday transitions in US default), each subtracting 2 calendar days.
- The IIF corrections handle partial weeks where the start or end falls on Sunday.
- Result: approximate business days between two dates (excludes Saturdays and Sundays; does NOT account for public holidays).

**Note**: SQL Server's `DATEPART(dw,...)` is locale-dependent via `SET DATEFIRST`. The formula assumes `DATEFIRST=7` (US default, Sunday=1). If the server uses a different DATEFIRST, the Sunday correction IIF conditions may be incorrect.

### 2.3 Threshold Logic

Both thresholds serve distinct purposes:
- `@DaysThreshold=5`: Time filter - a Redeem must be at least 5 business days old to be considered stuck.
- `@RedeemsThreshold=10`: Volume filter - at least 10 redeems must be stuck on the same creation date. Prevents single-record noise from alerting.

The dual-threshold design means: "alert only when a BATCH of redeems from a specific day has been stuck for an SLA breach window."

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DaysThreshold | INT | NO | 5 | CODE-BACKED | Minimum business days a Redeem must be in Approved status (RedeemStatusID=3) before being considered "stuck". Default 5 business days = approximately 1 calendar week. Increase for more tolerance; decrease for stricter SLA monitoring. |
| 2 | @RedeemsThreshold | INT | NO | 10 | CODE-BACKED | Minimum number of stuck Redeems per creation date required to trigger an alert. Default 10 prevents alerting on isolated single-record anomalies. Groups of < 10 stuck Redeems from the same day are silently ignored. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Stuck redeems | Billing.Redeem | READER | Queries for Approved (RedeemStatusID=3) records with excessive business-day age |

### 5.2 Referenced By (other objects point to this)

No callers found in SSDT. Called by application monitoring service or SQL Agent job that handles the returned alert string (e.g., formats and sends email or posts to monitoring system).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.ALERT_CheckRedeemNotProcessed (procedure)
|- Billing.Redeem (table) [leaf - stuck redeem query]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Redeem | Table | Queried for records in RedeemStatusID=3 (Approved) with business-day age >= @DaysThreshold |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

No SET NOCOUNT. RedeemStatusID=3 hardcoded as the target status. Business-day formula assumes DATEFIRST=7 (SQL Server US default) - locale-sensitive. Public holidays not accounted for in the business-day calculation. Output is a concatenated string (suitable for inclusion in monitoring messages). No transaction. No email dispatch (caller handles notification).

**Business-day formula caveat**: The IIF corrections check `DATEPART(dw,...) = 1` which equals Sunday only when `SET DATEFIRST 7` (US default). If the server has `SET DATEFIRST 1` (ISO standard, Monday=1), then `dw=1` means Monday, causing incorrect corrections. The formula should be verified against the server's DATEFIRST setting.

---

## 8. Sample Queries

### 8.1 Run with defaults (5 business days, 10 redeems minimum)

```sql
EXEC Billing.ALERT_CheckRedeemNotProcessed
    @DaysThreshold = 5,
    @RedeemsThreshold = 10
```

### 8.2 Run with stricter threshold (3 business days, 5 redeems)

```sql
EXEC Billing.ALERT_CheckRedeemNotProcessed
    @DaysThreshold = 3,
    @RedeemsThreshold = 5
```

### 8.3 Check stuck approved redeems manually

```sql
SELECT
    r.RedeemID,
    r.CID,
    r.RedeemStatusID,
    r.CreationDate,
    DATEDIFF(dd, r.CreationDate, GETDATE())
        - (DATEDIFF(wk, r.CreationDate, GETDATE()) * 2)
        - IIF(DATEPART(dw, r.CreationDate) = 1, 1, 0)
        + IIF(DATEPART(dw, GETDATE()) = 1, 1, 0) AS BusinessDaysStuck
FROM Billing.Redeem WITH (NOLOCK) AS r
WHERE r.RedeemStatusID = 3
ORDER BY r.CreationDate ASC
```

### 8.4 Count stuck redeems by creation date (find clustering)

```sql
SELECT
    CAST(r.CreationDate AS DATE) AS CreationDay,
    COUNT(*) AS StuckCount
FROM Billing.Redeem WITH (NOLOCK) AS r
WHERE r.RedeemStatusID = 3
  AND DATEDIFF(dd, r.CreationDate, GETDATE())
      - (DATEDIFF(wk, r.CreationDate, GETDATE()) * 2)
      - IIF(DATEPART(dw, r.CreationDate) = 1, 1, 0)
      + IIF(DATEPART(dw, GETDATE()) = 1, 1, 0) >= 5
GROUP BY CAST(r.CreationDate AS DATE)
HAVING COUNT(*) >= 10
ORDER BY CreationDay ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.ALERT_CheckRedeemNotProcessed | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.ALERT_CheckRedeemNotProcessed.sql*
