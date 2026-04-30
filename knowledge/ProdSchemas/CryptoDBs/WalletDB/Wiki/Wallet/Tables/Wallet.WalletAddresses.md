# Wallet.WalletAddresses

> Links blockchain addresses to their parent wallets, storing the public address, activation status, and provider wallet ID for each address a wallet owns. Supports multiple addresses per wallet with computed normalized address for cross-format matching.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 6 active NC (2 unique) + 1 clustered PK |

---

## 1. Business Meaning

This table links blockchain addresses to wallets from `Wallet.WalletPool`. Each row represents a specific address assigned to a wallet, with its activation status and provider-side identifier. With ~2.46M rows, most wallets have a single main address, but some blockchains support multiple addresses per wallet (e.g., Bitcoin's UTXO model generates new addresses).

This table is essential for resolving which wallet owns a given blockchain address. When an incoming transaction arrives, the system matches the receiver address against this table to identify the destination wallet and its owner. The `NormalizedAddress` computed column strips protocol prefixes and query parameters for consistent matching across address formats.

Addresses are created when a pool wallet is generated (`Wallet.InsertWalletToPool`) or when new addresses are added to existing wallets (`Wallet.AddWalletAddress`). The `CustomerWalletStatusId` tracks whether the address is pending or active. FK to `Wallet.WalletPool.WalletId` links the address back to its wallet.

---

## 2. Business Logic

### 2.1 Address Normalization

**What**: A computed column strips protocol prefixes and query parameters from addresses for consistent matching.

**Columns/Parameters Involved**: `Address`, `NormalizedAddress`

**Rules**:
- Removes protocol prefix before ':' (e.g., "bitcoin:bc1q..." becomes "bc1q...")
- Removes query parameters after '?' (e.g., "addr?dt=123" becomes "addr")
- Enables matching regardless of how the address was formatted in the original transaction
- Persisted for index performance

### 2.2 Wallet Activation Tracking

**What**: Each address tracks whether it has been activated on the blockchain via CustomerWalletStatusId.

**Columns/Parameters Involved**: `CustomerWalletStatusId`, `WalletId`

**Rules**:
- 0 = Pending: Address created but not yet confirmed on blockchain
- 1 = Active: Address confirmed and ready for transactions
- See [Customer Wallet Status](../../_glossary.md#customer-wallet-status). FK to Dictionary.CustomerWalletStatus.

---

## 3. Data Overview

| Id | WalletId | Address (truncated) | IsMain | CustomerWalletStatusId | Meaning |
|---|---|---|---|---|---|
| 2463725 | DBA0BC4B-... | DRudbp68Muz... | true | 1 (Active) | A Solana wallet address, main address, fully active. |
| 2463724 | 78AC6621-... | GFDsXEjLaHu... | true | 1 (Active) | Another SOL pool address ready for assignment. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | WalletId | uniqueidentifier | NO | - | VERIFIED | The parent wallet this address belongs to. FK to Wallet.WalletPool.WalletId. Multiple addresses can share the same WalletId (Bitcoin UTXO wallets). |
| 3 | Address | nvarchar(512) | YES | - | VERIFIED | The raw blockchain address string as provided by the wallet provider. May include protocol prefixes or query parameters. Unique constraint enforced. NULL only for wallets with deferred address generation. |
| 4 | IsMain | bit | YES | - | CODE-BACKED | Whether this is the wallet's primary address. 1=main address (used for receiving), NULL/0=secondary address. Most wallets have exactly one main address. |
| 5 | BlockchainProviderWalletId | nvarchar(100) | NO | - | CODE-BACKED | Provider-side wallet identifier (BitGo or CUG wallet ID). Used for API calls to the custody provider. |
| 6 | CustomerWalletStatusId | tinyint | NO | - | VERIFIED | Activation state: 0=Pending (awaiting blockchain confirmation), 1=Active (ready for transactions). See [Customer Wallet Status](../../_glossary.md#customer-wallet-status). FK to Dictionary.CustomerWalletStatus. |
| 7 | Occurred | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp when this address record was created. |
| 8 | BalanceAccountID | varchar(50) | YES | - | CODE-BACKED | External balance account identifier used by the provider for balance tracking. NULL for wallets without provider-side balance accounts. Unique constraint (filtered, non-NULL only). |
| 9 | NormalizedAddress | computed | - | - | VERIFIED | Computed PERSISTED column that strips protocol prefixes (before ':') and query parameters (after '?') from the Address. Enables consistent address matching regardless of formatting. Indexed for lookup performance. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WalletId | Wallet.WalletPool | FK | Links address to its parent wallet |
| CustomerWalletStatusId | Dictionary.CustomerWalletStatus | FK | Tracks address activation state |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.AddWalletAddress | - | Writer | Inserts new addresses |
| Wallet.GetWalletAddresses | - | Reader | Reads addresses for a wallet |
| Wallet.SetWalletAddressBalanceAccount | - | Modifier | Sets the BalanceAccountID |
| Wallet.vw_WalletBalanaces | - | JOIN | View joins this table to resolve WalletAddresses.Id from address string match |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.WalletAddresses (table)
├── Wallet.WalletPool (table)
│     └── Wallet.BlockchainCryptos (table)
└── Dictionary.CustomerWalletStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletPool | Table | FK target for WalletId |
| Dictionary.CustomerWalletStatus | Table | FK target for CustomerWalletStatusId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.AddWalletAddress | Stored Procedure | Inserts new address records |
| Wallet.GetWalletAddresses | Stored Procedure | Reads wallet addresses |
| Wallet.SetWalletAddressBalanceAccount | Stored Procedure | Updates balance account ID |
| Wallet.GetAddressesForSync | Stored Procedure | Reads addresses for synchronization |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_WalletAddresses | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Wallet_WalletAddresses_Address | NC UNIQUE | Address ASC | - | - | Active |
| IX_Wallet_WalletAddresses_BalanceAccountID | NC UNIQUE | BalanceAccountID ASC | - | WHERE BalanceAccountID IS NOT NULL | Active |
| IX_Wallet_WalletAddresses | NC | NormalizedAddress ASC | WalletId, Address, BlockchainProviderWalletId | - | Active |
| IX_Wallet_WalletAddresses_Address_Inc | NC | Address ASC | WalletId | - | Active |
| IX_Wallet_WalletAddresses_WalletId | NC | WalletId ASC | - | - | Active |
| IX_WalletAddresses_WalletId_Address | NC | WalletId, Address | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_WalletAddresses_Occurred | DEFAULT | getutcdate() |
| FK_...WalletId__Wallet_WalletPool_WalletId | FK | WalletId -> Wallet.WalletPool.WalletId |
| FK_...CustomerWalletStatusId | FK | CustomerWalletStatusId -> Dictionary.CustomerWalletStatus.Status |

---

## 8. Sample Queries

### 8.1 Find wallet by blockchain address
```sql
SELECT wa.WalletId, wa.Address, wa.NormalizedAddress, wa.CustomerWalletStatusId
FROM Wallet.WalletAddresses wa WITH (NOLOCK)
WHERE wa.NormalizedAddress = 'DRudbp68Muznc6SBsQ687EXe7f8iK41xhyy1xZZLi5VQ'
```

### 8.2 Get all addresses for a wallet
```sql
SELECT wa.Address, wa.IsMain, wa.CustomerWalletStatusId, wa.BalanceAccountID
FROM Wallet.WalletAddresses wa WITH (NOLOCK)
WHERE wa.WalletId = 'DBA0BC4B-F4BB-4235-B2FD-B128BD5F9FF6'
```

### 8.3 Count addresses by activation status
```sql
SELECT cws.Description AS Status, COUNT(*) AS AddressCount
FROM Wallet.WalletAddresses wa WITH (NOLOCK)
JOIN Dictionary.CustomerWalletStatus cws WITH (NOLOCK) ON wa.CustomerWalletStatusId = cws.Status
GROUP BY cws.Description
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.WalletAddresses | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.WalletAddresses.sql*
