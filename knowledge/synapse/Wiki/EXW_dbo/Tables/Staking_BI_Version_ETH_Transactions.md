# EXW_dbo.Staking_BI_Version_ETH_Transactions

> BI-enriched ETH staking transaction table providing position-level detail for the eToro ETH staking program (2021–2023). Each row is one staking operation (wallet-level ETH delegation), enriched with club tier, reward allocation metrics (EligibleStakingDaysCount, AverageDailyPositionPerTransaction, ClientMonthlyStakingReward), and eligibility flags. Transaction-level counterpart to the month-level summary in Staking_BI_Version_WalletUserRewards. All data frozen since May 2023.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | WalletDB.Staking.Staking + WalletDB.Staking.StakingTransactions + WalletDB.Wallet.CustomerWalletsView (via EXW_Staking External Tables → unknown external ETL enrichment) |
| **Refresh** | Frozen — ETH staking program ended May 2023 |
| **Row Count** | Unknown — no MCP query run; estimated ~2,000–35,000 rows based on WalletDB.Staking.Staking row count (2,181 at wiki generation) and EligibleTransactions range in WalletUserRewards (1–5+ per user/month) |
| **Synapse Distribution** | HASH (GCID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — no Gold layer target |

---

## 1. Business Meaning

EXW_dbo.Staking_BI_Version_ETH_Transactions is the transaction-level detail table for the eToro ETH staking program, providing the position-by-position breakdown that underpins the monthly reward summaries in `Staking_BI_Version_WalletUserRewards`.

**Relationship to summary table**: While `Staking_BI_Version_WalletUserRewards` has one row per wallet per reward month (user-month grain), this table has one row per staking operation (transaction grain). Multiple rows here can aggregate to one row in the summary table — the `EligibleTransactions` column in the summary counts how many rows this table contributes per user-month.

**What each row represents**: A single ETH staking transfer — the delegation of a specific ETH amount from a user's wallet to eToro's staking pool (address `0xCB2A66540680c344bab5f818d68c3e4B9D57363B`). The row includes the initiation timestamp (`Staking_DateTime`), amount staked (`Amount`), blockchain fees (always 0 — eToro absorbs costs), final status (always Completed for ETH program records), and BI-computed reward allocation metrics.

**Reward allocation mechanics**: The key BI additions are:
- `EligibleStakingDaysCount`: how many days of the reward month this specific position was staking-eligible
- `AverageDailyPositionPerTransaction`: the average ETH held across those eligible days
- `ClientMonthlyStakingReward`: the ETH reward earned by this specific transaction for the reward month

**StakingMonthID** groups transactions into their reward month — note this is the month the reward was calculated for, not necessarily the month the staking operation was initiated.

**eToro staking program context**: ETH staking ran Jul 2021–May 2023. eToro executed staking on behalf of users with real (non-CFD) ETH positions. Rewards distributed monthly as position airdrops (minimum ~$1 USD). eToro absorbed all blockchain fees.

---

## 2. Business Logic

### 2.1 Transaction-to-Month Assignment

**What**: Each staking transaction is attributed to the reward month during which its contribution was calculated.

**Columns Involved**: `StakingMonthID`, `StakingMonth`, `Staking_DateTime`

**Rules**:
- `StakingMonthID` is the YYYYMM integer of the reward month (e.g., 202107 = July 2021)
- `StakingMonth` is the human-readable label (e.g., "Jul-2021")
- A staking transaction initiated in month N may contribute to reward months N, N+1, ... depending on program rules
- `Staking_DateTime` records when the staking operation was initiated (source: WalletDB.Staking.Staking.Occurred)

### 2.2 Staking Eligibility

**What**: Not all staking positions contribute equally to monthly rewards — eligibility and duration determine each transaction's share.

**Columns Involved**: `IsStakingEligible`, `EffectiveStakingStartDate`, `EligibleStakingDaysCount`

**Rules**:
- `IsStakingEligible = 1`: position contributed to rewards for the reward month
- `IsStakingEligible = 0`: position was not eligible (new position with insufficient holding period, or other criteria)
- `EffectiveStakingStartDate`: the date from which this position started accumulating eligibility for the reward month
- `EligibleStakingDaysCount`: number of days within the reward month during which this position was eligible

### 2.3 Reward Allocation Per Transaction

**What**: The monthly reward is allocated across contributing transactions proportionally to their average daily position.

**Columns Involved**: `AverageDailyPositionPerTransaction`, `ClientMonthlyStakingReward`

**Rules**:
- `AverageDailyPositionPerTransaction`: average ETH amount held across eligible staking days for this transaction
- `ClientMonthlyStakingReward`: the portion of the total monthly ETH reward attributable to this specific transaction
- `SUM(ClientMonthlyStakingReward)` per GCID + StakingMonthID should equal `MonthlyRewards` in `Staking_BI_Version_WalletUserRewards` for real users

### 2.4 Status Lifecycle

**What**: Each staking operation passes through Pending → Completed (or Pending → Failed).

**Columns Involved**: `StatusID`, `Status_Name`, `Status_DateTime`

**Rules**:
- `StatusID` values: 1=Pending, 2=Failed, 3=Completed (source: WalletDB.Staking.StakingStatuses)
- `Status_Name`: human-readable label for StatusID
- `Status_DateTime`: timestamp of the most recent status transition
- For ETH staking program records: expected Completed (3) for all contributing transactions

### 2.5 Idempotency via CorrelationID

**What**: Each staking operation has a unique CorrelationID for deduplication.

**Columns Involved**: `CorrelationID`, `Id`

**Rules**:
- `CorrelationID` (uniqueidentifier) is the business idempotency key from `WalletDB.Staking.Staking.CorrelationId`
- `Id` is the auto-generated surrogate key (bigint, IDENTITY from WalletDB.Staking.Staking.Id)
- Both are preserved in the DWH for cross-system reconciliation

### 2.6 Fee Structure

**What**: Both eToro and blockchain fees are tracked but were zero throughout the ETH staking program.

**Columns Involved**: `EtoroFee`, `BlockchainEstFee`

**Rules**:
- `EtoroFee`: eToro's service fee for processing the staking delegation. Currently 0 across all records — eToro absorbs staking costs.
- `BlockchainEstFee`: estimated blockchain gas fee. Currently 0 across all records.
- Source: WalletDB.Staking.StakingTransactions (1:1 relationship with Staking.Staking)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(GCID) — optimal for per-user aggregations and JOINs to other GCID-distributed tables (EXW_DimUser, Staking_BI_Version_WalletUserRewards). HEAP appropriate for this small frozen table.

### 3.2 Grain Awareness

This table is transaction-grain — multiple rows per user per month. Always aggregate before joining to month-grain tables.

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Reconcile with monthly summary | `SUM(ClientMonthlyStakingReward)` GROUP BY GCID, StakingMonthID; compare to WalletUserRewards.MonthlyRewards |
| Count staking transactions per user/month | `COUNT(*) WHERE IsStakingEligible=1 AND IsTestUser=0 GROUP BY GCID, StakingMonthID` |
| Filter to production users | `WHERE IsTestUser = 0` |
| Check fee history | `SELECT EtoroFee, BlockchainEstFee FROM ... GROUP BY EtoroFee, BlockchainEstFee` — expect all zeros |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.Staking_BI_Version_WalletUserRewards | `t.GCID=r.GCID AND t.StakingMonthID=r.StakingMonthID` | Verify SUM(ClientMonthlyStakingReward) = MonthlyRewards |
| EXW_dbo.EXW_DimUser | `d.GCID = t.GCID` | User demographics enrichment |
| EXW_dbo.Staking_ETH_Rewards_Parameters | Year/Month of StakingMonthID | Pool-level yield parameters |

### 3.4 Gotchas

- **Transaction grain vs. month grain**: This is one row per staking operation, not one row per user-month. Never directly JOIN to Staking_BI_Version_WalletUserRewards without aggregating first.
- **StakingMonthID = reward month, not transaction month**: A staking operation in Jun 2021 may appear in StakingMonthID=202107 if its first reward month was July.
- **CryptoID always 2 (ETH)**: This table contains only ETH staking operations. No filtering needed, but include in queries for documentation clarity.
- **EtoroFee and BlockchainEstFee are always 0**: Do not use for fee analysis — values reflect eToro's policy of absorbing staking costs.
- **All fees in ETH native units**: Amount, EtoroFee, BlockchainEstFee, ClientMonthlyStakingReward are all in ETH (not USD).
- **WalletID as uniqueidentifier**: Correctly typed — CAST needed when joining to Staking_WalletUserRewards (varchar).
- **Status_DateTime precision**: datetime2(7) — includes sub-second precision from upstream source.

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
| 1 | StakingMonth | varchar(50) | YES | Human-readable label for the reward month (e.g., "Jul-2021"). Derived from StakingMonthID; format "Mmm-YYYY". (Tier 2 — derived from StakingMonthID) |
| 2 | StakingMonthID | int | YES | The reward month in YYYYMM format (e.g., 202107). Identifies which monthly reward calculation this transaction contributed to. Note: reward month may differ from the transaction initiation month. (Tier 2 — derived from reward month assignment logic) |
| 3 | Id | bigint | NO | Auto-incrementing surrogate key from WalletDB.Staking.Staking.Id (IDENTITY). Uniquely identifies the staking operation. FK anchor for StakingStatuses and StakingTransactions in production. (Tier 1 — WalletDB.Staking.Staking) |
| 4 | WalletID | uniqueidentifier | NO | The wallet from which ETH was staked. FK to Wallet.Wallets.WalletId. Stored as native uniqueidentifier (correctly typed). Used with GCID for per-user lookups. (Tier 1 — WalletDB.Staking.Staking) |
| 5 | GCID | int | YES | Group Customer ID linking the wallet owner. Derived by joining WalletID to WalletDB.Wallet.CustomerWalletsView. HASH distribution key. (Tier 2 — EXW_Staking ETL enrichment via CustomerWalletsView) |
| 6 | Club | varchar(50) | NO | eToro club tier at time of staking. Same 7 values as other Staking BI tables: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal. Determines RevShare. (Tier 2 — EXW_Staking ETL enrichment via CustomerWalletsView) |
| 7 | RevShare | numeric(2,2) | NO | Club-tier revenue share as decimal fraction. Values: 0.75=Internal, 0.85=Bronze/Silver/Gold/Platinum, 0.90=Platinum Plus. Derived by Club tier mapping. (Tier 2 — EXW_Staking ETL enrichment) |
| 8 | Amount | decimal(36,18) | NO | Quantity of ETH staked in this operation, in native ETH units (e.g., 1.345547 ETH). High precision (18 decimals). Summed across Completed operations for GetStakingTotals in production. (Tier 1 — WalletDB.Staking.Staking) |
| 9 | CorrelationID | uniqueidentifier | NO | Idempotency key for the staking operation, generated by the calling service. Used by WalletDB for duplicate detection (NOT EXISTS check before insert). Preserved for cross-system reconciliation. (Tier 1 — WalletDB.Staking.Staking) |
| 10 | CryptoID | int | NO | The cryptocurrency being staked. FK to Wallet.CryptoTypes.CryptoID. Value is always 2 (ETH) in this dataset — this is an ETH-only staking program. (Tier 1 — WalletDB.Staking.Staking) |
| 11 | Staking_DateTime | datetime2(7) | NO | Timestamp when the staking operation was initiated (maps to WalletDB.Staking.Staking.Occurred, which defaults to UTC now). Rename only. (Tier 1 — WalletDB.Staking.Staking) |
| 12 | Staking_Date | date | YES | Date portion of Staking_DateTime (date only, no time component). Derived for date-based filtering. (Tier 2 — derived from Staking_DateTime) |
| 13 | Staking_DateID | int | YES | Date key in YYYYMMDD integer format derived from Staking_DateTime (e.g., 20210701). (Tier 2 — derived from Staking_DateTime) |
| 14 | EtoroFee | decimal(36,18) | NO | eToro's service fee for processing the staking delegation, in ETH units. Currently 0 across all records — eToro absorbs staking costs. (Tier 1 — WalletDB.Staking.StakingTransactions) |
| 15 | BlockchainEstFee | decimal(36,18) | NO | Estimated blockchain gas fee for the staking transaction, in ETH units. Currently 0 across all records — blockchain fees absorbed by eToro. (Tier 1 — WalletDB.Staking.StakingTransactions) |
| 16 | StatusID | tinyint | NO | Numeric lifecycle status of this staking operation. Values: 1=Pending, 2=Failed, 3=Completed. Source: WalletDB.Staking.StakingStatuses (latest status per staking Id). For ETH program records, expected Completed (3). (Tier 2 — WalletDB.Staking.StakingStatuses) |
| 17 | Status_Name | varchar(64) | NO | Human-readable label for StatusID (e.g., "Completed", "Pending", "Failed"). Derived from status lookup. (Tier 2 — derived from StatusID mapping) |
| 18 | Status_DateTime | datetime2(7) | NO | Timestamp of the most recent status transition for this staking operation (source: WalletDB.Staking.StakingStatuses.Occurred). datetime2(7) precision. (Tier 2 — WalletDB.Staking.StakingStatuses) |
| 19 | Status_Date | date | YES | Date portion of Status_DateTime. Derived for date-based filtering. (Tier 2 — derived from Status_DateTime) |
| 20 | IsStakingEligible | int | NO | Eligibility flag: 1=this staking transaction contributed to rewards for the assigned StakingMonthID; 0=not eligible. (Tier 3 — inferred from column name + staking program logic) |
| 21 | EffectiveStakingStartDate | date | YES | The date from which this position started accumulating staking eligibility for the reward month. May differ from Staking_Date if eligibility has a minimum holding period. (Tier 3 — inferred from column name + staking program logic) |
| 22 | EligibleStakingDaysCount | int | YES | Number of calendar days within the reward month during which this position was staking-eligible. Used in AverageDailyPositionPerTransaction computation. (Tier 3 — inferred from column name + staking program logic) |
| 23 | AverageDailyPositionPerTransaction | float | YES | Average ETH amount held in this staking position across eligible staking days for the reward month. Basis for ClientMonthlyStakingReward allocation. (Tier 3 — inferred from column name + staking reward methodology) |
| 24 | ClientMonthlyStakingReward | float | YES | The ETH reward attributable to this specific staking transaction for the reward month. SUM across GCID+StakingMonthID should reconcile to MonthlyRewards in Staking_BI_Version_WalletUserRewards. (Tier 3 — inferred from column name + reward allocation pattern) |
| 25 | IsTestUser | int | NO | Test account flag: 1=internal/test eToro account; 0=real production user. Source: WalletDB.Wallet.CustomerWalletsView IsTest enrichment. Filter `WHERE IsTestUser = 0` for production analysis. (Tier 2 — EXW_Staking ETL enrichment via CustomerWalletsView) |
| 26 | UpdateDate | datetime | NO | Timestamp when this row was written to the DWH by the external ETL. (Tier 4 — unknown ETL) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Id | WalletDB.Staking.Staking | Id | Passthrough (bigint IDENTITY) |
| WalletID | WalletDB.Staking.Staking | WalletId | Passthrough (uniqueidentifier) |
| Amount | WalletDB.Staking.Staking | Amount | Passthrough (decimal 36,18) |
| CorrelationID | WalletDB.Staking.Staking | CorrelationId | Passthrough (uniqueidentifier) |
| CryptoID | WalletDB.Staking.Staking | CryptoId | Passthrough (int; always 2=ETH) |
| Staking_DateTime | WalletDB.Staking.Staking | Occurred | Rename only (datetime2 7) |
| EtoroFee | WalletDB.Staking.StakingTransactions | EtoroFee | Passthrough (decimal 36,18; always 0) |
| BlockchainEstFee | WalletDB.Staking.StakingTransactions | BlockchainEstFee | Passthrough (decimal 36,18; always 0) |
| GCID, Club, IsTestUser | WalletDB.Wallet.CustomerWalletsView | Gcid, Club, IsTest | JOIN enrichment via WalletID |

### 5.2 ETL Pipeline

```
WalletDB.Staking.Staking (production — WalletDB)
WalletDB.Staking.StakingTransactions (production — WalletDB)
WalletDB.Staking.StakingStatuses (production — WalletDB, latest status)
WalletDB.Wallet.CustomerWalletsView (GCID/Club/IsTestUser enrichment)
  |-- Generic Pipeline (Bronze export) --|
  v
EXW_Staking.Staking (External Table, Bronze)
EXW_Staking.StakingRewards (External Table, Bronze)
  |-- Unknown external ETL (Databricks/ADF — not in SSDT) --|
  |-- BI enrichment: GCID, Club, RevShare, IsTestUser --|
  |-- BI computation: IsStakingEligible, EffectiveStakingStartDate --|
  |-- BI computation: EligibleStakingDaysCount, AverageDailyPositionPerTransaction --|
  |-- BI computation: ClientMonthlyStakingReward --|
  v
EXW_dbo.Staking_BI_Version_ETH_Transactions (frozen May 2023)
  |-- No Gold layer UC target --|
  v
UC Target: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| WalletID | WalletDB.Wallet.Wallets | Wallet initiating the staking operation |
| Id | WalletDB.Staking.Staking | Source staking operation record |
| GCID | EXW_dbo.EXW_DimUser | GCID dimension for user demographics |
| StakingMonthID (logical) | EXW_dbo.Staking_ETH_Rewards_Parameters | Pool-level parameters by reward month |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Key | Description |
|-------------------|-----|-------------|
| EXW_dbo.Staking_BI_Version_WalletUserRewards | StakingMonthID, GCID (logical) | This table is the transaction detail; WalletUserRewards is the month-level summary. SUM(ClientMonthlyStakingReward) here = MonthlyRewards there. |

---

## 7. Sample Queries

### 7.1 Monthly ETH Rewards Reconciliation — Transaction vs Summary
```sql
SELECT
    t.StakingMonthID,
    t.GCID,
    SUM(t.ClientMonthlyStakingReward) AS TxnSumReward,
    r.MonthlyRewards AS SummaryReward,
    SUM(t.ClientMonthlyStakingReward) - r.MonthlyRewards AS Variance
FROM [EXW_dbo].[Staking_BI_Version_ETH_Transactions] t
JOIN [EXW_dbo].[Staking_BI_Version_WalletUserRewards] r
    ON t.GCID = r.GCID AND t.StakingMonthID = r.StakingMonthID
WHERE t.IsTestUser = 0 AND r.IsTestUser = 0
    AND t.IsStakingEligible = 1
GROUP BY t.StakingMonthID, t.GCID, r.MonthlyRewards
HAVING ABS(SUM(t.ClientMonthlyStakingReward) - r.MonthlyRewards) > 0.0000001
ORDER BY Variance DESC;
```

### 7.2 Eligible Staking Days Distribution Per Month
```sql
SELECT
    StakingMonthID,
    AVG(CAST(EligibleStakingDaysCount AS float)) AS AvgEligibleDays,
    MIN(EligibleStakingDaysCount) AS MinDays,
    MAX(EligibleStakingDaysCount) AS MaxDays,
    COUNT(*) AS TxnCount
FROM [EXW_dbo].[Staking_BI_Version_ETH_Transactions]
WHERE IsTestUser = 0 AND IsStakingEligible = 1
GROUP BY StakingMonthID
ORDER BY StakingMonthID;
```

### 7.3 Production Users — Staking Operations With Fees Verification
```sql
-- Confirm all fees are 0 throughout the program
SELECT
    EtoroFee, BlockchainEstFee, COUNT(*) AS Rows
FROM [EXW_dbo].[Staking_BI_Version_ETH_Transactions]
WHERE IsTestUser = 0
GROUP BY EtoroFee, BlockchainEstFee;
```

---

## 8. Atlassian Knowledge Sources

No direct Confluence sources found for this DWH table. Upstream context from WalletDB.Staking.Staking wiki: eToro executes staking on behalf of users; CorrelationId is the idempotency key; staking pool address `0xCB2A66540680c344bab5f818d68c3e4B9D57363B` (ETH); all fees are zero. From WalletDB.Staking.StakingTransactions wiki: 1:1 relationship with Staking.Staking; EtoroFee and BlockchainEstFee currently 0 for all records.

---

*Generated: 2026-04-20 | Quality: 8.0/10 | Phases: 11/14 (P9/P9B/P10 skipped — no SP; P10A: WalletDB.Staking.Staking + StakingTransactions found)*
*Tiers: 8 T1, 10 T2, 5 T3, 1 T4, 0 T5 | Elements: 26/26, Logic: 8/10, Sources: 7/10*
*Object: EXW_dbo.Staking_BI_Version_ETH_Transactions | Type: Table | Production Source: WalletDB.Staking.Staking + WalletDB.Staking.StakingTransactions*
