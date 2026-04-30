# Wallet.InsertClientNotificationStatus

> Appends a status event to a client notification record, tracking the notification lifecycle (sent, delivered, failed) for the billing notification service.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into Wallet.ClientNotificationsStatuses |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure records a status change for a client notification. When the wallet platform sends notifications to customers (e.g., transaction confirmed, balance updated), each notification's delivery status is tracked as an event-sourced record in ClientNotificationsStatuses. The billing notification service appends status events as the notification progresses through sent, delivered, or failed states.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Direct INSERT with NotificationId, StatusId, and optional DetailsJson.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NotificationId | bigint | NO | - | VERIFIED | Parent notification record. FK to Wallet.ClientNotifications.Id. |
| 2 | @StatusId | tinyint | NO | - | VERIFIED | Notification status. FK to Dictionary.ClientNotificationStatuses. |
| 3 | @DetailsJson | nvarchar(max) | YES | - | CODE-BACKED | Optional JSON details about this status event (e.g., delivery failure reason). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @NotificationId | Wallet.ClientNotificationsStatuses.NotificationId | INSERT | Status event for notification |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BillingNotificationUser | - | EXECUTE | Notification lifecycle tracking |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.InsertClientNotificationStatus (procedure)
+-- Wallet.ClientNotificationsStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ClientNotificationsStatuses | Table | INSERT target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BillingNotificationUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Record a notification status
```sql
EXEC Wallet.InsertClientNotificationStatus @NotificationId = 12345, @StatusId = 2, @DetailsJson = '{"channel":"email"}';
```

### 8.2 Check notification status history
```sql
SELECT * FROM Wallet.ClientNotificationsStatuses WITH (NOLOCK) WHERE NotificationId = 12345 ORDER BY Id;
```

### 8.3 Direct equivalent
```sql
INSERT INTO Wallet.ClientNotificationsStatuses (NotificationId, StatusId, DetailsJson) VALUES (12345, 2, '{"channel":"email"}');
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.InsertClientNotificationStatus | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.InsertClientNotificationStatus.sql*
