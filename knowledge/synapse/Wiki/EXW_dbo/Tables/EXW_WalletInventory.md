# EXW_dbo.EXW_WalletInventory

> 2,748,419-row live inventory of all blockchain wallets in the eToro Wallet pool, refreshed daily by SP_EXW_WalletInventory. Each row represents one wallet slot — either unoccupied (Occupied=0, GCID NULL, in the reserve pool) or allocated to a customer (Occupied=1, GCID assigned). Covers 702,412 distinct customers and 30+ crypto types. Sourced from WalletDB.Wallet.WalletPool + WalletPoolStatuses + CustomerWalletsView.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.WalletPool + WalletPoolStatuses + CustomerWalletsView + WalletAddresses |
| **Refresh** | Daily TRUNCATE + INSERT via SP_EXW_WalletInventory (UpdateDate = today) |
| **Synapse Distribution** | HASH(GCID) |
| **Synapse Index** | HEAP |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

EXW_WalletInventory is the daily snapshot of every blockchain wallet in the eToro Wallet system, combining the pre-provisioned pool wallets (not yet assigned to users) with the wallet-to-customer assignments. Each row represents one wallet for one blockchain — either a pool slot awaiting assignment (`Occupied=0`, `GCID` NULL, `PublicAddress` NULL) or a live customer wallet (`Occupied=1`, `GCID` set, `PublicAddress` populated).

The table answers the question "Which wallets does customer X have?" and "How many wallets are available for coin Y in the pool?" The pool architecture exists because creating on-chain wallets takes time — eToro pre-generates wallets in bulk so new customers can be assigned a wallet instantly.

As of last refresh: 1,771,467 occupied wallets (64%) belong to 702,412 distinct customers; 976,952 wallets (36%) are in the free pool. Top cryptos by wallet count: BTC (742K), ETH (353K), LTC (326K), XLM (298K), BCH (261K), XRP (137K). Coverage from 2018-04-23 to 2026-04-09 (Created); actively refreshed daily.

**Key structural observations**:
- The WHERE filter `CryptoID = BlockchainCryptoId` in the SP means only native blockchain coin wallets are included — ERC-20 tokens (e.g., USDEX on ETH blockchain) are excluded because their platform CryptoID differs from the Ethereum BlockchainCryptoId.
- `WalletPoolID` = `WalletID` in 100% of rows — this is a duplicate column.
- For unoccupied pool wallets: `GCID`, `PublicAddress`, `Allocated`, `ProviderWalletID`, and `NormalizedAddress` are all NULL simultaneously.

---

## 2. Business Logic

### 2.1 Pool vs. Occupied Wallet Architecture

**What**: The wallet inventory contains two distinct populations in a single table: free pool wallets and customer-owned wallets.

**Columns Involved**: `Occupied`, `GCID`, `PublicAddress`, `Allocated`, `WalletID`

**Rules**:
- `Occupied=0`: Wallet is in the reserve pool — not yet assigned to any customer. `GCID`, `PublicAddress`, `Allocated`, `ProviderWalletID`, and `NormalizedAddress` are all NULL.
- `Occupied=1`: Wallet has been assigned to a customer. All columns are populated.
- `Allocated` (date): When Occupied=1, this is the date the wallet was assigned to the user (CAST from CustomerWalletsView.Occurred).
- Pool wallets are created by background processes that monitor pool levels and top up when supply drops below thresholds.
- When a user acquires a new crypto, the system calls `Wallet.GetFreeWalletFromPool` → picks an available Verified wallet from the pool → calls `Wallet.AssociateWalletToCustomer`.

### 2.2 Wallet Pool Status Lifecycle

**What**: Each wallet transitions through defined lifecycle states tracked in `LastWalletPoolStatus` / `WalletStatus`.

**Columns Involved**: `LastWalletPoolStatus`, `WalletStatus`

