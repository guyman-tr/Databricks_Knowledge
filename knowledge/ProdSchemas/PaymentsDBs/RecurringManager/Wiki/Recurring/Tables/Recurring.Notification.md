# Recurring.Notification

> Tracks scheduled customer notifications linked to payment execution events, managing the lifecycle from creation through service delivery or cancellation.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Table |
| **Key Identifier** | NotificationCorrelationId (UNIQUEIDENTIFIER) |
| **Partition** | No |
| **Indexes** | 1 clustered PK + 1 unique nonclustered |

---

## 1. Business Meaning

Recurring.Notification stores scheduled notifications to customers about their recurring payment executions. Each row represents a notification that needs to be sent (e.g., "your recurring deposit of $100 will be charged on April 17") linked to a specific payment execution. The notification is created ahead of time with a scheduled SendDate and progresses through delivery states.

This table ensures customers are properly informed about upcoming or completed recurring charges, fulfilling regulatory and UX requirements. The unique index on (PaymentExecutionId, NotificationTypeId) ensures each execution generates at most one notification per type, preventing duplicate alerts.

Notifications are created by application code (no Recurring-schema stored procedures write to this table directly). The table tracks delivery status through Dictionary.NotificationStatus and is system-versioned with History.Notification for full audit trail.

---

## 2. Business Logic

### 2.1 Notification Delivery Lifecycle

**What**: Each notification progresses through states from creation to delivery or cancellation.

**Columns/Parameters Involved**: `NotificationStatusId`, `SendDate`, `CreateDate`

**Rules**:
- NotificationStatusId values from Dictionary.NotificationStatus:
  - 1=Created (default on insert, 0% in current data - transient)
  - 2=InProgress (transient processing state)
  - 3=SentToService (93%) - successfully handed off to notification service
  - 4=SentToServiceFailed - delivery to notification service failed
  - 5=Canceled (5%) - notification was cancelled before sending
  - 6=LateCancellation (2%) - cancelled after initially being queued
- SendDate is a FUTURE date relative to CreateDate, indicating when the notification should be delivered to the customer
- One notification per execution per type (enforced by unique index)

---

## 3. Data Overview

| NotificationCorrelationId | PaymentExecutionId | NotificationTypeId | NotificationStatusId | SendDate | Meaning |
|---|---|---|---|---|---|
| 36E65E6D-... | 859513 | 1 | 3 (SentToService) | 2026-04-17 | Pre-charge notification for execution 859513, scheduled for tomorrow. Successfully delivered to notification service. |
| 64EACABB-... | 859481 | 1 | 3 (SentToService) | 2026-04-19 | Pre-charge notification scheduled 4 days ahead. Longer lead time suggests weekend scheduling adjustment. |
| (example) | - | 1 | 5 (Canceled) | - | Cancelled notification - the payment execution was cancelled before the notification send date arrived. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | NotificationCorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Primary key (GUID). Used as a correlation ID to track this notification across the notification service pipeline. Not auto-generated - set by application code on insert. |
| 2 | PaymentExecutionId | int | NO | - | VERIFIED | FK to Recurring.PaymentExecution.PaymentExecutionId. Links this notification to the specific execution cycle it relates to. Part of unique index with NotificationTypeId. |
| 3 | NotificationTypeId | int | NO | - | CODE-BACKED | Type of notification. Currently only value 1 is used (100% of 48,688 rows). No Dictionary table found in this database - type definitions are managed externally. Likely represents a pre-charge reminder. |
| 4 | NotificationStatusId | int | NO | 1 (Created) | VERIFIED | Delivery lifecycle status. FK to Dictionary.NotificationStatus: 1=Created, 2=InProgress, 3=SentToService (93%), 4=SentToServiceFailed, 5=Canceled (5%), 6=LateCancellation (2%). Defaults to 1 on insert. |
| 5 | CreateDate | datetime | NO | - | CODE-BACKED | UTC timestamp when the notification record was created. Set by application code on insert. |
| 6 | SendDate | datetime | NO | - | CODE-BACKED | Scheduled delivery date for the notification. Typically 1-4 days after CreateDate. Represents when the customer should receive the alert (e.g., day before the charge). |
| 7 | Trace | (computed) | - | - | CODE-BACKED | Computed column generating a JSON string with connection metadata: HostName, AppName, SUserName, SPID, DBName, ObjectName. Formula: `CONCAT('{"HostName": "',host_name(),'","AppName": "',app_name(),...}')`. Used for auditing which process/connection created or last read the row. |
| 8 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | System-versioning row start time (HIDDEN). |
| 9 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | System-versioning row end time (HIDDEN). History stored in History.Notification. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PaymentExecutionId | Recurring.PaymentExecution | Implicit FK | The execution cycle this notification is about |
| NotificationStatusId | Dictionary.NotificationStatus | Implicit FK (Lookup) | Notification delivery status |
| - | History.Notification | System Versioning | Full audit trail |

### 5.2 Referenced By (other objects point to this)

No stored procedures or other database objects reference this table directly. Managed by application code.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (leaf table).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No database-level dependents found. Consumed by application code.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Recurring_Notification | CLUSTERED | NotificationCorrelationId ASC | - | - | Active |
| UQ_Notification_PaymentExecution_NotificationType | UNIQUE NONCLUSTERED | PaymentExecutionId ASC, NotificationTypeId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Recurring_Notification | PRIMARY KEY | Clustered on NotificationCorrelationId |
| DF_Recurring_Notification_Status | DEFAULT | 1 for NotificationStatusId (Created) |
| DF_Recurring_Notification_CreateDate | DEFAULT | getutcdate() for CreateDate |
| UQ unique index | UNIQUE | One notification per (PaymentExecutionId, NotificationTypeId) |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.Notification |

---

## 8. Sample Queries

### 8.1 Get pending notifications scheduled for today
```sql
SELECT n.NotificationCorrelationId, n.PaymentExecutionId,
       ns.Name AS Status, n.SendDate
FROM Recurring.Notification n WITH (NOLOCK)
INNER JOIN Dictionary.NotificationStatus ns WITH (NOLOCK) ON n.NotificationStatusId = ns.NotificationStatusId
WHERE n.NotificationStatusId IN (1, 2)
  AND CAST(n.SendDate AS DATE) = CAST(GETUTCDATE() AS DATE)
```

### 8.2 Find notifications for a specific payment execution
```sql
SELECT n.NotificationCorrelationId, n.NotificationTypeId,
       ns.Name AS Status, n.CreateDate, n.SendDate
FROM Recurring.Notification n WITH (NOLOCK)
INNER JOIN Dictionary.NotificationStatus ns WITH (NOLOCK) ON n.NotificationStatusId = ns.NotificationStatusId
WHERE n.PaymentExecutionId = @PaymentExecutionId
```

### 8.3 Notification delivery summary
```sql
SELECT ns.Name AS NotificationStatus, COUNT(*) AS NotificationCount
FROM Recurring.Notification n WITH (NOLOCK)
INNER JOIN Dictionary.NotificationStatus ns WITH (NOLOCK) ON n.NotificationStatusId = ns.NotificationStatusId
GROUP BY ns.Name
ORDER BY NotificationCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.Notification | Type: Table | Source: RecurringManager/Recurring/Tables/Recurring.Notification.sql*
