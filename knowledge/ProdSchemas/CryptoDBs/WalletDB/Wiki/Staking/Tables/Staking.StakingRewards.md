# Staking.StakingRewards

> Records the monthly staking reward distributions to individual wallets, capturing the reward amount, yield percentages, and the staking period month.

| Property | Value |
|----------|-------|
| **Schema** | Staking |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 active (PK + 1 NC + 1 unique NC) |

---

## 1. Business Meaning

Staking.StakingRewards stores the monthly reward distributions earned by users who stake their cryptocurrency through eToro's staking program. Each row represents a single monthly reward payment to a specific wallet for a specific crypto asset. Rewards are calculated based on the user's staked holdings, the monthly yield percentage, and their club-tier yield share, then distributed monthly (typically during the second business week of the following month) as a "Position Airdrop" (new crypto position) or cash compensation.

Without this table, there would be no record of how much reward each user earned per staking period. This is the financial record of all staking income distributions and feeds into user-facing reward history displays and total reward calculations.

Rows are created by `Staking.InsertStakingReward`, which uses StakingIncomeId for idempotency (skips if already exists). The procedure resolves CryptoId from Wallet.CustomerWalletsView for backward compatibility when NULL. `Staking.GetStakingRewardList` retrieves a user's reward history by Gcid/CryptoId, and `Staking.GetStakingTotals` sums MonthlyReward for total rewards per wallet. The table is also accessed by cross-schema function `Wallet.GetStakingRewardsList` for the unified staking records list.

---

## 2. Business Logic

### 2.1 Monthly Reward Distribution

**What**: Rewards are distributed once per month per wallet per crypto, with a unique constraint preventing duplicate distributions.

**Columns/Parameters Involved**: `CryptoId`, `WalletId`, `StakingMonthId`, `MonthlyReward`

**Rules**:
- Unique index `idx_UniqSync` on (CryptoId, WalletId, StakingMonthId) ensures exactly one reward per wallet per month per crypto
- StakingMonthId uses YYYYMM integer format (e.g., 202306 = June 2023)
- Rewards below $1 USD equivalent are not distributed (per Confluence business rules)
- InsertStakingReward checks `EXISTS` on StakingIncomeId before inserting - returns immediately if duplicate

### 2.2 Yield Tracking

**What**: Each reward records both the pool yield and the user's share percentage for transparency and audit.

**Columns/Parameters Involved**: `MonthlyYieldPercentage`, `UserYieldPercentage`, `MonthlyReward`

**Rules**:
- MonthlyYieldPercentage: the overall staking pool yield for that month
- UserYieldPercentage: the user's share based on their eToro club tier
- MonthlyReward: the actual crypto amount received by the user
- Recent records show 0% for both yield fields, suggesting yield tracking may have moved to an external calculation system

---

## 3. Data Overview

| Id | StakingMonthId | WalletId | MonthlyReward | IncomeDate | Meaning |
|----|---------------|----------|---------------|------------|---------|
| 23617 | 202306 | DF5CD535-... | 0.01172 ETH | 2023-06-18 | June 2023 reward distribution - ~0.012 ETH earned from staking for this wallet |
| 23614 | 202306 | E313B331-... | 0.01562 ETH | 2023-06-18 | Same distribution batch - slightly higher reward indicating larger staked balance |
| 23613 | 202306 | 295DE8F2-... | 0.01904 ETH | 2023-06-18 | Highest reward in sample - largest staked position among these wallets |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing surrogate key. |
| 2 | StakingIncomeId | bigint | NO | - | VERIFIED | External income identifier from the reward calculation system. Used as idempotency key by InsertStakingReward (`EXISTS` check prevents duplicate inserts). Indexed by `idx_StakingIncomeId` for fast lookups. |
| 3 | CryptoId | int | NO | - | VERIFIED | The cryptocurrency for which the reward was earned. FK to Wallet.CryptoTypes.CryptoID. Currently all records are CryptoId=2 (ETH). Part of the unique constraint (CryptoId, WalletId, StakingMonthId). Resolved from Wallet.CustomerWalletsView by InsertStakingReward if NULL (backward compatibility). |
| 4 | WalletId | uniqueidentifier | NO | - | VERIFIED | The wallet receiving the staking reward. FK to Wallet.Wallets.WalletId. Part of the unique constraint. Used with Gcid from Wallet.CustomerWalletsView for per-user reward lookups in GetStakingRewardList. |
| 5 | StakingMonthId | int | NO | - | VERIFIED | The staking period month in YYYYMM format (e.g., 202306 = June 2023). Part of the unique constraint ensuring one reward per wallet per crypto per month. Ranges from 202106 to 202306 in current data. |
| 6 | MonthlyReward | decimal(36,18) | NO | - | VERIFIED | The amount of crypto earned as staking reward for this month, in the asset's native units (e.g., 0.01172 ETH). Summed by Staking.GetStakingTotals for total rewards per wallet. Must exceed ~$1 USD equivalent to be distributed. |
| 7 | MonthlyYieldPercentage | decimal(36,18) | NO | - | CODE-BACKED | The overall staking pool yield percentage for this month. Recent records show 0, suggesting yield tracking may have been externalized. |
| 8 | UserYieldPercentage | decimal(36,18) | NO | - | CODE-BACKED | The user's share of the pool yield, based on their eToro club tier. Recent records show 0, suggesting calculation moved upstream. Per Confluence, yield varies by club level. |
| 9 | IncomeDate | datetime2(7) | NO | - | VERIFIED | The date/time when the reward was calculated or distributed. Multiple rewards in the same batch share the same IncomeDate (e.g., all June 2023 rewards have 2023-06-18T07:58:54). |
| 10 | Occurred | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp when this reward record was inserted into the database. Slightly after IncomeDate due to processing time. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CryptoId | Wallet.CryptoTypes | FK | Identifies the cryptocurrency for which the reward was earned |
| WalletId | Wallet.Wallets | FK | Identifies the wallet receiving the staking reward |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Staking.GetStakingRewardList | - | SELECT | Retrieves reward history for a user by Gcid and CryptoId |
| Staking.GetStakingTotals | - | SELECT SUM | Calculates total MonthlyReward per wallet |
| Staking.InsertStakingReward | - | INSERT | Creates new monthly reward records with idempotency check |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Staking.StakingRewards (table)
  (no code-level dependencies - leaf node)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CryptoTypes | Table | FK target for CryptoId |