**Rules**:
- Both columns represent the same state: `LastWalletPoolStatus` is the integer code, `WalletStatus` is the denormalized name string.
- Status lifecycle: 1=Pending → 2=Verified → 4=FundingInitiated → 5=FundingSent → 6=FundingVerified → 11=VerifiedForAssign
- Error states: 3=Failed, 7=FundingFailed, 10=Timeout
- Distribution in this table: 2=Verified (2,532,501 wallets), 6=FundingVerified (208,808), 3=Failed (4,682), 1=Pending (2,411), 11=VerifiedForAssign (17)
- `SP_EXW_WalletInventory` selects the LATEST status per wallet via `ROW_NUMBER() OVER (PARTITION BY WalletPoolId ORDER BY Occurred DESC)` from WalletPoolStatuses.
- Only wallets with `WalletStatus=Verified` (status 2) are typically available for assignment to new customers.

### 2.3 Native Coin Filter (ERC-20 Exclusion)

**What**: The SP includes only wallets where the platform CryptoID equals the BlockchainCryptoId, excluding ERC-20 derivative tokens.

**Columns Involved**: `CryptoID`, `BlockchainCryptoId`

**Rules**:
- `WHERE dd.CryptoID = dd.BlockchainCryptoId` filters out wallets where the platform crypto (ERC-20 token) differs from the underlying blockchain.
- Example excluded: USDEX (CryptoID=102) on Ethereum blockchain (BlockchainCryptoId=2) — 102 ≠ 2, excluded.
- Example included: SOL wallet (CryptoID=64, BlockchainCryptoId=64) — 64=64, included.
- As a result: `CryptoID` = `BlockchainCryptoId` for every row in this table.

### 2.4 Promotion Wallet Tracking

**What**: Some pool wallets are earmarked for promotional campaigns via `PromotionTagID`.

**Columns Involved**: `PromotionTagID`, `IsPromotionReady`

