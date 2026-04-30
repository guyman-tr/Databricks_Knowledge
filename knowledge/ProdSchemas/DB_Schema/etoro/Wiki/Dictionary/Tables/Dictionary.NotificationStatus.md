# Dictionary.NotificationStatus

> Defines the delivery lifecycle states for platform notifications, tracking each notification from creation through processing to delivery or failure.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | NotificationStatusID (int, PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

Dictionary.NotificationStatus defines the lifecycle states for customer-facing notifications (push notifications, emails, SMS). Unlike NotificationMessageStatus which tracks individual messages, this table tracks the higher-level notification entity that may produce one or more messages across delivery channels.

Without this table, the notification engine could not report on notification delivery progress or detect notifications stuck in intermediate states.

---

## 2. Business Logic

### 2.1 Notification Delivery States

**What**: Four-state lifecycle for customer notifications.

**Columns/Parameters Involved**: `NotificationStatusID`, `Name`

**Rules**:
- Pending (1): Notification created but not yet picked up by the processing engine
- Processing (2): Notification is being formatted and routed to delivery channels
- Sent (3): Notification successfully delivered to all target channels
- Failed (4): Notification delivery failed across all channels after retry exhaustion

---

## 3. Data Overview

| NotificationStatusID | Name | Meaning |
|---|---|---|
| 1 | Pending | Notification has been created and is waiting in queue for the notification engine to process it |
| 2 | Processing | Notification engine has picked up the notification and is formatting content, resolving recipients, and routing to delivery channels |
| 3 | Sent | Notification has been successfully delivered to the customer via all configured channels (push/email/SMS) |
| 4 | Failed | All delivery attempts failed — notification was not received by the customer and may need manual investigation |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | NotificationStatusID | int | NO | - | CODE-BACKED | Unique identifier for the notification state: 1=Pending, 2=Processing, 3=Sent, 4=Failed. |
| 2 | Name | varchar(50) | YES | - | CODE-BACKED | Human-readable state label. Nullable (unusual for lookup). Displayed in notification monitoring dashboards. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Notification tables | NotificationStatusID | Implicit | Notification records track delivery state |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in SSDT codebase beyond the DDL itself.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (unnamed PK) | CLUSTERED PK | NotificationStatusID | - | - | Active |

### 7.2 Constraints

None beyond PK.

---

## 8. Sample Queries

### 8.1 List all notification statuses
```sql
SELECT  NotificationStatusID,
        Name
FROM    [Dictionary].[NotificationStatus] WITH (NOLOCK)
ORDER BY NotificationStatusID;
```

### 8.2 Find the failed status ID
```sql
SELECT  NotificationStatusID
FROM    [Dictionary].[NotificationStatus] WITH (NOLOCK)
WHERE   Name = 'Failed';
```

### 8.3 All statuses with ordering
```sql
SELECT  NotificationStatusID,
        Name,
        ROW_NUMBER() OVER (ORDER BY NotificationStatusID) AS PipelineOrder
FROM    [Dictionary].[NotificationStatus] WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.NotificationStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.NotificationStatus.sql*
