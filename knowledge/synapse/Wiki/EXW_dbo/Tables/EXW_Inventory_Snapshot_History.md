# EXW_dbo.EXW_Inventory_Snapshot_History

> Daily inventory health snapshot for eToro Wallet's blockchain address pool. One row per (date, crypto, wallet-status) combination — 31,048 rows covering 2020-01-01 to 2026-04-11 across 12 crypto assets. Tracks how many wallets are Available, Allocated to users or omnibuses, FundingVerified (occupied vs free), and rolling counts of allocations and creations over 1/7/30-day windows. Written by SP_EXW_Inventory_Snapshot_History from EXW_WalletInventory. Enables operations to monitor address-pool health and replenishment demand per crypto.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table (Daily Snapshot / Operational Monitor) |
| **Production Source** | EXW_dbo.EXW_WalletInventory (internal — no upstream production DB) |
| **Writer SP** | EXW_dbo.SP_EXW_Inventory_Snapshot_History (@d DATE) |
| **Refresh** | Daily incremental — DELETE WHERE [Date for Report] = @d, then INSERT |
| **Row Count** | 31,048 (2,290 distinct dates × 12 cryptos × 5 wallet statuses) |
| **Date Range** | [Date for Report]: 2020-01-01 — 2026-04-11 |
| **Synapse Distribution** | HASH(BlockchainCryptoId) |
| **Synapse Index** | HEAP |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

EXW_Inventory_Snapshot_History is the daily time-series audit trail for eToro Wallet's blockchain address inventory. Each row captures the state of the address pool for one specific (date, crypto asset, wallet status) combination — allowing operations to track trends over time and detect replenishment shortfalls.

**What is the address inventory?** Each eToro Wallet customer is assigned a dedicated blockchain wallet address per crypto asset (e.g., a BTC address, an ETH address). The wallet infrastructure maintains a pool of pre-generated addresses in `EXW_WalletInventory`. Before assignment they sit as "Available"; once assigned to a user or to an omnibus account they become "Allocated"; once the customer has deposited and been verified they graduate to "FundingVerified".

**Business value**: The snapshot lets the operations team answer "are we running low on ETH addresses?" or "how many new BTC wallets did we allocate last week?" without querying the live inventory directly. The rolling 7-day and 30-day window counters provide trend visibility.

**Grain**: One row per (Date for Report × BlockchainCryptoName × BlockchainCryptoId × WalletStatus). On a given date, BTC will have up to 5 rows — one for each WalletStatus that exists.

**WalletStatus distribution** (all dates combined):
- Verified (20,263 rows): Wallets verified for blockchain use, standard state
- Pending (6,833 rows): Wallet address in provisioning
- FundingVerified (2,290 rows): Wallet has been funded and verified — active holding wallets
- VerifiedForAssign (1,272 rows): Verified and in queue to be assigned
- Failed (390 rows): Provisioning failure — excluded from FundingVerified counts

**Author**: Inessa Kontorovich (2020-05-21); migrated to Synapse 2024-02-21 (Jan).

---

## 2. Business Logic

### 2.1 Allocation vs Availability Decomposition

**What**: The SP decomposes the total wallet pool into mutually exclusive allocation buckets per (date, crypto, status) group.

**Columns Involved**: `[Allocated Total]`, `[Available]`, `[Total AllocatedOmnibuses]`, `[Total AllocatedToUsers]`

**Rules**:
- `[Allocated Total]` = count of wallets where `Allocated < @EndDate` (all wallets ever assigned up to the end of @d)
- `[Available]` = count of wallets where `Allocated IS NULL OR Allocated > @d` (unassigned pool)
- `[Total AllocatedOmnibuses]` = Allocated + GCID ≤ 0 (system/omnibus wallets; negative/zero GCID)
- `[Total AllocatedToUsers]` = Allocated + GCID > 0 (customer-assigned wallets)
- Relationship: `[Total Created]` = `[Allocated Total]` + `[Available]` (all wallets ever provisioned)

