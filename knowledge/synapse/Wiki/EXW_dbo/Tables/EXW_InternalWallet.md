# EXW_dbo.EXW_InternalWallet

> Current-state snapshot of eToro's own internal/system blockchain wallets (Gcid ≤ 0), covering all wallet types except standard customer wallets (type 5). Includes omnibus holding wallets, conversion wallets, funding wallets, payment wallets, and staking refund wallets across all supported cryptocurrencies. Refreshed via full TRUNCATE + INSERT from EXW_Wallet.CustomerWalletsView filtered to Gcid ≤ 0. Clustered Columnstore Index, HASH(CryptoId) distribution — optimized for analytic aggregation by crypto asset.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.CustomerWalletsView (Gcid ≤ 0 filter) + WalletDB.Wallet.CryptoTypes (name lookup) + WalletDB_Dictionary_WalletTypes (type label lookup) |
| **Refresh** | Periodic full refresh (TRUNCATE + INSERT) via SP_EXW_InternalWallet — no parameters; always current snapshot |
| **Row Count** | Unknown — bounded by internal wallet count × supported crypto count; estimated tens to hundreds of rows |
| **Synapse Distribution** | HASH (CryptoId) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX (CCI) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — no Gold layer target |

---

## 1. Business Meaning

EXW_dbo.EXW_InternalWallet is eToro's own internal blockchain wallet inventory — the company's system-owned crypto addresses across all supported assets. While the broader wallet platform manages millions of customer wallets, this table holds only the internal/operational wallets that eToro uses to run its crypto business.

