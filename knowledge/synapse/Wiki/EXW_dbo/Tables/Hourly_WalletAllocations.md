# EXW_dbo.Hourly_WalletAllocations

> Hourly row-level extract of recent wallet allocation events — one row per customer-crypto wallet allocation where Occurred falls within the rolling 7-day window, rebuilt on every SP_EXW_Hourly run. Covers all active customer wallets (WalletTypeId = 5 in practice), including ERC-20 tokens (unlike Hourly_WalletInventory which excludes them). Primary source for per-customer, per-crypto wallet assignment activity dashboards.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | EXW_Wallet.CustomerWalletsView (from WalletDB.Wallet.CustomerWalletsView) |
| **Refresh** | Hourly — TRUNCATE + INSERT on each run |
| **Synapse Distribution** | HASH (GCID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — Synapse-only operational KPI feed |

---

## 1. Business Meaning

Hourly_WalletAllocations provides a rolling 7-day extract of customer wallet allocation events — each row representing a wallet that was assigned to a customer (Occurred within the last 7 days), along with the wallet's blockchain address, crypto type, status, and provider details. It is one of six tables rebuilt each hour by SP_EXW_Hourly.

Unlike the other five Hourly tables (which are aggregates), Hourly_WalletAllocations is a **row-level** extract. Each row corresponds to a specific wallet allocation: one customer (GCID) × one crypto (CryptoID) × one blockchain address. This granularity enables dashboards to answer "which customers received wallets this week?" and "what's the current address for a recently allocated wallet?"

**Scope**: Wallets where `CustomerWalletsView.Occurred >= last 7 days`. In practice only WalletTypeId=5 (Customer wallets) appear in any 7-day window, since system wallet types (Redeem, Conversion, Funding, etc.) are not routinely created on a daily basis.

**Includes ERC-20 tokens**: Unlike Hourly_WalletInventory, this table includes ERC-20 token wallets (e.g., USDC, LINK) — these have `CryptoID ≠ BlockchainCryptoId` and `CrytpoType = 'ERCCryptos'`.

**Current footprint** (as of 2026-04-20): 9,877 rows, 44 distinct cryptos (17 native + 27 ERC-20 tokens), 3,178 distinct customers, Occurred range 2026-04-13→2026-04-20. Top allocations: BTC (1,867), ETH (1,554), XRP (789), SOL (648), USDC/ERCCryptos (444). 96.9% of rows are Status=0 (fully active); 3.1% Status=5 (pending activation).

---

## 2. Business Logic

### 2.1 7-Day Rolling Allocation Window

**What**: Only wallets allocated within the last ~7 days are included.

**Columns Involved**: Occurred, ReportDate

**Rules**:
- Filter: `cwv.Occurred >= Convert(DateTime, DATEDIFF(DAY, 7, GETDATE()))` — effective behavior is ~7-day lookback (same expression as Hourly_RedeemActivity)
- `Occurred` = the timestamp when this crypto asset was first added to the wallet (from WalletAssets.Occurred — when the customer first acquired this crypto)
- TRUNCATE before INSERT means only the latest run's data persists — no historical accumulation

### 2.2 ERC-20 vs Native Coin Classification

**What**: CrytpoType classifies each wallet allocation as native coin or ERC-20 token.

**Columns Involved**: CrytpoType, CryptoID, BlockchainCryptoId

**Rules**:
- `CASE WHEN CryptoId = BlockchainCryptoId THEN 'MainCryptos' ELSE 'ERCCryptos' END`
- Native coins (BTC, ETH, XRP, etc.): CryptoID = BlockchainCryptoId → `MainCryptos`
- ERC-20 tokens (USDC, LINK, COMP, etc.): CryptoID ≠ BlockchainCryptoId (token shares ETH blockchain) → `ERCCryptos`
- Current split: 6,839 MainCryptos (69.2%), 3,038 ERCCryptos (30.8%)
- **Note**: column name typo in DDL and SP — `CrytpoType` (transposed letters) is the actual column name

### 2.3 Wallet Activation Status

**What**: Status reflects whether the wallet has completed blockchain activation.

**Columns Involved**: Status, IsActive

**Rules**:
- `Status` is computed in CustomerWalletsView: `CASE WHEN IsActivated=1 THEN 0 ELSE 5 END`
- Status=0 (Active): wallet fully operational — 9,571 rows (96.9%)
- Status=5 (Pending): wallet awaiting blockchain confirmation — 306 rows (3.1%)
- `IsActive`: always 1 in this table (CustomerWalletsView only exposes IsActive=1 wallets)

### 2.4 AllocationDate Column Design Limitation

**What**: The `AllocationDate` column is intended to capture the wallet allocation date but always equals the SP run date.

**Columns Involved**: AllocationDate, ReportDate, Occurred

**Rules**:
- `allocationdate = CAST(GETDATE() AS DATE)` in SP — hardcoded to today
- `AllocationDate = ReportDate` always (both are CAST(GETDATE() AS DATE))
- The actual wallet allocation date is `CAST(Occurred AS DATE)`, not `AllocationDate`
- **To query allocation date**: use `CAST(Occurred AS DATE)` or `CAST(Occurred AS DATE)` for date-level analysis

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(GCID) — unique among the six Hourly tables (all others use HASH(CryptoID)). Optimized for per-customer queries (WHERE GCID = @gcid). HEAP — full scans inexpensive for 9,877 rows.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|----------------------|
| New wallets allocated today | `WHERE CAST(Occurred AS DATE) = CAST(GETDATE() AS DATE)` |
| Customer's recently allocated wallets | `WHERE GCID = @gcid ORDER BY Occurred DESC` |
| ERC-20 allocations this week | `WHERE CrytpoType = 'ERCCryptos'` |
| Allocations by crypto in last 7 days | `GROUP BY CryptoID ORDER BY COUNT(1) DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.Hourly_WalletInventory | `CryptoID` | Compare per-wallet allocation events against crypto-level inventory counts |
| EXW_dbo.EXW_DimUser | `GCID` | Enrich allocations with customer profile data |

### 3.4 Gotchas

- **HASH(GCID) not HASH(CryptoID)**: Unlike the other five Hourly tables, this table is distributed on GCID. Cross-table JOINs on CryptoID will not be co-located and may incur data movement
- **`AllocationDate` always equals `ReportDate`**: Despite the name, this column does NOT contain the wallet allocation date. Use `CAST(Occurred AS DATE)` for the actual allocation date
- **`CrytpoType` is a typo**: The column name is `CrytpoType` (not `CryptoType`). This typo is in both the DDL and the SP — always use the exact DDL spelling in queries
- **WalletTypeId=5 only (in practice)**: No hard filter — system wallet types (1-4, 6-7) don't appear in 7-day rolling windows because they aren't created on a rolling daily basis
- **`IsActive` is always 1**: CustomerWalletsView enforces `WHERE IsActive = 1`, so this column carries no discriminating information in this table
- **7-day window TRUNCATE**: No historical allocation data beyond ~7 days is retained in this table. For longer-term analysis, use EXW_dbo.EXW_DimUser or WalletDB source tables

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki (WalletDB.Wallet.CustomerWalletsView) |
| Tier 2 | ETL-computed or SP-derived; not in upstream wiki |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | nvarchar(1000) | NULL | The wallet's universal business key (aliased from Wallets.WalletId). Used as the primary identifier across the entire wallet system — referenced by SentTransactions, ReceivedTransactions, Conversions, Payments, Redemptions, and all balance/transaction lookups. DWH note: nvarchar(1000) in EXW vs uniqueidentifier in WalletDB source (GUID serialized as string from Parquet). (Tier 1 — WalletDB.Wallet.CustomerWalletsView) |
| 2 | GCID | int | NULL | Global Customer ID of the wallet owner. For customer wallets (type 5, 99.99% of rows), this is the real user. For system wallets (types 1-4, 6-7), this is a service account. Gcid=0 conventionally indicates omnibus/system wallets. DWH note: int in EXW DDL vs bigint in WalletDB source — no truncation risk in current data. Distribution key. (Tier 1 — WalletDB.Wallet.CustomerWalletsView) |
| 3 | CryptoID | int | NULL | The cryptocurrency asset visible in this wallet. FK to Wallet.CryptoTypes.CryptoID. Combined with Gcid for the standard wallet lookup pattern: WHERE Gcid = @gcid AND CryptoId = @cryptoId. Includes ERC-20 token CryptoIDs (CryptoID ≠ BlockchainCryptoId). (Tier 1 — WalletDB.Wallet.CustomerWalletsView) |
| 4 | Address | nvarchar(512) | NULL | Blockchain public address associated with this wallet. Users send/receive crypto at this address. Format varies by blockchain: BTC starts with 1/3/bc1, ETH starts with 0x, SOL is base58. Aliased from Wallet.WalletPool.PublicAddress. May be NULL during initial creation before address generation completes. (Tier 1 — WalletDB.Wallet.CustomerWalletsView) |
| 5 | BlockchainProviderWalletId | nvarchar(1000) | NULL | External wallet identifier assigned by the custody provider (BitGo or CUG). Used for all API interactions with the provider. Aliased from Wallet.WalletPool.ProviderWalletId. DWH note: nvarchar(1000) in EXW DDL vs nvarchar(100) in WalletDB source. (Tier 1 — WalletDB.Wallet.CustomerWalletsView) |
| 6 | Occurred | datetime | NULL | Timestamp when this crypto asset was first added to the wallet (when the user first acquired this crypto). From Wallet.WalletAssets.Occurred. Used for portfolio age tracking and ordering. DWH note: datetime in EXW DDL vs datetime2(7) in WalletDB source (precision reduction). Filter anchor: WHERE Occurred >= last 7 days. **Use CAST(Occurred AS DATE) for the actual allocation date** (not AllocationDate). (Tier 1 — WalletDB.Wallet.CustomerWalletsView) |
| 7 | WalletTypeId | int | NULL | Operational purpose of the wallet: 1=Redeem, 2=Conversion, 3=Funding, 4=Payment, 5=Customer (99.99%), 6=C2F, 7=StakingRefund. FK to Dictionary.WalletTypes. DWH note: int in EXW DDL vs tinyint in WalletDB source. In practice always 5 (Customer) within the 7-day window. (Tier 1 — WalletDB.Wallet.CustomerWalletsView) |
| 8 | IsActive | int | NULL | Whether this wallet is currently operational. Always 1 in this view (WHERE filter), but included for schema compatibility. 1=active, 0=deactivated (excluded by CustomerWalletsView). All rows in this table have IsActive=1. DWH note: int in EXW DDL vs bit in WalletDB source. (Tier 1 — WalletDB.Wallet.CustomerWalletsView) |
| 9 | Status | int | NULL | Computed activation status: 0=Created/Active (wallet fully operational, IsActivated=1), 5=Pending activation (awaiting blockchain confirmation, IsActivated=0). Computed in CustomerWalletsView: CASE WHEN w.IsActivated=1 THEN 0 ELSE 5 END. 96.9% are Status=0; 3.1% Status=5 (306/9,877 rows). (Tier 1 — WalletDB.Wallet.CustomerWalletsView) |
| 10 | WalletRecordId | bigint | NULL | Auto-incrementing surrogate key from the base Wallets table. Aliased from Wallet.Wallets.Id. Useful for ordering by creation sequence. (Tier 1 — WalletDB.Wallet.CustomerWalletsView) |
| 11 | BlockchainCryptoId | int | NULL | The blockchain network this wallet operates on. FK to Wallet.BlockchainCryptos.Id. Determines which blockchain the Address belongs to. May differ from CryptoId for multi-token blockchains (e.g., ERC-20 tokens share the ETH blockchain: USDC CryptoID=107, BlockchainCryptoId=2). (Tier 1 — WalletDB.Wallet.CustomerWalletsView) |
| 12 | ReportDate | date | NULL | Date of the SP_EXW_Hourly run that created this row. CAST(GETDATE() AS DATE). Same for all rows in a single run. (Tier 2 — SP_EXW_Hourly) |
| 13 | AllocationDate | date | NULL | Hardcoded to CAST(GETDATE() AS DATE) — always equals ReportDate. Despite the name, this does NOT contain the wallet allocation date. To get the actual allocation date, use CAST(Occurred AS DATE). (Tier 2 — SP_EXW_Hourly) |
| 14 | UpdateDate | datetime | NULL | ETL timestamp set to GETDATE() at INSERT time. Reflects the specific hourly run that produced this row. (Tier 2 — SP_EXW_Hourly) |
| 15 | CrytpoType | nvarchar(1000) | NULL | Native coin vs ERC-20 token classification. CASE WHEN CryptoId = BlockchainCryptoId THEN 'MainCryptos' ELSE 'ERCCryptos' END. Note: column name is a typo ('CrytpoType') preserved from DDL. Current split: 6,839 MainCryptos (69%), 3,038 ERCCryptos (31%). (Tier 2 — SP_EXW_Hourly) |
| 16 | WalletProviderId | int | NULL | Custody provider: 1=BitGo (97.5% of wallets, multi-sig), 2=CUG (2.5%, MPC-based, newer blockchains like SOL). FK to Dictionary.WalletProvider. (Tier 1 — WalletDB.Wallet.CustomerWalletsView) |

---

## 5. Lineage

See [Hourly_WalletAllocations.lineage.md](Hourly_WalletAllocations.lineage.md) for full column-level lineage including T1 copy verification table.

### 5.2 ETL Pipeline

```
WalletDB.Wallet.CustomerWalletsView (production — active customer wallet assignments)
  |-- joins: Wallet.Wallets + Wallet.WalletPool + Wallet.WalletAssets --|
  v
EXW_Wallet.CustomerWalletsView (Synapse live view)
  |-- SP_EXW_Hourly: SELECT * WHERE Occurred >= last 7 days --|
  |-- + CAST(GETDATE() AS DATE) AS reportdate/allocationdate --|
  |-- + CASE CryptoType classification --|
  v
EXW_dbo.Hourly_WalletAllocations
  (9,877 rows, 44 cryptos, 3,178 customers, 7-day window, HASH(GCID), HEAP)
  UC Target: _Not_Migrated (operational KPI, Synapse-only)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| ID (WalletId) | WalletDB.Wallet.WalletPool | Wallet GUID from the pre-provisioned pool |
| GCID | WalletDB.Wallet.Wallets | Customer ownership of the wallet |
| CryptoID | EXW_Wallet.CryptoTypes | Crypto asset metadata |
| BlockchainCryptoId | EXW_Wallet.BlockchainCryptos | Blockchain network metadata |
| WalletProviderId | Dictionary.WalletProvider | Custody provider (BitGo/CUG) |

### 6.2 Referenced By (other objects point to this)

No SSDT stored procedures or views found that reference EXW_dbo.Hourly_WalletAllocations. This table is consumed directly by Tableau dashboards for operational monitoring of wallet allocation activity.

---

## 7. Sample Queries

### 7.1 Today's wallet allocations by crypto

```sql
SELECT
    CryptoID,
    CrytpoType,
    COUNT(1) AS AllocationsToday,
    SUM(CASE WHEN Status = 0 THEN 1 ELSE 0 END) AS ActiveCount,
    SUM(CASE WHEN Status = 5 THEN 1 ELSE 0 END) AS PendingCount
FROM [EXW_dbo].[Hourly_WalletAllocations]
WHERE CAST(Occurred AS DATE) = CAST(GETDATE() AS DATE)
GROUP BY CryptoID, CrytpoType
ORDER BY AllocationsToday DESC
```

### 7.2 Recently allocated wallets for a specific customer

```sql
SELECT
    CryptoID,
    Address,
    WalletTypeId,
    Status,
    WalletProviderId,
    Occurred,
    CrytpoType
FROM [EXW_dbo].[Hourly_WalletAllocations]
WHERE GCID = 9661239  -- replace with actual GCID
ORDER BY Occurred DESC
```

### 7.3 ERC-20 vs native coin allocation split by day

```sql
SELECT
    CAST(Occurred AS DATE) AS AllocationDay,
    CrytpoType,
    COUNT(1) AS Allocations
FROM [EXW_dbo].[Hourly_WalletAllocations]
GROUP BY CAST(Occurred AS DATE), CrytpoType
ORDER BY AllocationDay DESC, CrytpoType
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object in the EXW_dbo schema. See upstream `Wallet.CustomerWalletsView` for Atlassian references related to the wallet allocation flow.

---

*Generated: 2026-04-20 | Quality: 9.0/10 | Phases: 13/14*
*Tiers: 12 T1, 4 T2, 0 T3, 0 T4, 0 T5 | Elements: 16/16, Logic: 10/10*
*Object: EXW_dbo.Hourly_WalletAllocations | Type: Table | Production Source: SP_EXW_Hourly ← EXW_Wallet.CustomerWalletsView*
