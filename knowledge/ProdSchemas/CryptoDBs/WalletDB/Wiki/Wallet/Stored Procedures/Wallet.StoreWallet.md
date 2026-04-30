# Wallet.StoreWallet

> Legacy wallet creation wrapper that delegates entirely to AssociateWalletToCustomer, accepting wallet parameters but only using Gcid and CryptoId for the actual association.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | EXEC Wallet.AssociateWalletToCustomer (delegation) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a legacy wallet creation procedure that accepts full wallet parameters (WalletId, Gcid, CryptoId, Address, ProviderWalletId, Status) but only passes Gcid, CryptoId, a hardcoded StatusId of 5, and NULL DetailsJson to AssociateWalletToCustomer. The conversion, executer, redeem scheduler, and scheduled jobs services still call this, though the actual wallet creation logic lives in AssociateWalletToCustomer.

The procedure ignores @WalletId, @Address, @BlockchainProviderWalletId, and @Status parameters - they are accepted for API compatibility but not used.

---

## 2. Business Logic

### 2.1 Pure Delegation

**What**: Passes through to AssociateWalletToCustomer with hardcoded StatusId=5.

**Rules**:
- EXEC Wallet.AssociateWalletToCustomer @Gcid, @CryptoId, 5, NULL
- StatusId=5 is hardcoded (not using @Status parameter)
- All wallet detail parameters (@WalletId, @Address, etc.) are ignored

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletId | uniqueidentifier | NO | - | CODE-BACKED | Wallet GUID. Accepted but NOT USED - ignored by implementation. |
| 2 | @Gcid | bigint | NO | - | VERIFIED | Customer ID. Passed to AssociateWalletToCustomer. |
| 3 | @CryptoId | int | NO | - | VERIFIED | Cryptocurrency. Passed to AssociateWalletToCustomer. |
| 4 | @Address | nvarchar(512) | NO | - | CODE-BACKED | Blockchain address. Accepted but NOT USED. |
| 5 | @BlockchainProviderWalletId | nvarchar(100) | NO | - | CODE-BACKED | Provider reference. Accepted but NOT USED. |
| 6 | @Status | tinyint | NO | - | CODE-BACKED | Wallet status. Accepted but NOT USED (hardcoded to 5). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.AssociateWalletToCustomer | EXEC | Full delegation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ConversionUser | - | EXECUTE | Wallet creation during conversion |
| ExecuterUser | - | EXECUTE | Wallet creation during execution |
| RedeemSchedulerUser | - | EXECUTE | Wallet creation during redemption |
| ScheduledJobsUser | - | EXECUTE | Scheduled wallet creation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.StoreWallet (procedure)
+-- Wallet.AssociateWalletToCustomer (procedure) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.AssociateWalletToCustomer | Stored Procedure | EXEC delegation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ConversionUser, ExecuterUser, RedeemSchedulerUser, ScheduledJobsUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Create a wallet (legacy interface)
```sql
EXEC Wallet.StoreWallet @WalletId='GUID', @Gcid=30351701, @CryptoId=1, @Address='1A1zP1eP5...', @BlockchainProviderWalletId='bitgo-123', @Status=1;
-- Note: Only @Gcid and @CryptoId are actually used
```

### 8.2 Direct equivalent
```sql
EXEC Wallet.AssociateWalletToCustomer @Gcid=30351701, @CryptoId=1, @StatusId=5, @DetailsJson=NULL;
```

### 8.3 Check the result
```sql
SELECT * FROM Wallet.CustomerWalletsView WITH (NOLOCK) WHERE Gcid = 30351701 AND CryptoId = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.StoreWallet | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.StoreWallet.sql*
