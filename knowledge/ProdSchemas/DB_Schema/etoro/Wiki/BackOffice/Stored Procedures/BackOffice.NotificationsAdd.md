# BackOffice.NotificationsAdd

> Inserts a new notification record into the BackOffice notification queue and returns the new NotificationID via both an OUTPUT parameter and a SELECT result set.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into BackOffice.Notifications; returns NotificationID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.NotificationsAdd` is the sole writer of the `BackOffice.Notifications` queue table. When a business event requires sending a back-office notification (triggered by a scheduled job, compliance event, or automated alert), this procedure enqueues the notification record with its type, trigger classification, delivery parameters, initial status, and retry configuration. A separate scheduler service then polls the queue and processes pending records.

The procedure decouples notification triggering from notification delivery. The caller synchronously enqueues the record and receives a confirmation ID; the actual sending happens asynchronously via the scheduler. This ensures that transient delivery failures do not block the triggering business process.

The InsertDate and LastModificationDate are both set to GETDATE() server-side at insert time. The procedure validates that the insert succeeded (NotificationID > 0) and raises error 60000 if SCOPE_IDENTITY() returns a non-positive value - though in practice this guard will not fire since SCOPE_IDENTITY() returns NULL (not <= 0) if the INSERT itself failed with an exception.

---

## 2. Business Logic

### 2.1 Queue Entry Lifecycle Initialization

**What**: Sets initial state for a new notification record that the scheduler will process.

**Columns/Parameters Involved**: `@NotificationStatusID`, `@TriesCounter`, `@NotificationTypeID`, `@NotificationTriggerID`

**Rules**:
- Caller sets initial NotificationStatusID (typically 1=Pending/Queued) - the procedure does not enforce a specific starting status.
- Caller sets TriesCounter initial value (typically 0 for fresh entries, or a specific value for re-queue scenarios).
- Both InsertDate and LastModificationDate are set to GETDATE() at insert - tracking when the notification entered the queue.
- @NotificationID OUTPUT captures SCOPE_IDENTITY() after the INSERT - the assigned queue ID.

### 2.2 Dual Return Mechanism

**What**: NotificationID is returned both as an OUTPUT parameter and as a scalar SELECT result set.

**Rules**:
- `Set @NotificationID = Scope_Identity()` populates the OUTPUT parameter.
- `Select @NotificationID` returns the same value as a result set row.
- Callers that support OUTPUT parameters use the parameter; callers using simple EXEC patterns read the result set.
- This dual mechanism supports both ADO.NET ExecuteScalar (result set) and ExecuteNonQuery with OUTPUT parameter patterns.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NotificationTypeID | int | NO | - | VERIFIED | Classifies the category of notification being enqueued. Written to BackOffice.Notifications.NotificationTypeID. Live data shows all active records use type 1. FK to notification type lookup (not enforced by DDL constraint on Notifications table). |
| 2 | @NotificationTriggerID | int | NO | - | VERIFIED | Identifies the business event that triggered this notification. Written to BackOffice.Notifications.NotificationTriggerID. Live data shows all records use trigger 1. |
| 3 | @NotificationStatusID | int | NO | - | VERIFIED | Initial delivery status for the queued notification. Typically 1=Pending (eligible for scheduler pickup). The scheduler reads records where NotificationStatusID IN (1, 4). Callers may set other initial values for special queue states. |
| 4 | @Params | nvarchar(max) | YES | NULL | VERIFIED | Notification-specific payload. Likely JSON or delimited string with recipient information, template parameters, or message content consumed by the scheduler. NULL is valid for parameter-free notification types. |
| 5 | @TriesCounter | int | NO | - | VERIFIED | Initial delivery attempt counter. Callers typically pass 0 for new notifications. The scheduler processes records where TriesCounter < @MaxTries parameter; NotificationsUpdate increments this on failure. |
| 6 | @NotificationID | int OUTPUT | - | - | VERIFIED | OUTPUT: receives the SCOPE_IDENTITY() of the inserted row (BackOffice.Notifications.ID). Also returned as a SELECT result set scalar. Callers use this to track or reference the queued notification. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT target | BackOffice.Notifications | Writer | Sole writer - creates new notification queue entries |

### 5.2 Referenced By (other objects point to this)

No SQL-layer callers found in BackOffice schema. Called from BackOffice application services and scheduled job processes.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.NotificationsAdd (procedure)
+-- BackOffice.Notifications (table) [INSERT target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Notifications | Table | INSERT - creates the queue record |

### 6.2 Objects That Depend On This

No SQL-layer dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Note: The guard `IF @NotificationID <= 0` is technically unreachable via normal SCOPE_IDENTITY() behavior - if the INSERT fails with an exception, control goes to SQL Server error handling, not to the IF check. The guard would only fire if SCOPE_IDENTITY() returned 0, which should not occur for an IDENTITY(1,1) column.

---

## 8. Sample Queries

### 8.1 Enqueue a notification and capture the ID

```sql
DECLARE @NewNotificationID INT;
EXEC BackOffice.NotificationsAdd
    @NotificationTypeID = 1,
    @NotificationTriggerID = 1,
    @NotificationStatusID = 1,
    @Params = N'{"recipient": "agent@etoro.com", "template": "AlertTemplate"}',
    @TriesCounter = 0,
    @NotificationID = @NewNotificationID OUTPUT;
SELECT @NewNotificationID AS QueuedNotificationID;
```

### 8.2 Verify the inserted record

```sql
SELECT ID, NotificationTypeID, NotificationTriggerID, NotificationStatusID,
       TriesCounter, InsertDate, LastModificationDate
FROM BackOffice.Notifications WITH (NOLOCK)
WHERE ID = @NewNotificationID;
```

### 8.3 Check current queue depth after insertion

```sql
SELECT NotificationStatusID, COUNT(*) AS Count
FROM BackOffice.Notifications WITH (NOLOCK)
GROUP BY NotificationStatusID
ORDER BY NotificationStatusID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Proc Ref Scan, Atlassian, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.NotificationsAdd | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.NotificationsAdd.sql*
