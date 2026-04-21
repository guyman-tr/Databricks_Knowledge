# EXW_dbo.Staking_ETH_Rewards_Parameters

> Historical ETH staking program parameter table storing 26 monthly records from June 2021 to May 2023, each capturing the total ETH rewards distributed and the decimal yield rate for a staking period. All records are frozen (IsActive=0, no updates since 2023-06-05); the ETH staking program ended in May 2023 coinciding with the Ethereum Merge transition to Proof-of-Stake.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown — no writer SP found in SSDT; table appears manually maintained or from a decommissioned pipeline |
| **Refresh** | Frozen since 2023-06-05; staking program ended May 2023 |
| **Row Count** | 26 rows (one per staking month period, Jun 2021 – May 2023) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — no Gold layer target |

---

## 1. Business Meaning

EXW_dbo.Staking_ETH_Rewards_Parameters is a historical reference table recording the ETH staking program's monthly reward parameters from the eToro Wallet staking program. It contains exactly 26 rows, one per completed staking period between 2021-06-16 and 2023-05-10. Each row represents one monthly (or partial-monthly) ETH staking cycle and stores two key financial metrics: the total ETH rewards distributed in that period (`Rewards`) and the equivalent yield expressed as a decimal fraction (`YieldInDecimal`).

**The ETH staking program has ended.** All 26 rows have `IsActive = 0` and `MinimumDays = 0`. The most recent record covers 2023-05-01 to 2023-05-10 (partial month), updated 2023-06-05. The program wound down in May 2023 as eToro transitioned its staking model following the Ethereum Merge (Sep 2022 → Proof-of-Stake). No new rows have been added since.

This table is a **frozen historical artifact**. It was likely used by ETL procedures to compute monthly individual user reward amounts in conjunction with `Staking_WalletUserRewards` and `Staking_BI_Version_WalletUserRewards`. It does not feed any live reporting pipelines as of April 2026.

**Yield observations**: `Rewards` ranged from ~0.06 ETH (June 2021 pilot) to ~27 ETH (Oct 2022 peak). `YieldInDecimal` ranged from ~0.0011 to ~0.0053 (0.11% to 0.53% monthly). The first two rows (Jun 2021) have NULL `YieldInDecimal`, suggesting the decimal yield metric was added retroactively in July 2021. **ID gaps** (42, 102, 162…) are a Synapse SQL Pool IDENTITY artifact — the pool pre-allocates IDENTITY blocks for parallel distribution, causing non-sequential IDs.

---

## 2. Business Logic

### 2.1 Monthly Staking Period Structure

**What**: Each row covers one ETH staking month/period with a defined start and end date. All periods are monthly except the final partial period.

**Columns Involved**: `StakingStartDate`, `StakingEndDate`, `Rewards`, `YieldInDecimal`

**Rules**:
- `StakingStartDate` is always the first of the month (except initial period: 2021-06-16)
- `StakingEndDate` is the last day of the month for full periods; 2023-05-10 for the final partial period
- There are two June 2021 rows (IDs 42 and 102) covering the same date range — the second appears to be a correction (YieldInDecimal differs; row 42 has `Rewards=32`, row 102 has `Rewards=0.0644`)
- `MinimumDays = 0` for all rows (minimum staking eligibility days not enforced in this program)

### 2.2 IsActive Flag (All Historical)

**What**: `IsActive` marks whether a period is currently active; all rows are 0.

**Columns Involved**: `IsActive`

**Rules**:
- `IsActive = 0` for all 26 rows — no active periods exist
- During the active program (2021–2023), the current period would have had `IsActive = 1` while being computed
- After the staking program ended, all rows were set to 0

### 2.3 Yield Progression

**What**: The `YieldInDecimal` column tracks the monthly ETH staking yield rate (decimal fraction, not percentage).

**Columns Involved**: `YieldInDecimal`, `Rewards`