| Wallet.Wallets | Table | FK target for WalletId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Staking.InsertStakingReward | Stored Procedure | WRITER - creates monthly reward records |
| Staking.GetStakingRewardList | Stored Procedure | READER - retrieves reward history per user |
| Staking.GetStakingTotals | Stored Procedure | READER - sums MonthlyReward for total rewards |
| Wallet.GetStakingRewardsList | Function | READER - cross-schema function for unified staking records |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_StakingRewards | CLUSTERED PK | Id ASC | - | - | Active |
| idx_StakingIncomeId | NC | StakingIncomeId ASC | - | - | Active |
| idx_UniqSync | UNIQUE NC | CryptoId ASC, WalletId ASC, StakingMonthId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_StakingRewards | PRIMARY KEY | Clustered on Id, PAGE compression |
| DF_Staking_StakingRewards__Occurred | DEFAULT | getutcdate() for Occurred |
| FK_Staking_StakingRewards_CryptoId__Wallet_CryptoTypes_CryptoId | FOREIGN KEY | CryptoId -> Wallet.CryptoTypes.CryptoID |
| FK_Wallet_StakingRewards_WalletId__Wallet_Wallets_WalletId | FOREIGN KEY | WalletId -> Wallet.Wallets.WalletId |

---

## 8. Sample Queries

### 8.1 Get reward history for a specific wallet
```sql
SELECT sr.StakingMonthId, sr.MonthlyReward, sr.IncomeDate
FROM Staking.StakingRewards sr WITH (NOLOCK)
WHERE sr.WalletId = @WalletId AND sr.CryptoId = @CryptoId
ORDER BY sr.StakingMonthId DESC
```

### 8.2 Total rewards per wallet with crypto name
```sql
SELECT sr.WalletId, ct.Name AS CryptoName, SUM(sr.MonthlyReward) AS TotalRewards, COUNT(*) AS MonthsRewarded
FROM Staking.StakingRewards sr WITH (NOLOCK)
INNER JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON ct.CryptoID = sr.CryptoId
GROUP BY sr.WalletId, ct.Name
ORDER BY TotalRewards DESC
```

### 8.3 Monthly distribution summary
```sql
SELECT sr.StakingMonthId, COUNT(*) AS WalletsRewarded, SUM(sr.MonthlyReward) AS TotalDistributed
FROM Staking.StakingRewards sr WITH (NOLOCK)
GROUP BY sr.StakingMonthId
ORDER BY sr.StakingMonthId DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Staking](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/2022637656/Staking) | Confluence | Rewards distributed monthly as "Position Airdrop" (new crypto position) or cash compensation; amount depends on days held, monthly yield by club level, and minimum $1 threshold; distribution usually second business week of following month |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.3/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Staking.StakingRewards | Type: Table | Source: WalletDB/Staking/Tables/Staking.StakingRewards.sql*
