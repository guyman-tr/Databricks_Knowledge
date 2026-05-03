# EXW_Wallet.Wallets

> 1.5M-row cryptocurrency wallet registry tracking every customer wallet in the eToroX (EXW) platform from April 2018 to present. Each row represents a wallet record linking a customer (Gcid) to a blockchain cryptocurrency type, with activation status and SCD-style date tracking. Loaded daily via Generic Pipeline Override from WalletDB.Wallet.Wallets. 99.99% of wallets are WalletTypeId=5 (Customer).

| Property | Value |
|----------|-------|
| **Schema** | EXW_Wallet |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.Wallets (Generic Pipeline ID 658) |
| **Refresh** | Daily (every 1440 min), Override strategy |
| **Synapse Distribution** | HASH(WalletId) |
| **Synapse Index** | HEAP |
| **UC Target** | `wallet.bronze_walletdb_wallet_wallets` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze export (Generic Pipeline) |

---

## 1. Business Meaning

EXW_Wallet.Wallets is the central wallet dimension for the eToroX crypto-wallet platform. It contains 1,498,021 rows spanning from April 2018 to April 2026, with each row representing a unique wallet record that associates a customer (Gcid) with a specific blockchain cryptocurrency (BlockchainCryptoId) and wallet type (WalletTypeId).

The table uses SCD-style date tracking with BeginDate/EndDate columns, where EndDate = 9999-12-31 23:59:59.999999 indicates an active (current) record. Nearly all wallets (99.99%) are WalletTypeId = 5 (Customer), with rare entries for Redeem, Conversion, Funding, Payment, C2F, and StakingRefund types.

The table is loaded directly via the Generic Pipeline (Override strategy, daily) from the production WalletDB.Wallet.Wallets table. No Synapse stored procedure transforms the data — it is a direct passthrough landing table. Downstream consumers access this table primarily through EXW_CustomerWalletsView (which JOINs Wallets with WalletPool and WalletAssets) and EXW_TransactionsView (which uses Wallets to resolve Gcid for transaction records).

The top blockchain cryptocurrencies by wallet count are BTC (593K), ETH (223K), LTC (185K), XLM (172K), BCH (161K), and XRP (103K).

---

## 2. Business Logic

### 2.1 Wallet Activation Status

**What**: Two separate boolean flags track wallet lifecycle state.
**Columns Involved**: IsActive, IsActivated
**Rules**:
- IsActive = 1 (True) for 99.99% of records (1,498,017 of 1,498,021). Only 4 wallets are inactive.
- IsActivated = 1 (True) for 99.5% of records (1,490,702). 7,319 wallets are not yet activated.
- A wallet can be IsActive = 1 but IsActivated = 0, indicating it exists but has not completed activation.

### 2.2 SCD-Style Date Tracking

**What**: BeginDate and EndDate form a slowly-changing-dimension validity window.
**Columns Involved**: BeginDate, EndDate, Occurred
**Rules**:
- EndDate = 9999-12-31 23:59:59.999999 is the sentinel value for currently-active records.
- Occurred represents when the wallet event originally happened in production.
- BeginDate represents when the record became valid in the wallet system.
- Many early records share BeginDate = 2019-04-14 08:32:11.122397, suggesting a bulk backfill.

### 2.3 Wallet Type Distribution

**What**: WalletTypeId classifies wallet purpose, with overwhelming dominance of Customer type.
**Columns Involved**: WalletTypeId
**Rules**:
- WalletTypeId = 5 (Customer): 1,497,981 rows (99.99%)
- Other types (Redeem=1, Conversion=2, Funding=3, Payment=4, C2F=6, StakingRefund=7) total 40 rows combined.
- These non-Customer wallets are internal/system wallets used for platform operations.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

The table is HASH-distributed on WalletId (uniqueidentifier) and stored as a HEAP (no clustered index). JOINs on WalletId are co-located. JOINs on Gcid or BlockchainCryptoId require data movement.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| How many wallets does a customer have? | `SELECT Gcid, COUNT(*) FROM EXW_Wallet.Wallets WHERE IsActive = 1 GROUP BY Gcid` |
| Which cryptos are most popular? | `SELECT BlockchainCryptoId, COUNT(*) FROM EXW_Wallet.Wallets GROUP BY BlockchainCryptoId ORDER BY 2 DESC` |
| Customer wallet details with addresses | Use `EXW_Wallet.EXW_CustomerWalletsView` which JOINs Wallets + WalletPool + WalletAssets |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_Wallet.BlockchainCryptos | BlockchainCryptoId = BlockchainCryptos.Id | Resolve crypto name (BTC, ETH, etc.) |
| EXW_Dictionary.WalletTypes | WalletTypeId = WalletTypes.Id | Resolve wallet type name |
| EXW_Wallet.WalletPool | WalletId = WalletPool.WalletId | Get public address and provider info |
| EXW_Wallet.WalletAssets | WalletId = WalletAssets.WalletId | Get asset/crypto allocation details |

