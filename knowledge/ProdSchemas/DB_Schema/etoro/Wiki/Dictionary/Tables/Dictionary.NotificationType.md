# Dictionary.NotificationType

> Defines the delivery channels (email providers, push notification) used to send customer notifications.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | NotificationTypeID (int, PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

Dictionary.NotificationType classifies the delivery channels through which customer notifications are sent. Each type represents a distinct communication mechanism — from legacy email marketing platforms (SilverPop) to direct SMTP email to mobile push notifications.

Without this table, the notification engine could not route notifications to the correct delivery channel. When a notification trigger fires, the system must know whether to send an email via SilverPop, a direct SMTP email, or a mobile push notification.

---

## 2. Business Logic

### 2.1 Delivery Channel Options

**What**: Three notification delivery channels.

**Columns/Parameters Involved**: `NotificationTypeID`, `Name`

**Rules**:
- SilverPopEmail (1): Email sent via Acoustic (formerly SilverPop) marketing automation platform — supports rich templates and tracking
- SmtpEmail (2): Direct SMTP email — simpler, more immediate, used for transactional emails
- PushNotification (3): Mobile push notification via platform's push infrastructure (iOS APNs / Android FCM)

---

## 3. Data Overview

| NotificationTypeID | Name | Meaning |
|---|---|---|
| 1 | SilverPopEmail | Email delivered via the Acoustic/SilverPop marketing automation platform — used for template-rich notifications with open/click tracking |
| 2 | SmtpEmail | Direct SMTP transactional email — used for immediate, system-generated notifications that don't need marketing tracking |
| 3 | PushNotification | Mobile push notification sent to the customer's device via iOS/Android push services — for real-time alerts |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | NotificationTypeID | int | NO | - | CODE-BACKED | Unique identifier for the delivery channel: 1=SilverPopEmail, 2=SmtpEmail, 3=PushNotification. |
| 2 | Name | varchar(50) | YES | - | VERIFIED | Human-readable channel name. Used in notification configuration to select the delivery method. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Notification configuration | NotificationTypeID | Implicit | Notification rules reference delivery channel type |

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
| (unnamed PK) | CLUSTERED PK | NotificationTypeID | - | - | Active |

### 7.2 Constraints

None beyond PK.

---

## 8. Sample Queries

### 8.1 List all notification types
```sql
SELECT  NotificationTypeID,
        Name
FROM    [Dictionary].[NotificationType] WITH (NOLOCK)
ORDER BY NotificationTypeID;
```

### 8.2 Find email delivery channels
```sql
SELECT  *
FROM    [Dictionary].[NotificationType] WITH (NOLOCK)
WHERE   Name LIKE '%Email%';
```

### 8.3 All channels with technology description
```sql
SELECT  NotificationTypeID,
        Name,
        CASE NotificationTypeID
            WHEN 1 THEN 'Acoustic/SilverPop marketing automation'
            WHEN 2 THEN 'Direct SMTP transactional'
            WHEN 3 THEN 'iOS APNs / Android FCM'
        END AS Technology
FROM    [Dictionary].[NotificationType] WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.NotificationType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.NotificationType.sql*
