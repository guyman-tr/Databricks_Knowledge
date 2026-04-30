# Wallet.ClientNotificationsStatuses

> Event-sourced status history for client notifications, tracking whether notifications were successfully delivered, failed, or acknowledged by the customer's device.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CI on Id) |
| **Partition** | No |
| **Indexes** | 1 active NC + 1 clustered index (not PK) |

---

## 1. Business Meaning

This table tracks the delivery status of client notifications from `Wallet.ClientNotifications`. Each row represents a delivery status event for a specific notification. The `StatusId` tracks whether the notification was queued, sent, delivered, or failed. No explicit FK to ClientNotifications (implicit via NotificationId).

---

## 2. Business Logic

No complex logic. Status event log for notification delivery tracking.

---

## 3. Data Overview

N/A for status event table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing event identifier. |
| 2 | Occurred | datetime2(7) | YES | getutcdate() | CODE-BACKED | Timestamp of this status event. |
| 3 | NotificationId | bigint | NO | - | CODE-BACKED | Parent notification from Wallet.ClientNotifications. Implicit FK (no constraint). |
| 4 | StatusId | tinyint | NO | - | CODE-BACKED | Delivery status code. |
| 5 | DetailsJson | nvarchar(max) | YES | - | CODE-BACKED | JSON with delivery details (error messages, provider responses). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| NotificationId | Wallet.ClientNotifications | Implicit | Parent notification |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.InsertClientNotificationStatus | - | Writer | Appends status events |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.ClientNotificationsStatuses (table)
└── Wallet.ClientNotifications (table, implicit)
```

### 6.1 Objects This Depends On

No FK dependencies (implicit only).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.InsertClientNotificationStatus | Stored Procedure | Inserts status events |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_ClientNotificationsStatuses | CLUSTERED | Id ASC | - | - | Active |
| IX_ClientNotificationsStatuses_NotificationId | NC | NotificationId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_...Occurred | DEFAULT | getutcdate() |

---

## 8. Sample Queries

### 8.1 Status history for a notification
```sql
SELECT Id, StatusId, Occurred, DetailsJson FROM Wallet.ClientNotificationsStatuses WITH (NOLOCK) WHERE NotificationId = 12345 ORDER BY Id
```

### 8.2 Recent failed notifications
```sql
SELECT TOP 20 NotificationId, StatusId, Occurred FROM Wallet.ClientNotificationsStatuses WITH (NOLOCK) WHERE StatusId = 3 ORDER BY Occurred DESC
```

### 8.3 Status distribution
```sql
SELECT StatusId, COUNT(*) AS Cnt FROM Wallet.ClientNotificationsStatuses WITH (NOLOCK) GROUP BY StatusId ORDER BY Cnt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.ClientNotificationsStatuses | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.ClientNotificationsStatuses.sql*
