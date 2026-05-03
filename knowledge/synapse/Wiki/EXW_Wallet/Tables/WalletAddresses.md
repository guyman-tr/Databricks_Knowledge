# EXW_Wallet.WalletAddresses

> 2.47M-row table storing blockchain wallet addresses for the eToroX crypto wallet platform, covering addresses from April 2018 to present. Each row maps a wallet (WalletId) to its blockchain address, with a flag indicating primary vs. secondary addresses. Loaded via Generic Pipeline (Append) from WalletDB.Wallet.WalletAddresses every 120 minutes.

| Property | Value |
|----------|-------|
| **Schema** | EXW_Wallet |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.WalletAddresses (Generic Pipeline, Append) |
| **Refresh** | Every 120 minutes via Generic Pipeline (Append strategy) |
| **Synapse Distribution** | HASH(WalletId) |
| **Synapse Index** | HEAP + NCI on partition_date |
| **UC Target** | `wallet.bronze_walletdb_wallet_walletaddresses` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze export (Generic Pipeline) |

---

## 1. Business Meaning

EXW_Wallet.WalletAddresses is a reference/dimension-style table within the eToroX crypto wallet ecosystem. It stores the mapping between internal wallet identifiers (WalletId) and their corresponding blockchain addresses. As of April 2026 it contains ~2.47M rows spanning from 2018-04-23 to 2026-04-26.

Each wallet can have one or more blockchain addresses, but one is designated as the "main" address (IsMain = True). In practice, 99.998% of rows (2,465,304 of 2,465,354) are main addresses, with only 50 non-main addresses.

The table is loaded directly from production `WalletDB.Wallet.WalletAddresses` via the Generic Pipeline CopyFromLake mechanism (Append strategy, parquet format). There is no writer stored procedure — the ETL is handled entirely by the framework. The `NormalizedAddress` column is heavily used in downstream views (EXW_TransactionsView) to filter out internal wallet-to-wallet transfers.

All rows currently have `CustomerWalletStatusId = 1`, suggesting a single active status for all addresses.

---

## 2. Business Logic

### 2.1 Main Address Designation

**What**: Each wallet has a primary blockchain address used for transactions.
**Columns Involved**: WalletId, IsMain, Address, NormalizedAddress
**Rules**:
- IsMain = True (1) marks the primary address for the wallet; only 50 out of 2.47M rows are non-main
- SP_EXW_WalletInventory explicitly filters `ewa.IsMain = 1` when joining to this table
- The main address is the one used for public-facing wallet inventory reporting

### 2.2 Normalized Address for Transaction Filtering

**What**: NormalizedAddress provides a canonical form of the blockchain address used to identify internal transfers.
**Columns Involved**: NormalizedAddress, WalletId
**Rules**:
- EXW_TransactionsView uses `NOT IN (SELECT wa1.NormalizedAddress FROM WalletAddresses wa1 WHERE wa1.WalletId = ...)` to exclude internal wallet-to-wallet movements
- NormalizedAddress strips protocol-specific suffixes (e.g., `?dt=0` removed from XRP addresses)
- Both ReceivedTransactions and SentTransactions (other_transactions CTE) use this filtering

### 2.3 ETL Partition Columns

**What**: The Generic Pipeline appends ETL timestamp partitions for incremental loading.
**Columns Involved**: etr_y, etr_ym, etr_ymd, partition_date, SynapseUpdateDate
**Rules**:
- etr_y/etr_ym/etr_ymd are derived from the source record's Occurred timestamp during pipeline extraction
- Rows loaded before the etr_* columns were added have NULL values (814,946 rows with NULL etr_y)
- partition_date is indexed (NCI) for efficient date-range queries
- SynapseUpdateDate is NULL for most historical rows, populated only on re-ingestion

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