**What Gcid ≤ 0 means**: In WalletDB, customer accounts have positive GCIDs. Gcid=0 conventionally indicates omnibus/system wallets (eToro's pooled holdings), and negative Gcid values represent other internal service accounts. The `WHERE Gcid <= 0` filter in SP_EXW_InternalWallet isolates these non-customer wallets.

**Wallet types present**: Since Gcid ≤ 0 excludes standard customer wallets (type 5), all rows in this table have InternalWalletTypeId in {1, 2, 3, 4, 6, 7}:
- 1=Redeem: wallets used for redemption/withdrawal operations
- 2=Conversion: wallets used for crypto-to-crypto conversions
- 3=Funding: wallets used to fund customer deposits
- 4=Payment: wallets used for payment processing
- 6=C2F: crypto-to-fiat operational wallets
- 7=StakingRefund: wallets used for staking-related refunds (includes the ETH staking pool address)

**On-chain significance**: The `Address` column holds the actual blockchain addresses of eToro's internal wallets — these are public on-chain addresses observable on block explorers. For ETH, this includes the staking pool address `0xCB2A66540680c344bab5f818d68c3e4B9D57363B` (referenced in WalletDB.Staking.StakingTransactions wiki).

**Refresh pattern**: The SP has no `@date` parameter — it completely replaces the table contents every run. This is a point-in-time snapshot of all currently active internal wallets (CustomerWalletsView already filters IsActive=1 and IsShown=1).

**CCI + HASH(CryptoId)**: The Clustered Columnstore Index enables analytic queries over the table — aggregating balances across wallet types within a crypto, or listing all internal addresses for a specific crypto type. HASH(CryptoId) aligns with the primary access pattern: "show all internal wallets for this cryptocurrency."

---

## 2. Business Logic

### 2.1 Internal vs Customer Wallet Separation

**What**: The table contains only non-customer (system) wallets identified by Gcid ≤ 0.

**Columns Involved**: `Gcid`, `InternalWalletTypeId`, `InternalType`

**Rules**:
- `Gcid = 0`: omnibus/system wallets — eToro's primary pooled holdings per crypto
- `Gcid < 0`: internal service account wallets
- `InternalWalletTypeId` (= WalletTypeId in source) identifies the operational role (never type 5=Customer in this table)
- `InternalType` is the human-readable label from WalletDB_Dictionary_WalletTypes (LEFT JOIN — NULL if type not in dictionary)

### 2.2 Wallet Activation Status

**What**: Status indicates whether an internal wallet is fully operational on-chain.

**Columns Involved**: `Status`

**Rules**:
- `Status = 0`: Active (IsActivated=1 in Wallets — blockchain address confirmed, fully operational)
- `Status = 5`: Pending activation (IsActivated=0 — awaiting blockchain confirmation)
- Both are computed in CustomerWalletsView: `CASE WHEN w.IsActivated = 1 THEN 0 ELSE 5 END`
- 99.6% of wallets have Status=0 (active) per upstream wiki data

### 2.3 Blockchain Provider Linkage

**What**: Each wallet is managed by an external custody provider.

**Columns Involved**: `Id`, `BlockchainProviderWalletId`

**Rules**:
- `Id` (uniqueidentifier) = the WalletDB wallet business key (aliased from Wallet.Wallets.WalletId)
- `BlockchainProviderWalletId` = the identifier assigned by BitGo or CUG custody provider
- Used for all API interactions with the blockchain custody provider for operational wallets

### 2.4 Crypto Asset Identification

**What**: Each wallet row is tied to a specific crypto type.

**Columns Involved**: `CryptoId`, `CryptoName`

**Rules**:
- `CryptoId` = FK to Wallet.CryptoTypes.CryptoID (174 assets: 12 native coins + 162 ERC-20 tokens)
- `CryptoName` = the human-readable display name (e.g., "Ethereum", "Bitcoin", "Tether") from CryptoTypes.Name
- HASH(CryptoId) distribution means per-crypto aggregations are co-located

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CryptoId) — optimal for per-crypto aggregations and JOINs to other CryptoId-keyed tables. CCI enables efficient analytic aggregation over the small table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All internal ETH wallets | `SELECT * FROM EXW_InternalWallet WHERE CryptoId = 2` |
| Staking pool wallet address | `SELECT Address WHERE InternalWalletTypeId = 7 AND CryptoId = 2` |
| All wallet types present | `SELECT InternalWalletTypeId, InternalType, COUNT(*) AS Wallets GROUP BY InternalWalletTypeId, InternalType` |
| Wallets by crypto | `SELECT CryptoId, CryptoName, COUNT(*) AS WalletCount GROUP BY CryptoId, CryptoName ORDER BY WalletCount DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.Staking_BI_Version_ETH_Transactions | (logical) Address matches staking pool | Cross-reference internal ETH staking wallet to transaction history |
| EXW_Wallet.CryptoTypes | CryptoId | Full crypto asset metadata (not needed for CryptoName — already in table) |

### 3.4 Gotchas

- **Snapshot, not history**: Full TRUNCATE + INSERT on each run — no historical record of past internal wallets. Any wallet removed from the system disappears from this table.
- **InternalType may be NULL**: LEFT JOIN to WalletDB_Dictionary_WalletTypes — if InternalWalletTypeId is not in the dictionary, InternalType is NULL.
- **Gcid ≤ 0 only**: All rows have Gcid ≤ 0. Do not use this table for customer wallet lookups.
- **UpdateDate = Occurred from WalletAssets**: Despite the name "UpdateDate", this column reflects when the crypto asset was first added to the wallet (Wallet.WalletAssets.Occurred) — not when the SP ran. It is a wallet creation timestamp, not an ETL timestamp.
- **CCI on small table**: The Clustered Columnstore Index is optimized for analytic queries. Row-by-row lookups (WHERE Id = '...') are less efficient than on a rowstore index — for PK-style lookups, full-scan the small table.
- **Address CAST widening**: SP casts Address from nvarchar(512) to nvarchar(1000) — no data loss; longest blockchain addresses fit within 512 chars.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Directly inherited from upstream production wiki (verbatim) |
| Tier 2 | Derived from ETL SP code reading or EXW_Staking column mapping |
| Tier 3 | Inferred from column name + data pattern |
| Tier 4 | Best available knowledge — limited confidence (no SP, no upstream wiki) |
| Tier 5 | Name-based inference only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | uniqueidentifier | YES | The wallet's universal business key (from WalletDB.Wallet.Wallets.WalletId via CustomerWalletsView). Referenced by SentTransactions, ReceivedTransactions, Conversions, and all wallet transaction lookups across the WalletDB system. (Tier 1 — WalletDB.Wallet.CustomerWalletsView) |
| 2 | Gcid | int | YES | Global Customer ID of the internal wallet owner. Always ≤ 0 in this table: Gcid=0 = omnibus/system wallets (eToro's pooled holdings); Gcid < 0 = internal service account wallets. (Tier 1 — WalletDB.Wallet.CustomerWalletsView) |
| 3 | CryptoId | int | YES | The cryptocurrency asset associated with this internal wallet. FK to Wallet.CryptoTypes.CryptoID (174 assets: 12 native coins + 162 ERC-20 tokens). HASH distribution key. (Tier 1 — WalletDB.Wallet.CustomerWalletsView) |
| 4 | Address | nvarchar(1000) | YES | Blockchain public address of this internal wallet, cast to nvarchar(1000). Format varies by blockchain: BTC starts with 1/3/bc1, ETH starts with 0x. For ETH staking (type 7), this is the staking pool address. (Tier 1 — WalletDB.Wallet.CustomerWalletsView) |
| 5 | BlockchainProviderWalletId | nvarchar(100) | YES | External wallet identifier assigned by the custody provider (BitGo or CUG). Used for all API interactions with the blockchain custody provider for operational wallets. (Tier 1 — WalletDB.Wallet.CustomerWalletsView) |
| 6 | Status | tinyint | YES | Wallet activation status: 0=Created/Active (wallet fully operational, blockchain address confirmed), 5=Pending activation (awaiting blockchain confirmation). Computed in CustomerWalletsView: `CASE WHEN IsActivated=1 THEN 0 ELSE 5 END`. (Tier 1 — WalletDB.Wallet.CustomerWalletsView) |
| 7 | UpdateDate | datetime | YES | Timestamp when this crypto asset was first added to the wallet (maps to WalletDB.Wallet.WalletAssets.Occurred). Despite the name, this is a wallet creation/association timestamp — not the ETL run time. CAST from datetime2(7) to datetime. (Tier 2 — SP_EXW_InternalWallet; renamed from Occurred) |
| 8 | InternalWalletTypeId | int | YES | Operational purpose of this internal wallet (maps to WalletDB.Wallet.Wallets.WalletTypeId). Values present in this table (Gcid ≤ 0, excluding type 5=Customer): 1=Redeem, 2=Conversion, 3=Funding, 4=Payment, 6=C2F, 7=StakingRefund. (Tier 2 — SP_EXW_InternalWallet; renamed from WalletTypeId) |
| 9 | InternalType | nvarchar(100) | YES | Human-readable label for InternalWalletTypeId. Sourced from CopyFromLake.WalletDB_Dictionary_WalletTypes.Name via LEFT JOIN. May be NULL if wallet type is not in the dictionary. (Tier 2 — SP_EXW_InternalWallet; LEFT JOIN dictionary) |
| 10 | CryptoName | nvarchar(100) | YES | Display name of the cryptocurrency for this wallet (e.g., "Ethereum", "Bitcoin", "Tether"). Sourced from EXW_Wallet.CryptoTypes.Name. CAST to nvarchar(50). (Tier 2 — SP_EXW_InternalWallet; JOIN to CryptoTypes) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Id | WalletDB.Wallet.Wallets (via CustomerWalletsView) | WalletId | Passthrough (uniqueidentifier) |
| Gcid | WalletDB.Wallet.Wallets (via CustomerWalletsView) | Gcid | Passthrough; WHERE Gcid <= 0 |
| CryptoId | WalletDB.Wallet.WalletAssets (via CustomerWalletsView) | CryptoId | Passthrough |
| Address | WalletDB.Wallet.WalletPool.PublicAddress (via CustomerWalletsView) | Address | CAST NVARCHAR(512) → NVARCHAR(1000) |
| BlockchainProviderWalletId | WalletDB.Wallet.WalletPool.ProviderWalletId (via CustomerWalletsView) | BlockchainProviderWalletId | Passthrough |
| Status | CustomerWalletsView computed | Status | Passthrough (0=Active, 5=Pending) |
| UpdateDate | WalletDB.Wallet.WalletAssets (via CustomerWalletsView) | Occurred | Rename + CAST datetime2 → datetime |
| InternalWalletTypeId | WalletDB.Wallet.Wallets (via CustomerWalletsView) | WalletTypeId | Rename only |
| InternalType | WalletDB_Dictionary_WalletTypes (CopyFromLake) | Name | LEFT JOIN on WalletTypeId; CAST NVARCHAR(50) |
| CryptoName | WalletDB.Wallet.CryptoTypes (via EXW_Wallet.CryptoTypes) | Name | JOIN on CryptoId; CAST NVARCHAR(50) |

### 5.2 ETL Pipeline

```
WalletDB.Wallet.Wallets (IsActive=1 filter in CustomerWalletsView)
WalletDB.Wallet.WalletPool (Address, BlockchainProviderWalletId)
WalletDB.Wallet.WalletAssets (CryptoId, Occurred, IsShown=1 filter)
  |-- Generic Pipeline (Bronze export) --|
  v
