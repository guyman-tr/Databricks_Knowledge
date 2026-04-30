# Staking.InsertStakingReward

> Creates a monthly staking reward record for a wallet with idempotency protection via StakingIncomeId.

| Property | Value |
|----------|-------|
| **Schema** | Staking |
| **Object Type** | Stored Procedure |
| **Key Identifier** | WRITER for Staking.StakingRewards |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure records a monthly staking reward distribution for a specific wallet. It is called by the reward calculation batch process during the monthly distribution cycle (typically second business week of the following month). The StakingIncomeId serves as an idempotency key - if a reward with this ID already exists, the procedure returns immediately without inserting.

For backward compatibility, if @CryptoId is NULL, it is resolved from Wallet.CustomerWalletsView using the wallet's blockchain crypto ID.

---

## 2. Business Logic

### 2.1 Idempotent Reward Insert

**What**: Prevents duplicate reward records using StakingIncomeId existence check.

**Columns/Parameters Involved**: `@StakingIncomeId`

**Rules**:
- Checks EXISTS on StakingRewards WHERE StakingIncomeId = @StakingIncomeId
- If exists: RETURN immediately (no error, silent skip)
- If not exists: INSERT the reward record
- This is softer than InsertStaking's approach (which raises an error on duplicate)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StakingIncomeId | bigint (IN) | NO | - | VERIFIED | External income ID from the reward calculation system. Idempotency key - skips insert if already exists in StakingRewards. |
| 2 | @CryptoId | int (IN) | YES | - | VERIFIED | The cryptocurrency for which the reward was earned. If NULL, resolved from Wallet.CustomerWalletsView. |
| 3 | @WalletId | uniqueidentifier (IN) | NO | - | VERIFIED | The wallet receiving the reward. FK to Wallet.Wallets.WalletId. |
| 4 | @StakingMonthId | int (IN) | NO | - | VERIFIED | The staking period month in YYYYMM format (e.g., 202306). |
| 5 | @MonthlyReward | decimal(36,18) (IN) | NO | - | VERIFIED | The reward amount in crypto native units. |
| 6 | @MonthlyYieldPercentage | decimal(36,18) (IN) | NO | - | CODE-BACKED | The overall pool yield percentage for the month. |
| 7 | @UserYieldPercentage | decimal(36,18) (IN) | NO | - | CODE-BACKED | The user's yield share based on their club tier. |
| 8 | @IncomeDate | datetime2(7) (IN) | NO | - | CODE-BACKED | The date the reward was calculated/distributed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Staking.StakingRewards | INSERT/SELECT | Creates reward records, checks for duplicates |
| - | Wallet.CustomerWalletsView | SELECT | CryptoId resolution fallback |

### 5.2 Referenced By (other objects point to this)

Called by the monthly reward distribution batch process.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Staking.InsertStakingReward (procedure)
+-- Staking.StakingRewards (table)
+-- Wallet.CustomerWalletsView (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Staking.StakingRewards | Table | INSERT + EXISTS check |
| Wallet.CustomerWalletsView | View | SELECT - CryptoId fallback |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Insert a monthly reward
```sql
EXEC Staking.InsertStakingReward
    @StakingIncomeId = 23618,
    @CryptoId = 2,
    @WalletId = 'AA322F68-E305-48EF-866B-599E503F418D',
    @StakingMonthId = 202307,
    @MonthlyReward = 0.015,
    @MonthlyYieldPercentage = 0.04,
    @UserYieldPercentage = 0.03,
    @IncomeDate = '2023-07-15'
```

### 8.2 Verify the inserted reward
```sql
SELECT * FROM Staking.StakingRewards WITH (NOLOCK) WHERE StakingIncomeId = 23618
```

### 8.3 Recent reward distributions
```sql
SELECT TOP 10 sr.Id, sr.StakingIncomeId, sr.WalletId, sr.MonthlyReward, sr.StakingMonthId
FROM Staking.StakingRewards sr WITH (NOLOCK)
ORDER BY sr.Id DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Staking](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/2022637656/Staking) | Confluence | Rewards distributed monthly during second business week; amount depends on held days, monthly yield, and club tier; minimum $1 threshold |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Staking.InsertStakingReward | Type: Stored Procedure | Source: WalletDB/Staking/Stored Procedures/Staking.InsertStakingReward.sql*