The table is HASH-distributed on `WalletId` with a HEAP storage structure. An NCI exists on `partition_date` for date-range filtering. JOINs on `WalletId` will be co-located with other EXW_Wallet tables that share the same distribution key.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Find the main address for a wallet | `SELECT * FROM EXW_Wallet.WalletAddresses WHERE WalletId = '...' AND IsMain = 1` |
| Count addresses by year | `SELECT etr_y, COUNT(*) FROM EXW_Wallet.WalletAddresses GROUP BY etr_y` |
| Recent address assignments | `SELECT * FROM EXW_Wallet.WalletAddresses WHERE partition_date >= '2026-04-01'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_Wallet.CustomerWalletsView | `cw.Id = ewa.WalletId AND ewa.IsMain = 1` | Get public address and normalized address for customer wallets (SP_EXW_WalletInventory) |
| EXW_Wallet.SentTransactions / ReceivedTransactions | `wa1.WalletId = st.WalletId` (subquery on NormalizedAddress) | Filter out internal transfers in EXW_TransactionsView |

### 3.4 Gotchas

- **Almost all rows are IsMain = True**: Only 50 rows have IsMain = False; do not assume a balanced distribution
- **CustomerWalletStatusId is always 1**: This column currently has no variation; do not use it for filtering
- **etr_* columns have NULLs for historical data**: ~815K rows (pre-ETL-partition era) have NULL etr_y/etr_ym/etr_ymd; use partition_date instead for date filtering
- **SynapseUpdateDate is mostly NULL**: Only rows that were re-ingested have a value; do not rely on this for freshness checks
- **NormalizedAddress vs Address**: Some blockchain formats append suffixes (e.g., XRP `?dt=0`); NormalizedAddress strips these. Always use NormalizedAddress for comparison/filtering
- **WalletId is a GUID string**: Despite being varchar(4000), actual values are standard 36-char UUIDs

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from ETL/SP logic with transform documented |
| Tier 3 | No upstream wiki; described from DDL, sample data, and downstream SP usage |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | bigint | YES | Surrogate or natural primary key from the production WalletDB.Wallet.WalletAddresses table. Unique identifier for each wallet address record. (Tier 3 — WalletDB.Wallet.WalletAddresses) |
| 2 | WalletId | varchar(4000) | YES | GUID identifier for the crypto wallet. Distribution key. Used to JOIN to CustomerWalletsView (cw.Id = ewa.WalletId) in SP_EXW_WalletInventory and as the subquery correlation in EXW_TransactionsView. (Tier 3 — WalletDB.Wallet.WalletAddresses) |
| 3 | Address | varchar(max) | YES | Raw blockchain address string assigned to the wallet. May include protocol-specific suffixes (e.g., XRP addresses with `?dt=0`). Mapped as PublicAddress in SP_EXW_WalletInventory. (Tier 3 — WalletDB.Wallet.WalletAddresses) |
| 4 | IsMain | bit | YES | Flag indicating whether this is the primary address for the wallet. True = main address, False = secondary. SP_EXW_WalletInventory filters on IsMain = 1. In practice, 99.998% of rows are True. (Tier 3 — WalletDB.Wallet.WalletAddresses) |
| 5 | BlockchainProviderWalletId | varchar(max) | YES | External identifier assigned by the blockchain provider (e.g., Fireblocks). Used in SP_EXW_WalletInventory as ProviderWalletID. Referenced in SP_EXW_FactBalance and SP_EXW_Hourly to exclude specific legacy beta wallets via NOT IN list. (Tier 3 — WalletDB.Wallet.WalletAddresses) |
| 6 | CustomerWalletStatusId | int | YES | Status identifier for the customer wallet address. Currently all rows contain value 1. No dictionary wiki available for value mappings. (Tier 3 — WalletDB.Wallet.WalletAddresses) |
| 7 | Occurred | datetime2(7) | YES | Timestamp of when the wallet address was created or assigned in production. Ranges from 2018-04-23 to 2026-04-26. Used by the Generic Pipeline to derive etr_y/etr_ym/etr_ymd partition columns. (Tier 3 — WalletDB.Wallet.WalletAddresses) |
| 8 | BalanceAccountID | varchar(max) | YES | Identifier linking the wallet address to a balance account. Sparsely populated — many rows have NULL values, particularly newer records. (Tier 3 — WalletDB.Wallet.WalletAddresses) |
| 9 | NormalizedAddress | varchar(max) | YES | Canonical form of the blockchain address with protocol-specific suffixes stripped (e.g., XRP `?dt=0` removed). Used in EXW_TransactionsView NOT IN subqueries to filter out internal wallet-to-wallet transfers. Also passed through in SP_EXW_WalletInventory. (Tier 3 — WalletDB.Wallet.WalletAddresses) |
| 10 | etr_y | varchar(max) | YES | ETL partition year derived from the source record's Occurred timestamp during Generic Pipeline extraction. Format: `YYYY`. NULL for ~815K historical rows loaded before partition columns were added. (Tier 2 — Generic Pipeline) |
| 11 | etr_ym | varchar(max) | YES | ETL partition year-month derived from Occurred. Format: `YYYY-MM`. NULL for historical rows. (Tier 2 — Generic Pipeline) |
| 12 | etr_ymd | varchar(max) | YES | ETL partition year-month-day derived from Occurred. Format: `YYYY-MM-DD`. NULL for historical rows. (Tier 2 — Generic Pipeline) |
| 13 | SynapseUpdateDate | datetime | YES | Timestamp of when the row was last ingested or updated in Synapse. NULL for most historical rows; populated only during re-ingestion events. (Tier 2 — Generic Pipeline) |
| 14 | partition_date | date | YES | Date-typed partition column for incremental loading. Indexed (NCI) for efficient date-range scans. Aligned with etr_ymd when present. (Tier 2 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| Id | WalletDB.Wallet.WalletAddresses | Id | Passthrough |
| WalletId | WalletDB.Wallet.WalletAddresses | WalletId | Passthrough |
| Address | WalletDB.Wallet.WalletAddresses | Address | Passthrough |
| IsMain | WalletDB.Wallet.WalletAddresses | IsMain | Passthrough |
| BlockchainProviderWalletId | WalletDB.Wallet.WalletAddresses | BlockchainProviderWalletId | Passthrough |
| CustomerWalletStatusId | WalletDB.Wallet.WalletAddresses | CustomerWalletStatusId | Passthrough |
| Occurred | WalletDB.Wallet.WalletAddresses | Occurred | Passthrough |
| BalanceAccountID | WalletDB.Wallet.WalletAddresses | BalanceAccountID | Passthrough |
| NormalizedAddress | WalletDB.Wallet.WalletAddresses | NormalizedAddress | Passthrough |
| etr_y | Generic Pipeline | Occurred | Year extraction |
| etr_ym | Generic Pipeline | Occurred | Year-month extraction |
| etr_ymd | Generic Pipeline | Occurred | Year-month-day extraction |
| SynapseUpdateDate | Generic Pipeline | — | Ingestion timestamp |
| partition_date | Generic Pipeline | Occurred | Date cast |

### 5.2 ETL Pipeline

```
WalletDB.Wallet.WalletAddresses (PROD, WalletDB server)
  |-- Generic Pipeline (id=717, Append, parquet, 120 min) ---|
  v
