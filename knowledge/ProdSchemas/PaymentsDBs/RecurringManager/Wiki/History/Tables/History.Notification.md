# History.Notification

> Temporal history table storing previous versions of notification records that track outbound notifications sent to external services about recurring payment execution events.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | NotificationCorrelationId (mirrors PK of Recurring.Notification, GUID) |
| **Partition** | No |
| **Indexes** | 1 clustered (SysEndTime, SysStartTime) |

---

## 1. Business Meaning

History.Notification is the system-versioned temporal history table for `Recurring.Notification`. Each row represents a previous state of a notification record - an outbound communication sent to external notification services (push notifications, emails, webhooks) about recurring payment execution events. Notifications have a GUID-based correlation ID as their PK, enabling end-to-end tracing across distributed systems.

This table exists to provide an audit trail of notification delivery. Notifications transition from Created (1) through SentToService (3) or SentToServiceFailed (4), and each transition generates a history row. With 52K+ rows, the history shows that most notifications are quickly sent (sub-second Created -> SentToService transitions), but some fail and require investigation.

Data enters this table automatically via SQL Server's temporal mechanism. No stored procedures in the SSDT repo reference Recurring.Notification directly - the application (RecurringManagerService, visible in the Trace column) manages notifications through direct SQL operations. The Trace column (computed in the base table) captures the Kubernetes pod name, application, and service identity for each operation, providing full attribution. One notification per (PaymentExecutionId, NotificationTypeId) is enforced by a unique index.

---

## 2. Business Logic

### 2.1 Notification Delivery Lifecycle

**What**: Notifications progress through a delivery lifecycle from creation to service hand-off.

**Columns/Parameters Involved**: `NotificationStatusId`, `SendDate`

