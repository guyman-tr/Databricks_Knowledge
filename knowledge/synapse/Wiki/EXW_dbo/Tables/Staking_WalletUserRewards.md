# EXW_dbo.Staking_WalletUserRewards

> Per-user monthly ETH staking reward table storing 23,617 records for 1,425 distinct wallet users across 25 staking months from June 2021 to May 2023, plus 14 trailing June 2023 records. Each row represents one GCID-WalletID combination's reward for a single staking month, capturing the ETH reward earned, yield rate, and eligibility details. Data is frozen since June 2023; the ETH staking program ended in May 2023.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | WalletDB.Staking.StakingRewards (via EXW_Staking External Tables → unknown ETL enrichment with GCID/Club from CustomerWalletsView) |
| **Refresh** | Frozen — staking program ended May 2023; last update Jun 2023 |
| **Row Count** | 23,617 rows (1,425 distinct GCIDs, 25 staking months) |
| **Synapse Distribution** | HASH (GCID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — no Gold layer target identified |

---

## 1. Business Meaning

EXW_dbo.Staking_WalletUserRewards is the per-user monthly ETH staking rewards table for the eToro Wallet ETH staking program. It records the actual ETH reward earned by each individual wallet user for each staking month from June 2021 (program launch) through June 2023 (wind-down). This is the historical record of every staking reward payout at the per-GCID level.

**Program context**: eToro offered ETH staking rewards to Wallet users who held ETH on the platform. Rewards were computed monthly based on the user's staked position, the pool's monthly yield rate, and their eToro club tier (which determines their revenue share percentage). The program ran from June 2021 to May 2023 and was wound down after the Ethereum Merge transition to Proof-of-Stake.

**User population**: 1,425 distinct GCIDs participated in the staking program across its full run. Growth was rapid: 11 users in Jun 2021, growing to 1,406 users/month by Apr–May 2023. All 7 club tiers are represented: Bronze (5,412 rows), Gold (5,143), Platinum Plus (4,975), Platinum (4,455), Silver (2,818), Diamond (725), Internal (89).

**MonthlyRewards vs EligibleRewards**: In all observed data, `MonthlyRewards` equals `EligibleRewards`. The EligibleRewards column likely represents the portion of MonthlyRewards that the user was eligible to receive (all ETH staking users were fully eligible during this program's run).

**ETL mechanism unknown**: No writer SP found in SSDT. The table is populated by an external ETL process (likely Databricks or ADF) that reads from EXW_Staking External Tables (Bronze copies of WalletDB.Staking.StakingRewards) and enriches with GCID/Club data from WalletDB.Wallet.CustomerWalletsView.

---

## 2. Business Logic

### 2.1 Monthly Reward Calculation

**What**: Each user's monthly ETH reward is computed from their staked ETH balance, the pool yield rate for that month, and their Club tier revenue share.

**Columns Involved**: `MonthlyYield`, `RevShare`, `MonthlyRewards`, `EligibleTransactions`

**Rules**:
- `MonthlyYield` = pool-level yield rate for the staking month (matches `YieldInDecimal` in `Staking_ETH_Rewards_Parameters`)
- `RevShare` = Club tier multiplier (75%=Internal, 85%=Silver/Bronze/Gold/Platinum, 90%=Platinum Plus, rates hardcoded by Club)
- `UserYield` = `MonthlyYield` (all observed rows show UserYield = MonthlyYield; the user gets the full pool yield)
- `MonthlyRewards` = actual ETH reward distributed to this wallet for this month
- `EligibleTransactions` = count of staking periods/transactions contributing to the monthly reward (range: 1–5+ per row)

### 2.2 Club Revenue Share Structure

**What**: `ClubRevShare` and `RevShare` encode the user's club-tier yield entitlement.

**Columns Involved**: `Club`, `ClubRevShare`, `RevShare`

**Rules**:
- Club values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal
- RevShare by Club (observed from data): Internal=0.75 (75%), Bronze/Silver/Gold/Platinum=0.85 (85%), Platinum Plus=0.90 (90%)
- Diamond club tier appears in data — RevShare assumed same as Platinum Plus (0.85–0.90, not directly confirmed)
- `ClubRevShare` (varchar) and `RevShare` (decimal) encode the same value in different formats

### 2.3 Staking Month Identification

**What**: Each monthly reward period is identified by `StakingMonthID` (YYYYMM integer) and `StakingMonth` (human label).

**Columns Involved**: `StakingMonthID`, `StakingMonth`, `StakingStartDate`

**Rules**:
- `StakingMonthID` format: YYYYMM (e.g., 202108 = August 2021)
- `StakingMonth` format: "Mmm-YYYY" (e.g., "Aug-2021")
- `StakingStartDate` = datetime2 of the first day of the staking month (1st of the month)
- 14 rows have `StakingMonthID = 202306` (June 2023) with NULL avg_yield — trailing records after program end

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(GCID) ensures all reward rows for a given user land in the same distribution — optimal for per-user aggregations (`GROUP BY GCID`). HEAP avoids columnar overhead for this mid-sized frozen table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total ETH rewards per user across all months | `SELECT GCID, SUM(MonthlyRewards) AS TotalETH FROM [EXW_dbo].[Staking_WalletUserRewards] GROUP BY GCID ORDER BY TotalETH DESC` |
| Reward per month per Club tier | `SELECT StakingMonthID, Club, COUNT(*) AS Users, SUM(MonthlyRewards) AS TotalETH FROM [EXW_dbo].[Staking_WalletUserRewards] GROUP BY StakingMonthID, Club ORDER BY StakingMonthID, Club` |
| Users who participated in every month | `SELECT GCID FROM [EXW_dbo].[Staking_WalletUserRewards] GROUP BY GCID HAVING COUNT(DISTINCT StakingMonthID) = 25` |
| Monthly pool yield history | `SELECT DISTINCT StakingMonthID, StakingMonth, MonthlyYield FROM [EXW_dbo].[Staking_WalletUserRewards] ORDER BY StakingMonthID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.Staking_ETH_Rewards_Parameters | `YEAR(sep.StakingStartDate)*100+MONTH(sep.StakingStartDate) = swr.StakingMonthID` | Correlate per-user rewards with pool-level parameters |
| EXW_dbo.EXW_DimUser | `d.GCID = swr.GCID` | Enrich with user demographics (Region, Regulation, etc.) |
| EXW_dbo.Staking_BI_Version_WalletUserRewards | `bi.WalletID = swr.WalletID AND bi.StakingMonthID = swr.StakingMonthID` | Compare BI-enriched version with base rewards |

### 3.4 Gotchas

- **MonthlyRewards = EligibleRewards always**: In all 23,617 rows, these two columns are equal. Only one needs to be used for reward amounts.
- **14 Jun-2023 trailing rows**: `StakingMonthID = 202306` has 14 rows with NULL `MonthlyYield`. These are post-program trailing records; filter with `StakingMonthID <= 202305` for clean historical analysis.
- **WalletID is varchar(1024) not GUID**: Source is uniqueidentifier in WalletDB; cast to string in this DWH table. Do not compare directly with WalletDB tables without CAST.
- **RevShare ≠ actual payout fraction**: RevShare encodes the club's yield share entitlement, but the actual reward formula involves additional factors not visible in this table.
- **No data since Jun 2023**: Table is frozen; do not expect new rows.

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
| 1 | ID | int | NO | Auto-incrementing surrogate key. IDENTITY(1,1), sequential (1, 2, 3...). Not a business key. (Tier 4 — EXW_dbo.Staking_WalletUserRewards) |
| 2 | WalletID | varchar(1024) | YES | The wallet receiving the staking reward. FK to Wallet.Wallets.WalletId. Part of the unique constraint. Used with Gcid from Wallet.CustomerWalletsView for per-user reward lookups. Stored as varchar in DWH (cast from uniqueidentifier source). (Tier 1 — WalletDB.Staking.StakingRewards) |
| 3 | GCID | int | YES | Group Customer ID — platform-internal customer identifier linking the wallet owner. Derived by joining WalletID to WalletDB.Wallet.CustomerWalletsView. HASH distribution key; all rows for a user are co-located. (Tier 2 — EXW_Staking ETL enrichment via CustomerWalletsView) |
| 4 | Club | varchar(1024) | YES | eToro club tier of the staking user at time of reward. 7 values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal. Determines the RevShare percentage. (Tier 2 — EXW_Staking ETL enrichment via CustomerWalletsView) |
| 5 | ClubRevShare | varchar(1024) | YES | Club-tier revenue share percentage as a string (e.g., "0.85" for 85%). Matches RevShare in decimal form. Values observed: 0.75=Internal, 0.85=Bronze/Silver/Gold/Platinum, 0.90=Platinum Plus. (Tier 2 — EXW_Staking ETL enrichment) |
| 6 | RevShare | decimal(32,18) | YES | Club-tier revenue share as decimal fraction (0.75–0.90). Internal=0.75 (75%), Bronze/Silver/Gold/Platinum=0.85 (85%), Platinum Plus=0.90 (90%). Used to determine the user's staking yield entitlement relative to pool yield. (Tier 2 — EXW_Staking ETL enrichment) |
| 7 | StakingStartDate | datetime2(7) | YES | First datetime of the staking period this reward covers. Derived from StakingMonthID (always 1st of the month at 00:00:00), except Jun 2021 pilot row which starts 2021-06-22. (Tier 2 — derived from StakingMonthID) |
| 8 | StakingMonthID | int | YES | The staking period month in YYYYMM format (e.g., 202306 = June 2023). Part of the unique constraint ensuring one reward per wallet per crypto per month. Ranges from 202106 to 202306 in current data. (Tier 1 — WalletDB.Staking.StakingRewards) |
| 9 | StakingMonth | varchar(1024) | YES | Human-readable label for the staking month (e.g., "Aug-2021", "Jan-2022"). Derived from StakingMonthID; format "Mmm-YYYY". For display purposes only. (Tier 2 — derived from StakingMonthID) |
| 10 | MonthlyYield | decimal(32,18) | YES | The overall staking pool yield percentage for this month (maps to WalletDB.StakingRewards.MonthlyYieldPercentage). Range: 0.00112–0.00528 (0.11%–0.53% monthly). NULL for 14 June 2023 trailing rows. (Tier 1 — WalletDB.Staking.StakingRewards) |
| 11 | MonthlyRewards | decimal(32,18) | YES | The amount of ETH earned as staking reward for this month, in native ETH units (maps to WalletDB.StakingRewards.MonthlyReward). This is the actual crypto reward received. In all observed data, equals EligibleRewards. (Tier 1 — WalletDB.Staking.StakingRewards) |
| 12 | UserYield | decimal(32,18) | YES | The user's share of the pool yield, based on their eToro club tier (maps to WalletDB.StakingRewards.UserYieldPercentage). In all observed data, equals MonthlyYield (users receive the full pool yield rate). (Tier 1 — WalletDB.Staking.StakingRewards) |
| 13 | EligibleRewards | decimal(32,18) | YES | The portion of MonthlyRewards for which the user was eligible. In all 23,617 rows, equals MonthlyRewards exactly — all ETH staking users in this program were fully eligible. Likely a hook for partial-eligibility logic that was never triggered. (Tier 2 — EXW_Staking ETL computation) |
| 14 | EligibleTransactions | int | YES | Count of staking transactions/periods that contributed to this month's reward (range: 1–5+ per row). Higher values indicate a user had multiple staking positions or sub-periods within the month. (Tier 2 — derived from EXW_Staking.Staking transaction count) |
| 15 | UpdateDate | datetime2(7) | NO | Timestamp when this reward record was written to the DWH table. (Tier 4 — unknown ETL) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| WalletID | WalletDB.Staking.StakingRewards | WalletId | CAST uniqueidentifier → varchar(1024) |
| StakingMonthID | WalletDB.Staking.StakingRewards | StakingMonthId | Passthrough |
| MonthlyYield | WalletDB.Staking.StakingRewards | MonthlyYieldPercentage | Rename only |
| MonthlyRewards | WalletDB.Staking.StakingRewards | MonthlyReward | Rename only |
| UserYield | WalletDB.Staking.StakingRewards | UserYieldPercentage | Rename only |
| GCID, Club | WalletDB.Wallet.CustomerWalletsView | Gcid, Club | JOIN enrichment via WalletID |

### 5.2 ETL Pipeline

```
WalletDB.Staking.StakingRewards (production — WalletDB)
WalletDB.Wallet.CustomerWalletsView (GCID/Club enrichment)
  |-- Generic Pipeline (Bronze export) --|
  v
EXW_Staking.StakingRewards (External Table, Bronze)
EXW_Staking.Staking (External Table, Bronze)
  |-- Unknown external ETL (Databricks/ADF — not in SSDT) --|
  |-- Enrichment: JOIN to CustomerWalletsView for GCID, Club --|
  |-- Computation: StakingStartDate, StakingMonth from StakingMonthID --|
  |-- Computation: RevShare by Club tier --|
  v
EXW_dbo.Staking_WalletUserRewards (23,617 rows, frozen Jun 2023)
  |-- No Gold layer UC target --|
  v
UC Target: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| WalletID | WalletDB.Wallet.Wallets | Wallet receiving staking reward (source GUID, stored as varchar in DWH) |
| GCID | EXW_dbo.EXW_DimUser | GCID dimension for wallet user demographic enrichment |
| StakingMonthID (logical) | EXW_dbo.Staking_ETH_Rewards_Parameters | Pool-level parameters for each staking month |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Key | Description |
|-------------------|-----|-------------|
| EXW_dbo.Staking_BI_Version_WalletUserRewards | WalletID, StakingMonthID (logical) | BI-enriched version with additional eligibility and test-user fields |

---

## 7. Sample Queries

### 7.1 Top 10 ETH Staking Earners (All-Time)
```sql
SELECT
    GCID,
    Club,
    COUNT(DISTINCT StakingMonthID) AS MonthsParticipated,
    SUM(MonthlyRewards) AS TotalETHEarned
FROM [EXW_dbo].[Staking_WalletUserRewards]
WHERE StakingMonthID <= 202305
GROUP BY GCID, Club
ORDER BY TotalETHEarned DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
```

### 7.2 Monthly ETH Distribution by Club Tier
```sql
SELECT
    StakingMonthID,
    StakingMonth,
    Club,
    COUNT(*) AS Users,
    SUM(MonthlyRewards) AS TotalETH
FROM [EXW_dbo].[Staking_WalletUserRewards]
WHERE StakingMonthID BETWEEN 202201 AND 202212
GROUP BY StakingMonthID, StakingMonth, Club
ORDER BY StakingMonthID, Club;
```

### 7.3 User Staking Reward History
```sql
SELECT
    StakingMonthID,
    StakingMonth,
    Club,
    MonthlyYield,
    MonthlyRewards,
    EligibleTransactions
FROM [EXW_dbo].[Staking_WalletUserRewards]
WHERE GCID = @GCID
ORDER BY StakingMonthID;
```

---

## 8. Atlassian Knowledge Sources

No direct Confluence sources found for this DWH table. Context from WalletDB.Staking.StakingRewards wiki: rewards distributed monthly as "Position Airdrop" or cash compensation; amount depends on days held, monthly yield by club level, and minimum $1 USD threshold; distribution typically during the second business week of the following month.

---

*Generated: 2026-04-20 | Quality: 8.0/10 | Phases: 11/14 (P9/P9B/P10 skipped — no SP; P10A: WalletDB.Staking.StakingRewards found)*
*Tiers: 5 T1, 8 T2, 0 T3, 2 T4, 0 T5 | Elements: 15/15, Logic: 8/10, Sources: 7/10*
*Object: EXW_dbo.Staking_WalletUserRewards | Type: Table | Production Source: WalletDB.Staking.StakingRewards*
