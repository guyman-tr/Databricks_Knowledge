# Wallet.InsertWebHookNotification

> Records a blockchain provider webhook notification containing transaction hash, transfer type, coin, state, and wallet details for audit and deduplication.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into Wallet.WebHookNotifications |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure records incoming webhook notifications from blockchain providers (e.g., BitGo). When the provider notifies eToro about a transaction event (new transfer, status change, confirmation), the notification payload is persisted here. The back-office API and conversion service call this. The stored notifications enable deduplication (via IsExistsWebHookNotification) and audit trailing.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Direct INSERT with all parameters.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Hash | nvarchar(100) | NO | - | CODE-BACKED | Blockchain transaction hash from the webhook payload. |
| 2 | @Transfer | nvarchar(64) | NO | - | CODE-BACKED | Transfer identifier from the provider. |
| 3 | @Coin | nvarchar(32) | NO | - | CODE-BACKED | Coin/crypto symbol (e.g., 'btc', 'eth'). |
| 4 | @State | nvarchar(32) | NO | - | CODE-BACKED | Transaction state from the provider (e.g., 'confirmed', 'signed'). |
| 5 | @Wallet | nvarchar(64) | NO | - | CODE-BACKED | Provider wallet identifier that the transaction relates to. |
| 6 | @CorrelationId | uniqueidentifier | YES | NULL | CODE-BACKED | Optional business correlation ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.WebHookNotifications | INSERT | Webhook audit record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackApiUser | - | EXECUTE | Webhook recording |
| ConversionUser | - | EXECUTE | Conversion webhook recording |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.InsertWebHookNotification (procedure)
+-- Wallet.WebHookNotifications (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WebHookNotifications | Table | INSERT target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackApiUser, ConversionUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Record a webhook
```sql
EXEC Wallet.InsertWebHookNotification @Hash='0xabc...', @Transfer='transfer-123', @Coin='btc', @State='confirmed', @Wallet='wallet-456';
```

### 8.2 Check if webhook already received
```sql
EXEC Wallet.IsExistsWebHookNotification @Hash='0xabc...', @Wallet='wallet-456';
```

### 8.3 Recent webhooks
```sql
SELECT TOP 10 * FROM Wallet.WebHookNotifications WITH (NOLOCK) ORDER BY Id DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.InsertWebHookNotification | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.InsertWebHookNotification.sql*
