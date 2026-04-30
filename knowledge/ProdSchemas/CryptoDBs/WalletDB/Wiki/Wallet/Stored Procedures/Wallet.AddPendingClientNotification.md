# Wallet.AddPendingClientNotification

> Creates a new client notification with an initial Pending status, queuing it for delivery to the customer via the notification pipeline.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | New rows in Wallet.ClientNotifications + Wallet.ClientNotificationsStatuses |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure creates a customer notification record and sets its initial status to Pending (StatusId=1). Notifications inform customers about wallet events such as received deposits, completed withdrawals, address changes, or compliance actions. The notification system is decoupled from transaction processing - this procedure queues the notification, and a separate pipeline (likely Wallet.GetPendingClientNotifications) picks it up for delivery.

Without this procedure, the system could not notify customers about important wallet events, degrading the user experience and potentially violating regulatory notification requirements.

The procedure performs two inserts atomically: first the notification record, then the initial status entry. It uses @@IDENTITY to link the status to the just-created notification.

---

## 2. Business Logic

### 2.1 Two-Phase Insert (Notification + Initial Status)

**What**: Creates both the notification and its first status entry in a single call.

**Columns/Parameters Involved**: `ClientNotifications`, `ClientNotificationsStatuses`

**Rules**:
- First inserts into ClientNotifications with the notification details
- Then inserts into ClientNotificationsStatuses with StatusId=1 (Pending) using @@IDENTITY to get the new NotificationId
- No explicit transaction wrapping - relies on implicit transaction behavior
- The IsClientNotificationExist procedure references this workflow to check for duplicate notifications

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NotificationType | tinyint | NO | - | CODE-BACKED | Type of notification being sent. Determines the notification template and delivery channel (e.g., deposit received, withdrawal completed, AML hold). |
| 2 | @CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Links this notification to the originating transaction or event for traceability. |
| 3 | @Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID of the notification recipient. |
| 4 | @CryptoId | int | YES | - | CODE-BACKED | Cryptocurrency related to the notification, if applicable. NULL for non-crypto-specific notifications. Maps to Wallet.CryptoTypes.CryptoID. |
| 5 | @ParametersJson | nvarchar(MAX) | YES | - | CODE-BACKED | JSON payload with notification-specific parameters (e.g., amount, address, transaction hash) used to populate the notification template. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Gcid | Customer | Implicit | Notification recipient |
| @CryptoId | Wallet.CryptoTypes | Implicit | Related cryptocurrency |
| INSERT target 1 | Wallet.ClientNotifications | Writer | Creates the notification record |
| INSERT target 2 | Wallet.ClientNotificationsStatuses | Writer | Creates the initial Pending status |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.IsClientNotificationExist | - | Related | Checks for existing notifications before this SP is called |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.AddPendingClientNotification (procedure)
  ├── Wallet.ClientNotifications (table)
  └── Wallet.ClientNotificationsStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ClientNotifications | Table | INSERT target |
| Wallet.ClientNotificationsStatuses | Table | INSERT target (initial status) |

### 6.2 Objects That Depend On This

No direct SQL dependents. Wallet.IsClientNotificationExist is used as a guard before calling this procedure.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Uses @@IDENTITY (not SCOPE_IDENTITY) to get the notification ID - this could be affected by triggers on ClientNotifications if any exist
- No explicit error handling or transaction wrapping

---

## 8. Sample Queries

### 8.1 View recent pending notifications
```sql
SELECT cn.Id, cn.Gcid, cn.NotificationType, cn.CryptoId, cn.CorrelationId, cn.Created
FROM Wallet.ClientNotifications cn WITH (NOLOCK)
JOIN Wallet.ClientNotificationsStatuses cns WITH (NOLOCK) ON cns.NotificationId = cn.Id
WHERE cns.StatusId = 1
ORDER BY cn.Id DESC
```

### 8.2 Find notifications for a customer
```sql
SELECT cn.Id, cn.NotificationType, cn.CryptoId, cn.ParametersJson, cn.Created
FROM Wallet.ClientNotifications cn WITH (NOLOCK)
WHERE cn.Gcid = 12345678
ORDER BY cn.Id DESC
```

### 8.3 Notification counts by type and status
```sql
SELECT cn.NotificationType, cns.StatusId, COUNT(*) AS Cnt
FROM Wallet.ClientNotifications cn WITH (NOLOCK)
CROSS APPLY (
    SELECT TOP 1 StatusId FROM Wallet.ClientNotificationsStatuses WITH (NOLOCK)
    WHERE NotificationId = cn.Id ORDER BY Id DESC
) cns
GROUP BY cn.NotificationType, cns.StatusId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.AddPendingClientNotification | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.AddPendingClientNotification.sql*