Bronze/WalletDB/Wallet/WalletAddresses/ (Data Lake)
  |-- CopyFromLake framework ---|
  v
CopyFromLake_staging.EXW_Wallet.WalletAddresses (9 cols, ROUND_ROBIN)
  |-- CopyFromLake swap (adds etr_*, SynapseUpdateDate, partition_date) ---|
  v
EXW_Wallet.WalletAddresses (2.47M rows, HASH(WalletId), HEAP)
  |-- Read by SP_EXW_WalletInventory, EXW_TransactionsView, SP_EXW_FactBalance ---|
  v
EXW_dbo.EXW_WalletInventory, EXW_dbo.Hourly_* (downstream aggregations)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| WalletId | EXW_Wallet.CustomerWalletsView.Id | Links address to the customer wallet entity |
| CustomerWalletStatusId | (Unknown dictionary) | Status lookup — no dictionary table identified; all values = 1 |

### 6.2 Referenced By (other objects point to this)

| Element | Referencing Object | Description |
|---|---|---|
| WalletId, IsMain, Address, NormalizedAddress | EXW_dbo.SP_EXW_WalletInventory | JOINed on WalletId + IsMain=1 to obtain public address for wallet inventory |
| WalletId, NormalizedAddress | EXW_Wallet.EXW_TransactionsView | NOT IN subquery to exclude internal addresses from transaction reporting |
| (indirect) | EXW_dbo.SP_EXW_Hourly | Uses SP_EXW_WalletInventory logic inline, which reads WalletAddresses |

---

## 7. Sample Queries

### 7.1 Find Main Address for a Specific Wallet

```sql
SELECT WalletId, Address, NormalizedAddress, Occurred
FROM EXW_Wallet.WalletAddresses
WHERE WalletId = 'bc5dab1a-d1ed-41d4-84e6-09a694f8ecc2'
  AND IsMain = 1;
```

### 7.2 Daily Address Creation Trend

```sql
SELECT partition_date, COUNT(*) AS addresses_created
FROM EXW_Wallet.WalletAddresses
WHERE partition_date >= '2026-01-01'
GROUP BY partition_date
ORDER BY partition_date;
```

### 7.3 Addresses with Mismatched Raw vs Normalized Form

```sql
SELECT TOP 20 Address, NormalizedAddress, Occurred
FROM EXW_Wallet.WalletAddresses
WHERE Address <> NormalizedAddress
  AND NormalizedAddress IS NOT NULL
ORDER BY Occurred DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (regen harness mode — Jira/Confluence search skipped).

---

*Generated: 2026-04-30 | Quality: 7.5/10 | Phases: 13/14*
*Tiers: 0 T1, 5 T2, 9 T3, 0 T4, 0 T5 | Elements: 14/14, Logic: 7/10, Lineage: 8/10*
*Object: EXW_Wallet.WalletAddresses | Type: Table | Production Source: WalletDB.Wallet.WalletAddresses (Generic Pipeline)*
