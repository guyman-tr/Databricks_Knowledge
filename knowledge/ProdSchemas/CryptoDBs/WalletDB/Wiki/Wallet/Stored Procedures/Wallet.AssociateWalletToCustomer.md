# Wallet.AssociateWalletToCustomer

> Associates a wallet from the pre-generated pool to a customer for a given cryptocurrency, handling pool selection, promotion matching, duplicate key retries, and wallet asset creation in a single operation.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns customer wallet details including WalletPoolId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the primary wallet assignment procedure in the system. When a customer needs a crypto wallet (first crypto purchase, new blockchain, promotional campaign), this procedure selects an available wallet from the pre-generated pool and assigns it to the customer. The pool approach is essential for blockchain performance - wallets are created on-chain in advance so customers get instant wallet access without waiting for blockchain confirmation.

Without this procedure, customers could not receive crypto wallets, blocking the entire crypto buy/receive flow. It is called by Wallet.StoreWallet (another SP) and by application services directly.

The procedure handles multiple scenarios: reusing an existing customer wallet if one exists for the same blockchain, selecting from the promotion-tagged pool if a promotion applies, selecting from the general verified pool otherwise, and retrying on duplicate key conflicts (concurrent wallet assignment race condition).

---

## 2. Business Logic

### 2.1 Wallet Pool Selection Strategy

**What**: Selects the best available wallet from the pool based on promotion and verification status.

**Columns/Parameters Involved**: `@Gcid`, `@CryptoId`, `@WalletTypeId`, `@PromotionTagId`, WalletPool, WalletPoolStatuses

**Rules**:
- If @PromotionTagId is NOT NULL and exists in PromotionTags: selects wallets with "FundingVerified" status and matching PromotionTagId
- If @PromotionTagId is NULL or not found: selects wallets with "Verified" status (standard pool)
- Wallet must NOT already be in Wallets table (not yet assigned to any customer)
- If @EnforceNewWallet = 0: also checks that the customer doesn't already have an active wallet for this blockchain + wallet type
- Ordered by Created date (FIFO - oldest wallets assigned first)
- Takes TOP 1 from the eligible set

### 2.2 Duplicate Key Retry Loop

**What**: Handles concurrent wallet assignment race conditions.

**Columns/Parameters Involved**: Wallets.WalletId unique index

**Rules**:
- The pool selection + INSERT is wrapped in a WHILE @Flag = 0 loop
- If INSERT fails with "Cannot insert duplicate key IX_Wallet_Wallets__WalletId", it means another concurrent process took the same wallet
- The loop retries, picking the next available wallet
- Any OTHER error is thrown immediately
- Loop exits when INSERT succeeds (@Flag = 1)

### 2.3 EnforceNewWallet Mode

**What**: Forces creation of a new wallet even if the customer already has one for this blockchain.

**Columns/Parameters Involved**: `@EnforceNewWallet`, `@Gcid`, `@WalletTypeId`

**Rules**:
- Only allowed when @Gcid = 0 AND @WalletTypeId IN (1, 6) (internal/omnibus wallets)
- Raises error if used with a real customer GCID or incompatible wallet type
- Bypasses the "existing wallet reuse" check, always selecting from the pool

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID. 0 for internal/system wallets, positive for customer wallets. |
| 2 | @CryptoId | int | NO | - | CODE-BACKED | Cryptocurrency for the wallet. Maps to CryptoTypes to resolve BlockchainCryptoId. |
| 3 | @WalletTypeId | tinyint | NO | - | CODE-BACKED | Wallet type: 1=customer, 5=internal/hot, 6=omnibus. Determines pool selection rules. |
| 4 | @PromotionTagId | int | YES | NULL | CODE-BACKED | Optional promotion tag. If provided and valid, selects from promotion-funded pool (FundingVerified status) instead of standard pool (Verified status). |
| 5 | @EnforceNewWallet | bit | YES | 0 | CODE-BACKED | Force new wallet allocation even if customer already has one. Only valid for @Gcid=0 with WalletTypeId 1 or 6. Used for internal/omnibus wallet provisioning. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PromotionTagId | Wallet.PromotionTags | EXISTS check | Validates promotion exists |
| @CryptoId | Wallet.CryptoTypes | JOIN | Resolves BlockchainCryptoId |
| - | Wallet.CryptoProviderContract | JOIN | Gets IsInitiallyActivated |
| - | Wallet.WalletPool | JOIN | Source of available wallets |
| - | Wallet.WalletPoolStatuses | Subquery | Gets latest status per pool entry |
| - | Dictionary.WalletPoolStatuses | JOIN | Resolves status names |
| INSERT | Wallet.Wallets | Writer | Creates wallet record |
| INSERT | Wallet.WalletAssets | Writer | Creates asset association |
| SELECT | Wallet.CustomerWalletsView | Reader | Returns wallet details |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.StoreWallet | EXEC | Caller | StoreWallet calls this to assign a pool wallet |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.AssociateWalletToCustomer (procedure)
  ├── Wallet.PromotionTags (table)
  ├── Wallet.Wallets (table)
  ├── Wallet.WalletAssets (table)
  ├── Wallet.CryptoTypes (table)
  ├── Wallet.CryptoProviderContract (table)
  ├── Wallet.WalletPool (table)
  ├── Wallet.WalletPoolStatuses (table)
  ├── Wallet.CustomerWalletsView (view)
  └── Dictionary.WalletPoolStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.PromotionTags | Table | Validates promotion tag |
