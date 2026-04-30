# BackOffice.GetNotificationRecordsForProcessing

> Poll-based notification queue reader - returns the next batch of pending or retry-eligible BackOffice notifications within a configurable time window and retry limit, ordered by ID for FIFO processing.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BackwardHoursRange + @TriesCounter + @MaxAllowedProcessingRowsPerCycle |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the polling mechanism for eToro's withdrawal notification email pipeline. It reads the next batch of unprocessed notification records from `BackOffice.Notifications` that are eligible for processing - i.e., in a pending or retry state, not yet exhausted their retry budget, and inserted within the configured time window.

**Architecture context** (from Confluence: "Task scheduler for sending Email"):
The procedure is called by the Azure function `prod-WithdrawNotif-func-ne`, which runs on a **5-minute timer** under the `WithdrawalServiceUser` account. The function orchestrates the full withdrawal notification email dispatch workflow by calling these procedures in sequence:

1. `BackOffice.AuditActionAdd` - log the processing attempt
2. **`BackOffice.GetNotificationRecordsForProcessing`** - fetch the next batch to process
3. `BackOffice.NotificationsUpdate` - mark fetched notifications as in-progress / complete
4. `BackOffice.GetWithdrawProcessEmailParams` - get email parameters for each notification
5. `BackOffice.GetPaymentsDetailsHTMLTable` - build the HTML email body

This procedure (step 2) is the "dequeue" step - it identifies which notification records need to be sent and returns them to the Azure function for email dispatch. The @MaxAllowedProcessingRowsPerCycle parameter throttles the batch size to prevent overloading the email system per cycle.

**Created**: 2017-02-14 by Geri Reshef (ticket 43750).

---

## 2. Business Logic

### 2.1 Status Filter - Pending and Retry States

**What**: Only returns notifications in states that require processing action.

**Columns/Parameters Involved**: BON.NotificationStatusID

**Rules**:
- `NotificationStatusID = 1`: **Pending** - newly inserted notification not yet attempted.
- `NotificationStatusID = 4`: **Retry** - previously attempted but failed; eligible for re-processing.
- All other status IDs (e.g., Sent/Completed = 2, Failed/Exhausted = 3) are excluded.

### 2.2 Retry Budget Guard

**What**: Prevents indefinitely retrying permanently failing notifications.

**Columns/Parameters Involved**: BON.TriesCounter, @TriesCounter

**Rules**:
- `BON.TriesCounter < @TriesCounter`: Only notifications that have been attempted fewer times than the configured threshold are returned.
- When a notification reaches `TriesCounter >= @TriesCounter`, it will never be returned by this procedure again - the notification is effectively dead-lettered (remains in the table but no longer queued for processing).

### 2.3 Time Window Filter

**What**: Limits processing to notifications inserted within a recent time window, preventing stale notifications from being processed.

**Columns/Parameters Involved**: BON.InsertDate, @BackwardHoursRange, @Now (GETDATE())

**Rules**:
- `BON.InsertDate BETWEEN DateAdd(Hour, @BackwardHoursRange, @Now) AND @Now`
- `@BackwardHoursRange` is expected to be a **negative integer** (e.g., -24 means "the last 24 hours"). `DateAdd(Hour, -24, NOW)` produces a timestamp 24 hours ago.
- Notifications inserted before the time window (older than @BackwardHoursRange hours) are excluded even if still in pending/retry state. This prevents re-surfacing very old stuck notifications that may no longer be relevant.

### 2.4 Batch Size Control (FIFO)

**What**: Caps the number of records returned per processing cycle and enforces FIFO ordering.

**Columns/Parameters Involved**: @MaxAllowedProcessingRowsPerCycle, BON.ID

**Rules**:
- `SELECT TOP(@MaxAllowedProcessingRowsPerCycle)`: Hard cap on records per cycle - prevents email system overload on high-volume periods.
- `ORDER BY BON.ID`: Ascending order by primary key ensures oldest-first (FIFO) processing. Notifications inserted first are dispatched first, maintaining event ordering for audit purposes.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BackwardHoursRange | INT | NO | - | CODE-BACKED | Negative integer defining the lookback window in hours. Example: -24 = process only notifications inserted in the last 24 hours. Prevents reprocessing very old stuck notifications. |
| 2 | @TriesCounter | INT | NO | - | CODE-BACKED | Maximum retry attempts allowed. Notifications where TriesCounter >= this value are excluded (dead-lettered). Typical values: 3-5. |
| 3 | @MaxAllowedProcessingRowsPerCycle | INT | NO | - | CODE-BACKED | Batch size cap. Maximum number of notification records to return per 5-minute cycle. Controls throughput to avoid email system overload. |

