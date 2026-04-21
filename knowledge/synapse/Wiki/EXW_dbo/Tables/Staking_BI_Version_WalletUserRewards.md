# EXW_dbo.Staking_BI_Version_WalletUserRewards

> BI-enriched per-user monthly ETH staking rewards table storing 23,659 records for 1,414 distinct wallet users across 23 staking months (July 2021 – May 2023), including 42 test-user rows marked with IsTestUser=1. This is the BI-layer counterpart to Staking_WalletUserRewards, differing in WalletID type (uniqueidentifier vs varchar), ClubRevShare type (numeric vs varchar), and month coverage (no Jun 2021 or Jun 2023). All data frozen since May 2023.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | WalletDB.Staking.StakingRewards + WalletDB.Wallet.CustomerWalletsView (via EXW_Staking External Tables → unknown external ETL enrichment) |
| **Refresh** | Frozen — ETH staking program ended May 2023 |
| **Row Count** | 23,659 rows (1,414 distinct GCIDs, 23 months: 202107–202305) |
| **Synapse Distribution** | HASH (GCID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — no Gold layer target |

---

## 1. Business Meaning

EXW_dbo.Staking_BI_Version_WalletUserRewards is the BI-enriched version of `Staking_WalletUserRewards`, containing per-user monthly ETH staking rewards with additional data quality improvements: proper uniqueidentifier type for WalletID, numeric ClubRevShare (vs varchar in base), and the `IsTestUser` flag for filtering analysis to real vs test accounts.

**Relationship to base table**: The BI version contains 42 more rows than the base table (23,659 vs 23,617) due to inclusion of test users (42 IsTestUser=1 rows). However, it covers fewer months: starts Jul 2021 (not Jun 2021) and ends May 2023 (not Jun 2023). The missing Jun 2021 pilot month and Jun 2023 trailing records suggest different ETL run windows.

**Same program context**: This is the ETH staking program historical archive (2021–2023). Each row represents one wallet user's reward for one staking month. The program ended in May 2023. No new rows since then.

**Club tier distribution** matches the base table: Bronze (5,437), Gold (5,156), Platinum Plus (4,977), Platinum (4,460), Silver (2,819), Diamond (725), Internal (85). RevShare values: Internal=0.75, Bronze/Silver/Gold/Platinum=0.85, Platinum Plus=0.90.

**Type improvements over base table**:
- `WalletID` is `uniqueidentifier` (UUID format) — correctly typed vs varchar(1024) in base table
- `ClubRevShare` is `numeric(2,2)` — matches `RevShare`; base table stores this as varchar
- `MonthlyRewards` and `EligibleRewards` are `float` (vs decimal in base table)
- `StakingStartDate` is `date` (vs datetime2 in base table)

---

## 2. Business Logic

### 2.1 BI vs Base Table Scope Differences

**What**: The BI version covers a different month range and includes test users not present in the base table.

**Columns Involved**: `StakingMonthID`, `IsTestUser`

**Rules**:
- BI version: months 202107–202305 (23 months, Jul 2021–May 2023)
- Base version: months 202106–202306 (25 months, Jun 2021–Jun 2023)
- BI version includes 42 rows with `IsTestUser = 1` (test accounts)
- Base version appears to exclude test users (no IsTestUser column)

### 2.2 IsTestUser Flag

**What**: `IsTestUser` marks whether the staking user is a test/internal eToro account.

**Columns Involved**: `IsTestUser`

**Rules**:
- `IsTestUser = 1`: 42 rows (test accounts, ~0.18% of total)
- `IsTestUser = 0`: 23,617 rows (real users)
- Filter `WHERE IsTestUser = 0` for production analysis excluding test accounts

### 2.3 Monthly Reward Structure (same as base table)

**What**: Each row captures one wallet user's ETH reward for one staking month.

**Columns Involved**: `StakingMonthID`, `MonthlyYield`, `MonthlyRewards`, `EligibleRewards`, `RevShare`

**Rules**:
- `MonthlyYield` = pool yield rate for the month (matches `YieldInDecimal` in `Staking_ETH_Rewards_Parameters`)
- `UserYield` = same as `MonthlyYield` in all observed data
- `MonthlyRewards` = `EligibleRewards` in all observed data (all users fully eligible)
- `EligibleTransactions` = count of staking positions contributing to this month's reward (range: 1–5+)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(GCID) — same as base table. Optimal for per-user GROUP BY. HEAP appropriate for this small frozen table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Monthly rewards for real users only | `SELECT * FROM [EXW_dbo].[Staking_BI_Version_WalletUserRewards] WHERE IsTestUser = 0` |
| Compare BI vs base row counts per month | JOIN on GCID+StakingMonthID; differences = Jun 2021, Jun 2023 rows and test users |
| WalletID-based lookup (proper GUID) | `WHERE WalletID = '...'` — no CAST needed (already uniqueidentifier) |
| Total ETH per Club tier | `SELECT Club, SUM(MonthlyRewards) FROM ... WHERE IsTestUser=0 GROUP BY Club` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.Staking_WalletUserRewards | `bi.GCID=base.GCID AND bi.StakingMonthID=base.StakingMonthID` | Cross-reference; BI version has proper uniqueidentifier WalletID |
| EXW_dbo.Staking_ETH_Rewards_Parameters | `YEAR(sep.StakingStartDate)*100+MONTH(sep.StakingStartDate) = bi.StakingMonthID` | Pool-level parameters |
| EXW_dbo.EXW_DimUser | `d.GCID = bi.GCID` | User demographics enrichment |

### 3.4 Gotchas

- **WalletID type mismatch**: This table uses `uniqueidentifier`, base table uses `varchar(1024)`. Always CAST(base.WalletID AS uniqueidentifier) when joining.
- **Missing Jun 2021 and Jun 2023**: BI version starts Jul 2021 (not Jun 2021) and ends May 2023 (not Jun 2023). For full history including Jun 2021, use the base `Staking_WalletUserRewards`.
- **Test users included**: Filter `WHERE IsTestUser = 0` for pure production analysis.
- **MonthlyRewards and EligibleRewards as float**: Floating-point type may produce minor rounding artifacts vs decimal in base table. Use `ROUND(MonthlyRewards, 8)` when comparing.
- **ClubRevShare numeric vs varchar**: Unlike base table (varchar), this column is numeric(2,2) — more type-safe.

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
| 1 | StakingMonth | varchar(50) | YES | Human-readable label for the staking month (e.g., "Jul-2021"). Derived from StakingMonthID; format "Mmm-YYYY". Range: "Jul-2021" to "May-2023". (Tier 2 — derived from StakingMonthID) |
| 2 | StakingMonthID | int | YES | The staking period month in YYYYMM format (e.g., 202306 = June 2023). Part of the unique constraint ensuring one reward per wallet per crypto per month. Ranges from 202107 to 202305 in current data. (Tier 1 — WalletDB.Staking.StakingRewards) |
| 3 | WalletID | uniqueidentifier | NO | The wallet receiving the staking reward. FK to Wallet.Wallets.WalletId. Part of the unique constraint. Stored as native uniqueidentifier — correctly typed vs varchar in base table Staking_WalletUserRewards. (Tier 1 — WalletDB.Staking.StakingRewards) |
| 4 | GCID | int | YES | Group Customer ID — platform-internal customer identifier linking the wallet owner. Derived by joining WalletID to WalletDB.Wallet.CustomerWalletsView. HASH distribution key. (Tier 2 — EXW_Staking ETL enrichment via CustomerWalletsView) |
| 5 | Club | varchar(50) | NO | eToro club tier of the staking user at time of reward. 7 values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal. Determines RevShare percentage. (Tier 2 — EXW_Staking ETL enrichment via CustomerWalletsView) |
| 6 | ClubRevShare | numeric(2,2) | NO | Club-tier revenue share as decimal fraction (numeric, unlike varchar in base table). Values: 0.75=Internal, 0.85=Bronze/Silver/Gold/Platinum, 0.90=Platinum Plus. Same value as RevShare. (Tier 2 — EXW_Staking ETL enrichment) |
| 7 | RevShare | numeric(2,2) | NO | Same as ClubRevShare — the club's revenue share decimal fraction (0.75–0.90). Both columns appear in this table for backward compatibility with the base table schema. (Tier 2 — EXW_Staking ETL enrichment) |
| 8 | StakingStartDate | date | YES | First day of the staking period this reward covers (e.g., 2021-07-01 for Jul 2021). Stored as date (not datetime2 as in base table). Range: 2021-07-01 to 2023-05-01. (Tier 2 — derived from StakingMonthID) |
| 9 | MonthlyYield | decimal(18,16) | NULL | The overall staking pool yield percentage for this month (maps to WalletDB.StakingRewards.MonthlyYieldPercentage). Range: 0.00112–0.00528 (0.11%–0.53% monthly). Stored as decimal(18,16) for higher precision. (Tier 1 — WalletDB.Staking.StakingRewards) |
| 10 | MonthlyRewards | float | NULL | The amount of ETH earned as staking reward for this month, in native ETH units (maps to WalletDB.StakingRewards.MonthlyReward). Stored as float in this BI version (vs decimal in base table). In all observed data, equals EligibleRewards. (Tier 1 — WalletDB.Staking.StakingRewards) |
| 11 | UserYield | decimal(18,16) | NULL | The user's share of the pool yield, based on their eToro club tier (maps to WalletDB.StakingRewards.UserYieldPercentage). In all observed data, equals MonthlyYield exactly. (Tier 1 — WalletDB.Staking.StakingRewards) |
| 12 | EligibleRewards | float | NULL | The eligible portion of MonthlyRewards for this wallet. In all 23,659 rows, equals MonthlyRewards — all ETH staking users were fully eligible throughout the program. (Tier 2 — EXW_Staking ETL computation) |
| 13 | EligibleTransactions | int | NO | Count of staking transactions/periods that contributed to this month's reward. Range: 1–5+ per row. Higher values indicate multiple staking positions within the month. (Tier 2 — derived from EXW_Staking.Staking transaction count) |
| 14 | IsTestUser | int | NO | Test account flag. 1=internal/test eToro account; 0=real production user. 42 test-user rows present (~0.18% of total). Filter `WHERE IsTestUser = 0` for production analysis. Not present in base table Staking_WalletUserRewards. (Tier 2 — EXW_Staking ETL enrichment via CustomerWalletsView) |
| 15 | UpdateDate | datetime | NOT NULL | Timestamp when this reward record was written to the DWH table by the external ETL. (Tier 4 — unknown ETL) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| WalletID | WalletDB.Staking.StakingRewards | WalletId | Passthrough (uniqueidentifier — correct type) |
| StakingMonthID | WalletDB.Staking.StakingRewards | StakingMonthId | Passthrough |
| MonthlyYield | WalletDB.Staking.StakingRewards | MonthlyYieldPercentage | Rename only |
| MonthlyRewards | WalletDB.Staking.StakingRewards | MonthlyReward | Rename; stored as float |
| UserYield | WalletDB.Staking.StakingRewards | UserYieldPercentage | Rename only |
| GCID, Club, IsTestUser | WalletDB.Wallet.CustomerWalletsView | Gcid, Club, IsTest | JOIN enrichment |

### 5.2 ETL Pipeline

```
WalletDB.Staking.StakingRewards (production — WalletDB)
WalletDB.Wallet.CustomerWalletsView (GCID/Club/IsTestUser enrichment)
  |-- Generic Pipeline (Bronze export) --|
  v
EXW_Staking.StakingRewards (External Table, Bronze)
EXW_Staking.Staking (External Table, Bronze)
  |-- Unknown external ETL (Databricks/ADF — not in SSDT) --|
  |-- Enrichment: GCID, Club, IsTestUser --|
  |-- WalletID preserved as uniqueidentifier --|
  |-- ClubRevShare/RevShare as numeric(2,2) --|
  v
EXW_dbo.Staking_BI_Version_WalletUserRewards (23,659 rows, frozen May 2023)
  |-- No Gold layer UC target --|
  v
UC Target: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| WalletID | WalletDB.Wallet.Wallets | Wallet receiving staking reward (proper uniqueidentifier) |
| GCID | EXW_dbo.EXW_DimUser | GCID dimension for user demographics |
| StakingMonthID (logical) | EXW_dbo.Staking_ETH_Rewards_Parameters | Pool-level parameters by staking month |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Key | Description |
|-------------------|-----|-------------|
| EXW_dbo.Staking_BI_Version_ETH_Transactions | StakingMonthID, GCID (logical) | BI transaction-level detail complements this month-level summary |

---

## 7. Sample Queries

### 7.1 Monthly ETH Staking Rewards — Production Users Only
```sql
SELECT
    StakingMonthID,
    StakingMonth,
    Club,
    COUNT(*) AS Users,
    SUM(MonthlyRewards) AS TotalETH,
    AVG(MonthlyYield) AS PoolYield
FROM [EXW_dbo].[Staking_BI_Version_WalletUserRewards]
WHERE IsTestUser = 0
GROUP BY StakingMonthID, StakingMonth, Club
ORDER BY StakingMonthID, Club;
```

### 7.2 Compare Test vs Production User Rewards
```sql
SELECT
    IsTestUser,
    COUNT(*) AS Rows,
    COUNT(DISTINCT GCID) AS Users,
    SUM(MonthlyRewards) AS TotalETH
FROM [EXW_dbo].[Staking_BI_Version_WalletUserRewards]
GROUP BY IsTestUser;
```

### 7.3 Join With Base Table to Get Full History (Including Jun 2021)
```sql
-- Use base table for Jun 2021 + Jun 2023; BI version for Jul 2021–May 2023
SELECT GCID, StakingMonthID, MonthlyRewards
FROM [EXW_dbo].[Staking_WalletUserRewards]
WHERE StakingMonthID IN (202106, 202306)
UNION ALL
SELECT GCID, StakingMonthID, CAST(MonthlyRewards AS decimal(32,18))
FROM [EXW_dbo].[Staking_BI_Version_WalletUserRewards]
WHERE IsTestUser = 0;
```

---

## 8. Atlassian Knowledge Sources

No direct Confluence sources found for this DWH table. See WalletDB.Staking.StakingRewards wiki for upstream context. Context from that wiki: rewards distributed monthly as "Position Airdrop" or cash compensation; minimum $1 USD threshold applies; distribution typically during second business week of following month.

---

*Generated: 2026-04-20 | Quality: 8.2/10 | Phases: 11/14 (P9/P9B/P10 skipped — no SP; P10A: WalletDB.Staking.StakingRewards found)*
*Tiers: 5 T1, 9 T2, 0 T3, 1 T4, 0 T5 | Elements: 15/15, Logic: 8/10, Sources: 7/10*
*Object: EXW_dbo.Staking_BI_Version_WalletUserRewards | Type: Table | Production Source: WalletDB.Staking.StakingRewards*
