# EXW_dbo.Hourly_WalletInventory

> Hourly snapshot of wallet pool inventory levels — one row per CryptoID × WalletStatus, rebuilt on every SP_EXW_Hourly run. Covers native coin wallets only (ERC-20 tokens excluded). Provides real-time visibility into pool capacity (allocated vs free), promotion-ready supply, and recent allocation velocity (today, yesterday, 7-day windows) for Tableau KPI dashboards and operational monitoring.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | EXW_Wallet.WalletPool + EXW_Wallet.CustomerWalletsView → SP_EXW_Hourly |
| **Refresh** | Hourly — TRUNCATE + INSERT on each run |
| **Synapse Distribution** | HASH (CryptoID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — Synapse-only operational KPI feed |

---

## 1. Business Meaning

Hourly_WalletInventory provides a current-state snapshot of eToro Wallet Exchange's pre-provisioned blockchain wallet pool, broken down by cryptocurrency and pool status. It is one of six tables rebuilt each hour by SP_EXW_Hourly and is the primary operational KPI source for wallet inventory management — answering questions like "how many free ETH wallets do we have?", "how fast are we allocating wallets today?", and "are we running low on inventory for a specific crypto?"

**The pre-provisioned pool model**: eToro pre-creates blockchain wallets in advance (via BitGo or CUG custody providers) and stores them in WalletDB.Wallet.WalletPool. When a customer needs a wallet, a free pool wallet is assigned (allocated) to them instantly, avoiding on-chain creation latency. With ~2.47M pool entries, this represents a large provisioning buffer.

**Scope**: Native coin wallets only. ERC-20 token wallets (e.g., USDC, LINK — which share an ETH blockchain address) are excluded by the filter `WHERE CryptoID = BlockchainCryptoId`. As of 2026-04-20: 26 rows, 12 native cryptos (BTC, ETH, LTC, XLM, BCH, XRP, ADA, TRX, DOGE, SOL, ETC, a 12th crypto), 5 WalletStatuses, ~2.47M total wallets: 1.49M allocated (60%), 977K free (40%).

**Key operational metrics**:
- BTC: largest pool at 742,266 wallets (79.7% allocated)
- ETH has a unique `FundingVerified` sub-pool of 78,269 wallets with 609 PromotionReadyAvailable
- Today's allocation pace (2026-04-20): 115 wallets allocated since midnight
- Yesterday: 853 allocations

---

## 2. Business Logic

### 2.1 Wallet Scope — Native Coins Only

**What**: Only native coin wallets are included. ERC-20 token wallets are excluded.

**Columns Involved**: CryptoID, WalletStatus, TotalWalletsInInventory

**Rules**:
- Source: `#EXW_WalletInventory` temp table, populated from `EXW_Wallet.WalletPool` + joins
- Filter: `WHERE CryptoID = BlockchainCryptoId` — includes only wallets where the CryptoID equals the blockchain-level ID (native coins). ERC-20 tokens have `CryptoIDERC ≠ BlockchainCryptoId` and are excluded
- 12 native cryptos present as of 2026-04-20. ERC-20 tokens (USDC, LINK, etc.) managed by EXW do not appear here

### 2.2 WalletStatus Classification

**What**: WalletStatus classifies pool wallets by their lifecycle stage.

**Columns Involved**: WalletStatus, TotalWalletsInInventory, TotalAllocated, TotalFreeInventory

**Rules**:
- Source: `CopyFromLake.WalletDB_Dictionary_WalletPoolStatuses.Name` — resolved via most recent `EXW_Wallet.WalletPoolStatuses` entry per wallet (ROW_NUMBER PARTITION BY WalletPoolId ORDER BY Occurred DESC = 1)
- Values observed: `Verified` (primary active state), `FundingVerified` (funded and verified), `Pending` (creation in progress), `Failed` (creation failed), `VerifiedForAssign` (ready for special assignment)
- `Verified` dominates: 19 of 26 rows, ~95% of total wallets

### 2.3 Allocation State

**What**: TotalAllocated and TotalFreeInventory track how many pool wallets are assigned vs available.

**Columns Involved**: TotalAllocated, TotalFreeInventory, TotalWalletsInInventory

**Rules**:
- `TotalAllocated` = `SUM(CASE WHEN GCID IS NOT NULL THEN 1 ELSE 0 END)` — wallets linked to a customer via `EXW_Wallet.CustomerWalletsView`
- `TotalFreeInventory` = `SUM(CASE WHEN GCID IS NULL THEN 1 ELSE 0 END)` — unallocated wallets in the pool
- `TotalAllocated + TotalFreeInventory = TotalWalletsInInventory` (all wallets are either allocated or free)
- A wallet becomes `Occupied` (GCID IS NOT NULL) when a customer is linked via CustomerWalletsView

### 2.4 Promotion-Ready Wallets

**What**: PromotionReady tracks wallets earmarked for promotion campaigns.

**Columns Involved**: PromotionReadyAvailable, PromotionReadyAllocated

**Rules**:
- `IsPromotionReady` (in #EXW_WalletInventory) = 1 when: `PromotionTagId = 1` AND `CryptoID IN (SELECT DISTINCT BlockchainCryptoId FROM EXW_Wallet.CryptoTypes)`
- `PromotionReadyAvailable` = promotion-eligible wallets that are not yet allocated (GCID IS NULL)
- `PromotionReadyAllocated` = promotion-eligible wallets currently assigned to customers
- As of 2026-04-20: only ETH FundingVerified wallets have PromotionReady supply (609 available, 77,660 allocated)

### 2.5 Temporal Allocation Metrics

**What**: Multiple time-window counters for monitoring allocation velocity.

**Columns Involved**: AllocatedToday, TodayAllocationPace, YesterdayAllocation, Allocated7Days, Created7Days, SameDayLastWeekAllocation

**Rules**:
- `Allocated date` = `CAST(CustomerWalletsView.Occurred AS DATE)` — the date the wallet was assigned to a customer
- `AllocatedToday`: wallets where `Allocated BETWEEN CAST(GETDATE() AS DATE) AND GETDATE()` (since midnight of the SP run date)
- `TodayAllocationPace` = `(AllocatedToday × DATEDIFF(HOUR, CAST(GETDATE() AS DATE), GETDATE())) / 24` — see §3.4 gotcha
- `YesterdayAllocation`: `Allocated BETWEEN CAST(GETDATE()-1 AS DATE) AND CAST(GETDATE() AS DATE)` (yesterday 00:00 to today 00:00)
- `SameDayLastWeekAllocation`: `Allocated BETWEEN CAST(GETDATE()-7 AS DATE) AND CAST(GETDATE()-6 AS DATE)` (the same calendar date last week)
- `Allocated7Days`: `Allocated BETWEEN CAST(GETDATE()-7 AS DATE) AND GETDATE()` (rolling 7-day window)
- `Created7Days`: `Created BETWEEN CAST(GETDATE()-7 AS DATE) AND GETDATE()` — wallets added to pool in last 7 days (pool replenishment rate)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CryptoID) — co-located with Hourly_CustomerBalances, Hourly_OmnibusBalances, and Hourly_RedeemActivity for co-located JOINs on CryptoID. HEAP — trivial full scans given 26 total rows.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|----------------------|
| Free wallets by crypto (capacity check) | `WHERE WalletStatus = 'Verified' GROUP BY CryptoID ORDER BY TotalFreeInventory ASC` |
| Low inventory alert (< N free wallets) | `WHERE WalletStatus = 'Verified' AND TotalFreeInventory < 10000` |
| Today's allocation rate vs yesterday | `SELECT CryptoID, AllocatedToday, YesterdayAllocation, SameDayLastWeekAllocation` |
| Total pool size across all statuses | `GROUP BY CryptoID` with `SUM(TotalWalletsInInventory)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.EXW_WalletInventory | `CryptoID` | Compare hourly snapshot vs longer-term inventory history |
| EXW_dbo.Hourly_RedeemActivity | `CryptoID` | Compare redemption drain rate vs available free inventory |

### 3.4 Gotchas

- **ERC-20 wallets excluded**: Cryptos like USDC, LINK, COMP, and other ERC-20 tokens do not appear in this table. Only the 12 native coin blockchains are tracked here
- **TodayAllocationPace formula is non-standard**: The SP comment says "pro rate hourly for the full day," but the formula `(AllocatedToday × hours_elapsed) / 24` produces a value that decreases as hours_elapsed increases — this is NOT a full-day extrapolation. At hour 12, with 100 allocations, the formula gives 50 (not 200). The correct full-day extrapolation would be `AllocatedToday × 24 / hours_elapsed`. Use `AllocatedToday` and `YesterdayAllocation` for reliable comparisons instead
- **WalletStatus = 'Verified' is the operational subset**: Most operational monitoring should filter to `WalletStatus = 'Verified'`. Failed wallets (0 free allocations) and VerifiedForAssign (1 wallet each) represent edge-case states
- **TRUNCATE each run**: No historical trend data — this is always the current moment's snapshot
- **Grain is CryptoID × WalletStatus**: Summing `TotalFreeInventory` across all WalletStatuses for a CryptoID gives the true total free count. Filter to `WalletStatus = 'Verified'` for the primary operational supply
- **FundingVerified is ETH-only**: Only ETH has a FundingVerified sub-pool (78,269 wallets). These are wallets pre-funded with gas ETH for ERC-20 operations

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived from SP code analysis — aggregated CASE/SUM expressions, lookup-enriched, or ETL-computed. No direct passthrough columns; all values are aggregated across WalletPool entries. |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CryptoID | int | NULL | Native coin cryptocurrency identifier. From EXW_Wallet.CryptoTypes.CryptoID, resolved via JOIN on WalletPool.BlockchainCryptoId. ERC-20 tokens excluded (WHERE CryptoID = BlockchainCryptoId). Distribution key. GROUP BY key alongside WalletStatus. (Tier 2 — SP_EXW_Hourly) |
| 2 | WalletStatus | nvarchar(1000) | NULL | Pool lifecycle status from CopyFromLake.WalletDB_Dictionary_WalletPoolStatuses.Name. Most recent status per wallet via ROW_NUMBER() on EXW_Wallet.WalletPoolStatuses. Values: Verified (active), FundingVerified (ETH gas-funded), Pending (in progress), Failed (failed creation), VerifiedForAssign (special assignment). GROUP BY key. (Tier 2 — SP_EXW_Hourly) |
| 3 | TotalWalletsInInventory | int | NULL | Total count of pool wallets in this CryptoID × WalletStatus group, regardless of allocation state. COUNT(WalletPoolID). (Tier 2 — SP_EXW_Hourly) |
| 4 | TotalAllocated | int | NULL | Count of wallets currently assigned to customers (GCID IS NOT NULL in CustomerWalletsView). TotalAllocated + TotalFreeInventory = TotalWalletsInInventory. (Tier 2 — SP_EXW_Hourly) |
| 5 | TotalFreeInventory | int | NULL | Count of unallocated wallets available for customer assignment (GCID IS NULL). Primary operational capacity metric. (Tier 2 — SP_EXW_Hourly) |
| 6 | PromotionReadyAvailable | int | NULL | Count of promotion-eligible unallocated wallets: IsPromotionReady=1 AND GCID IS NULL. IsPromotionReady requires PromotionTagId=1 (from WalletPoolStatuses) AND CryptoID in EXW_Wallet.CryptoTypes.BlockchainCryptoIds. Currently non-zero only for ETH FundingVerified (609 as of 2026-04-20). (Tier 2 — SP_EXW_Hourly) |
| 7 | PromotionReadyAllocated | int | NULL | Count of promotion-eligible wallets currently assigned to customers: IsPromotionReady=1 AND GCID IS NOT NULL. Currently 77,660 ETH FundingVerified wallets. (Tier 2 — SP_EXW_Hourly) |
| 8 | Created7Days | int | NULL | Count of wallets added to EXW_Wallet.WalletPool in the last 7 days. Measures pool replenishment rate. Uses WalletPool.Created (wallet pool creation timestamp). (Tier 2 — SP_EXW_Hourly) |
| 9 | Allocated7Days | int | NULL | Count of wallets allocated to customers in the last 7 days (CustomerWalletsView.Occurred within rolling 7-day window). Measures recent demand on pool supply. (Tier 2 — SP_EXW_Hourly) |
| 10 | AllocatedToday | int | NULL | Count of wallets allocated to customers since midnight of the SP run date (CAST(GETDATE() AS DATE) to GETDATE()). Raw today-so-far allocation count. (Tier 2 — SP_EXW_Hourly) |
| 11 | TodayAllocationPace | int | NULL | Integer formula: (AllocatedToday × hours_elapsed_today) / 24. SP comment: "pro rate hourly for the full day." Note: this formula does NOT produce a full-day extrapolation — see §3.4 gotcha. Use AllocatedToday + YesterdayAllocation for reliable trend analysis. (Tier 2 — SP_EXW_Hourly) |
| 12 | YesterdayAllocation | int | NULL | Count of wallets allocated on the previous calendar day (CAST(GETDATE()-1 AS DATE) to CAST(GETDATE() AS DATE)). Day-over-day comparison baseline. (Tier 2 — SP_EXW_Hourly) |
| 13 | SameDayLastWeekAllocation | int | NULL | Count of wallets allocated exactly 7 calendar days ago (CAST(GETDATE()-7 AS DATE) to CAST(GETDATE()-6 AS DATE)). Week-over-week comparison for the same weekday. (Tier 2 — SP_EXW_Hourly) |
| 14 | UpdateDate | datetime | NULL | ETL timestamp set to GETDATE() at INSERT time. Reflects the specific hourly run that produced this row. (Tier 2 — SP_EXW_Hourly) |
| 15 | ReportDate | date | NULL | Date of the SP_EXW_Hourly run. CAST(GETDATE() AS DATE). Same for all rows in a single run. (Tier 2 — SP_EXW_Hourly) |

---

## 5. Lineage

See [Hourly_WalletInventory.lineage.md](Hourly_WalletInventory.lineage.md) for full column-level lineage.

### 5.2 ETL Pipeline

```
WalletDB.Wallet.WalletPool (production — pre-provisioned blockchain wallet pool)
  |-- EXW_Wallet.WalletPool (live Synapse table) --|
  |-- EXW_Wallet.WalletPoolStatuses (latest status, ROW_NUMBER) --|
  |-- CopyFromLake.WalletDB_Dictionary_WalletPoolStatuses (status names) --|
  |-- EXW_Wallet.CustomerWalletsView (GCID + allocation date) --|
  |-- EXW_Wallet.CryptoTypes + BlockchainCryptos (crypto names) --|
  |-- EXW_Wallet.WalletAddresses (main address) --|
  |-- SP_EXW_Hourly: multi-join → #EXW_WalletInventory (HASH(GCID), HEAP) --|
  |-- WHERE CryptoID = BlockchainCryptoId (native coins only) --|
  |-- GROUP BY CryptoID, WalletStatus --|
  v
EXW_dbo.Hourly_WalletInventory
  (26 rows, 12 cryptos, 5 WalletStatuses, ~2.47M wallets, HASH(CryptoID), HEAP)
  UC Target: _Not_Migrated (operational KPI, Synapse-only)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CryptoID | EXW_Wallet.CryptoTypes | Crypto type metadata (native coin CryptoID = BlockchainCryptoId) |
| WalletStatus | EXW_Wallet.WalletPoolStatuses + CopyFromLake.WalletDB_Dictionary_WalletPoolStatuses | Lifecycle status of pool wallets |
| TotalAllocated / TotalFreeInventory | EXW_Wallet.WalletPool + EXW_Wallet.CustomerWalletsView | Individual wallet allocation state |
| AllocationDate columns | EXW_Wallet.CustomerWalletsView | Date wallet was allocated to customer |

### 6.2 Referenced By (other objects point to this)

No SSDT stored procedures or views found that reference EXW_dbo.Hourly_WalletInventory. This table is consumed directly by Tableau dashboards for operational monitoring of wallet pool capacity.

---

## 7. Sample Queries

### 7.1 Current free wallet supply by crypto (Verified wallets only)

```sql
SELECT
    CryptoID,
    TotalWalletsInInventory,
    TotalAllocated,
    TotalFreeInventory,
    CAST(100.0 * TotalAllocated / NULLIF(TotalWalletsInInventory, 0) AS decimal(5,1)) AS AllocPct
FROM [EXW_dbo].[Hourly_WalletInventory]
WHERE WalletStatus = 'Verified'
ORDER BY TotalFreeInventory ASC
```

### 7.2 Today vs yesterday allocation rate by crypto

```sql
SELECT
    CryptoID,
    AllocatedToday,
    YesterdayAllocation,
    SameDayLastWeekAllocation,
    Allocated7Days
FROM [EXW_dbo].[Hourly_WalletInventory]
WHERE WalletStatus = 'Verified'
ORDER BY AllocatedToday DESC
```

### 7.3 Promotion-ready supply check

```sql
SELECT
    CryptoID,
    WalletStatus,
    PromotionReadyAvailable,
    PromotionReadyAllocated,
    TotalFreeInventory
FROM [EXW_dbo].[Hourly_WalletInventory]
WHERE PromotionReadyAvailable > 0
ORDER BY PromotionReadyAvailable DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-20 | Quality: 8.8/10 | Phases: 13/14*
*Tiers: 0 T1, 15 T2, 0 T3, 0 T4, 0 T5 | Elements: 15/15, Logic: 10/10*
*Object: EXW_dbo.Hourly_WalletInventory | Type: Table | Production Source: SP_EXW_Hourly ← EXW_Wallet.WalletPool + CustomerWalletsView*