### 2.2 FundingVerified Wallet Occupancy

**What**: Among FundingVerified wallets, distinguishes those actively holding customer funds (Occupied) from those available for new holders (Free).

**Columns Involved**: `[Funded Free]`, `[Funded Occupied]`, `WalletStatus`

**Rules**:
- `[Funded Free]` = WalletStatus='FundingVerified' AND Occupied=0 AND IsPromotionReady=1
- `[Funded Occupied]` = WalletStatus='FundingVerified' AND Occupied=1 AND IsPromotionReady=1
- Only rows where WalletStatus='FundingVerified' have non-zero values in these two columns

### 2.3 Rolling Window Metrics

**What**: Provides 1-day, 7-day, and 30-day rolling windows for wallet allocation and creation velocity.

**Columns Involved**: `[Allocated Daily]`, `[Created Daily]`, `[Allocated 7 days]`, `[Allocated 30 days]`, `[Created 7 days]`, `[Created 30 days]`

**Rules**:
- Daily: exact match on @d (Allocated = @d or CreatedDateID = YYYYMMDD(@d))
- 7 days: date BETWEEN @d-6 AND @d (includes @d)
- 30 days: date BETWEEN @d-29 AND @d (includes @d)
- Rolling windows look backward from @d (not forward); they accumulate across all WalletStatus values

### 2.4 Idempotency Pattern

**What**: The SP can be safely rerun for the same date without creating duplicate rows.

**Columns Involved**: `[Date for Report]`, `UpdateDate`

**Rules**:
- On each run: `DELETE FROM EXW_Inventory_Snapshot_History WHERE [Date for Report] = @d`
- Then INSERT the fresh snapshot for @d
- `UpdateDate` = GETDATE() at insert time — reflects SP execution timestamp, not business date
- If re-run on the same day, the older snapshot is replaced

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH distributed on `BlockchainCryptoId` (int). HEAP — no clustered index. For large time-range queries, filter on `[BlockchainCryptoName]` or `[Date for Report]` to reduce scan size.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Current pool health (latest snapshot) | `WHERE [Date for Report] = (SELECT MAX([Date for Report]) FROM EXW_dbo.EXW_Inventory_Snapshot_History)` |
| BTC wallet availability trend (90 days) | Filter `BlockchainCryptoId = 1` AND `[Date for Report] >= DATEADD(d,-90,GETDATE())` |
| Daily allocation velocity by crypto | Select `[Allocated Daily]`, `[Created Daily]`, group by `[Date for Report]`, `BlockchainCryptoName` |
| FundingVerified occupancy rate | Filter `WalletStatus = 'FundingVerified'`, compare `[Funded Occupied]` / (`[Funded Free]` + `[Funded Occupied]`) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.EXW_WalletInventory | BlockchainCryptoId | Get individual wallet details from the live inventory |

### 3.4 Gotchas

