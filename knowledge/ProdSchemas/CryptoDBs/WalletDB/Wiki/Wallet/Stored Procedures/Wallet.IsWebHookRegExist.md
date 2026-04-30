# Wallet.IsWebHookRegExist

> Checks if a webhook registration exists for a specific wallet, returning 1 if found, used by back-office API and executer to avoid duplicate webhook registrations.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 1 if WebHookReg exists for WalletId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure checks if a webhook registration already exists for a wallet. The back-office API and executer service call this before calling InsertWebHookReg to prevent duplicate webhook registrations. Returns SELECT 1 if found, or no result set if not.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple EXISTS check on WebHookReg WHERE WalletId.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletId | uniqueidentifier | NO | - | VERIFIED | Wallet to check for existing webhook registration. |
| 2 | Result (output) | int | YES | - | CODE-BACKED | 1 if registration exists. No result set if not. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WalletId | Wallet.WebHookReg.WalletId | EXISTS check | Registration lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackApiUser, ExecuterUser | - | EXECUTE | Webhook deduplication |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.IsWebHookRegExist (procedure)
+-- Wallet.WebHookReg (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WebHookReg | Table | EXISTS check |

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

### 8.1 Check if webhook exists
```sql
EXEC Wallet.IsWebHookRegExist @WalletId = 'WALLET-GUID';
```

### 8.2 Idempotent webhook registration pattern
```sql
-- Step 1: Check if exists
EXEC Wallet.IsWebHookRegExist @WalletId = 'WALLET-GUID';
-- Step 2: If no result, register
EXEC Wallet.InsertWebHookReg @WalletId='WALLET-GUID', @Created=GETUTCDATE(), @Url='https://...', @NumberOfConfirmation=6;
```

### 8.3 Direct equivalent
```sql
IF EXISTS (SELECT TOP 1 WalletId FROM Wallet.WebHookReg WHERE WalletId = 'WALLET-GUID') SELECT 1 AS Result;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.IsWebHookRegExist | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.IsWebHookRegExist.sql*
