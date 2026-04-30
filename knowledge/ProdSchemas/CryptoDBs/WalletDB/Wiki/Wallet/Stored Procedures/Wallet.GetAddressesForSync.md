# Wallet.GetAddressesForSync

> Retrieves wallet addresses that have balance account IDs assigned and use a specific blockchain provider prefix, providing the data needed for balance synchronization with external systems.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns BalanceAccountID, BalanceAssetName, GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves wallet addresses eligible for balance synchronization with an external balance tracking system. It returns addresses that have been assigned a BalanceAccountID (meaning they are registered with the external balance system) and whose blockchain provider wallet ID starts with "5" (a specific provider prefix). The output provides the external system's account ID, asset name, and customer ID needed for sync operations.

Without this procedure, the balance synchronization process could not identify which wallet addresses need to be synced with the external balance system, leading to stale or missing balance data.

The procedure is parameterless and returns all eligible addresses across all customers and cryptocurrencies.

---

## 2. Business Logic

### 2.1 Sync Eligibility Criteria

**What**: Only addresses with external balance system registration and a specific provider are eligible.

**Columns/Parameters Involved**: WalletAddresses.BalanceAccountID, WalletAddresses.BlockchainProviderWalletId

**Rules**:
- BalanceAccountID IS NOT NULL - address must be registered with external balance system
- BlockchainProviderWalletId LIKE '5%' - filters to a specific blockchain provider (provider IDs starting with "5")
- JOINs through CustomerWalletsView to get customer context and CryptoTypes for asset naming

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BalanceAccountID | - | NO | - | CODE-BACKED | External balance system's account identifier for this wallet address. Used by the sync process to match wallet addresses to external accounts. |
| 2 | BalanceAssetName | - | NO | - | CODE-BACKED | The asset name in the external balance system (from CryptoTypes). Maps the cryptocurrency to the external system's naming convention. |
| 3 | GCID | bigint | NO | - | CODE-BACKED | Global Customer ID of the wallet owner. Used for customer-level reconciliation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.WalletAddresses | Reader | Source of address records |
| - | Wallet.CustomerWalletsView | JOIN | Links addresses to customer wallets |
| - | Wallet.CryptoTypes | JOIN | Gets BalanceAssetName for the crypto |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase. Called by balance sync services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetAddressesForSync (procedure)
  ├── Wallet.WalletAddresses (table)
  ├── Wallet.CustomerWalletsView (view)
  └── Wallet.CryptoTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletAddresses | Table | SELECT - source of addresses with BalanceAccountID |
| Wallet.CustomerWalletsView | View | JOIN - links to customer wallet context |
| Wallet.CryptoTypes | Table | JOIN - gets BalanceAssetName |

### 6.2 Objects That Depend On This

No dependents found in SQL codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- NOLOCK hints on all tables
- No parameters, no pagination - returns full result set
- Provider filter: BlockchainProviderWalletId LIKE '5%'

---

## 8. Sample Queries

### 8.1 Execute the sync address query
```sql
EXEC Wallet.GetAddressesForSync
```

### 8.2 Manual check of addresses with balance accounts
```sql
SELECT wa.Id, wa.WalletId, wa.Address, wa.BalanceAccountID, wa.BlockchainProviderWalletId
FROM Wallet.WalletAddresses wa WITH (NOLOCK)
WHERE wa.BalanceAccountID IS NOT NULL
  AND wa.BlockchainProviderWalletId LIKE '5%'
```

### 8.3 Count eligible addresses by crypto
```sql
SELECT ct.CryptoName, COUNT(*) AS EligibleAddresses
FROM Wallet.WalletAddresses wa WITH (NOLOCK)
JOIN Wallet.CustomerWalletsView wc WITH (NOLOCK) ON wa.WalletId = wc.Id
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON ct.CryptoID = wc.CryptoId
WHERE wa.BalanceAccountID IS NOT NULL
  AND wa.BlockchainProviderWalletId LIKE '5%'
GROUP BY ct.CryptoName
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetAddressesForSync | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetAddressesForSync.sql*