**Rules**:
- NotificationStatusId maps to Dictionary.NotificationStatus: 1=Created, 2=InProgress, 3=SentToService, 4=SentToServiceFailed, 5=Canceled, 6=LateCancellation. See [Notification Status](../../_glossary.md#notification-status). DEFAULT: 1 (Created)
- History distribution: Created 94%, SentToService 7%, SentToServiceFailed <1% - most history rows capture the Created state before transition to Sent
- SendDate is the scheduled delivery time (future-dated when created, e.g., "2022-06-17T00:00:00" for a notification created on 2022-06-14)

**Diagram**:
```
[Created (1)] --delivered--> [SentToService (3)]
     |
     +--failed--> [SentToServiceFailed (4)]
     |
     +--canceled--> [Canceled (5)]
```

### 2.2 One-Notification-Per-Execution-Type

**What**: The system enforces exactly one notification per payment execution per notification type.

**Columns/Parameters Involved**: `PaymentExecutionId`, `NotificationTypeId`, `NotificationCorrelationId`

**Rules**:
- Unique index UQ_Notification_PaymentExecution_NotificationType enforces 1:1 per (PaymentExecutionId, NotificationTypeId)
- NotificationCorrelationId (GUID) serves as the PK and enables cross-system tracing
- NotificationTypeId value 1 is the only observed type in production data

---

## 3. Data Overview

| NotificationCorrelationId | PaymentExecutionId | NotificationStatusId | SendDate | Meaning |
|---|---|---|---|---|
| 999C17D7-... | 105287 | 1 | 2022-06-14 11:00 | Notification created for execution 105287, scheduled to send at 11:00 UTC. This Created version lasted only 156ms before transitioning to SentToService. |
| 999C17D7-... | 105287 | 3 | 2022-06-14 11:00 | Same notification after successful delivery to the notification service. SentToService state lasted ~48 minutes before being superseded (likely a status update or cleanup). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | NotificationCorrelationId | uniqueidentifier | NO | - | CODE-BACKED | GUID primary key, mirroring the PK of Recurring.Notification. Serves as a cross-system correlation identifier enabling end-to-end tracing of notification delivery across the platform's distributed services. Not unique in history - same ID appears for each status transition. |
| 2 | PaymentExecutionId | int | NO | - | VERIFIED | References the payment execution that triggered this notification. Links to Recurring.PaymentExecution / History.PaymentExecution. Part of the unique constraint (with NotificationTypeId) ensuring one notification per execution per type. |
| 3 | NotificationTypeId | int | NO | - | CODE-BACKED | Classifies the type of notification. No Dictionary lookup table exists within RecurringManager. Only value 1 observed in all production data. Part of the unique constraint with PaymentExecutionId. Same column appears in Configuration.NotificationSetting / History.NotificationSetting. |
| 4 | NotificationStatusId | int | NO | 1 | VERIFIED | Delivery lifecycle state. Maps to Dictionary.NotificationStatus: 1=Created, 2=InProgress, 3=SentToService, 4=SentToServiceFailed, 5=Canceled, 6=LateCancellation. See [Notification Status](../../_glossary.md#notification-status). DEFAULT: 1 (Created). History shows 94% Created (captured before send), 7% SentToService, <1% SentToServiceFailed. (Dictionary.NotificationStatus) |
| 5 | CreateDate | datetime | NO | - | CODE-BACKED | Timestamp when the notification was created. DEFAULT: getutcdate(). Immutable after creation. |
| 6 | SendDate | datetime | NO | - | CODE-BACKED | Scheduled delivery date/time for the notification. May be future-dated relative to CreateDate (e.g., created June 14, scheduled to send June 17). Represents when the notification service should deliver to the end user, not when the record was created. |
| 7 | Trace | nvarchar(733) | NO | - | VERIFIED | Audit context captured at modification time. Computed column in the base table using CONCAT(HOST_NAME(), APP_NAME(), SUSER_NAME(), @@SPID, DB_NAME(), OBJECT_NAME(@@PROCID)) as JSON. Materialized in history. Shows Kubernetes pod names (e.g., "payments-recurring-manager-69c767889b-dgh8q"), confirming notifications are managed by the RecurringManagerService application. |
| 8 | SysStartTime | datetime2(7) | NO | - | VERIFIED | System-managed temporal column. Part of the clustered index. |
| 9 | SysEndTime | datetime2(7) | NO | - | VERIFIED | System-managed temporal column. Part of the clustered index. Sub-second gaps for Created->SentToService transitions show rapid notification processing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (table) | Recurring.Notification | Temporal History | This is the system-versioned history table for Recurring.Notification |
| PaymentExecutionId | Recurring.PaymentExecution / History.PaymentExecution | Implicit FK | The execution that triggered this notification |
| NotificationStatusId | Dictionary.NotificationStatus | Implicit Lookup | Delivery status: 1=Created through 6=LateCancellation |

### 5.2 Referenced By (other objects point to this)

No objects reference this history table directly.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Recurring.Notification | Table | This is the temporal history table (SYSTEM_VERSIONING = ON) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_Notification | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

PAGE compression. The base table has a unique NC index (UQ_Notification_PaymentExecution_NotificationType on PaymentExecutionId, NotificationTypeId).

### 7.2 Constraints

None. The base table holds:
- PK_Recurring_Notification (PK on NotificationCorrelationId)
- DF_Recurring_Notification_Status (DEFAULT 1 for NotificationStatusId)
- DF_Recurring_Notification_CreateDate (DEFAULT getutcdate())

---

## 8. Sample Queries

### 8.1 View notification delivery history for an execution
```sql
SELECT NotificationCorrelationId, PaymentExecutionId,
       NotificationStatusId, SendDate,
       SysStartTime AS StateStart, SysEndTime AS StateEnd
FROM History.Notification WITH (NOLOCK)
WHERE PaymentExecutionId = 105287
ORDER BY SysStartTime ASC
```

### 8.2 Find failed notification deliveries
```sql
SELECT NotificationCorrelationId, PaymentExecutionId,
       CreateDate, SendDate,
       JSON_VALUE(Trace, '$.HostName') AS ProcessingPod
FROM History.Notification WITH (NOLOCK)
WHERE NotificationStatusId = 4  -- SentToServiceFailed
ORDER BY SysStartTime DESC
```

### 8.3 Measure notification processing speed
```sql
SELECT h.NotificationCorrelationId,
       h.PaymentExecutionId,
       ns.Name AS Status,
       DATEDIFF(MILLISECOND, h.SysStartTime, h.SysEndTime) AS DurationMs
FROM History.Notification h WITH (NOLOCK)
JOIN Dictionary.NotificationStatus ns WITH (NOLOCK) ON ns.NotificationStatusId = h.NotificationStatusId
WHERE h.NotificationStatusId = 1  -- Created state duration
ORDER BY DATEDIFF(MILLISECOND, h.SysStartTime, h.SysEndTime) DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.Notification | Type: Table | Source: RecurringManager/History/Tables/History.Notification.sql*
