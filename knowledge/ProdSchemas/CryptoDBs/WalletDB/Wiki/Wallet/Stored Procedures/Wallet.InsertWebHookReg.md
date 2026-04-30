# Wallet.InsertWebHookReg

> Registers a webhook listener for a wallet, specifying the callback URL and number of blockchain confirmations required before notification, returning the generated registration ID.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into Wallet.WebHookReg, returns SCOPE_IDENTITY |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure registers a webhook endpoint for a specific wallet. When a blockchain transaction affecting this wallet reaches the specified number of confirmations, the platform sends a notification to the registered URL. The back-office API and executer service use this to set up webhook listeners during wallet creation or configuration.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Direct INSERT with SCOPE_IDENTITY return.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletId | uniqueidentifier | NO | - | VERIFIED | Wallet to register the webhook for. |
| 2 | @Created | datetime2(7) | NO | - | CODE-BACKED | Registration timestamp. |
| 3 | @Url | nvarchar(100) | NO | - | CODE-BACKED | Callback URL for webhook notifications. |
| 4 | @NumberOfConfirmation | int | NO | - | CODE-BACKED | Number of blockchain confirmations before triggering the webhook. |
| 5 | Identity (output) | bigint | NO | - | CODE-BACKED | Generated registration ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.WebHookReg | INSERT | Webhook registration |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackApiUser | - | EXECUTE | Webhook configuration |
| ExecuterUser | - | EXECUTE | Automated webhook setup |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.InsertWebHookReg (procedure)
+-- Wallet.WebHookReg (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WebHookReg | Table | INSERT target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackApiUser, ExecuterUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Register a webhook
```sql
EXEC Wallet.InsertWebHookReg @WalletId='WALLET-GUID', @Created=GETUTCDATE(), @Url='https://api.example.com/webhook', @NumberOfConfirmation=6;
```

### 8.2 Check registrations for a wallet
```sql
SELECT * FROM Wallet.WebHookReg WITH (NOLOCK) WHERE WalletId = 'WALLET-GUID';
```

### 8.3 Check if webhook exists
```sql
EXEC Wallet.IsWebHookRegExist @WalletId = 'WALLET-GUID';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.InsertWebHookReg | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.InsertWebHookReg.sql*
