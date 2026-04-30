# Wallet.GetInternalWallets

> Retrieves all internal (system-owned, non-customer) wallets, returning one representative wallet per cryptocurrency and wallet type combination.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns internal wallets where Gcid=0, deduplicated by CryptoId+WalletTypeId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns all internal (system-owned) wallets used by eToro's crypto infrastructure. Internal wallets are identified by Gcid=0 (no customer association) and include hot wallets, cold storage wallets, funding wallets, fee collection wallets, and other operational wallets. These are the wallets the platform uses to manage crypto operations rather than wallets belonging to customers.

The platform needs a registry of its internal wallets for operations like transaction routing, balance reconciliation, and funding flows. Services query this to know which addresses belong to the platform itself (vs. customer addresses) and to route transactions through the correct internal wallet type.

Data is sourced from `Wallet.CustomerWalletsView` (despite the name, this view contains ALL wallets including internal ones). The procedure deduplicates by taking only the first record (by WalletRecordId) per CryptoId+WalletTypeId combination, giving one representative wallet per type per crypto. Backward-compatible aliases (InternalWalletId, InternalWalletTypeId) are included.

---

## 2. Business Logic

### 2.1 Internal Wallet Identification

**What**: Internal wallets are distinguished from customer wallets by Gcid=0.

**Columns/Parameters Involved**: `Gcid`, `WalletTypeId`, `CryptoId`

**Rules**:
- Gcid=0 marks a wallet as system-owned (no customer association)
- Customer wallets have Gcid > 0 (maps to a customer's global ID)
- ROW_NUMBER() PARTITION BY CryptoId, WalletTypeId ORDER BY WalletRecordId selects the first/oldest record per combination
- Only RowNum=1 is returned, giving one representative internal wallet per type per crypto
- Commented-out JOIN to Dictionary.WalletTypes suggests a previous filter excluding 'Customer' type was removed in favor of the Gcid=0 approach

### 2.2 Backward Compatibility Aliases

**What**: Duplicate column aliases maintain compatibility with older consuming code.

**Columns/Parameters Involved**: `Id/InternalWalletId`, `WalletTypeId/InternalWalletTypeId`

**Rules**:
- `Id` is aliased as both `Id` and `InternalWalletId` (same value)
- `WalletTypeId` is aliased as both `WalletTypeId` and `InternalWalletTypeId` (same value)
- These duplicates exist for backward compatibility with consumers that reference the old column names

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

This procedure has no input parameters.

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | BIGINT | NO | - | CODE-BACKED | Internal wallet record ID from CustomerWalletsView. Primary identifier for this wallet record. |
| 2 | InternalWalletId | BIGINT | NO | - | CODE-BACKED | Backward-compatible alias for Id. Same value as Id, retained for older consuming code. |
| 3 | RecordId | BIGINT | NO | - | CODE-BACKED | The WalletRecordId from CustomerWalletsView. Secondary identifier used for ordering and deduplication. |
| 4 | Gcid | BIGINT | NO | - | CODE-BACKED | Global Customer ID. Always 0 for internal wallets (no customer association). |
| 5 | CryptoId | INT | NO | - | CODE-BACKED | Cryptocurrency identifier. FK to Wallet.CryptoTypes. Determines which blockchain network this wallet operates on. |
| 6 | ProviderWalletId | NVARCHAR | YES | - | CODE-BACKED | The custody provider's wallet identifier (e.g., BitGo wallet ID). Aliased from BlockchainProviderWalletId. Used for API calls to the custody provider. |
| 7 | Address | NVARCHAR | YES | - | CODE-BACKED | The public blockchain address of this internal wallet. Used for transaction routing and balance monitoring. |
| 8 | WalletTypeId | INT | NO | - | CODE-BACKED | Wallet type identifier. FK to Dictionary.WalletTypes. Classifies the internal wallet's operational role (hot, cold, funding, fee, etc.). |
| 9 | InternalWalletTypeId | INT | NO | - | CODE-BACKED | Backward-compatible alias for WalletTypeId. Same value, retained for older consuming code. |
| 10 | WalletProviderId | INT | NO | - | CODE-BACKED | Custody provider identifier. FK to Dictionary.WalletProvider (1=Bitgo, 2=CUG, 3=None). Identifies which provider manages this internal wallet. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.CustomerWalletsView | FROM | Primary data source (filtered to Gcid=0 for internal wallets) |

### 5.2 Referenced By (other objects point to this)

No direct SQL callers found. Called by application services to load the internal wallet registry.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetInternalWallets (procedure)
+-- Wallet.CustomerWalletsView (view)
      +-- Wallet.Wallets (table)
      +-- Wallet.WalletAddresses (table)
      +-- Wallet.WalletBalances (table)
      +-- Wallet.BlockchainCryptoProviders (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerWalletsView | View | FROM - source of all wallet data including internal wallets |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute the procedure
```sql
EXEC Wallet.GetInternalWallets;
```

### 8.2 List all internal wallets with crypto and type names
```sql
SELECT cwv.Id, ct.Name AS CryptoName, cwv.Address, cwv.WalletProviderId
FROM Wallet.CustomerWalletsView cwv WITH (NOLOCK)
INNER JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON ct.CryptoID = cwv.CryptoId
WHERE cwv.Gcid = 0
ORDER BY cwv.CryptoId, cwv.WalletTypeId;
```

### 8.3 Count internal wallets per crypto
```sql
SELECT cwv.CryptoId, ct.Name AS CryptoName, COUNT(*) AS InternalWalletCount
FROM Wallet.CustomerWalletsView cwv WITH (NOLOCK)
INNER JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON ct.CryptoID = cwv.CryptoId
WHERE cwv.Gcid = 0
GROUP BY cwv.CryptoId, ct.Name
ORDER BY cwv.CryptoId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetInternalWallets | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetInternalWallets.sql*
