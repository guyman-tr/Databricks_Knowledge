# EXW_dbo.New_UsersAndWallets_Inventory

> 1,760,434-row lookup table tracking the first wallet allocation date per customer per cryptocurrency, sourced entirely from EXW_WalletInventory. Each row represents one GCID × CryptoID combination, providing WalletJoinDate (first time this user activated a wallet for this specific crypto) and UserJoinDate (first time this user activated any wallet at all). Covers 699,694 distinct customers and 174 crypto types from 2019-06-11 to 2026-04-12. Refreshed daily via SP_New_UsersAndWallets_Inventory (TRUNCATE + INSERT).

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | EXW_dbo.EXW_WalletInventory → WalletDB.Wallet.WalletPool + CustomerWalletsView |
| **Refresh** | Daily TRUNCATE + INSERT via SP_New_UsersAndWallets_Inventory (no date parameter — full rebuild) |
| **Synapse Distribution** | HASH(GCID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

New_UsersAndWallets_Inventory is the canonical source of wallet inception dates in the eToro Wallet system. It answers two related but distinct questions per customer:

1. **When did this user first get any wallet?** → `UserJoinDate` (MIN(Allocated) across all cryptos for this GCID)
2. **When did this user first get a Bitcoin / ETH / [crypto X] wallet?** → `WalletJoinDate` (MIN(Allocated) for this GCID × CryptoID combination)

These two dates are identical for a user's first-ever wallet acquisition (e.g., getting BTC for the first time), but diverge when an existing user opens a wallet for a new cryptocurrency. For example, a user who joined in 2020 (UserJoinDate=2020-03-15) but first acquired SOL in 2022 (WalletJoinDate=2022-08-10) would have both dates populated correctly.

The table covers 699,694 distinct GCIDs — matching the EXW_DimUser scope — and 174 crypto types. The WHERE GCID>0 filter in the writer SP ensures only real customers are included; omnibus and system wallets (GCID=0 or NULL) are excluded.

Primary consumer: `SP_EXW_FirstTimeWalletsAndUsers` uses this table as the authoritative source of `UserJoinDate` and `WalletJoinDate` to compute monthly new-user and new-wallet analytics.

---

## 2. Business Logic

### 2.1 Two-Level Aggregation of Wallet Inception Dates

**What**: The SP computes two separate MIN(Allocated) aggregations from EXW_WalletInventory at different granularities.

**Columns Involved**: `UserJoinDate`, `WalletJoinDate`, `GCID`, `CryptoID`

**Rules**:
- `UserJoinDate` = MIN(EXW_WalletInventory.Allocated) GROUP BY GCID — the earliest wallet allocation date for this customer across all cryptos.
- `WalletJoinDate` = MIN(EXW_WalletInventory.Allocated) GROUP BY GCID, CryptoID — the earliest wallet allocation for this customer for this specific cryptocurrency.
- `UserJoinDate ≤ WalletJoinDate` always (UserJoinDate is the global minimum; WalletJoinDate is the per-crypto minimum).
- When a user's first wallet is BTC: UserJoinDate = WalletJoinDate for that user's BTC row.
- `WalletJoinDate` reflects the pool allocation event from EXW_WalletInventory.Allocated (CAST to DATE), not account registration date.

### 2.2 GCID Scope and Omnibus Exclusion

**What**: Only real customer wallets are included; omnibus and unoccupied pool wallets are excluded.

**Columns Involved**: `GCID`

**Rules**:
- SP uses `WHERE GCID > 0` — excludes unoccupied pool wallets (NULL GCID) and system/omnibus wallets (GCID=0).
- This aligns the scope with EXW_DimUser (699,694 GCIDs), making this table safe to LEFT JOIN to EXW_DimUser without fanout.
- A single GCID may have multiple rows (one per CryptoID). Average ~2.5 cryptos per user.

### 2.3 Crypto Granularity

**What**: Each row covers one GCID × CryptoID pairing.

**Columns Involved**: `CryptoID`, `CryptoName`

**Rules**:
- 174 distinct CryptoIDs in current data.
- CryptoName is denormalized from EXW_WalletInventory (which sourced it from EXW_Wallet.CryptoTypes).
- Only native blockchain coin wallets are present (inherited from EXW_WalletInventory's ERC-20 exclusion filter).

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(GCID) with HEAP. All GCID-based queries benefit from distribution key alignment. With 1.76M rows and 699K GCIDs (~2.5 rows/GCID on average), GCID filter queries are efficient. For broad crypto-based aggregations (GROUP BY CryptoID), expect cross-distribution shuffles since GCID is the distribution key.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| When did user X first register on Wallet? | `SELECT MIN(UserJoinDate) FROM New_UsersAndWallets_Inventory WHERE GCID = X` (or join to EXW_DimUser) |
| When did user X first get BTC wallet? | `WHERE GCID = X AND CryptoID = 1` |
| Monthly cohort of first-time Wallet users | Use `EXW_FirstTimeWalletsAndUsers` (pre-aggregated by SP_EXW_FirstTimeWalletsAndUsers) |
| All cryptos a user has wallets for | `SELECT CryptoID, CryptoName FROM New_UsersAndWallets_Inventory WHERE GCID = X ORDER BY WalletJoinDate` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_dbo.EXW_DimUser | `GCID = GCID` | Enrich with user attributes (country, regulation, level) |
| EXW_dbo.EXW_FactBalance | `GCID = GCID AND CryptoID = CryptoID` | Add current balance |
| EXW_dbo.EXW_WalletInventory | `GCID = GCID AND CryptoID = CryptoID` | Get wallet-level detail (PublicAddress, WalletPoolStatusId) |

### 3.4 Gotchas

- **UserJoinDate is NOT account registration date**: It is the date of first wallet allocation via EXW_WalletInventory.Allocated. A user may have registered on eToro much earlier but only activated a wallet later.
- **Full rebuild on every run**: No date parameter — the entire table is rebuilt daily. Historical values may change if EXW_WalletInventory data is corrected retroactively.
- **One row per GCID × CryptoID**: Aggregating totals by GCID requires GROUP BY or a DISTINCT GCID subquery; summing directly will count each crypto separately.
- **174 CryptoIDs** but only native blockchain wallets (no ERC-20 tokens like SHIB on ETH). Crypto counts may differ from EXW_FactTransactions which includes ERC-20 transactions.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|---|---|
| Tier 1 | Verbatim from upstream wiki (WalletDB, DB_Schema) |
| Tier 2 | Sourced from SP code / DWH computation |
| Tier 3 | Inferred from column name + context |
| Tier 4 | Best available (limited confidence) |
| Tier 5 | Glossary / domain knowledge only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | YES | Global Customer ID of the wallet owner. For customer wallets (type 5), this is the real user. For system wallets (types 1-4, 6-7), this is a service account. Gcid=0 conventionally indicates omnibus/system wallets. From Wallet.Wallets.Gcid. DWH note: WHERE GCID>0 filter in SP excludes unoccupied pool wallets and omnibus wallets — all GCIDs in this table belong to real customers. (Tier 1 — WalletDB.Wallet.CustomerWalletsView) |
| 2 | WalletJoinDate | date | YES | Timestamp when this crypto asset was first added to the wallet (when the user first acquired this crypto). From Wallet.WalletAssets.Occurred. Used for portfolio age tracking and ordering. DWH note: MIN(EXW_WalletInventory.Allocated) per GCID×CryptoID — the earliest wallet allocation date for this customer for this specific cryptocurrency. CAST to DATE. (Tier 1 — WalletDB.Wallet.CustomerWalletsView) |
| 3 | UserJoinDate | date | YES | Timestamp when this crypto asset was first added to the wallet (when the user first acquired this crypto). From Wallet.WalletAssets.Occurred. Used for portfolio age tracking and ordering. DWH note: MIN(EXW_WalletInventory.Allocated) per GCID across all cryptos — the user's earliest wallet allocation date for any cryptocurrency. Repeated for every CryptoID row of this GCID. CAST to DATE. (Tier 1 — WalletDB.Wallet.CustomerWalletsView) |
| 4 | CryptoName | nvarchar(256) | YES | Human-readable name of the cryptocurrency for this wallet (e.g., BTC, ETH, SOL). Denormalized from EXW_Wallet.CryptoTypes. Mirrors the CryptoID selection logic: ERC-20 name takes precedence if available, else blockchain native name. (Tier 2 — EXW_Wallet.CryptoTypes) |
| 5 | CryptoID | int | YES | Platform cryptocurrency identifier for this wallet. Equals BlockchainCryptoId for all rows due to SP WHERE filter (ERC-20 token wallets are excluded). FK to EXW_Wallet.CryptoTypes.CryptoID. (Tier 3 — EXW_Wallet.CryptoTypes) |
| 6 | UpdateDate | date | YES | Daily refresh timestamp — set to GETDATE() at load time. Indicates when the row was last rebuilt. All rows share the same UpdateDate from the last SP run. (Tier 2 — SP_New_UsersAndWallets_Inventory) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| GCID | WalletDB.Wallet.CustomerWalletsView | Gcid | Passthrough via EXW_WalletInventory (WHERE GCID>0) |
| WalletJoinDate | WalletDB.Wallet.WalletAssets (via CustomerWalletsView) | Occurred | MIN per GCID×CryptoID, CAST to DATE, via EXW_WalletInventory.Allocated |
| UserJoinDate | WalletDB.Wallet.WalletAssets (via CustomerWalletsView) | Occurred | MIN per GCID, CAST to DATE, via EXW_WalletInventory.Allocated |
| CryptoName | EXW_Wallet.CryptoTypes | Name | Passthrough via EXW_WalletInventory |
| CryptoID | EXW_Wallet.CryptoTypes | CryptoID | Passthrough via EXW_WalletInventory |
| UpdateDate | — | — | GETDATE() at SP execution |

### 5.2 ETL Pipeline

```
WalletDB.Wallet.WalletPool + WalletPoolStatuses + CustomerWalletsView + WalletAddresses
  |-- SP_EXW_WalletInventory (daily TRUNCATE+INSERT) ---|
  v
EXW_dbo.EXW_WalletInventory (2,748,419 rows)
  |-- SP_New_UsersAndWallets_Inventory
  |   WHERE GCID > 0
  |   #userjoin: MIN(Allocated) per GCID
  |   #walletjoin: MIN(Allocated) per GCID × CryptoID
  |   TRUNCATE + INSERT ---|
  v
EXW_dbo.New_UsersAndWallets_Inventory (1,760,434 rows)
  |-- SP_EXW_FirstTimeWalletsAndUsers (monthly analytics) ---|
  v
EXW_dbo.EXW_FirstTimeWalletsAndUsers
  |-- (no UC migration) ---|
  v
_Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| GCID | EXW_dbo.EXW_DimUser | FK to primary Wallet user dimension |
| CryptoID | EXW_Wallet.CryptoTypes | FK to crypto type lookup |

### 6.2 Referenced By (other objects point to this)

| Object | How Used |
|---|---|
| EXW_dbo.EXW_FirstTimeWalletsAndUsers | SP_EXW_FirstTimeWalletsAndUsers reads UserJoinDate + WalletJoinDate to compute monthly first-time user/wallet cohorts |

---

## 7. Sample Queries

### Get a user's first-wallet inception dates by crypto

```sql
SELECT
    n.GCID,
    n.CryptoName,
    n.CryptoID,
    n.WalletJoinDate,
    n.UserJoinDate
FROM [EXW_dbo].[New_UsersAndWallets_Inventory] n
WHERE n.GCID = 12345678
ORDER BY n.WalletJoinDate;
```

### Monthly new wallet registrations by crypto (full-period trend)

```sql
SELECT
    YEAR(WalletJoinDate)  AS JoinYear,
    MONTH(WalletJoinDate) AS JoinMonth,
    CryptoName,
    COUNT(DISTINCT GCID)  AS NewWallets
FROM [EXW_dbo].[New_UsersAndWallets_Inventory]
GROUP BY YEAR(WalletJoinDate), MONTH(WalletJoinDate), CryptoName
ORDER BY JoinYear, JoinMonth, NewWallets DESC;
```

### Users who joined Wallet in the last 30 days (new-user cohort)

```sql
SELECT
    n.GCID,
    n.UserJoinDate,
    d.CountryID,
    d.RegulationID
FROM (
    SELECT GCID, MIN(UserJoinDate) AS UserJoinDate
    FROM [EXW_dbo].[New_UsersAndWallets_Inventory]
    GROUP BY GCID
) n
JOIN [EXW_dbo].[EXW_DimUser] d ON n.GCID = d.GCID
WHERE n.UserJoinDate >= DATEADD(DAY, -30, CAST(GETDATE() AS DATE))
ORDER BY n.UserJoinDate DESC;
```

---

## 8. Atlassian Knowledge Sources

No Jira issues or Confluence pages identified for this table. SP header attributes: Author Inessa Kontorovich, original 2020-04-12, Synapse migration 2024-03-14.

---

*Generated: 2026-04-20 | Quality: 8.6/10 | Phases: 13/14*
*Tiers: 3 T1, 3 T2, 0 T3, 0 T4, 0 T5 | Elements: 6/6, Logic: 8/10, Lineage: full*
*Object: EXW_dbo.New_UsersAndWallets_Inventory | Type: Table | Production Source: EXW_WalletInventory → WalletDB.Wallet.WalletPool*
