# Wallet.IsExistsWebHookNotification

> Checks if a webhook notification with a specific blockchain hash and wallet combination has already been recorded, returning 1 if it exists, used by the back-office API and conversion service for webhook deduplication.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 1 if matching WebHookNotifications row exists |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure checks if a webhook notification for a specific blockchain transaction hash and wallet has already been processed. The back-office API and conversion service call this before processing incoming webhooks to prevent duplicate handling. Combined with InsertWebHookNotification, these two SPs form an idempotent webhook processing pattern: check -> process -> record.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple EXISTS check on WebHookNotifications WHERE Hash + Wallet match.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Hash | nvarchar(100) | NO | - | CODE-BACKED | Blockchain transaction hash to check. |
| 2 | @Wallet | nvarchar(64) | NO | - | CODE-BACKED | Provider wallet identifier to check. |
| 3 | Result (output) | int | YES | - | CODE-BACKED | 1 if notification already exists. No result set if not. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Hash + @Wallet | Wallet.WebHookNotifications | EXISTS check | Deduplication lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackApiUser | - | EXECUTE | Webhook deduplication |
| ConversionUser | - | EXECUTE | Webhook deduplication |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.IsExistsWebHookNotification (procedure)
+-- Wallet.WebHookNotifications (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WebHookNotifications | Table | EXISTS check |

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

### 8.1 Check if webhook was already received
```sql
EXEC Wallet.IsExistsWebHookNotification @Hash = '0xabc...', @Wallet = 'wallet-456';
```

### 8.2 Idempotent webhook pattern
```sql
-- Step 1: Check
EXEC Wallet.IsExistsWebHookNotification @Hash='0xabc...', @Wallet='wallet-456';
-- Step 2: If no result, process the webhook
-- Step 3: Record
EXEC Wallet.InsertWebHookNotification @Hash='0xabc...', @Transfer='transfer-123', @Coin='btc', @State='confirmed', @Wallet='wallet-456';
```

### 8.3 Direct equivalent
```sql
IF EXISTS (SELECT TOP 1 [Hash] FROM Wallet.WebHookNotifications WHERE [Hash] = '0xabc...' AND [Wallet] = 'wallet-456') SELECT 1 AS Result;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.IsExistsWebHookNotification | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.IsExistsWebHookNotification.sql*