| Wallet.Wallets | Table | INSERT/SELECT - creates or finds wallet |
| Wallet.WalletAssets | Table | INSERT - ensures asset record |
| Wallet.CryptoTypes | Table | JOIN to resolve blockchain |
| Wallet.CryptoProviderContract | Table | JOIN to get activation flag |
| Wallet.WalletPool | Table | Source of pool wallets |
| Wallet.WalletPoolStatuses | Table | Reads latest status per pool entry |
| Dictionary.WalletPoolStatuses | Table | Resolves status names ("Verified", "FundingVerified") |
| Wallet.CustomerWalletsView | View | Returns wallet details |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.StoreWallet | Stored Procedure | Calls via EXEC |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- WHILE loop with TRY/CATCH for concurrent duplicate key handling
- RAISERROR for invalid @EnforceNewWallet usage
- NOLOCK hints on pool reads
- OUTPUT clause to capture inserted WalletId
- Complex subqueries for status resolution (correlated TOP 1 ORDER BY Id DESC)

---

## 8. Sample Queries

### 8.1 View available wallets in the pool (Verified status)
```sql
SELECT wp.Id, wp.WalletId, wp.BlockchainCryptoId, wp.ProviderWalletId
FROM Wallet.WalletPool wp WITH (NOLOCK)
CROSS APPLY (
    SELECT TOP 1 WalletPoolStatusId FROM Wallet.WalletPoolStatuses WITH (NOLOCK)
    WHERE WalletPoolId = wp.Id ORDER BY Id DESC
) wps
JOIN Dictionary.WalletPoolStatuses dwps WITH (NOLOCK) ON dwps.Id = wps.WalletPoolStatusId
WHERE dwps.Name = 'Verified'
  AND NOT EXISTS (SELECT 1 FROM Wallet.Wallets w WITH (NOLOCK) WHERE w.WalletId = wp.WalletId)
```

### 8.2 Customer's assigned wallets
```sql
SELECT cwv.Id, cwv.Gcid, cwv.CryptoId, cwv.Address, cwv.WalletProviderId, cwv.BlockchainCryptoId
FROM Wallet.CustomerWalletsView cwv WITH (NOLOCK)
WHERE cwv.Gcid = 12345678 AND cwv.IsActive = 1
```

### 8.3 Pool availability by blockchain
```sql
SELECT wp.BlockchainCryptoId, dwps.Name AS Status, COUNT(*) AS Available
FROM Wallet.WalletPool wp WITH (NOLOCK)
CROSS APPLY (
    SELECT TOP 1 WalletPoolStatusId FROM Wallet.WalletPoolStatuses WITH (NOLOCK)
    WHERE WalletPoolId = wp.Id ORDER BY Id DESC
) wps
JOIN Dictionary.WalletPoolStatuses dwps WITH (NOLOCK) ON dwps.Id = wps.WalletPoolStatusId
WHERE NOT EXISTS (SELECT 1 FROM Wallet.Wallets w WITH (NOLOCK) WHERE w.WalletId = wp.WalletId)
GROUP BY wp.BlockchainCryptoId, dwps.Name
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Crypto IN - Address vs Wallet Flow Mapping | Confluence | High-level wallet assignment flow context - wallet pool to customer association lifecycle |

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 caller | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.AssociateWalletToCustomer | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.AssociateWalletToCustomer.sql*