- **Space-in-name columns**: All 14 metric columns have spaces — must use `[bracket]` notation: `[Allocated Total]`, `[Date for Report]`, etc.
- **FundingVerified only row for FundingVerified metrics**: `[Funded Free]` and `[Funded Occupied]` are 0 for all rows where `WalletStatus != 'FundingVerified'`
- **Total Created is cumulative not daily**: `[Total Created]` is the lifetime count of wallets created for that crypto/status group up to @EndDate, not a daily counter
- **UpdateDate is ETL time, not business date**: Use `[Date for Report]` for business date filtering, not `UpdateDate`
- **GCID ≤ 0 = omnibus**: System/omnibus wallets have GCID ≤ 0; customer wallets have GCID > 0

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from SP code analysis — SP is the authoritative source |
| Tier 3 | Inferred from column name + data patterns |
| Tier 4 | Best available knowledge (limited confidence) |
| Tier 5 | Domain glossary / reference knowledge |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | WalletStatus | nvarchar(1000) | YES | Lifecycle state of wallets in this snapshot group. 5 distinct values: Verified (wallets verified for blockchain use), Pending (in provisioning), FundingVerified (funded and verified — holding customer crypto), VerifiedForAssign (verified, queued for assignment), Failed (provisioning failure). Part of the grouping key (GROUP BY with BlockchainCryptoName, BlockchainCryptoId). (Tier 2 — SP_EXW_Inventory_Snapshot_History via EXW_WalletInventory) |
| 2 | BlockchainCryptoName | varchar(100) | YES | Short display name for the crypto asset. 12 distinct values: BTC, ETH, XRP, EOS, LTC, BCH, XLM, TRX, ADA, DOGE, ETC, SOL. Part of the grouping key. (Tier 2 — SP_EXW_Inventory_Snapshot_History via EXW_WalletInventory) |
| 3 | BlockchainCryptoId | int | YES | Wallet-system internal integer ID for the crypto asset. 12 distinct values: 1=BTC, 2=ETH, 4=XRP, 3=BCH, 6=LTC, 8=ETC, 18=ADA, 19=DOGE, 21=XLM, 23=EOS, 27=TRX, 64=SOL. HASH distribution key. Part of the grouping key. (Tier 2 — SP_EXW_Inventory_Snapshot_History via EXW_WalletInventory) |
| 4 | Allocated Total | int | YES | Cumulative count of all wallets of this crypto/status that have been allocated (assigned to any GCID, omnibus or user) up to and including [Date for Report]. Formula: SUM(CASE WHEN Allocated < @EndDate THEN 1 ELSE 0). (Tier 2 — SP_EXW_Inventory_Snapshot_History) |
| 5 | Funded Free | int | YES | Count of FundingVerified wallets that are unoccupied and ready for promotion. Formula: SUM(CASE WHEN WalletStatus='FundingVerified' AND Occupied=0 AND IsPromotionReady=1 THEN 1 ELSE 0). Non-zero only for WalletStatus='FundingVerified' rows. (Tier 2 — SP_EXW_Inventory_Snapshot_History) |
| 6 | Funded Occupied | int | YES | Count of FundingVerified wallets that are actively holding customer funds. Formula: SUM(CASE WHEN WalletStatus='FundingVerified' AND Occupied=1 AND IsPromotionReady=1 THEN 1 ELSE 0). Non-zero only for WalletStatus='FundingVerified' rows. (Tier 2 — SP_EXW_Inventory_Snapshot_History) |
| 7 | Available | int | YES | Count of wallets in the unallocated pool — not yet assigned to any customer or omnibus. Formula: SUM(CASE WHEN Allocated IS NULL OR Allocated > @d THEN 1 ELSE 0). High values indicate a healthy address reserve. (Tier 2 — SP_EXW_Inventory_Snapshot_History) |
| 8 | Date for Report | date | YES | The business date of this snapshot row. Corresponds to the @d parameter passed to SP_EXW_Inventory_Snapshot_History. Used as the DELETE key for idempotent reruns. (Tier 2 — SP_EXW_Inventory_Snapshot_History) |
| 9 | UpdateDate | datetime | YES | Timestamp when this row was inserted by SP_EXW_Inventory_Snapshot_History. Set to GETDATE() at insert time. Reflects ETL execution time, not business date. (Tier 2 — SP_EXW_Inventory_Snapshot_History) |
| 10 | Total AllocatedOmnibuses | int | YES | Count of wallets allocated to omnibus/system accounts (GCID ≤ 0). Subset of [Allocated Total] for system-held wallets. Formula: SUM(CASE WHEN Allocated < @EndDate AND GCID <= 0 THEN 1 ELSE 0). (Tier 2 — SP_EXW_Inventory_Snapshot_History) |
| 11 | Total AllocatedToUsers | int | YES | Count of wallets allocated to real customer accounts (GCID > 0). Subset of [Allocated Total] for customer-held wallets. Formula: SUM(CASE WHEN Allocated < @EndDate AND GCID > 0 THEN 1 ELSE 0). Should equal [Allocated Total] minus [Total AllocatedOmnibuses]. (Tier 2 — SP_EXW_Inventory_Snapshot_History) |
| 12 | Total Created | int | YES | Cumulative count of all wallet addresses ever created for this crypto/status group up to @EndDate. Formula: COUNT(DISTINCT WalletID) WHERE Created < @EndDate. Includes both allocated and available wallets. (Tier 2 — SP_EXW_Inventory_Snapshot_History) |
| 13 | Allocated Daily | int | YES | Count of wallets allocated on exactly [Date for Report] (Allocated = @d). Point-in-time daily allocation velocity — how many new assignments happened that day. (Tier 2 — SP_EXW_Inventory_Snapshot_History) |
| 14 | Created Daily | int | YES | Count of wallets provisioned on exactly [Date for Report] (CreatedDateID = YYYYMMDD(@d)). Point-in-time daily creation velocity — how many new address records were generated that day. (Tier 2 — SP_EXW_Inventory_Snapshot_History) |
| 15 | Allocated 7 days | int | YES | Count of wallets allocated within the 7-day window ending on [Date for Report] (Allocated BETWEEN @d-6 AND @d). Rolling 7-day allocation velocity. (Tier 2 — SP_EXW_Inventory_Snapshot_History) |
| 16 | Allocated 30 days | int | YES | Count of wallets allocated within the 30-day window ending on [Date for Report] (Allocated BETWEEN @d-29 AND @d). Rolling 30-day allocation velocity. (Tier 2 — SP_EXW_Inventory_Snapshot_History) |
| 17 | Created 7 days | int | YES | Count of wallets created within the 7-day window ending on [Date for Report] (Created BETWEEN @d-6 AND @d). Rolling 7-day provisioning velocity. (Tier 2 — SP_EXW_Inventory_Snapshot_History) |
| 18 | Created 30 days | int | YES | Count of wallets created within the 30-day window ending on [Date for Report] (Created BETWEEN @d-29 AND @d). Rolling 30-day provisioning velocity. (Tier 2 — SP_EXW_Inventory_Snapshot_History) |