**Rules**:
- `PromotionTagID`: NULL for standard wallets (2,538,904 rows); set to promotion ID when reserved for a campaign. FK to Wallet.PromotionTags.
- `IsPromotionReady`: 1 if `PromotionTagID=1` AND `CryptoID` is a supported blockchain crypto (i.e., in EXW_Wallet.CryptoTypes); else 0.
- Promotion wallets are typically pre-funded (FundingVerified status) before being distributed to promotion participants.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH on GCID — good for customer-scoped queries and JOINs to EXW_DimUser. Unoccupied wallets have NULL GCID, so they land on the same distribution node as GCID=NULL (all together). HEAP index: no CCI; full table scans are viable at 2.7M rows.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|----------------------|
| All wallets for a customer | `WHERE GCID = @gcid AND Occupied = 1` |
| Available pool wallets for BTC | `WHERE CryptoName = 'BTC' AND Occupied = 0 AND WalletStatus = 'Verified'` |
| Pool depth by crypto | `WHERE Occupied = 0 GROUP BY CryptoID, CryptoName` |
| Customer wallet allocation date | `SELECT GCID, CryptoName, Allocated WHERE Occupied = 1` |
| Wallets by status | `GROUP BY LastWalletPoolStatus, WalletStatus ORDER BY COUNT(*) DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.EXW_DimUser | `ON EXW_WalletInventory.GCID = EXW_DimUser.GCID` | Enrich with user demographics |
| EXW_dbo.EXW_FactTransactions | `ON EXW_WalletInventory.WalletID = EXW_FactTransactions.WalletID` | Link wallets to their transactions |

### 3.4 Gotchas

- **WalletPoolID = WalletID always**: Do not use `WalletPoolID` — it is a duplicate of `WalletID` and adds no information.
- **ERC-20 wallets are excluded**: This table does NOT contain USDEX, EURX, or other ERC-20 token wallets. Only native blockchain coin wallets appear.
- **Unoccupied wallets have NULL GCID**: Filtering `WHERE GCID IS NOT NULL` is equivalent to `WHERE Occupied = 1`.
- **CryptoID = BlockchainCryptoId for all rows**: The SP WHERE filter guarantees this — no need to join separately.
- **UpdateDate is today**: Unlike historical snapshots, this table is refreshed daily. UpdateDate reflects the current load, not the wallet creation.
- **HASH(GCID) with NULL GCID**: The 976,952 pool wallets (Occupied=0) all have NULL GCID, so they hash to a single distribution node — joins involving pool wallets only will create data skew.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki (WalletDB.Wallet.WalletPool, WalletPoolStatuses, CustomerWalletsView, or WalletAddresses) |
| Tier 2 | Derived from SP code analysis, JOIN patterns, or live data sampling |
| Tier 4 | Best available knowledge — limited confidence; inferred from data observation |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | WalletID | nvarchar(max) | YES | Internal wallet identifier (GUID). The primary business key used across the wallet system. Unique constraint. FK target for Wallet.WalletAddresses, Wallet.ReceivedTransactions, and Wallet.AmlValidations. Also referenced by Wallet.Wallets (logical link, not FK). Stored as nvarchar(max) in Synapse (source is uniqueidentifier). (Tier 1 — WalletDB.Wallet.WalletPool) |
| 2 | CryptoID | int | YES | Platform cryptocurrency identifier for this wallet. Equals BlockchainCryptoId for all rows due to SP WHERE filter (ERC-20 token wallets are excluded). FK to EXW_Wallet.CryptoTypes.CryptoID. (Tier 2 — SP_EXW_WalletInventory) |
| 3 | ProviderWalletID | nvarchar(100) | YES | Wallet identifier assigned by the external custody provider (BitGo or CUG). Used for all API interactions with the provider. Format varies by provider. NULL for unoccupied pool wallets. (Tier 1 — WalletDB.Wallet.WalletPool) |
| 4 | PublicAddress | nvarchar(512) | YES | Blockchain address associated with this wallet. Users send crypto to this address. NULL during initial creation before address generation completes. Format depends on blockchain (e.g., bc1... for BTC, 0x... for ETH). NULL for unoccupied pool wallets. (Tier 1 — WalletDB.Wallet.WalletPool) |
| 5 | Created | datetime | YES | Timestamp when this pool wallet was created. Used for pool age monitoring and FIFO assignment ordering. DWH note: CAST from datetime2 source. (Tier 1 — WalletDB.Wallet.WalletPool) |
| 6 | Occupied | int | YES | Whether this wallet has been assigned to a customer: 1=occupied (GCID is set), 0=available in the pool. Computed by SP: CASE WHEN GCID IS NOT NULL THEN 1 ELSE 0 END. (Tier 2 — SP_EXW_WalletInventory) |
| 7 | GCID | int | YES | Global Customer ID of the wallet owner. For customer wallets (type 5), this is the real user. For system wallets (types 1-4, 6-7), this is a service account. Gcid=0 conventionally indicates omnibus/system wallets. From Wallet.Wallets.Gcid. NULL for unoccupied pool wallets. HASH distribution key for this table. (Tier 1 — WalletDB.Wallet.CustomerWalletsView) |
| 8 | UpdateDate | datetime | YES | Timestamp of the last ETL data load. Set to GETDATE() at SP execution — reflects the daily refresh date, not the wallet creation or assignment date. (Tier 2 — SP_EXW_WalletInventory) |
| 9 | WalletPoolID | nvarchar(max) | YES | Duplicate of WalletID. Both WalletID and WalletPoolID are set to WalletPool.WalletId in the SP. Loading artifact — carries no additional information. Do not use for filtering or grouping. (Tier 4 — data observation) |
| 10 | CryptoName | nvarchar(256) | YES | Human-readable name of the cryptocurrency for this wallet (e.g., BTC, ETH, SOL). Denormalized from EXW_Wallet.CryptoTypes. Mirrors the CryptoID selection logic: ERC-20 name takes precedence if available, else blockchain native name. (Tier 2 — EXW_Wallet.CryptoTypes) |
| 11 | LastWalletPoolStatus | tinyint | YES | The lifecycle status: 1=Pending, 2=Verified, 3=Failed, 4=FundingInitiated, 5=FundingSent, 6=FundingVerified, 7=FundingFailed, 10=Timeout, 11=VerifiedForAssign. FK to Dictionary.WalletPoolStatuses. DWH note: derived as the latest status event per wallet via ROW_NUMBER() OVER (PARTITION BY WalletPoolId ORDER BY Occurred DESC) in SP. (Tier 1 — WalletDB.Wallet.WalletPoolStatuses) |
| 12 | WalletStatus | varchar(64) | YES | Denormalized string name for LastWalletPoolStatus. Values: Pending, Verified, Failed, FundingInitiated, FundingSent, FundingVerified, FundingFailed, Timeout, VerifiedForAssign. Joined from CopyFromLake.WalletDB_Dictionary_WalletPoolStatuses. (Tier 2 — WalletDB_Dictionary_WalletPoolStatuses) |
| 13 | PromotionTagID | int | YES | Links to a promotional campaign if this wallet is part of a promotion. NULL for standard wallets. FK to Wallet.PromotionTags.Id. (Tier 1 — WalletDB.Wallet.WalletPoolStatuses) |
| 14 | IsPromotionReady | int | YES | Whether this wallet is eligible to be distributed as a promotion: 1=ready (PromotionTagId=1 AND CryptoID is a supported blockchain crypto), 0=not ready. Computed by SP CASE expression. (Tier 2 — SP_EXW_WalletInventory) |
| 15 | Allocated | date | YES | Timestamp when this crypto asset was first added to the wallet (when the user first acquired this crypto). From Wallet.WalletAssets.Occurred. Used for portfolio age tracking and ordering. DWH note: CAST to DATE type; NULL for unoccupied pool wallets. (Tier 1 — WalletDB.Wallet.CustomerWalletsView) |
| 16 | BlockchainCryptoId | int | YES | The blockchain this pool wallet was created for. FK to Wallet.BlockchainCryptos.Id. Determines which blockchain network the PublicAddress belongs to. Always equals CryptoID due to SP WHERE filter. (Tier 1 — WalletDB.Wallet.WalletPool) |
| 17 | BlockchainCryptoName | varchar(255) | YES | Blockchain network name for this wallet (e.g., BTC, ETH, SOL). Denormalized from EXW_Wallet.BlockchainCryptos by joining on BlockchainCryptoId. Always equals CryptoName due to the native-coin-only filter. (Tier 2 — EXW_Wallet.BlockchainCryptos) |
| 18 | CreatedDateID | int | YES | Date integer derived from Created in YYYYMMDD format. Computed by SP: CAST(CONVERT(VARCHAR(8), Created, 112) AS INT). Useful for date-based partitioning and joining to calendar dimension tables. (Tier 2 — SP_EXW_WalletInventory) |
| 19 | NormalizedAddress | varchar(512) | YES | Computed PERSISTED column that strips protocol prefixes (before ':') and query parameters (after '?') from the Address. Enables consistent address matching regardless of formatting. Indexed for lookup performance. Passthrough from Wallet.WalletAddresses (IsMain=1). NULL for unoccupied pool wallets. (Tier 1 — WalletDB.Wallet.WalletAddresses) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|--------------|-----------|
| WalletID, WalletPoolID | WalletDB.Wallet.WalletPool | WalletId | Passthrough (GUID→nvarchar(max)); WalletPoolID is duplicate |
| BlockchainCryptoId | WalletDB.Wallet.WalletPool | BlockchainCryptoId | Passthrough |
| PublicAddress | WalletDB.Wallet.WalletPool (via CustomerWalletsView) | PublicAddress | Passthrough; NULL for unoccupied |
| ProviderWalletID | WalletDB.Wallet.WalletPool (via CustomerWalletsView) | ProviderWalletId | Passthrough; NULL for unoccupied |
| Created | WalletDB.Wallet.WalletPool | Created | CAST to DATETIME |
| GCID | WalletDB.Wallet.CustomerWalletsView | Gcid | Passthrough rename; NULL for unoccupied |
| PublicAddress | WalletDB.Wallet.CustomerWalletsView | Address | Passthrough; NULL for unoccupied |
| Allocated | WalletDB.Wallet.CustomerWalletsView | Occurred | CAST to DATE; NULL for unoccupied |
| LastWalletPoolStatus | WalletDB.Wallet.WalletPoolStatuses | WalletPoolStatusId | Latest via ROW_NUMBER window |
| PromotionTagID | WalletDB.Wallet.WalletPoolStatuses | PromotionTagId | Passthrough from latest event |
| WalletStatus | WalletDB_Dictionary_WalletPoolStatuses | Name | JOIN on LastWalletPoolStatus |
| NormalizedAddress | WalletDB.Wallet.WalletAddresses | NormalizedAddress | Passthrough (IsMain=1); NULL for unoccupied |
| CryptoID, CryptoName | EXW_Wallet.CryptoTypes | CryptoID, Name | CASE (ERC preferred); WHERE CryptoID=BlockchainCryptoId |
| BlockchainCryptoName | EXW_Wallet.BlockchainCryptos | Name | JOIN on BlockchainCryptoId |
| Occupied | SP computation | — | CASE WHEN GCID IS NOT NULL THEN 1 ELSE 0 END |
| UpdateDate | ETL process | — | GETDATE() |
| CreatedDateID | SP computation | — | YYYYMMDD int from Created |
| IsPromotionReady | SP computation | — | CASE PromotionTagId=1 AND CryptoID in supported list |

### 5.2 ETL Pipeline

```
WalletDB (etoro-walletdb-prod)
├── Wallet.WalletPool (pool wallet registry — 2.47M rows)
│     └── LATEST STATUS via ROW_NUMBER from Wallet.WalletPoolStatuses
├── CopyFromLake.WalletDB_Dictionary_WalletPoolStatuses (status name dict, Bronze)
├── Wallet.CustomerWalletsView ← occupied-wallet assignments (GCID, Address, OccurredERC)
│     └── Wallet.WalletAddresses (NormalizedAddress, IsMain=1)
├── EXW_Wallet.CryptoTypes (CryptoName)
└── EXW_Wallet.BlockchainCryptos (BlockchainCryptoName)
     |
     |-- [SP_EXW_WalletInventory — TRUNCATE+INSERT daily] --|
     |   Filter: WHERE CryptoID = BlockchainCryptoId (native coins only)
     v
