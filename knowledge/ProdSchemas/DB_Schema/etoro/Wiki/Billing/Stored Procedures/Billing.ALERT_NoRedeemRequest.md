# Billing.ALERT_NoRedeemRequest

> Monitoring alert procedure that checks for redeem (crypto withdrawal) request activity within a configurable look-back window (default: last 3 hours); produces a human-readable diagnostic message ONLY when no requests are found, enabling monitoring systems to detect redeem processing gaps.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns single-column resultset (Msg) only when alert condition is met (no redeem requests in window) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.ALERT_NoRedeemRequest` is an operational monitoring procedure for the redeem (crypto/stock cashout) pipeline. It checks whether any customer redeem requests have been submitted in the last N hours. If there are none - which would be unusual during business hours - it returns a single diagnostic row with a plain-text message naming the last known redeem ID and its timestamp.

The procedure follows an "alert on silence" pattern: it is silent (no result) when the pipeline is healthy, and speaks only when something looks wrong. This makes it simple for a monitoring scheduler to use: any non-empty resultset is the alert signal. The default 3-hour window is calibrated to catch processing gaps that would indicate a stuck or broken redeem intake service, while tolerating normal overnight or weekend quiet periods.

The alert is complementary to `Billing.Alert_CashoutSentToProvider` (which monitors the outbound payment side of cashouts) - this procedure covers the earlier intake stage: customers submitting redeem requests.

---

## 2. Business Logic

### 2.1 Alert-on-Silence Pattern

**What**: The procedure emits output ONLY when no redeem requests have been received in the look-back window. Normal operation produces no output.

**Parameters/Columns Involved**: `@IntervalInHours`, `Billing.Redeem.RequestDate`

**Rules**:
- Condition: `NOT EXISTS (SELECT * FROM Billing.Redeem WHERE RequestDate > DATEADD(HOUR, -@IntervalInHours, GETUTCDATE()))`.
- Note: The code uses `DATEADD(HOUR, 0-@IntervalInHours, ...)` which is equivalent to `DATEADD(HOUR, -@IntervalInHours, ...)` - a style choice, not a bug.
- If the EXISTS check finds ANY request in the window: the IF block does NOT execute. Zero rows returned. Monitor interprets this as "all healthy."
- If NO requests exist in the window: the IF block executes, returns one row with a Msg column.
- Callers should treat any non-empty resultset as the alert condition.

### 2.2 Diagnostic Message Content

**What**: When the alert fires, the message provides operational context: how long the gap is, what the last known request was, and when it occurred.

**Parameters/Columns Involved**: `Billing.Redeem.RedeemID`, `Billing.Redeem.RequestDate`

**Rules**:
- `SELECT @last_id = MAX(RedeemID), @last_date = MAX(RequestDate) FROM Billing.Redeem` - looks at ALL historical records (no time filter) to find the last known activity.
- Message format: `'There are no redeem requests within {N} hours! Last redeem #{id} was on {date}'`
- `CONVERT(VARCHAR(25), @last_date, 100)` uses SQL Server style 100 (Mon DD YYYY HH:MMAM/PM format, e.g., "Mar 17 2026  9:30AM").
- If Billing.Redeem is empty (no records at all), @last_id and @last_date are NULL, and the CONCAT message will read: "There are no redeem requests within 3 hours! Last redeem # was on " - a partial but still actionable alert.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IntervalInHours | INT | YES | 3 | VERIFIED | Look-back window in hours. The procedure checks for redeem requests with RequestDate > DATEADD(HOUR, -@IntervalInHours, GETUTCDATE()). Default 3 hours is calibrated to catch processing gaps while tolerating short quiet periods. Increase for off-hours / weekend monitoring runs. |

**Result set** (returned ONLY when alert condition is met - no requests found in window):

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | Msg | VARCHAR | Human-readable alert message: "There are no redeem requests within {N} hours! Last redeem #{id} was on {date}". Non-empty resultset = alert triggered. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RequestDate filter | Billing.Redeem | READER | EXISTS check against RequestDate to determine if any recent redeem intake exists. Also reads MAX(RedeemID) and MAX(RequestDate) for the diagnostic message. |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in the Billing schema SP files. Called from monitoring/alerting systems on a scheduled basis.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.ALERT_NoRedeemRequest (procedure)
+- Billing.Redeem (table)   [EXISTS check + MAX aggregates for diagnostic message]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Redeem | Table | EXISTS check on RequestDate to detect activity gap; MAX(RedeemID)/MAX(RequestDate) for alert message context |

### 6.2 Objects That Depend On This

No dependents found in the Billing schema SP files. Called from monitoring/alerting tooling.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Run with default window (check last 3 hours)
```sql
EXEC Billing.ALERT_NoRedeemRequest;
-- Returns: no rows = healthy (requests found in last 3 hours)
-- Returns: 1 row with Msg = alert (no requests in last 3 hours)
```

### 8.2 Run with extended window for off-hours monitoring
```sql
EXEC Billing.ALERT_NoRedeemRequest @IntervalInHours = 12;
-- Suitable for overnight batch check - alerts only if 12+ hours of silence
```

### 8.3 Direct equivalents for debugging
```sql
-- Check if any recent requests exist (the EXISTS side)
SELECT COUNT(*) AS RequestsInLast3Hours
FROM Billing.Redeem WITH (NOLOCK)
WHERE RequestDate > DATEADD(HOUR, -3, GETUTCDATE());

-- Get the last known request (the diagnostic side)
SELECT MAX(RedeemID) AS LastRedeemID, MAX(RequestDate) AS LastRequestDate
FROM Billing.Redeem WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (SKIPPED - no Billing repos configured) | Corrections: 0 applied*
*Object: Billing.ALERT_NoRedeemRequest | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.ALERT_NoRedeemRequest.sql*
