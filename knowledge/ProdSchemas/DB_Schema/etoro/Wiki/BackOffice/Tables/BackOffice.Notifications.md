# BackOffice.Notifications

> Outbound notification queue that holds pending and processed notifications for the BackOffice notification scheduler service, tracking delivery status and retry attempts.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | PK_BackOffice_Notifications: ID IDENTITY (CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (clustered PK, PAGE compressed) |

---

## 1. Business Meaning

`BackOffice.Notifications` is the outbound notification queue for eToro's back-office notification scheduler. When a back-office event or trigger fires that requires sending a notification (e.g., a scheduled alert, a compliance trigger, an automated message), a record is inserted into this table. A scheduler service periodically polls the table for eligible records and processes them - sending the notification and updating the status.

This table exists to decouple the triggering of a notification from its delivery. The insert is synchronous with the business event, while the delivery is asynchronous via the scheduler. This ensures reliability: if the notification service is temporarily unavailable, records remain in the queue for retry.

Data lifecycle: Records are inserted by `BackOffice.NotificationsAdd`, modified by `BackOffice.NotificationsUpdate` (status and retry counter updates), and read by `BackOffice.GetNotificationRecordsForProcessing` (the scheduler's fetch query). Live data shows ~320K records, almost all with NotificationTypeID=1 and NotificationTriggerID=1, the vast majority in status 3 (processed).

---

## 2. Business Logic

### 2.1 Notification Processing State Machine

**What**: NotificationStatusID tracks each notification through its delivery lifecycle.

**Columns/Parameters Involved**: `NotificationStatusID`, `TriesCounter`

**Rules**:
- Status 1 = Pending/Queued - ready to be picked up by the scheduler (eligible for processing).
- Status 2 = In Progress - currently being processed (very few rows; transitional state).
- Status 3 = Completed/Processed - notification was delivered successfully.
- Status 4 = Failed/Retry Eligible - previous delivery attempt failed; eligible for retry if TriesCounter < threshold.
- The scheduler selects rows WHERE `NotificationStatusID IN (1, 4)` AND `TriesCounter < @MaxTries` AND `InsertDate` within a time window.
- `TriesCounter` is incremented each time a delivery is attempted.

**Diagram**:
```
Insert (Status=1, TriesCounter=0)
        |
        v
Scheduler picks up (Status=1 or 4, TriesCounter < max)
        |
        +-- Success --> Status=3 (Completed)
        |
        +-- Failure --> Status=4, TriesCounter++ (Retry Eligible)
                               |
                               v (if TriesCounter >= max)
                             Status=4, never retried (stuck/abandoned)
```

### 2.2 Notification Type and Trigger Classification

**What**: NotificationTypeID and NotificationTriggerID classify what kind of notification this is and what caused it.

**Columns/Parameters Involved**: `NotificationTypeID`, `NotificationTriggerID`

**Rules**:
- In live data, all records have NotificationTypeID=1 and NotificationTriggerID=1 - suggesting a single primary notification type is currently active.
- `Params` carries the notification-specific payload as NVARCHAR(MAX) - likely JSON or delimited string with recipient, message content, etc.

---

## 3. Data Overview

| ID | NotificationTypeID | NotificationTriggerID | NotificationStatusID | TriesCounter | Meaning |
|----|-------------------|----------------------|---------------------|-------------|---------|
| 320201 | 1 | 1 | 3 | 1 | Processed notification - delivered on first attempt |
| 320200 | 1 | 1 | 3 | 1 | Processed notification - delivered on first attempt |
| 320199 | 1 | 1 | 3 | 1 | Processed notification - delivered on first attempt |
| 320198 | 1 | 1 | 3 | 1 | Processed notification from prior hour cycle |
| 320197 | 1 | 1 | 3 | 1 | Processed notification from prior hour cycle |

Distribution: 155,872 completed (status 3), 131,267 pending (status 1), 31,997 failed/retry (status 4), 12 in-progress (status 2). Active queue has ~163K unprocessed records.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-incrementing primary key. NOT FOR REPLICATION flag means the identity seed is not replicated to subscribers. |
| 2 | NotificationTypeID | int | NO | - | CODE-BACKED | Classifies the category of notification. All current data has value 1. Likely references a lookup table for notification types (e.g., email, SMS, push). |
| 3 | NotificationTriggerID | int | NO | - | CODE-BACKED | Identifies what business event triggered this notification. All current data has value 1. Likely references a lookup for trigger events (e.g., compliance threshold reached, scheduled alert). |
| 4 | Params | nvarchar(max) | YES | - | NAME-INFERRED | Notification payload parameters. Likely JSON or delimited string containing recipient information, message content, or template parameters needed by the sending service. |
| 5 | NotificationStatusID | int | NO | - | VERIFIED | Delivery state of this notification: 1=Pending/Queued (eligible for processing), 2=In Progress (being processed), 3=Completed/Delivered, 4=Failed/Retry Eligible. Evidence: SP code WHERE clause `(NotificationStatusID=1 Or NotificationStatusID=4)` confirms 1=pending, 4=failed. |
| 6 | TriesCounter | int | NO | - | VERIFIED | Number of delivery attempts made so far. Starting value is set by the inserter. The scheduler only processes records where TriesCounter < @MaxTries parameter. On failure, incremented via NotificationsUpdate. |
| 7 | InsertDate | datetime | NO | - | CODE-BACKED | UTC timestamp when the notification was added to the queue. The scheduler uses this in a time-window filter: only processes records inserted within the last @BackwardHoursRange hours. |
| 8 | LastModificationDate | datetime | NO | - | CODE-BACKED | UTC timestamp of the most recent update to this record. Set to GETDATE() by NotificationsAdd on insert, and updated on every NotificationsUpdate call. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing foreign key references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.NotificationsAdd | INSERT | Writer | Creates new notification queue entries |
| BackOffice.NotificationsUpdate | UPDATE | Modifier | Updates status and retry counter after delivery attempt |
| BackOffice.GetNotificationRecordsForProcessing | SELECT | Reader | Scheduler fetch: retrieves eligible pending/retry records within time window |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (leaf table).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.NotificationsAdd | Stored Procedure | Writer - inserts new notification queue records |
| BackOffice.NotificationsUpdate | Stored Procedure | Modifier - updates NotificationStatusID and TriesCounter |
| BackOffice.GetNotificationRecordsForProcessing | Stored Procedure | Reader - fetches eligible records for the scheduler service |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BackOffice_Notifications | CLUSTERED PK | ID ASC | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Page-level compression applied to the clustered index - reduces storage for this high-volume queue table. |
| ID NOT FOR REPLICATION | Identity | IDENTITY value is not copied to replication subscribers, allowing each subscriber to maintain its own identity sequence. |

---

## 8. Sample Queries

### 8.1 Check the current notification queue by status

```sql
SELECT NotificationStatusID, COUNT(*) AS RecordCount
FROM BackOffice.Notifications WITH (NOLOCK)
GROUP BY NotificationStatusID
ORDER BY NotificationStatusID;
-- 1=Pending, 2=InProgress, 3=Completed, 4=Failed/Retry
```

### 8.2 Find stuck notifications (failed, max retries reached)

```sql
SELECT TOP 20 ID, NotificationTypeID, NotificationTriggerID, TriesCounter, InsertDate, LastModificationDate
FROM BackOffice.Notifications WITH (NOLOCK)
WHERE NotificationStatusID = 4
ORDER BY TriesCounter DESC, InsertDate;
```

### 8.3 Simulate what the scheduler would fetch (last 24 hours, max 3 tries)

```sql
DECLARE @BackwardHoursRange INT = -24;
DECLARE @MaxTries INT = 3;
DECLARE @MaxRows INT = 1000;
DECLARE @Now DATETIME = GETDATE();

SELECT TOP(@MaxRows) *
FROM BackOffice.Notifications WITH (NOLOCK)
WHERE (NotificationStatusID = 1 OR NotificationStatusID = 4)
    AND TriesCounter < @MaxTries
    AND (InsertDate BETWEEN DATEADD(HOUR, @BackwardHoursRange, @Now) AND @Now)
ORDER BY ID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 5/11 (DDL, Live Data, Distribution, Procedure Ref, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.Notifications | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.Notifications.sql*
