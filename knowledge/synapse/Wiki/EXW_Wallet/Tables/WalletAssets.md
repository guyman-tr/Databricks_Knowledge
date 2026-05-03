# EXW_Wallet.WalletAssets

> 1.78M-row crypto wallet asset registry tracking every cryptocurrency asset linked to a wallet, from June 2019 to present. Sourced from WalletDB.Wallet.WalletAssets via Generic Pipeline (Append, daily). Contains wallet-to-crypto associations with visibility flags and partition metadata.

| Property | Value |
|----------|-------|
| **Schema** | EXW_Wallet |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.WalletAssets (Generic Pipeline #651, Append) |
| **Refresh** | Daily (~06:00 UTC, 1440-minute interval) |
| **Synapse Distribution** | HASH(WalletId) |
| **Synapse Index** | HEAP + NCI on partition_date |
| **UC Target** | `wallet.bronze_walletdb_wallet_walletassets` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze export (Generic Pipeline) |

---

## 1. Business Meaning

EXW_Wallet.WalletAssets is a Bronze-layer replica of the production WalletDB.Wallet.WalletAssets table, recording the association between crypto wallets and cryptocurrency assets on the eToro Money (eToroX) platform. Each row represents one crypto asset activated within a specific wallet, identified by a GUID-based WalletId and an integer CryptoId.

The table contains 1,780,223 rows spanning from 2019-06-11 to 2026-04-27. Data grows daily via the Generic Pipeline (Append strategy, pipeline #651), with approximately 1,000-3,000 new or updated rows per day based on SynapseUpdateDate distribution. The vast majority of records (99.996%) have IsShown = True, indicating they are visible/active assets; only 66 rows are hidden.

CryptoId has 174 distinct values, with the top five being CryptoId 1 (593K rows), 2 (223K), 6 (185K), 21 (172K), and 3 (161K). No cryptocurrency dictionary table is available in Synapse to resolve CryptoId to coin names; the lookup table resides in the production WalletDB.

There are no stored procedures in Synapse that write to or transform this table. It is a direct Bronze copy with no DWH-side ETL logic applied.

---

## 2. Business Logic

### 2.1 Wallet-Asset Association

**What**: Each row links a wallet (WalletId) to a specific cryptocurrency (CryptoId) with the timestamp when the association occurred.
**Columns Involved**: WalletId, CryptoId, Occurred
**Rules**:
- WalletId is a GUID string (varchar 4000) and serves as the distribution key
- CryptoId is an integer FK to the production cryptocurrency dictionary (174 distinct values)
- Occurred records the timestamp when the asset was added to the wallet

### 2.2 Visibility Flag

**What**: IsShown controls whether the wallet asset is visible/active in the platform.
**Columns Involved**: IsShown
**Rules**:
- True (1) = visible/active asset — 1,780,157 rows (99.996%)
- False (0) = hidden/deactivated asset — 66 rows (0.004%)

### 2.3 ETL Partition Columns

**What**: Three string columns (etr_y, etr_ym, etr_ymd) carry date-based partition keys derived from the Occurred timestamp, used by the Generic Pipeline for incremental data lake partitioning.
**Columns Involved**: etr_y, etr_ym, etr_ymd, partition_date
**Rules**:
- etr_y = year string (e.g., "2019"), etr_ym = year-month (e.g., "2019-06"), etr_ymd = year-month-day (e.g., "2019-06-11")
- These columns are populated for historical data but empty/NULL for recent rows (observed from ~2025 onwards), suggesting the pipeline partition strategy changed
- partition_date (date type) aligns with the Occurred date and is indexed (NCI) for efficient partition pruning

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: HASH(WalletId) — queries filtering or joining on WalletId benefit from data locality
- **Index**: HEAP (no clustered index) + NCI on partition_date — always include partition_date in WHERE clauses for large scans
- The table has 1.78M rows — moderate size, safe for aggregations with date filters

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Count active wallet assets per crypto | `SELECT CryptoId, COUNT(*) FROM EXW_Wallet.WalletAssets WHERE IsShown = 1 GROUP BY CryptoId` |
| Find all assets for a specific wallet | `SELECT * FROM EXW_Wallet.WalletAssets WHERE WalletId = '<guid>'` (uses distribution key) |
| Daily new asset activations | `SELECT partition_date, COUNT(*) FROM EXW_Wallet.WalletAssets GROUP BY partition_date ORDER BY partition_date DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_Wallet.WalletPool | WalletAssets.WalletId = WalletPool.WalletId | Resolve wallet public addresses and provider info |
| EXW_Wallet.Wallets | WalletAssets.WalletId = Wallets.WalletId (via WalletPool) | Resolve wallet owner (Gcid), wallet type, activation status |
| EXW_Wallet.EXW_CustomerWalletsView | Direct reference | Pre-built view joining Wallets + WalletPool + WalletAssets |

### 3.4 Gotchas

- **CryptoId has no Synapse lookup**: The cryptocurrency dictionary is in WalletDB production only. Use `wallet.bronze_walletdb_wallet_walletassets` in Databricks if UC-side lookup is needed.
- **etr_y/etr_ym/etr_ymd are empty for recent data**: Do not rely on these columns for date filtering on data from ~2025 onwards. Use partition_date instead.
- **SynapseUpdateDate is NULL for early data**: Rows loaded before ~April 2025 have NULL SynapseUpdateDate. This column only reflects Synapse load time, not production update time.
- **WalletId is varchar(4000)**: Actual values are 36-character GUIDs but the column is vastly over-sized. Be aware of potential performance implications in JOINs.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from SP code / ETL logic |
| Tier 3 | Grounded in DDL + live data evidence, no upstream wiki |
| Tier 4 | Inferred from column name only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | bigint | YES | Production record identifier for the wallet asset. Unique row key from WalletDB.Wallet.WalletAssets. Observed values range from ~46K to ~1.2M+. (Tier 3 — WalletDB.Wallet.WalletAssets) |
| 2 | WalletId | varchar(4000) | YES | Wallet identifier in GUID format (e.g., "f31e0d49-3404-44ef-b3b3-d8e4adf79aa8"). Distribution key. Links to EXW_Wallet.WalletPool and EXW_Wallet.Wallets. Despite varchar(4000) type, actual values are 36-character UUIDs. (Tier 3 — WalletDB.Wallet.WalletAssets) |
| 3 | CryptoId | int | YES | Cryptocurrency asset identifier. FK to the production crypto dictionary in WalletDB (no Synapse-side lookup available). 174 distinct values observed; top values: 1 (593K rows), 2 (223K), 6 (185K), 21 (172K), 3 (161K). (Tier 3 — WalletDB.Wallet.WalletAssets) |
| 4 | Occurred | datetime2(7) | YES | Timestamp when the wallet asset association was created or the event occurred. Ranges from 2019-06-11 to 2026-04-27. Aligns with partition_date for date-based filtering. (Tier 3 — WalletDB.Wallet.WalletAssets) |
| 5 | etr_y | varchar(max) | YES | ETL partition key — year component derived from Occurred (e.g., "2019"). Used by Generic Pipeline for data lake partitioning. Populated for historical data; empty/NULL for rows from ~2025 onwards. (Tier 3 — WalletDB.Wallet.WalletAssets) |
| 6 | etr_ym | varchar(max) | YES | ETL partition key — year-month component derived from Occurred (e.g., "2019-06"). Used by Generic Pipeline for data lake partitioning. Populated for historical data; empty/NULL for rows from ~2025 onwards. (Tier 3 — WalletDB.Wallet.WalletAssets) |
| 7 | etr_ymd | varchar(max) | YES | ETL partition key — year-month-day component derived from Occurred (e.g., "2019-06-11"). Used by Generic Pipeline for data lake partitioning. Populated for historical data; empty/NULL for rows from ~2025 onwards. (Tier 3 — WalletDB.Wallet.WalletAssets) |
| 8 | SynapseUpdateDate | datetime | YES | Timestamp when the row was loaded or last updated in Synapse by the Generic Pipeline. NULL for rows loaded before ~April 2025. Daily loads typically occur around 06:00 UTC. (Tier 3 — ETL-injected) |
| 9 | partition_date | date | YES | Date-typed partition key aligned with Occurred. Indexed (NCI XI_partition_date) for efficient date-range queries. Ranges from 2019-06-11 to 2026-04-27. Preferred over etr_ymd for date filtering. (Tier 3 — WalletDB.Wallet.WalletAssets) |
| 10 | IsShown | bit | YES | Visibility flag indicating whether the wallet asset is shown/active in the platform. True=1,780,157 rows (99.996%), False=66 rows (0.004%). (Tier 3 — WalletDB.Wallet.WalletAssets) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| Id | WalletDB.Wallet.WalletAssets | Id | Passthrough |
| WalletId | WalletDB.Wallet.WalletAssets | WalletId | Passthrough |
| CryptoId | WalletDB.Wallet.WalletAssets | CryptoId | Passthrough |
| Occurred | WalletDB.Wallet.WalletAssets | Occurred | Passthrough |
| etr_y | WalletDB.Wallet.WalletAssets | etr_y | Passthrough (ETL partition) |
| etr_ym | WalletDB.Wallet.WalletAssets | etr_ym | Passthrough (ETL partition) |
| etr_ymd | WalletDB.Wallet.WalletAssets | etr_ymd | Passthrough (ETL partition) |
| SynapseUpdateDate | — | — | ETL-injected by Generic Pipeline |
| partition_date | WalletDB.Wallet.WalletAssets | partition_date | Passthrough |
| IsShown | WalletDB.Wallet.WalletAssets | IsShown | Passthrough |

### 5.2 ETL Pipeline

```
WalletDB.Wallet.WalletAssets (production, WalletDB server)
  |-- Generic Pipeline #651 (Bronze, Append, daily 1440 min, parquet) ---|
  v
Bronze/WalletDB/Wallet/WalletAssets/ (data lake)
  |-- Synapse External Table / COPY INTO ---|
  v
EXW_Wallet.WalletAssets (1.78M rows, HASH(WalletId), HEAP)
  |-- Generic Pipeline (Bronze export, delta) ---|
  v
wallet.bronze_walletdb_wallet_walletassets (UC Bronze)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| CryptoId | WalletDB cryptocurrency dictionary (production only) | FK to crypto asset type; no Synapse-side lookup available |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Join Condition | Description |
|---|---|---|
| EXW_Wallet.EXW_CustomerWalletsView | wa.WalletId = wp.WalletId | View joining Wallets + WalletPool + WalletAssets for customer wallet overview |
| EXW_Wallet.EXW_TransactionsView | (commented out in current code) | Transaction view historically referenced WalletAssets; currently disabled |

---

## 7. Sample Queries

### 7.1 Active Wallet Assets by Cryptocurrency

```sql
SELECT
    CryptoId,
    COUNT(*) AS asset_count,
    MIN(Occurred) AS first_activated,
    MAX(Occurred) AS last_activated
FROM EXW_Wallet.WalletAssets
WHERE IsShown = 1
GROUP BY CryptoId
ORDER BY asset_count DESC;
```

### 7.2 Daily New Wallet Asset Activations (Last 30 Days)

```sql
SELECT
    partition_date,
    COUNT(*) AS new_assets,
    COUNT(DISTINCT WalletId) AS unique_wallets,
    COUNT(DISTINCT CryptoId) AS unique_cryptos
FROM EXW_Wallet.WalletAssets
WHERE partition_date >= DATEADD(DAY, -30, GETDATE())
GROUP BY partition_date
ORDER BY partition_date DESC;
```

### 7.3 Customer Wallet Asset Summary via EXW_CustomerWalletsView

```sql
SELECT
    v.Id AS WalletId,
    v.Gcid,
    v.CryptoId,
    v.Address,
    v.Occurred
FROM EXW_Wallet.EXW_CustomerWalletsView v
WHERE v.Gcid = 12345;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object (regen harness — Atlassian search skipped).

---

*Generated: 2026-04-30 | Quality: 7.0/10 | Phases: 11/14*
*Tiers: 0 T1, 0 T2, 10 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 6/10, Lineage: 8/10*
*Object: EXW_Wallet.WalletAssets | Type: Table | Production Source: WalletDB.Wallet.WalletAssets (Generic Pipeline #651)*