EXW_Wallet.CustomerWalletsView (External View; 1.76M rows = all active customer wallets)
EXW_Wallet.CryptoTypes (External Table; crypto asset registry)
CopyFromLake.WalletDB_Dictionary_WalletTypes (dictionary copy)
  |-- EXW_dbo.SP_EXW_InternalWallet --|
  |-- TRUNCATE TABLE (full replace) --|
  |-- INSERT SELECT WHERE Gcid <= 0 --|
  v
EXW_dbo.EXW_InternalWallet (current snapshot; CCI, HASH(CryptoId))
  |-- No Gold layer UC target --|
  v
UC Target: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Id | WalletDB.Wallet.Wallets | Source wallet record (WalletId) |
| CryptoId | WalletDB.Wallet.CryptoTypes | Crypto asset registry |
| InternalWalletTypeId | WalletDB_Dictionary_WalletTypes | Wallet type lookup |
| Address (logical) | WalletDB.Staking.StakingExternalAddress | ETH staking pool address match (type 7 wallets) |

### 6.2 Referenced By (other objects point to this)

No objects in EXW_dbo are known to JOIN to this table. Used as a standalone reference table for internal wallet audit and reconciliation.

---

## 7. Sample Queries

### 7.1 All Internal ETH (CryptoId=2) Wallets
```sql
SELECT Id, Gcid, Address, InternalWalletTypeId, InternalType, Status
FROM [EXW_dbo].[EXW_InternalWallet]
WHERE CryptoId = 2
ORDER BY InternalWalletTypeId;
```

