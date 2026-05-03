# EXW_Wallet.WalletPool

> 2.5M-row wallet pool inventory table containing pre-generated blockchain wallet addresses from WalletDB.Wallet.WalletPool, spanning 2018-04-23 to present. Loaded via CopyFromLake Generic Pipeline (Append, every 120 minutes). Covers 12 blockchain crypto types across 2 wallet providers.

| Property | Value |
|----------|-------|
| **Schema** | EXW_Wallet |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.WalletPool via CopyFromLake Generic Pipeline (#652) |
| **Refresh** | Every 120 minutes (Append strategy) |
| **Synapse Distribution** | HASH(WalletId) |
| **Synapse Index** | HEAP + NCI on partition_date |
| **UC Target** | `wallet.bronze_walletdb_wallet_walletpool` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze export (CopyFromLake) |

---

## 1. Business Meaning

EXW_Wallet.WalletPool is the Synapse replica of the production WalletDB.Wallet.WalletPool table, containing the pre-generated pool of blockchain wallet addresses used by the eToro crypto wallet platform (eToroX). Each row represents a single wallet address that has been created on a specific blockchain (identified by BlockchainCryptoId) and is available for allocation to customers.

The table currently holds approximately 2,470,928 rows spanning from April 2018 to April 2026. It covers 12 distinct blockchain crypto types (e.g., BTC, ETH, LTC, ADA, XRP, etc.) and 2 wallet providers (provider 1 with ~2.25M wallets, provider 2 with ~225K wallets).

This table is a CopyFromLake passthrough — no stored procedure writes to it. The Generic Pipeline (#652) copies data from the production WalletDB every 120 minutes using an Append strategy with parquet format. Downstream SPs (SP_EXW_WalletInventory, SP_EXW_Hourly) read from this table to build wallet inventory reports and operational dashboards.

Key views EXW_CustomerWalletsView and EXW_TransactionsView join to this table to resolve blockchain public addresses and provider wallet IDs for customer wallet assignments and transaction sender addresses.

---

## 2. Business Logic

### 2.1 Wallet Pre-Generation Pool

**What**: Blockchain wallet addresses are pre-generated and stored in the pool before being assigned to customers.
**Columns Involved**: Id, WalletId, BlockchainCryptoId, PublicAddress, ProviderWalletId, Created, WalletProviderId
**Rules**:
- Each wallet pool entry has a unique Id (bigint) and a WalletId (GUID) that serves as the distribution key
- A wallet is created for a specific blockchain type (BlockchainCryptoId) and cannot change crypto type after creation
- The PublicAddress is the on-chain address (e.g., Bitcoin base58, Ethereum hex, Cardano bech32)
- ProviderWalletId is the external identifier from the wallet infrastructure provider

### 2.2 Wallet Allocation Flow

**What**: Wallets from the pool are allocated to customers via the Wallets and WalletAssets tables, tracked through EXW_CustomerWalletsView.
**Columns Involved**: WalletId, BlockchainCryptoId, WalletProviderId
**Rules**:
- EXW_CustomerWalletsView joins WalletPool on WalletId to resolve PublicAddress and ProviderWalletId for allocated wallets
- SP_EXW_WalletInventory uses WalletPool joined with WalletPoolStatuses to track which wallets are allocated (have a GCID) vs. free
- WalletProviderId distinguishes between wallet infrastructure providers (2 providers in production)

### 2.3 ETL Partitioning

**What**: CopyFromLake adds temporal partition columns for data management.
**Columns Involved**: etr_y, etr_ym, etr_ymd, partition_date, SynapseUpdateDate
**Rules**:
- etr_y, etr_ym, etr_ymd are string-typed year/month/day partitions derived from the Created date
- partition_date is a date-typed partition column with an NCI index for efficient range queries
- SynapseUpdateDate tracks the CopyFromLake load timestamp (observed as NULL in sampled data — may be populated only on specific load types)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: HASH(WalletId) — optimized for joins on WalletId, which is the primary join key used by EXW_CustomerWalletsView and EXW_TransactionsView
- **Index**: HEAP (no clustered index) with a nonclustered index on partition_date for date-range filtering
- JOINs on WalletId are co-located; JOINs on Id (used by SP_EXW_WalletInventory to join WalletPoolStatuses) require data movement

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| How many wallets exist per blockchain? | `SELECT BlockchainCryptoId, COUNT(*) FROM EXW_Wallet.WalletPool GROUP BY BlockchainCryptoId` |
| Find a wallet by public address | `SELECT * FROM EXW_Wallet.WalletPool WHERE PublicAddress = '...'` (full scan — no index on PublicAddress) |
| Wallet creation trend over time | `SELECT partition_date, COUNT(*) FROM EXW_Wallet.WalletPool GROUP BY partition_date ORDER BY partition_date` (uses NCI) |
| Wallet provider breakdown | `SELECT WalletProviderId, COUNT(*) FROM EXW_Wallet.WalletPool GROUP BY WalletProviderId` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_Wallet.Wallets | Wallets.WalletId = WalletPool.WalletId | Link pool entry to customer wallet record |
| EXW_Wallet.WalletPoolStatuses | WalletPoolStatuses.WalletPoolId = WalletPool.Id | Get latest status for each pool entry |
| EXW_Wallet.CryptoTypes | CryptoTypes.CryptoID = WalletPool.BlockchainCryptoId | Resolve crypto name/details |
| EXW_Wallet.WalletAssets | WalletAssets.WalletId = WalletPool.WalletId | Link to asset balances |

### 3.4 Gotchas

- **SynapseUpdateDate is NULL** in sampled data — do not rely on it for freshness tracking; use partition_date instead
- **PublicAddress is varchar(max)** — not indexable, full scans required for address lookups
- **ProviderWalletId is varchar(4000)** — despite being an external ID, it can be a GUID or long hash depending on the provider
- **No clustered index** (HEAP) — table scans on non-indexed columns can be slow at 2.5M rows
- **Id vs WalletId**: Id is the bigint sequential PK; WalletId is the GUID used for joins. Do not confuse them — most downstream joins use WalletId, but WalletPoolStatuses joins on Id
- **etr_* columns are varchar(max)** — use partition_date (date type, indexed) for date filtering instead

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from ETL/SP code with transform |
| Tier 3 | Grounded in DDL, live data, and SP usage — no upstream wiki available |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | bigint | YES | Sequential primary key identifier for the wallet pool entry. Used as join key by EXW_Wallet.WalletPoolStatuses (WalletPoolId = Id). Production origin: WalletDB.Wallet.WalletPool. (Tier 3 — WalletDB.Wallet.WalletPool) |
| 2 | WalletId | uniqueidentifier | YES | GUID identifier for the wallet pool entry. Distribution key (HASH). Primary join key used by EXW_CustomerWalletsView, EXW_TransactionsView, and EXW_Wallet.Wallets. Each WalletId maps to one pre-generated blockchain address. (Tier 3 — WalletDB.Wallet.WalletPool) |
| 3 | BlockchainCryptoId | int | YES | FK to EXW_Wallet.CryptoTypes.CryptoID. Identifies the blockchain/cryptocurrency type for this wallet address. 12 distinct values observed: top values include 1 (742K wallets), 2 (353K), 6 (326K), 21 (298K), 3 (261K). (Tier 3 — WalletDB.Wallet.WalletPool) |
| 4 | ProviderWalletId | varchar(4000) | YES | External wallet identifier assigned by the wallet infrastructure provider. Format varies by provider — can be a GUID or a hex hash. Used by SP_EXW_WalletInventory as BlockchainProviderWalletId in the inventory report. (Tier 3 — WalletDB.Wallet.WalletPool) |
| 5 | PublicAddress | varchar(max) | YES | Blockchain public address for this wallet. Format varies by chain: Bitcoin (base58 starting with 1/3/bc1), Ethereum (hex 0x prefix), Cardano (bech32 addr1), XRP (r prefix). Used by EXW_CustomerWalletsView as Address and by EXW_TransactionsView as SenderAddress. (Tier 3 — WalletDB.Wallet.WalletPool) |
| 6 | Created | datetime2(7) | YES | Timestamp when the wallet pool entry was created in the production WalletDB system. Range: 2018-04-23 to 2026-04-26. Used by downstream SPs to filter wallet age (e.g., SP_EXW_Transactions_Monthly filters on Created < @EndDate_m). (Tier 3 — WalletDB.Wallet.WalletPool) |
| 7 | WalletProviderId | int | YES | Identifier for the wallet infrastructure provider that generated this address. 2 distinct values: 1 (~2.25M wallets, ~91%), 2 (~225K wallets, ~9%). Passed through to EXW_CustomerWalletsView and Hourly_WalletAllocations. (Tier 3 — WalletDB.Wallet.WalletPool) |
| 8 | etr_y | varchar(max) | YES | ETL partition column: year extracted from Created date (e.g., "2022"). Added by CopyFromLake pipeline for data partitioning. String type — use partition_date for filtering. (Tier 3 — CopyFromLake pipeline) |
| 9 | etr_ym | varchar(max) | YES | ETL partition column: year-month extracted from Created date (e.g., "2022-03"). Added by CopyFromLake pipeline for data partitioning. String type — use partition_date for filtering. (Tier 3 — CopyFromLake pipeline) |
| 10 | etr_ymd | varchar(max) | YES | ETL partition column: year-month-day extracted from Created date (e.g., "2022-03-18"). Added by CopyFromLake pipeline for data partitioning. String type — use partition_date for filtering. (Tier 3 — CopyFromLake pipeline) |
| 11 | SynapseUpdateDate | datetime | YES | Timestamp of the CopyFromLake load into Synapse. Observed as NULL in all sampled rows — may only be populated on specific load events or legacy loads. (Tier 3 — CopyFromLake pipeline) |
| 12 | partition_date | date | YES | Date-based partition column with nonclustered index (XI_partition_date). Matches etr_ymd as a proper date type. Preferred column for date-range filtering due to indexing and native date type. (Tier 3 — CopyFromLake pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| Id | WalletDB.Wallet.WalletPool | Id | Passthrough |
| WalletId | WalletDB.Wallet.WalletPool | WalletId | Passthrough |
| BlockchainCryptoId | WalletDB.Wallet.WalletPool | BlockchainCryptoId | Passthrough |
| ProviderWalletId | WalletDB.Wallet.WalletPool | ProviderWalletId | Passthrough |
| PublicAddress | WalletDB.Wallet.WalletPool | PublicAddress | Passthrough |
| Created | WalletDB.Wallet.WalletPool | Created | Passthrough |
| WalletProviderId | WalletDB.Wallet.WalletPool | WalletProviderId | Passthrough |
| etr_y | — | — | CopyFromLake ETL: year from Created |
| etr_ym | — | — | CopyFromLake ETL: year-month from Created |
| etr_ymd | — | — | CopyFromLake ETL: year-month-day from Created |
| SynapseUpdateDate | — | — | CopyFromLake ETL: load timestamp |
| partition_date | — | — | CopyFromLake ETL: date partition |

### 5.2 ETL Pipeline

```
WalletDB.Wallet.WalletPool (production, WalletDB server)
  |-- Generic Pipeline #652 (Append, every 120 min, parquet) ---|
  v
Bronze/WalletDB/Wallet/WalletPool/ (Data Lake)
  |-- CopyFromLake (staging → target) ---|
  v
CopyFromLake_staging.EXW_Wallet.WalletPool (ROUND_ROBIN, HEAP)
  |-- CopyFromLake merge/swap ---|
  v
EXW_Wallet.WalletPool (2.5M rows, HASH(WalletId), HEAP)
  |-- Generic Pipeline (Bronze export) ---|
  v
wallet.bronze_walletdb_wallet_walletpool (UC Bronze)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| BlockchainCryptoId | EXW_Wallet.CryptoTypes | FK to CryptoTypes.CryptoID — resolves crypto name and blockchain details |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---|---|---|
| WalletId | EXW_Wallet.EXW_CustomerWalletsView | JOIN on WalletPool.WalletId — resolves PublicAddress (as Address) and ProviderWalletId (as BlockchainProviderWalletId) |
| WalletId | EXW_Wallet.EXW_TransactionsView | JOIN on WalletPool.WalletId via trx_out CTE — resolves PublicAddress as SenderAddress |
| WalletId, Id | EXW_dbo.SP_EXW_WalletInventory | Reads WalletPool to build wallet inventory; joins WalletPoolStatuses on WalletPool.Id |
| WalletId | EXW_dbo.SP_EXW_Hourly | Reads WalletPool indirectly via EXW_CustomerWalletsView and embedded inventory logic |
| WalletId | EXW_dbo.SP_EXW_Transactions_Monthly | Reads WalletPool via CustomerWalletsView JOIN for wallet-to-customer mapping |
| WalletId | EXW_dbo.SP_EXW_FinanceReportsBalancesNew | Reads WalletPool for finance balance reports |

---

## 7. Sample Queries

### 7.1 Wallet Pool Inventory by Blockchain Type

```sql
SELECT
    ct.Name AS CryptoName,
    ct.CryptoID AS BlockchainCryptoId,
    COUNT(*) AS TotalWallets,
    MIN(wp.Created) AS EarliestCreated,
    MAX(wp.Created) AS LatestCreated
FROM EXW_Wallet.WalletPool wp
JOIN EXW_Wallet.CryptoTypes ct ON ct.CryptoID = wp.BlockchainCryptoId
GROUP BY ct.Name, ct.CryptoID
ORDER BY TotalWallets DESC;
```

### 7.2 Daily Wallet Creation Trend (Last 30 Days)

```sql
SELECT
    partition_date,
    COUNT(*) AS WalletsCreated,
    COUNT(DISTINCT BlockchainCryptoId) AS CryptoTypes
FROM EXW_Wallet.WalletPool
WHERE partition_date >= DATEADD(DAY, -30, GETDATE())
GROUP BY partition_date
ORDER BY partition_date DESC;
```

### 7.3 Wallet Provider Distribution

```sql
SELECT
    WalletProviderId,
    COUNT(*) AS TotalWallets,
    COUNT(DISTINCT BlockchainCryptoId) AS CryptoTypesServed,
    MIN(Created) AS FirstWallet,
    MAX(Created) AS LastWallet
FROM EXW_Wallet.WalletPool
GROUP BY WalletProviderId;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode).

---

*Generated: 2026-04-30 | Quality: pending/10 | Phases: 13/14*
*Tiers: 0 T1, 0 T2, 12 T3, 0 T4, 0 T5 | Elements: 12/12, Logic: 3/10, Lineage: complete*
*Object: EXW_Wallet.WalletPool | Type: Table | Production Source: WalletDB.Wallet.WalletPool via CopyFromLake*