EXW_dbo.EXW_WalletInventory (2,748,419 rows, HASH(GCID), HEAP)
     |
     |-- [Read by SP_New_UsersAndWallets_Inventory, SP_EXW_Inventory_Snapshot_History] --|
     v
New_UsersAndWallets_Inventory / EXW_Inventory_Snapshot_History
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| GCID | EXW_dbo.EXW_DimUser | User dimension for wallet owners |
| CryptoID | EXW_Wallet.CryptoTypes | Crypto asset reference |
| BlockchainCryptoId | EXW_Wallet.BlockchainCryptos | Blockchain network reference |
| WalletID | WalletDB.Wallet.WalletPool | Production source row |

### 6.2 Referenced By (other objects point to this)

| Source Object | Join Condition | Purpose |
|--------------|---------------|---------|
| EXW_dbo.SP_New_UsersAndWallets_Inventory | WalletID | New user + wallet population analysis |
| EXW_dbo.SP_EXW_Inventory_Snapshot_History | WalletID / GCID | Daily inventory snapshot archival |

---

## 7. Sample Queries

### 7.1 All wallets for a customer
```sql
SELECT WalletID, CryptoName, WalletStatus, PublicAddress, Allocated, NormalizedAddress
FROM [EXW_dbo].[EXW_WalletInventory]
WHERE GCID = @gcid
  AND Occupied = 1
ORDER BY Allocated DESC
```

### 7.2 Pool depth by crypto (available inventory)
```sql
SELECT CryptoName, COUNT(*) AS available_pool_count
FROM [EXW_dbo].[EXW_WalletInventory]
WHERE Occupied = 0
  AND WalletStatus = 'Verified'
GROUP BY CryptoName
ORDER BY available_pool_count ASC  -- ASC to spot thin cryptos
```

### 7.3 Recently allocated wallets
```sql
SELECT GCID, CryptoName, Allocated, PublicAddress, WalletStatus
FROM [EXW_dbo].[EXW_WalletInventory]
WHERE Occupied = 1
  AND Allocated >= CAST(GETDATE()-7 AS DATE)
ORDER BY Allocated DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-20 | Quality: 9.4/10 (P16 adversarial: 9.35) | Phases: 14/14*
*Tiers: 10 T1, 8 T2, 0 T3, 1 T4, 0 T5 | Elements: 19/19, Logic: 9/10, Lineage: 9/10*
*Object: EXW_dbo.EXW_WalletInventory | Type: Table | Production Source: WalletDB.Wallet.WalletPool*