### 3.4 Gotchas

- **etr_y / etr_ym / etr_ymd are empty**: These Generic Pipeline partition columns contain no data for this table (Override strategy loads full snapshot).
- **EndDate sentinel**: 9999-12-31 23:59:59.999999 means "current" — do not filter on `EndDate IS NOT NULL` expecting to find closed records; filter on `EndDate < '9999-12-31'` instead.
- **IsActive vs IsActivated**: These are different flags. IsActive indicates the wallet record is live; IsActivated indicates the wallet completed its activation process. Use the appropriate flag for your query.
- **Prefer the view**: Most downstream SPs use `EXW_Wallet.CustomerWalletsView` (materialized table) or `EXW_Wallet.EXW_CustomerWalletsView` (view) rather than querying Wallets directly. The view enriches with address and provider data.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|---|---|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | ETL-computed or derived by stored procedure |
| Tier 3 | No upstream wiki available; described from DDL, data evidence, and downstream usage |

| # | Element | Type | Nullable | Description |
|---|---|---|---|---|
| 1 | Id | bigint | YES | Surrogate record identifier for the wallet row. Sequential bigint assigned in the production WalletDB system. Not the wallet's business key (see WalletId). (Tier 3 — WalletDB.Wallet.Wallets, no upstream wiki) |
| 2 | WalletId | uniqueidentifier | YES | Business key for the wallet. GUID that uniquely identifies a wallet across the platform. Used as the HASH distribution key in Synapse. FK to EXW_Wallet.WalletPool and EXW_Wallet.WalletAssets. (Tier 3 — WalletDB.Wallet.Wallets, no upstream wiki) |
| 3 | Gcid | int | YES | Global Customer ID. Identifies the customer who owns this wallet. Used in downstream JOINs to link wallet data to customer dimension tables. (Tier 3 — WalletDB.Wallet.Wallets, no upstream wiki) |
| 4 | BlockchainCryptoId | int | YES | FK to EXW_Wallet.BlockchainCryptos. Identifies the blockchain cryptocurrency type for this wallet. 1=BTC, 2=ETH, 3=BCH, 4=XRP, 6=LTC, 8=ETC, 18=ADA, 19=DOGE, 21=XLM, 23=EOS, 27=TRX, 64=SOL. (Tier 3 — WalletDB.Wallet.Wallets, no upstream wiki) |
| 5 | WalletTypeId | int | YES | FK to EXW_Dictionary.WalletTypes. Classifies the wallet purpose. 1=Redeem, 2=Conversion, 3=Funding, 4=Payment, 5=Customer, 6=C2F, 7=StakingRefund. 99.99% of records are 5 (Customer). (Tier 3 — WalletDB.Wallet.Wallets, no upstream wiki) |
| 6 | IsActive | bit | YES | Whether the wallet record is currently active. 1=Active, 0=Inactive. 99.99% of records are active (only 4 inactive wallets observed). (Tier 3 — WalletDB.Wallet.Wallets, no upstream wiki) |
| 7 | Occurred | datetime2(7) | YES | Timestamp of the original wallet event in production. Ranges from 2018-04-23 to present. Represents when the wallet was created or last modified in WalletDB. (Tier 3 — WalletDB.Wallet.Wallets, no upstream wiki) |
| 8 | BeginDate | datetime2(7) | YES | SCD validity start date for this wallet record. Many early records share 2019-04-14 08:32:11.122397, indicating a bulk historical backfill. Newer records align with Occurred. (Tier 3 — WalletDB.Wallet.Wallets, no upstream wiki) |
| 9 | EndDate | datetime2(7) | YES | SCD validity end date for this wallet record. 9999-12-31 23:59:59.999999 = currently active (sentinel value). A date before the sentinel indicates the record was superseded or closed. (Tier 3 — WalletDB.Wallet.Wallets, no upstream wiki) |
| 10 | IsActivated | bit | YES | Whether the wallet has completed its activation process. 1=Activated, 0=Not yet activated. 99.5% activated; 7,319 wallets remain unactivated. Distinct from IsActive (record-level status vs. activation-level status). (Tier 3 — WalletDB.Wallet.Wallets, no upstream wiki) |
| 11 | etr_y | varchar(max) | YES | Generic Pipeline partition column representing the extraction year. Currently empty for all rows (Override strategy loads full snapshot, not incremental partitions). (Tier 2 — Generic Pipeline) |
| 12 | etr_ym | varchar(max) | YES | Generic Pipeline partition column representing the extraction year-month. Currently empty for all rows. (Tier 2 — Generic Pipeline) |
| 13 | etr_ymd | varchar(max) | YES | Generic Pipeline partition column representing the extraction year-month-day. Currently empty for all rows. (Tier 2 — Generic Pipeline) |
| 14 | SynapseUpdateDate | datetime | YES | Timestamp when this row was last loaded into Synapse by the Generic Pipeline. Reflects the most recent Override refresh. (Tier 2 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| Id | WalletDB.Wallet.Wallets | Id | Passthrough |
| WalletId | WalletDB.Wallet.Wallets | WalletId | Passthrough |
| Gcid | WalletDB.Wallet.Wallets | Gcid | Passthrough |
| BlockchainCryptoId | WalletDB.Wallet.Wallets | BlockchainCryptoId | Passthrough |
| WalletTypeId | WalletDB.Wallet.Wallets | WalletTypeId | Passthrough |
| IsActive | WalletDB.Wallet.Wallets | IsActive | Passthrough |
| Occurred | WalletDB.Wallet.Wallets | Occurred | Passthrough |
| BeginDate | WalletDB.Wallet.Wallets | BeginDate | Passthrough |
| EndDate | WalletDB.Wallet.Wallets | EndDate | Passthrough |
| IsActivated | WalletDB.Wallet.Wallets | IsActivated | Passthrough |
| etr_y | — | — | Generic Pipeline partition (year) |
| etr_ym | — | — | Generic Pipeline partition (year-month) |
| etr_ymd | — | — | Generic Pipeline partition (year-month-day) |
| SynapseUpdateDate | — | — | Generic Pipeline load timestamp |

### 5.2 ETL Pipeline

```
WalletDB.Wallet.Wallets (production, WalletDB server)
  |-- Generic Pipeline (Bronze export, Override, daily, parquet) ---|
  v
Bronze/WalletDB/Wallet/Wallets/ (Data Lake)
  |-- CopyFromLake → EXW_Wallet.Wallets (Synapse) ---|
  v
EXW_Wallet.Wallets (1,498,021 rows, HASH(WalletId), HEAP)
  |-- Generic Pipeline (Bronze export, delta) ---|
  v
wallet.bronze_walletdb_wallet_wallets (Unity Catalog)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| BlockchainCryptoId | EXW_Wallet.BlockchainCryptos | Resolves to blockchain cryptocurrency name (BTC, ETH, etc.) |
| WalletTypeId | EXW_Dictionary.WalletTypes | Resolves to wallet type name (Customer, Redeem, etc.) |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Join Condition | Description |
|---|---|---|
| EXW_Wallet.EXW_CustomerWalletsView (view) | WalletId | Enriches wallet with address and provider data from WalletPool + WalletAssets |
| EXW_Wallet.EXW_TransactionsView (view) | WalletId | Resolves Gcid for transaction records |
| EXW_Wallet.CustomerWalletsView (materialized table) | — | Pre-materialized version of EXW_CustomerWalletsView |

---

## 7. Sample Queries

### 7.1 Customer Wallet Count by Cryptocurrency

```sql
SELECT bc.Name AS CryptoName,
       COUNT(*) AS WalletCount
FROM EXW_Wallet.Wallets w
JOIN EXW_Wallet.BlockchainCryptos bc ON w.BlockchainCryptoId = bc.Id
WHERE w.IsActive = 1
GROUP BY bc.Name
ORDER BY WalletCount DESC;
```

### 7.2 Unactivated Wallets Summary

```sql
SELECT bc.Name AS CryptoName,
       COUNT(*) AS UnactivatedCount
FROM EXW_Wallet.Wallets w
JOIN EXW_Wallet.BlockchainCryptos bc ON w.BlockchainCryptoId = bc.Id
WHERE w.IsActivated = 0
  AND w.IsActive = 1
GROUP BY bc.Name
ORDER BY UnactivatedCount DESC;
```

### 7.3 Daily New Wallet Creation Trend

```sql
SELECT CAST(Occurred AS DATE) AS WalletDate,
       COUNT(*) AS NewWallets
FROM EXW_Wallet.Wallets
WHERE Occurred >= '2026-01-01'
GROUP BY CAST(Occurred AS DATE)
ORDER BY WalletDate DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources were searched for this object (Phase 10 skipped — SOFT phase in regen harness mode).

---

*Generated: 2026-04-30 | Quality: 7/10 | Phases: 12/14*
*Tiers: 0 T1, 4 T2, 10 T3, 0 T4 | Elements: 14/14, Logic: 3/10, Lineage: complete*
*Object: EXW_Wallet.Wallets | Type: Table | Production Source: WalletDB.Wallet.Wallets*