**Rules**:
- To convert to percentage: `YieldInDecimal × 100` (e.g., 0.0053 = 0.53% monthly yield)
- NULL for the first two rows (June 2021) — metric was not yet tracked
- Peak yield: ~0.0053 (Jun–Jul 2021 pilot). Decline mirrors broader ETH staking yield market trends
- `Rewards` represents total ETH pool distributed to all staking users for that period (not per-user)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — suitable for this small 26-row table. Round Robin causes each row to be placed in alternating distributions, which is appropriate since there's no natural distribution key. HEAP avoids row-group optimization overhead for this tiny static table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What was the yield for a specific month? | `SELECT * FROM [EXW_dbo].[Staking_ETH_Rewards_Parameters] WHERE StakingStartDate = '2022-10-01'` |
| What were total ETH rewards distributed per year? | `SELECT YEAR(StakingStartDate), SUM(Rewards) FROM [EXW_dbo].[Staking_ETH_Rewards_Parameters] GROUP BY YEAR(StakingStartDate)` |
| What was the peak monthly yield? | `SELECT TOP 1 * FROM [EXW_dbo].[Staking_ETH_Rewards_Parameters] ORDER BY YieldInDecimal DESC` |
| How many staking periods were there? | `SELECT COUNT(*) FROM [EXW_dbo].[Staking_ETH_Rewards_Parameters]` — returns 26 |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.Staking_WalletUserRewards | `sep.StakingMonthID = swr.StakingMonthID` (logical) | Correlate pool-level parameters with per-user reward records |
| EXW_dbo.Staking_BI_Version_WalletUserRewards | Same logic | BI-enriched per-user rewards correlated with pool yield |
| EXW_dbo.Staking_BI_Version_ETH_Transactions | `StakingStartDate/StakingEndDate` range | Correlate individual ETH staking transactions with period parameters |

### 3.4 Gotchas

- **Two June 2021 rows**: IDs 42 and 102 both cover 2021-06-16 to 2021-06-30. Row 42 has `Rewards=32` (likely an early estimate), row 102 has `Rewards=0.064` (corrected value). Always filter to the lower-Rewards row for accurate data, or use `WHERE ID = 102` for June 2021.
- **NULL YieldInDecimal**: First two rows (IDs 42, 102, Jun 2021) have NULL `YieldInDecimal`. Handle with `ISNULL(YieldInDecimal, 0)` if aggregating.
- **Non-sequential IDs**: IDENTITY gaps (42, 102, 162…+60) are a Synapse parallel IDENTITY artifact, not missing rows.
- **Rewards = total pool, not per-user**: `Rewards` is the aggregate ETH distributed across ALL staking users for that month, not an individual user's reward.
- **Program ended**: No new rows since 2023-06-05. Do not expect live data.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Directly inherited from upstream production wiki (verbatim) |
| Tier 2 | Derived from ETL SP code reading |
| Tier 3 | Inferred from column name + data pattern |
| Tier 4 | Best available knowledge — limited confidence (no SP, no upstream wiki) |
| Tier 5 | Name-based inference only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | int | NO | Auto-incrementing surrogate key. IDENTITY(1,1) — values are non-sequential (42, 102, 162…) due to Synapse parallel IDENTITY block pre-allocation. Not usable as a business key. (Tier 4 — EXW_dbo.Staking_ETH_Rewards_Parameters) |
| 2 | Rewards | decimal(38,16) | NO | Total ETH rewards distributed to all staking users for this staking period, in native ETH units. Pool-level aggregate (not per-user). Range: 0.06 ETH (Jun 2021 pilot) to ~27 ETH (Oct 2022 peak). Note: two Jun 2021 rows exist — ID=42 has Rewards=32 (estimate), ID=102 has Rewards=0.064 (corrected). (Tier 4 — EXW_dbo.Staking_ETH_Rewards_Parameters) |
| 3 | StakingStartDate | date | YES | First calendar day of the ETH staking period covered by this parameter row. All full-month periods start on the 1st; the initial period starts 2021-06-16 (program launch). (Tier 4 — EXW_dbo.Staking_ETH_Rewards_Parameters) |
| 4 | StakingEndDate | date | YES | Last calendar day of the staking period. Full months end on the month's last day. Final row ends 2023-05-10 (program terminated mid-month). Range: 2021-06-30 to 2023-05-10. (Tier 4 — EXW_dbo.Staking_ETH_Rewards_Parameters) |
| 5 | MinimumDays | int | YES | Minimum number of staking days required for eligibility in this period. Always 0 across all 26 rows — no minimum day requirement was enforced in the ETH staking program. (Tier 4 — EXW_dbo.Staking_ETH_Rewards_Parameters) |
| 6 | IsActive | int | YES | Active period flag. 1 = currently active staking period (none exist); 0 = closed/historical period. All 26 rows = 0 — program fully closed. (Tier 4 — EXW_dbo.Staking_ETH_Rewards_Parameters) |
| 7 | UpdateDate | datetime | YES | Timestamp when this parameter row was last written/updated. Most recent: 2023-06-05 (final row close). (Tier 4 — EXW_dbo.Staking_ETH_Rewards_Parameters) |
| 8 | YieldInDecimal | decimal(38,16) | YES | Monthly ETH staking pool yield expressed as a decimal fraction (divide by 1 to get decimal, multiply by 100 for %). NULL for June 2021 rows (metric not yet tracked). Range for non-NULL rows: 0.00112 to 0.00528. Example: 0.00528 = 0.528% monthly yield. (Tier 4 — EXW_dbo.Staking_ETH_Rewards_Parameters) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| All columns | Unknown — no writer SP found in SSDT | — | ETL mechanism not identified; data appears manually entered or from a decommissioned historical pipeline |

