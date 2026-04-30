# Dictionary.NotificationStatus

> Lookup table tracking the lifecycle of notifications sent to external services about recurring payment events, with six states from creation through delivery or cancellation.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | NotificationStatusId (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.NotificationStatus tracks the lifecycle of notifications sent to external services (push notifications, emails, webhook callbacks) about recurring payment events. It is more granular than MessageStatus (3 states), providing six states that distinguish between initial creation, active processing, successful delivery, delivery failure, and two types of cancellation.

This table is used by both the Recurring.Notification table (active notifications) and the History.Notification table (archived notifications). The default value for new notification records is 1 (Created), as defined by the DF_Recurring_Notification_Status constraint on Recurring.Notification.

The distinction between Canceled (5) and LateCancellation (6) is important for audit and reconciliation: Canceled means the notification was stopped before any delivery processing began, while LateCancellation means processing had already started and the notification may have been partially delivered.

---

## 2. Business Logic

### 2.1 Six-State Notification Lifecycle with Cancellation Granularity

**What**: Notifications progress through creation, processing, and delivery states, with special handling for cancellations at different stages.

**Columns/Parameters Involved**: `NotificationStatusId`, `Name`

**Rules**:
- Created (1) is the default initial state (DB constraint DF_Recurring_Notification_Status)
- InProgress (2) means the notification is being prepared for delivery
- SentToService (3) means successful handoff to the external notification service
- SentToServiceFailed (4) means the handoff to the external service failed
- Canceled (5) means the notification was canceled before processing started
- LateCancellation (6) means cancellation occurred after processing began - may have partially been delivered

**Diagram**:
```
Created (1) --> InProgress (2) --> SentToService (3)
    |               |                    
    |               +---> SentToServiceFailed (4)
    |               |
    +-> Canceled (5) +---> LateCancellation (6)
```

---

## 3. Data Overview

| NotificationStatusId | Name | Meaning |
|---|---|---|
| 1 | Created | Notification record created. Default state per DB constraint DF_Recurring_Notification_Status. Processing has not started. |
| 2 | InProgress | Notification is being prepared or actively processed for delivery to the external service. |
| 3 | SentToService | Notification successfully handed off to the external notification service. Terminal success state. |
| 4 | SentToServiceFailed | Delivery attempt to the external service failed. Terminal failure state requiring investigation. |
| 5 | Canceled | Notification canceled before processing started (e.g., triggering event was reversed). Clean cancellation. |
| 6 | LateCancellation | Notification canceled after processing had already begun. May have been partially delivered. Important for reconciliation. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | NotificationStatusId | int | NO | - | VERIFIED | Primary key identifying the notification lifecycle state. 1=Created (default), 2=InProgress, 3=SentToService, 4=SentToServiceFailed, 5=Canceled, 6=LateCancellation. See [Notification Status](../../_glossary.md#notification-status) for full definitions. (Dictionary.NotificationStatus) |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable label for the notification status. Values: "Created", "InProgress", "SentToService", "SentToServiceFailed", "Canceled", "LateCancellation". Note: "Canceled" and "LateCancellation" have trailing spaces in live data. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Recurring.Notification | NotificationStatusId | Implicit FK | Tracks current lifecycle state of active notifications. Default constraint DF_Recurring_Notification_Status sets initial value to 1 (Created). |
| History.Notification | NotificationStatusId | Implicit FK | Archived notifications retain their final status for audit. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Recurring.Notification | Table | NotificationStatusId column with DEFAULT ((1)) constraint |
| History.Notification | Table | NotificationStatusId column for audit records |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| pk | CLUSTERED PK | NotificationStatusId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| pk | PRIMARY KEY | Ensures each notification status has a unique integer identifier. Note: PK constraint name is simply "pk" (non-standard naming). |

---

## 8. Sample Queries

### 8.1 List all notification statuses
```sql
SELECT NotificationStatusId, Name
FROM Dictionary.NotificationStatus WITH (NOLOCK)
ORDER BY NotificationStatusId
```

### 8.2 Find notifications stuck in non-terminal states
```sql
SELECT n.*, ns.Name AS NotificationStatus
FROM Recurring.Notification n WITH (NOLOCK)
INNER JOIN Dictionary.NotificationStatus ns WITH (NOLOCK) ON n.NotificationStatusId = ns.NotificationStatusId
WHERE n.NotificationStatusId IN (1, 2) -- Created or InProgress
ORDER BY n.NotificationStatusId
```

### 8.3 Notification delivery success rate
```sql
SELECT ns.Name AS NotificationStatus, COUNT(*) AS NotificationCount
FROM Recurring.Notification n WITH (NOLOCK)
INNER JOIN Dictionary.NotificationStatus ns WITH (NOLOCK) ON n.NotificationStatusId = ns.NotificationStatusId
GROUP BY ns.Name
ORDER BY NotificationCount DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Manager](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1922891833) | Confluence | Architecture: Notifications are sent via Azure Service Bus to external services |

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.NotificationStatus | Type: Table | Source: RecurringManager/Dictionary/Tables/Dictionary.NotificationStatus.sql*