### 7.2 Internal Wallet Inventory by Crypto and Type
```sql
SELECT
    CryptoId, CryptoName,
    InternalWalletTypeId, InternalType,
    COUNT(*) AS WalletCount,
    SUM(CASE WHEN Status = 0 THEN 1 ELSE 0 END) AS ActiveCount,
    SUM(CASE WHEN Status = 5 THEN 1 ELSE 0 END) AS PendingCount
FROM [EXW_dbo].[EXW_InternalWallet]
GROUP BY CryptoId, CryptoName, InternalWalletTypeId, InternalType
ORDER BY CryptoId, InternalWalletTypeId;
```

### 7.3 Staking Pool Wallets (Type 7 = StakingRefund)
```sql
SELECT Id, CryptoId, CryptoName, Address, BlockchainProviderWalletId, Status
FROM [EXW_dbo].[EXW_InternalWallet]
WHERE InternalWalletTypeId = 7
ORDER BY CryptoId;
```

---

## 8. Atlassian Knowledge Sources

No direct Confluence sources found for this DWH table. Context from WalletDB.Wallet.CustomerWalletsView wiki: "the primary abstraction layer for accessing active customer wallets"; Gcid=0 = omnibus/system wallets; WalletTypeId 7=StakingRefund. From WalletDB.Wallet.CryptoTypes wiki: 174 assets (12 native coins + 162 ERC-20 tokens); CryptoId=2 is ETH.

---

*Generated: 2026-04-20 | Quality: 8.8/10 | Phases: 11/14 (P9: SP_EXW_InternalWallet found; P10A: CustomerWalletsView + CryptoTypes upstream wikis found)*
*Tiers: 6 T1, 4 T2, 0 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 9/10, Sources: 9/10*
*Object: EXW_dbo.EXW_InternalWallet | Type: Table | Production Source: WalletDB.Wallet.CustomerWalletsView (Gcid ≤ 0)*
