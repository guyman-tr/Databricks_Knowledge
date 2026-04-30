# Wallet.IsClientNotificationExist

> Checks if a client notification exists by optional CorrelationId and/or NotificationType, returning 1 if found, used by the billing notification service for deduplication before creating new notifications.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 1 if matching ClientNotifications row exists |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure checks if a client notification already exists, supporting flexible matching by CorrelationId, NotificationType, or both. The billing notification service calls this before creating new notifications to prevent duplicates. Both parameters are optional - when NULL, that condition is skipped (matches all).

---

## 2. Business Logic

### 2.1 Flexible Match with Optional Parameters

**What**: Both parameters are optional, allowing different match strategies.

**Rules**:
- @CorrelationId IS NULL -> skips CorrelationId condition
- @NotificationType IS NULL -> skips NotificationType condition
- Both NULL -> matches ANY notification (returns 1 if any exist)
- Both provided -> exact match on both fields

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NotificationType | tinyint | YES | NULL | VERIFIED | Optional notification type filter. FK to Dictionary.NotificationTypes. |
| 2 | @CorrelationId | uniqueidentifier | YES | NULL | VERIFIED | Optional business correlation ID filter. |
| 3 | (result) | int | YES | - | CODE-BACKED | SELECT 1 if matching notification found, empty result set if not. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.ClientNotifications | SELECT | Existence check |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BillingNotificationUser | - | EXECUTE | Notification deduplication |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.IsClientNotificationExist (procedure)
+-- Wallet.ClientNotifications (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ClientNotifications | Table | Existence check |

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

### 8.1 Check by correlation ID
```sql
EXEC Wallet.IsClientNotificationExist @CorrelationId = 'YOUR-GUID', @NotificationType = NULL;
```

### 8.2 Check by both fields
```sql
EXEC Wallet.IsClientNotificationExist @CorrelationId = 'YOUR-GUID', @NotificationType = 1;
```

### 8.3 Direct equivalent
```sql
SELECT 1 FROM Wallet.ClientNotifications WITH (NOLOCK) WHERE CorrelationId = 'YOUR-GUID';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.IsClientNotificationExist | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.IsClientNotificationExist.sql*
