# Wallet.AddWalletAddress

> Adds a secondary (non-main) blockchain address to an existing customer wallet, linking it to the wallet's blockchain provider and verifying the wallet owns the correct blockchain cryptocurrency.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | New row in Wallet.WalletAddresses |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure registers an additional blockchain address for an existing customer wallet. Wallets can have multiple addresses (e.g., Bitcoin UTXO model generates new addresses for each transaction). This procedure adds a non-main address (IsMain=0) to the wallet's address list, inheriting the blockchain provider wallet ID from the customer wallet view.

Without this procedure, the system could not track multiple receiving addresses per wallet, which is essential for UTXO-based cryptocurrencies and for privacy features that generate new addresses.

The procedure validates that the wallet exists, belongs to the correct blockchain crypto (CryptoId = BlockchainCryptoId filter), and that the address is not already registered for this wallet.

---

## 2. Business Logic

### 2.1 Conditional Insert with Wallet Validation

**What**: Only adds the address if the wallet is valid and the address is not already registered.

**Columns/Parameters Involved**: `@WalletId`, `@Address`, CustomerWalletsView, WalletAddresses

**Rules**:
- JOINs to CustomerWalletsView to verify the wallet exists and get the BlockchainProviderWalletId
- Filters on CryptoId = BlockchainCryptoId (ensures the wallet is a base blockchain wallet, not a token wallet)
- LEFT JOINs to existing WalletAddresses to check for duplicates (wa.Id IS NULL)
- Sets IsMain = 0 (secondary address) and CustomerWalletStatusId = 1 (active)
- If wallet does not exist or address already registered, INSERT produces zero rows

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletId | uniqueidentifier | NO | - | CODE-BACKED | The customer wallet to add the address to. Must exist in CustomerWalletsView with CryptoId = BlockchainCryptoId. |
| 2 | @Address | nvarchar(512) | NO | - | CODE-BACKED | The blockchain address to register. Must be unique per wallet (duplicate check via LEFT JOIN). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WalletId | Wallet.CustomerWalletsView | JOIN | Validates wallet exists and gets provider wallet ID |
| INSERT target | Wallet.WalletAddresses | Writer | Creates the address record |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase. Called by application wallet services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.AddWalletAddress (procedure)
  ├── Wallet.CustomerWalletsView (view)
  └── Wallet.WalletAddresses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerWalletsView | View | JOIN for wallet validation and provider wallet ID |
| Wallet.WalletAddresses | Table | INSERT target + duplicate check |

### 6.2 Objects That Depend On This

No dependents found in SQL codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- SET NOCOUNT ON
- Hardcoded values: IsMain = 0, CustomerWalletStatusId = 1
- No error handling - silent no-op on validation failure

---

## 8. Sample Queries

### 8.1 View all addresses for a wallet
```sql
SELECT Id, WalletId, Address, IsMain, CustomerWalletStatusId, BlockchainProviderWalletId
FROM Wallet.WalletAddresses WITH (NOLOCK)
WHERE WalletId = '4B26D85F-BF00-4E27-9166-4F8AF2D599D6'
ORDER BY IsMain DESC, Id
```

### 8.2 Find wallets with multiple addresses
```sql
SELECT WalletId, COUNT(*) AS AddressCount
FROM Wallet.WalletAddresses WITH (NOLOCK)
GROUP BY WalletId
HAVING COUNT(*) > 1
ORDER BY AddressCount DESC
```

### 8.3 Validate a wallet in CustomerWalletsView
```sql
SELECT Id, Gcid, CryptoId, BlockchainCryptoId, Address, WalletProviderId
FROM Wallet.CustomerWalletsView WITH (NOLOCK)
WHERE Id = '4B26D85F-BF00-4E27-9166-4F8AF2D599D6'
  AND CryptoId = BlockchainCryptoId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.AddWalletAddress | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.AddWalletAddress.sql*
