# Wallet.WebHookNotifications

> Records webhook notifications received from blockchain providers (BitGo/CUG) about transaction state changes, providing a raw event log of provider-side transaction updates.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active NC UNIQUE + 1 clustered PK |

---

## 1. Business Meaning

This table stores incoming webhook notifications from blockchain custody providers. When a transaction state changes (e.g., confirmed on blockchain), the provider sends a webhook to eToro. Each notification is recorded here with the transaction hash, transfer ID, coin type, state, and wallet. With ~3.8M rows, it is a high-volume event log of provider-side activity.

The unique index on (Hash, Wallet) prevents processing duplicate webhook deliveries. The CorrelationId links the notification to the internal request for correlation.

---

## 2. Business Logic

No complex logic. Raw webhook event log with deduplication.

---

## 3. Data Overview

N/A for high-volume webhook event table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key. |
| 2 | Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | When the webhook was received and recorded. |
| 3 | Hash | nvarchar(100) | YES | - | CODE-BACKED | Blockchain transaction hash from the webhook payload. Part of unique dedup key. |
| 4 | Transfer | nvarchar(64) | YES | - | CODE-BACKED | Provider's transfer/transaction identifier. |
| 5 | Coin | nvarchar(32) | YES | - | CODE-BACKED | Cryptocurrency ticker from the webhook (e.g., "btc", "eth"). |
| 6 | State | nvarchar(32) | YES | - | CODE-BACKED | Transaction state from the provider (e.g., "confirmed", "signed", "unconfirmed"). |
| 7 | Wallet | nvarchar(64) | YES | - | CODE-BACKED | Provider's wallet identifier that the notification is for. Part of unique dedup key. |
| 8 | CorrelationId | uniqueidentifier | YES | - | CODE-BACKED | Links to the internal request for end-to-end tracing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing FK references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.InsertWebHookNotification | - | Writer | Records incoming webhooks |
| Wallet.IsExistsWebHookNotification | - | Reader | Checks for duplicate webhooks |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.InsertWebHookNotification | Stored Procedure | Inserts webhook records |
| Wallet.IsExistsWebHookNotification | Stored Procedure | Checks for duplicates |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_WebHookNotifications_Id | CLUSTERED PK | Id ASC | - | - | Active |
| ix_WebHookNotifications_Hash | NC UNIQUE | Hash, Wallet | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_WebHookNotifications_Created | DEFAULT | getutcdate() |

---

## 8. Sample Queries

### 8.1 Recent webhook notifications
```sql
SELECT TOP 20 Id, Hash, Coin, State, Wallet, Created
FROM Wallet.WebHookNotifications WITH (NOLOCK)
ORDER BY Id DESC
```

### 8.2 Check if a webhook was already received
```sql
SELECT 1 FROM Wallet.WebHookNotifications WITH (NOLOCK)
WHERE Hash = '0xabc...' AND Wallet = 'wallet123'
```

### 8.3 Webhook volume by coin and state
```sql
SELECT Coin, State, COUNT(*) AS Cnt
FROM Wallet.WebHookNotifications WITH (NOLOCK)
WHERE Created > DATEADD(DAY, -7, GETUTCDATE())
GROUP BY Coin, State ORDER BY Cnt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.WebHookNotifications | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.WebHookNotifications.sql*
