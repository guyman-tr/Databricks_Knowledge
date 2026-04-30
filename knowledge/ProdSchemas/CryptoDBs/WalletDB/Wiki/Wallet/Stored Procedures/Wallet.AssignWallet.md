# Wallet.AssignWallet

> Assigns a specific wallet ID to a customer for a given cryptocurrency, creating the wallet record and asset association if they do not exist, then returning the customer wallet details.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns customer wallet details from CustomerWalletsView |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure assigns a pre-determined wallet ID to a customer. Unlike AssociateWalletToCustomer (which picks a wallet from the pool), this procedure uses a specific @WalletId provided by the caller. It is used when the system has already selected which wallet to assign (e.g., during migration, manual assignment, or when the pool selection was done externally).

Without this procedure, there would be no way to assign a known wallet to a customer outside of the pool-based allocation flow. This is important for manual operations, migrations, and scenarios where wallet selection logic lives in the application layer.

The procedure first checks if the customer already has a wallet for this blockchain. If yes, it reuses the existing wallet and only ensures the WalletAsset record exists. If no existing wallet, it creates one using the provided WalletId, setting the activation status from CryptoProviderContract.IsInitiallyActivated. Finally, it returns the full wallet details from CustomerWalletsView.

---

## 2. Business Logic

### 2.1 Wallet Reuse vs Creation

**What**: Reuses an existing wallet if the customer already has one for the same blockchain, otherwise creates a new one.

**Columns/Parameters Involved**: `@Gcid`, `@CryptoId`, `@WalletTypeId`, `@WalletId`

**Rules**:
- First checks Wallets table for existing active wallet matching Gcid + BlockchainCryptoId + WalletTypeId
- If found, reuses that wallet (WalletAsset may still need to be created for the specific CryptoId)
- If not found, INSERTs into Wallets with the provided @WalletId
- Uses OUTPUT INSERTED.WalletId to capture the assigned wallet
- Only inserts if no duplicate exists (LEFT JOIN Wallets dest WHERE dest.id IS NULL)

### 2.2 WalletAsset Guarantee

**What**: Ensures the WalletAsset record exists for the specific crypto on the assigned wallet.

**Columns/Parameters Involved**: `WalletAssets.WalletId`, `WalletAssets.CryptoId`

**Rules**:
- Always attempts to INSERT into WalletAssets for the assigned wallet + CryptoId
- LEFT JOIN prevents duplicates (wa.id IS NULL)
- This handles the case where a wallet exists for the blockchain but the specific token asset hasn't been registered

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID of the customer to assign the wallet to. |
| 2 | @CryptoId | int | NO | - | CODE-BACKED | Cryptocurrency to assign. Maps to Wallet.CryptoTypes. Used to resolve BlockchainCryptoId and ensure WalletAsset exists. |
| 3 | @WalletTypeId | tinyint | NO | - | CODE-BACKED | Type of wallet (e.g., 1=customer, 5=internal, 6=omnibus). Determines the wallet's role in the system. |
| 4 | @WalletId | uniqueidentifier | NO | - | CODE-BACKED | The specific wallet ID to assign. Unlike AssociateWalletToCustomer, the caller pre-determines which wallet to use. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CryptoId | Wallet.CryptoTypes | JOIN | Resolves BlockchainCryptoId |
| - | Wallet.CryptoProviderContract | JOIN | Gets IsInitiallyActivated flag |
| INSERT/SELECT | Wallet.Wallets | Writer/Reader | Creates or finds existing wallet |
| INSERT | Wallet.WalletAssets | Writer | Ensures asset record exists |
| SELECT | Wallet.CustomerWalletsView | Reader | Returns full wallet details |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase. Called by application wallet services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.AssignWallet (procedure)
  ├── Wallet.Wallets (table)
  ├── Wallet.WalletAssets (table)
  ├── Wallet.CryptoTypes (table)
  ├── Wallet.CryptoProviderContract (table)
  └── Wallet.CustomerWalletsView (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Wallets | Table | INSERT/SELECT - creates or finds wallet |
| Wallet.WalletAssets | Table | INSERT - ensures asset record |
| Wallet.CryptoTypes | Table | JOIN to resolve blockchain |
| Wallet.CryptoProviderContract | Table | JOIN to get activation status |
| Wallet.CustomerWalletsView | View | SELECT to return wallet details |

### 6.2 Objects That Depend On This

No dependents found in SQL codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Uses @Result table variable to track assigned wallet
- OUTPUT clause captures the wallet ID on INSERT
- NOLOCK hints on all reads
- No explicit transaction wrapping

---

## 8. Sample Queries

### 8.1 Check if a customer has a wallet for a crypto
```sql
SELECT w.WalletId, w.BlockchainCryptoId, w.WalletTypeId, w.IsActive
FROM Wallet.Wallets w WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON ct.BlockchainCryptoId = w.BlockchainCryptoId
WHERE w.Gcid = 12345678 AND ct.CryptoID = 1 AND w.IsActive = 1
```

### 8.2 View wallet assets for a customer
```sql
SELECT wa.Id, wa.WalletId, wa.CryptoId, ct.CryptoName
FROM Wallet.WalletAssets wa WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON ct.CryptoID = wa.CryptoId
JOIN Wallet.Wallets w WITH (NOLOCK) ON w.WalletId = wa.WalletId
WHERE w.Gcid = 12345678
```

### 8.3 Customer wallet details via the view
```sql
SELECT Id, Gcid, CryptoId, Address, WalletProviderId, BlockchainCryptoId, WalletTypeId
FROM Wallet.CustomerWalletsView WITH (NOLOCK)
WHERE Gcid = 12345678 AND IsActive = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.AssignWallet | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.AssignWallet.sql*
