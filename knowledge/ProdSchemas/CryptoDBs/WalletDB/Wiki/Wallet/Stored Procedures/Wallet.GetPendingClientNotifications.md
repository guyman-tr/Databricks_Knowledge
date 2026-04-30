# Wallet.GetPendingClientNotifications

> Retrieves client notifications with the latest status of Pending (1), optionally filtered by notification type and/or correlation ID.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns pending notifications with their latest status details |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves client notifications that are waiting to be sent. Notifications inform customers about crypto events (received transactions, completed sends, status changes, etc.). The notification service polls this procedure to find unsent notifications, processes them (sends push/email/in-app), then updates their status.

The optional filters allow retrieving all pending notifications (no filters), a specific notification by correlation ID, or all pending notifications of a specific type. This flexibility supports both batch processing (send all pending) and targeted lookup (check status of a specific notification).

Data comes from `Wallet.ClientNotifications` with a CROSS APPLY to `Wallet.ClientNotificationsStatuses` to find the latest status per notification. Only notifications with StatusId=1 (Pending) are returned.

---

## 2. Business Logic

### 2.1 Pending Notification Detection

**What**: Finds notifications whose latest status is Pending.

**Columns/Parameters Involved**: `StatusId`, `NotificationType`, `CorrelationId`

**Rules**:
- CROSS APPLY with TOP 1 ORDER BY Occurred DESC gets the most recent status per notification
- StatusId=1 = Pending (notification has been created but not yet sent)
- Optional @NotificationType filter: when non-NULL, restricts to a specific notification type
- Optional @CorrelationId filter: when non-NULL, retrieves a specific notification
- Both filters use IS NULL pattern for optional matching

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NotificationType | TINYINT | YES | NULL | CODE-BACKED | Filter by notification type. When NULL, returns all types. Different types correspond to different crypto events (receive, send, status change, etc.). |
| 2 | @CorrelationId | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Filter by correlation ID. When NULL, returns all pending. When specified, targets a specific notification. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | Id | BIGINT | NO | - | CODE-BACKED | ClientNotifications record ID. Primary identifier for this notification. |
| 4 | Occurred | DATETIME2 | NO | - | CODE-BACKED | Timestamp when the notification was created. |
| 5 | NotificationType | TINYINT | NO | - | CODE-BACKED | Type of notification (e.g., receive confirmation, send status, etc.). |
| 6 | CorrelationId | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | Correlation ID linking notification to the triggering transaction/request. |
| 7 | Gcid | BIGINT | NO | - | CODE-BACKED | Global Customer ID. The customer to notify. |
| 8 | CryptoId | INT | YES | - | CODE-BACKED | Cryptocurrency related to the notification. FK to Wallet.CryptoTypes. |
| 9 | ParametersJson | NVARCHAR(MAX) | YES | - | CODE-BACKED | JSON payload with notification-specific parameters (amounts, addresses, etc.). Used by the notification service to render the message. |
| 10 | StatusOccured | DATETIME2 | NO | - | CODE-BACKED | Timestamp of the latest status event (the Pending status). |
| 11 | StatusId | TINYINT | NO | - | CODE-BACKED | Always 1 (Pending) due to the WHERE filter. |
| 12 | StatusDetailsJson | NVARCHAR(MAX) | YES | - | CODE-BACKED | JSON details from the latest status event. May contain error/retry info from previous attempts. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.ClientNotifications | FROM | Source of notification records |
| NotificationId | Wallet.ClientNotificationsStatuses | CROSS APPLY | Latest status per notification |

### 5.2 Referenced By (other objects point to this)

No direct SQL callers found. Called by the notification delivery service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetPendingClientNotifications (procedure)
+-- Wallet.ClientNotifications (table)
+-- Wallet.ClientNotificationsStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ClientNotifications | Table | FROM - notification records |
| Wallet.ClientNotificationsStatuses | Table | CROSS APPLY - latest status |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all pending notifications
```sql
EXEC Wallet.GetPendingClientNotifications @NotificationType = NULL, @CorrelationId = NULL;
```

### 8.2 Get pending notifications of a specific type
```sql
EXEC Wallet.GetPendingClientNotifications @NotificationType = 1, @CorrelationId = NULL;
```

### 8.3 Count pending notifications by type
```sql
SELECT cn.NotificationType, COUNT(*) AS PendingCount
FROM Wallet.ClientNotifications cn WITH (NOLOCK)
CROSS APPLY (SELECT TOP 1 StatusId FROM Wallet.ClientNotificationsStatuses cns WITH (NOLOCK)
             WHERE cns.NotificationId = cn.Id ORDER BY cns.Occurred DESC) cns
WHERE cns.StatusId = 1
GROUP BY cn.NotificationType;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetPendingClientNotifications | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetPendingClientNotifications.sql*