### 5.2 ETL Pipeline

```
Unknown source (manual or decommissioned ETL)
  |-- Unknown mechanism --|
  v
EXW_dbo.Staking_ETH_Rewards_Parameters
(26 rows, frozen 2023-06-05, program ended May 2023)
  |-- No Generic Pipeline target (not in mapping) --|
  v
UC Target: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| — | — | No FK references; standalone parameter table |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Key | Description |
|-------------------|-----|-------------|
| EXW_dbo.Staking_WalletUserRewards | StakingMonthID (logical) | Per-user monthly rewards correlate with pool parameters by staking month |
| EXW_dbo.Staking_BI_Version_WalletUserRewards | StakingMonthID (logical) | BI-enriched user rewards correspond to pool-level yield rows |
| EXW_dbo.Staking_BI_Version_ETH_Transactions | StakingStartDate–StakingEndDate range | Individual ETH staking transactions fall within each period's date range |

---

## 7. Sample Queries

### 7.1 Monthly ETH Staking Yield History
```sql
SELECT
    StakingStartDate,
    StakingEndDate,
    Rewards AS TotalETHDistributed,
    CAST(YieldInDecimal * 100 AS decimal(10,4)) AS YieldPct,
    IsActive
FROM [EXW_dbo].[Staking_ETH_Rewards_Parameters]
ORDER BY StakingStartDate;
```

### 7.2 Total ETH Distributed by Year
```sql
SELECT
    YEAR(StakingStartDate) AS StakingYear,
    SUM(Rewards) AS TotalETHRewards,
    AVG(YieldInDecimal) AS AvgYield
FROM [EXW_dbo].[Staking_ETH_Rewards_Parameters]
WHERE StakingStartDate IS NOT NULL
GROUP BY YEAR(StakingStartDate)
ORDER BY StakingYear;
```

### 7.3 Find Parameter Row for a Given Staking Date
```sql
SELECT *
FROM [EXW_dbo].[Staking_ETH_Rewards_Parameters]
WHERE '2022-08-15' BETWEEN StakingStartDate AND StakingEndDate;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table. Context from WalletDB.Staking.StakingRewards wiki: ETH staking rewards distributed monthly as "Position Airdrop" (new crypto position) or cash compensation; amount depends on days held, monthly yield by club level, and minimum $1 USD threshold; distribution typically during second business week of the following month.

---

*Generated: 2026-04-20 | Quality: 7.5/10 | Phases: 8/14 (P9/P9B/P10/P10A skipped — no SP, no upstream wiki)*
*Tiers: 0 T1, 0 T2, 0 T3, 8 T4, 0 T5 | Elements: 8/8, Logic: 7/10, Sources: 4/10*
*Object: EXW_dbo.Staking_ETH_Rewards_Parameters | Type: Table | Production Source: Unknown*
