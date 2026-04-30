# Wallet.WalletAssets

> Tracks which cryptocurrency assets are visible in each customer's wallet portfolio, controlling what the user sees in their wallet UI and when assets were first added.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 4 active NC (1 unique) + 1 clustered PK |

---

## 1. Business Meaning

This table controls which crypto assets appear in a customer's wallet portfolio. Each row represents a specific crypto asset visible in a specific wallet. With ~1.76M rows, it manages the personalized view of each user's wallet - a user who holds BTC and ETH has two WalletAssets rows, while a user with 10 different cryptos has 10 rows.

Without this table, the system would not know which assets to display in a user's wallet UI. It acts as the "portfolio composition" table, tracking both what the user holds and when they first acquired each asset. The `IsShown` flag allows hiding assets without deleting the record.

Rows are created when a user first interacts with a crypto (e.g., receives a deposit, completes a redemption, or has a wallet created). FK references to both `Wallet.Wallets.WalletId` and `Wallet.CryptoTypes.CryptoID` link each entry to the specific wallet and crypto.

---

## 2. Business Logic

### 2.1 Asset Visibility

**What**: Assets can be shown or hidden in the wallet UI without being removed.

**Columns/Parameters Involved**: `IsShown`, `WalletId`, `CryptoId`

**Rules**:
- IsShown=1: Asset is visible in the wallet portfolio UI (default)
- IsShown=0: Asset is hidden but the record is preserved for history
- Filtered index on IsShown=1 optimizes the common "show active portfolio" query
- Unique constraint on (WalletId, CryptoId) prevents duplicate asset entries per wallet

---

## 3. Data Overview

| Id | WalletId | CryptoId | Occurred | IsShown | Meaning |
|---|---|---|---|---|---|
| 2109866 | 27491C93-... | 64 (SOL) | 2026-04-14 14:46 | true | Solana just added to this user's wallet portfolio - newest entry |
| 2109865 | 7EE5D523-... | 1 (BTC) | 2026-04-14 14:43 | true | Bitcoin added to wallet portfolio |
| 2109863 | 4EEFD257-... | 107 | 2026-04-14 14:40 | true | An ERC-20 token (crypto 107, likely USDC) visible in wallet |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | WalletId | uniqueidentifier | NO | - | VERIFIED | The wallet this asset belongs to. FK to Wallet.Wallets.WalletId. Combined with CryptoId for unique constraint. |
| 3 | CryptoId | int | NO | - | VERIFIED | The cryptocurrency asset. FK to Wallet.CryptoTypes.CryptoID. A wallet can hold multiple cryptos - each is a separate WalletAssets row. |
| 4 | Occurred | datetime2(7) | NO | getutcdate() | CODE-BACKED | When this asset was first added to the wallet. Represents the moment the user first acquired this crypto. Used for "portfolio age" analytics. |
| 5 | IsShown | bit | NO | 1 | CODE-BACKED | Whether this asset is visible in the wallet UI. 1=shown (default), 0=hidden. Allows users or the system to hide zero-balance or deprecated assets without deleting the record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WalletId | Wallet.Wallets | FK | Links to the customer's wallet |
| CryptoId | Wallet.CryptoTypes | FK | Identifies the crypto asset |

### 5.2 Referenced By (other objects point to this)

Not directly referenced by other tables.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.WalletAssets (table)
├── Wallet.Wallets (table)
│     └── Wallet.BlockchainCryptos (table)
└── Wallet.CryptoTypes (table)
      └── Wallet.BlockchainCryptos (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Wallets | Table | FK target for WalletId |
| Wallet.CryptoTypes | Table | FK target for CryptoId |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_WalletAssets | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Wallet_WalletAssets__WalletId_CryptoId | NC UNIQUE | WalletId, CryptoId | - | - | Active |
| IX_WalletAssets_CryptoId | NC | CryptoId | WalletId | - | Active |
| IX_WalletAssets_IsShown | NC | IsShown | CryptoId, Occurred | WHERE IsShown=1 | Active |
| IX_WalletAssets_WalletId_CryptoId_IncOccurred | NC | WalletId, CryptoId | Occurred | - | Active |
| nci_wi_WalletAssets_... | NC | Occurred | CryptoId, WalletId | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_Wallet_WalletAssets__Occurred | DEFAULT | getutcdate() |
| DF_WalletAssets_IsShown | DEFAULT | 1 - assets are shown by default |
| FK_...CryptoId | FK | CryptoId -> Wallet.CryptoTypes.CryptoID |
| FK_...WalletId | FK | WalletId -> Wallet.Wallets.WalletId |

---

## 8. Sample Queries

### 8.1 Get a user's visible crypto portfolio
```sql
SELECT ct.DisplayName, ct.Name AS Ticker, wa.Occurred AS FirstAdded
FROM Wallet.WalletAssets wa WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON wa.CryptoId = ct.CryptoID
WHERE wa.WalletId = '27491C93-3F5C-43FD-8AA8-2C3A6C014527'
  AND wa.IsShown = 1
ORDER BY wa.Occurred
```

### 8.2 Count assets per wallet
```sql
SELECT wa.WalletId, COUNT(*) AS AssetCount
FROM Wallet.WalletAssets wa WITH (NOLOCK)
WHERE wa.IsShown = 1
GROUP BY wa.WalletId
HAVING COUNT(*) > 5
ORDER BY AssetCount DESC
```

### 8.3 Most popular crypto assets by wallet count
```sql
SELECT ct.Name, ct.DisplayName, COUNT(*) AS WalletCount
FROM Wallet.WalletAssets wa WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON wa.CryptoId = ct.CryptoID
WHERE wa.IsShown = 1
GROUP BY ct.Name, ct.DisplayName
ORDER BY WalletCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.WalletAssets | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.WalletAssets.sql*