---

## 5. Lineage

### 5.1 Production Sources

| DWH Column | Source Table | Source Column | Transform |
|-----------|-------------|---------------|-----------|
| WalletStatus | EXW_WalletInventory | WalletStatus | GROUP BY key passthrough |
| BlockchainCryptoName | EXW_WalletInventory | BlockchainCryptoName | GROUP BY key passthrough |
| BlockchainCryptoId | EXW_WalletInventory | BlockchainCryptoId | GROUP BY key / HASH key |
| [Allocated Total] | EXW_WalletInventory | Allocated | SUM CASE WHERE Allocated < @EndDate |
| [Funded Free] | EXW_WalletInventory | WalletStatus, Occupied, IsPromotionReady | SUM CASE filter |
| [Funded Occupied] | EXW_WalletInventory | WalletStatus, Occupied, IsPromotionReady | SUM CASE filter |
| [Available] | EXW_WalletInventory | Allocated | SUM CASE WHERE Allocated IS NULL OR > @d |
| [Date for Report] | SP parameter | @d | Literal |
| UpdateDate | SP runtime | GETDATE() | ETL load time |
| [Total AllocatedOmnibuses] | EXW_WalletInventory | Allocated, GCID | SUM CASE GCID<=0 |
| [Total AllocatedToUsers] | EXW_WalletInventory | Allocated, GCID | SUM CASE GCID>0 |
| [Total Created] | EXW_WalletInventory | WalletID, Created | COUNT DISTINCT WHERE Created < @EndDate |
| [Allocated Daily] | EXW_WalletInventory | WalletID, Allocated | COUNT DISTINCT WHERE Allocated = @d |
| [Created Daily] | EXW_WalletInventory | WalletID, CreatedDateID | COUNT DISTINCT WHERE CreatedDateID = YYYYMMDD(@d) |
| [Allocated 7 days] | EXW_WalletInventory | Allocated | SUM CASE 7-day window |
| [Allocated 30 days] | EXW_WalletInventory | Allocated | SUM CASE 30-day window |
| [Created 7 days] | EXW_WalletInventory | Created | SUM CASE 7-day window |
| [Created 30 days] | EXW_WalletInventory | Created | SUM CASE 30-day window |

