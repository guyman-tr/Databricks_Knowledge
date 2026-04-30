# Billing.DD_NoRedeemRequest

> DataDog heartbeat monitor that fires an alert when no new crypto redemption requests have been submitted in the past N hours, detecting a cessation of redemption activity that may indicate a system outage or pipeline failure.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 1-row result: value (0=activity detected, 1=no activity/alert) + diagnostic context |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DD_NoRedeemRequest` is a DataDog heartbeat monitor procedure (DBAD-16, October 2022). Unlike most DD_ monitors that fire when something BAD happens (too many accounts, stuck payments), this procedure fires when something STOPS happening: it alerts when NO new crypto redemption requests have arrived in `Billing.Redeem` within the configured time window.

On a live trading platform, customers continuously submit crypto redemption requests throughout the trading day. A gap of 3+ hours with zero new requests is operationally anomalous - it likely indicates one of: the redemption submission API is down, a message queue is failing to deliver requests to the database, the trading platform is experiencing an outage, or a firewall/routing issue has blocked the connection path.

The `value=1` alert (inverted logic compared to most monitors) means "silence = alarm". DataDog uses this as a dead-man's switch or watchdog: expected activity proves the system is alive; absence of activity is the alert condition.

The procedure also returns diagnostic context via CROSS APPLY: the `last_id` (most recent RedeemID) and `last_date` (most recent RequestDate) from the entire Redeem table, regardless of the time window. This tells the operations team WHEN the last redemption was seen, which helps diagnose whether the silence just started or has been ongoing for a long time.

---

## 2. Business Logic

### 2.1 Inverted Heartbeat - Absence-of-Activity Alert

**What**: Monitors the expected stream of redemption requests; fires when the stream goes silent.

**Columns/Parameters Involved**: `@IntervalInHours`, `Billing.Redeem.RequestDate`

**Rules**:
- `value=0` means activity IS present (normal); `value=1` means no activity (alert) - the opposite of most DD_ monitors
- The CTE counts redeems with `RequestDate > (now - @IntervalInHours)`. If COUNT > 0 -> value=0 (OK). If COUNT = 0 -> value=1 (alert)
- Default interval: 3 hours - appropriate for a platform with continuous trading activity
- On weekends or market holidays, legitimate low activity may cause false alerts - DataDog monitor schedules should account for this

**Diagram**:
```
@IntervalInHours=3
          |
  COUNT * FROM Billing.Redeem
  WHERE RequestDate > (now - 3 hours)
          |
    +-----+-----+
    |             |
  COUNT > 0   COUNT = 0
    |               |
  value=0         value=1  <-- Alert: no redeem requests in 3 hours
  (system alive)   (system may be down)
```

### 2.2 Diagnostic Context via CROSS APPLY

**What**: Returns the most recent redemption record's ID and date for operational context, regardless of time window.

**Columns/Parameters Involved**: `Billing.Redeem.RedeemID`, `Billing.Redeem.RequestDate`

**Rules**:
- `last_id` = MAX(RedeemID) from the entire table (not window-filtered)
- `last_date` = MAX(RequestDate) from the entire table
- When `value=1` (alert), these fields tell the team WHEN the last redemption was submitted and how long ago that was
- Example: if `last_date` is 5 hours ago and `value=1`, the system stopped receiving requests 5 hours ago

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IntervalInHours | INT | NO | 3 | CODE-BACKED | Time window in hours for checking redemption request activity. When no Billing.Redeem rows have RequestDate within the past @IntervalInHours hours, value=1 fires. Default of 3 hours balances sensitivity (short enough to catch outages) against noise (long enough to avoid holiday false alerts). |
| 2 | value (output) | INT | NO | - | CODE-BACKED | Inverted alert flag: 0 = at least one redemption request found in the window (system is alive); 1 = no redemption requests in the window (alert - system silence). DataDog alerts on value=1 (absence of expected activity). |
| 3 | last_id (output) | INT | YES | - | CODE-BACKED | MAX(RedeemID) from the full Billing.Redeem table regardless of time window. Diagnostic context: shows the most recent redemption request ID ever submitted, helping operators understand how long ago the last request arrived. |
| 4 | last_date (output) | DATETIME | YES | - | CODE-BACKED | MAX(RequestDate) from the full Billing.Redeem table regardless of time window. Diagnostic context: shows the exact timestamp of the most recent redemption request, enabling operators to determine how long the silence has lasted when an alert fires. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RequestDate, RedeemID filter | Billing.Redeem | Read | Reads Billing.Redeem for both time-window activity check and global max values for diagnostic context. See [Billing.Redeem](../Tables/Billing.Redeem.md). |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called externally by DataDog synthetic monitors.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DD_NoRedeemRequest (procedure)
└── Billing.Redeem (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Redeem | Table | Reads for two purposes: (1) count of recent requests in the time window; (2) MAX(RedeemID) and MAX(RequestDate) for diagnostic context |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DataDog Synthetic Monitor | External | Calls this procedure on a schedule as a system-alive heartbeat; alerts when redemption request flow stops |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Run with default 3-hour window

```sql
EXEC Billing.DD_NoRedeemRequest;
-- value=0: recent redemption requests found (system alive)
-- value=1: no redemption requests in past 3 hours (investigate)
```

### 8.2 Widen to 8-hour window for weekend/holiday monitoring

```sql
EXEC Billing.DD_NoRedeemRequest @IntervalInHours = 8;
```

### 8.3 Manually investigate if the monitor fires: check recent redemption activity

```sql
SELECT TOP 20
       RedeemID,
       RequestDate,
       RedeemStatusID,
       DATEDIFF(MINUTE, RequestDate, GETUTCDATE()) AS MinutesAgo
FROM Billing.Redeem WITH (NOLOCK)
ORDER BY RequestDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 applicable)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DD_NoRedeemRequest | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DD_NoRedeemRequest.sql*
