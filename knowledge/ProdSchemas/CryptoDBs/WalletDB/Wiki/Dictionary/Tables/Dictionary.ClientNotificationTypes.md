# Dictionary.ClientNotificationTypes

> Lookup table defining the types of client-facing notifications triggered by wallet transaction events.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (int, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table classifies the types of notifications sent to clients (external systems or customer-facing applications) when significant wallet events occur. Each notification type corresponds to a different transaction event that triggers outbound communication.

Client notifications are the mechanism by which the wallet system informs downstream systems (mobile app, web platform, email service) about transaction lifecycle events. Without this classification, the system could not route notifications to the correct handler or display the appropriate message to the customer.

The values are consumed by `Wallet.ClientNotifications` table records and related notification processing procedures.

---

## 2. Business Logic

### 2.1 Transaction Event Notifications

**What**: Each type maps to a specific transaction lifecycle event that warrants customer notification.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `SentTransaction` (1): Notification triggered when a cryptocurrency send transaction reaches a reportable state (confirmed, failed, etc.)
- `ReceivedTransaction` (2): Notification triggered when an incoming cryptocurrency deposit is detected and confirmed on the blockchain
- `PendingPayment` (3): Notification triggered when a fiat payment is in a pending state requiring customer awareness

**Diagram**:
```
Wallet Event --> Notification Router
    |
    +---> SentTransaction (1)      [Outgoing crypto transfer update]
    +---> ReceivedTransaction (2)  [Incoming crypto deposit detected]
    +---> PendingPayment (3)       [Fiat payment awaiting completion]
```

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 1 | SentTransaction | Notification for outgoing cryptocurrency transactions. Triggered when a send operation changes state - e.g., broadcast to blockchain, confirmed on-chain, or failed. Enables the customer to track their withdrawal progress. |
| 2 | ReceivedTransaction | Notification for incoming cryptocurrency deposits. Triggered when the system detects and confirms a deposit on the blockchain. Informs the customer that funds have arrived in their wallet. |
| 3 | PendingPayment | Notification for fiat payment operations in a pending state. Alerts the customer or downstream systems that a payment is being processed and not yet finalized. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | Unique identifier for the notification type. Values: 1=SentTransaction, 2=ReceivedTransaction, 3=PendingPayment. Referenced by Wallet.ClientNotifications records. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Human-readable label for the notification type. Used in notification routing logic and audit logs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No direct FK references found. Consumed implicitly by `Wallet.ClientNotifications` and notification processing logic.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No direct dependents found in the Wallet schema SSDT.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ClientNotificationTypes_Id | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all notification types
```sql
SELECT Id, Name FROM Dictionary.ClientNotificationTypes WITH (NOLOCK) ORDER BY Id
```

### 8.2 Count notifications by type
```sql
SELECT cnt.Name, COUNT(cn.Id) AS NotificationCount
FROM Dictionary.ClientNotificationTypes cnt WITH (NOLOCK)
LEFT JOIN Wallet.ClientNotifications cn WITH (NOLOCK) ON cn.NotificationTypeId = cnt.Id
GROUP BY cnt.Name ORDER BY NotificationCount DESC
```

### 8.3 Recent notifications with type names
```sql
SELECT cn.Id, cnt.Name AS NotificationType, cn.Created
FROM Wallet.ClientNotifications cn WITH (NOLOCK)
JOIN Dictionary.ClientNotificationTypes cnt WITH (NOLOCK) ON cn.NotificationTypeId = cnt.Id
ORDER BY cn.Created DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 3.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ClientNotificationTypes | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.ClientNotificationTypes.sql*