### 5.2 ETL Pipeline

```
EXW_dbo.EXW_WalletInventory (live blockchain address master — 742K+ BTC, 272K+ ETH, etc.)
  |-- SP_EXW_Inventory_Snapshot_History @d DATE
  |   Aggregates by (date, BlockchainCryptoName, BlockchainCryptoId, WalletStatus)
  |   DELETE WHERE [Date for Report] = @d + INSERT (idempotent)
  v
EXW_dbo.EXW_Inventory_Snapshot_History (daily snapshot, 31K rows)
  |-- UC Target: _Not_Migrated ---|
  N/A
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BlockchainCryptoId | EXW_dbo.EXW_WalletInventory | Aggregation source | All metrics aggregated from EXW_WalletInventory by this key |

### 6.2 Referenced By

No downstream consumers found in SSDT. This table is used operationally for address-pool health monitoring.

---

## 7. Sample Queries

### Latest snapshot — available pool by crypto

```sql
SELECT
    [BlockchainCryptoName],
    [BlockchainCryptoId],
    [WalletStatus],
    [Available],
    [Allocated Total],
    [Total AllocatedToUsers],
    [Total AllocatedOmnibuses]
FROM [EXW_dbo].[EXW_Inventory_Snapshot_History]
WHERE [Date for Report] = (SELECT MAX([Date for Report]) FROM [EXW_dbo].[EXW_Inventory_Snapshot_History])
ORDER BY [BlockchainCryptoName], [WalletStatus];
```

### 30-day allocation velocity trend for BTC

```sql
SELECT
    [Date for Report],
    SUM([Allocated Daily])  AS AllocatedDaily,
    SUM([Allocated 7 days]) AS Allocated7d,
    SUM([Allocated 30 days]) AS Allocated30d
FROM [EXW_dbo].[EXW_Inventory_Snapshot_History]
WHERE [BlockchainCryptoId] = 1  -- BTC
  AND [Date for Report] >= DATEADD(d, -90, GETDATE())
GROUP BY [Date for Report]
ORDER BY [Date for Report] DESC;
```

### FundingVerified occupancy rate by crypto (latest day)

```sql
SELECT
    [BlockchainCryptoName],
    [Funded Occupied],
    [Funded Free],
    CASE WHEN ([Funded Occupied] + [Funded Free]) > 0
         THEN CAST([Funded Occupied] AS FLOAT) / ([Funded Occupied] + [Funded Free]) * 100.0
         ELSE 0 END AS OccupancyPct
FROM [EXW_dbo].[EXW_Inventory_Snapshot_History]
WHERE [WalletStatus] = 'FundingVerified'
  AND [Date for Report] = (SELECT MAX([Date for Report]) FROM [EXW_dbo].[EXW_Inventory_Snapshot_History])
ORDER BY [BlockchainCryptoName];
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. SP comment (Inessa Kontorovich, 2020-05-21): "Take snapshot of inventory Funded, Occupied and Available each date. We don't track this currently."

---

*Generated: 2026-04-20 | Quality: 8.3/10 | Phases: 11/14*
*Tiers: 0 T1, 18 T2, 0 T3, 0 T4, 0 T5 | Elements: 18/18, Logic: 4 subsections*
*Object: EXW_dbo.EXW_Inventory_Snapshot_History | Type: Table | Production Source: EXW_WalletInventory (internal)*