**Output Columns**:

All columns from `BackOffice.Notifications` (SELECT *). Key columns include:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | INT | NO | - | CODE-BACKED | Primary key of the notification record. Used for FIFO ordering and as the handle for subsequent `NotificationsUpdate` calls. |
| 2 | NotificationStatusID | TINYINT/INT | NO | - | CODE-BACKED | Current status: 1=Pending, 4=Retry. Only these values are returned by this procedure. |
| 3 | TriesCounter | INT | NO | - | CODE-BACKED | Number of times this notification has been attempted. Incremented by `NotificationsUpdate` after each processing attempt. |
| 4 | InsertDate | DATETIME | NO | - | CODE-BACKED | When the notification was created. Used for the time window filter. |
| 5 | (other columns) | - | - | - | NAME-INFERRED | Other notification columns (e.g., CID, notification type, email content reference, etc.) passed through via SELECT * to the Azure function for email dispatch. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All columns | BackOffice.Notifications | Read (FROM) | Sole data source. Queried with NOLOCK for non-blocking poll reads. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Azure func: prod-WithdrawNotif-func-ne | EXECUTE | Caller (Step 2 of 5) | Withdrawal notification email pipeline. Runs every 5 minutes. Calls this SP to dequeue pending notifications for email dispatch. |
| WithdrawalServiceUser | EXECUTE | Permission | Azure function user account. Confirmed by Confluence: "Task scheduler for sending Email". |
| BOUserTaskScheduler | EXECUTE | Permission | Legacy or secondary scheduler account also granted EXECUTE rights. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Azure func: prod-WithdrawNotif-func-ne (every 5 min)
  -> BackOffice.AuditActionAdd (step 1)
  -> BackOffice.GetNotificationRecordsForProcessing (step 2 - this SP)
  -> BackOffice.NotificationsUpdate (step 3)
  -> BackOffice.GetWithdrawProcessEmailParams (step 4)
  -> BackOffice.GetPaymentsDetailsHTMLTable (step 5)

BackOffice.GetNotificationRecordsForProcessing
+-- BackOffice.Notifications (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Notifications | Table | FROM clause; sole data source for the notification queue poll |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| prod-WithdrawNotif-func-ne (Azure function) | External service | Calls this SP every 5 minutes as step 2 of the withdrawal email pipeline |
| BackOffice.NotificationsUpdate | Stored Procedure | Called immediately after this SP in the same pipeline cycle to update the status of the fetched records |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH(NOLOCK) on BackOffice.Notifications | Locking | Non-blocking read; avoids lock contention with write operations that insert/update notifications |
| ORDER BY BON.ID | FIFO guarantee | Oldest notifications processed first; maintains audit trail ordering |
| SELECT TOP(...) | Throughput control | Limits per-cycle processing to prevent email system overload |
| @BackwardHoursRange as negative INT | Design convention | Callers must pass a negative value (e.g., -24) for the BETWEEN to work correctly |

---

## 8. Sample Queries

### 8.1 Typical invocation (24-hour window, 3 retries max, 50 per cycle)

```sql
EXEC BackOffice.GetNotificationRecordsForProcessing
    @BackwardHoursRange = -24,
    @TriesCounter = 3,
    @MaxAllowedProcessingRowsPerCycle = 50
```

### 8.2 Check current pending/retry notification count

```sql
SELECT NotificationStatusID, COUNT(*) AS Count
FROM BackOffice.Notifications WITH (NOLOCK)
WHERE NotificationStatusID IN (1, 4)
AND InsertDate >= DATEADD(Hour, -24, GETDATE())
GROUP BY NotificationStatusID;
-- NotificationStatusID 1 = Pending, 4 = Retry
```

### 8.3 Check for stuck/dead-lettered notifications (over retry budget)

```sql
SELECT TOP 20 ID, NotificationStatusID, TriesCounter, InsertDate
FROM BackOffice.Notifications WITH (NOLOCK)
WHERE NotificationStatusID IN (1, 4)
AND TriesCounter >= 3  -- matching typical @TriesCounter threshold
ORDER BY InsertDate;
```

---

## 9. Atlassian Knowledge Sources

- **Confluence**: "Task scheduler for sending Email" (page ID: 12562301093) - documents the Azure function architecture, 5-minute timer, WithdrawalServiceUser, and the 5-step procedure sequence for withdrawal notification emails. Confirms this SP as step 2 of the `prod-WithdrawNotif-func-ne` pipeline.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 9.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 2 app service consumers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetNotificationRecordsForProcessing | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetNotificationRecordsForProcessing.sql*
