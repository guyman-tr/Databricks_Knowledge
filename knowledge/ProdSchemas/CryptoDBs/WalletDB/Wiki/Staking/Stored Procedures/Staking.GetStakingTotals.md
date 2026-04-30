# Staking.GetStakingTotals

> Calculates the total staked amount (completed only) and total rewards for a specific wallet and cryptocurrency.

| Property | Value |
|----------|-------|
| **Schema** | Staking |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: TotalTransfers, TotalRewards |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure computes two key aggregate values for a user's staking activity: the total amount transferred to staking pools (from completed operations only) and the total rewards earned. These values are displayed to users in their staking dashboard as a summary of their staking portfolio.

The TotalTransfers calculation joins Staking.Staking to Staking.StakingStatuses and filters for StakingStatusId=3 (Completed), ensuring only successfully delegated amounts are counted. Failed or pending staking operations are excluded. TotalRewards simply sums all MonthlyReward values from StakingRewards for the same wallet.

---

## 2. Business Logic

### 2.1 Completed-Only Staking Totals

**What**: Sums only Completed staking amounts, excluding Failed and Pending operations.

**Columns/Parameters Involved**: `@WalletId`, `@CryptoId`, StakingStatusId

**Rules**:
- TotalTransfers: SUM(s.Amount) FROM Staking.Staking INNER JOIN StakingStatuses WHERE StakingStatusId=3
- TotalRewards: SUM(sr.MonthlyReward) FROM StakingRewards (no status filter - all rewards are already distributed)
- Both filtered by @WalletId AND @CryptoId
- Returns NULL for either total if no matching records exist

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CryptoId | int (IN) | NO | - | VERIFIED | The cryptocurrency to calculate totals for. Filters both Staking.Staking and StakingRewards by CryptoId. |
| 2 | @WalletId | uniqueidentifier (IN) | NO | - | VERIFIED | The wallet to calculate totals for. Filters both Staking.Staking and StakingRewards by WalletId. |

**Return Columns**:

| # | Element | Type | Description |
|---|---------|------|-------------|
| 1 | TotalTransfers | decimal(38,18) | Sum of Amount from completed staking operations. NULL if no completed stakings. |
| 2 | TotalRewards | decimal(38,18) | Sum of MonthlyReward from all reward distributions. NULL if no rewards. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Staking.Staking | SELECT SUM | Sums Amount for completed operations |
| - | Staking.StakingStatuses | INNER JOIN | Filters for StakingStatusId=3 (Completed) |
| - | Staking.StakingRewards | SELECT SUM | Sums MonthlyReward for total rewards |

### 5.2 Referenced By (other objects point to this)

Called by the staking service API for dashboard totals display.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Staking.GetStakingTotals (procedure)
+-- Staking.Staking (table)
+-- Staking.StakingStatuses (table)
+-- Staking.StakingRewards (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Staking.Staking | Table | SELECT SUM(Amount) - completed staking totals |
| Staking.StakingStatuses | Table | INNER JOIN - status filter (StakingStatusId=3) |
| Staking.StakingRewards | Table | SELECT SUM(MonthlyReward) - reward totals |

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

### 8.1 Get staking totals for a wallet
```sql
EXEC Staking.GetStakingTotals @CryptoId = 2, @WalletId = 'AA322F68-E305-48EF-866B-599E503F418D'
```

### 8.2 Equivalent direct query
```sql
SELECT
    (SELECT SUM(s.Amount) FROM Staking.Staking s WITH (NOLOCK)
     INNER JOIN Staking.StakingStatuses ss WITH (NOLOCK) ON ss.StakingId = s.Id
     WHERE ss.StakingStatusId = 3 AND s.WalletId = @WalletId AND s.CryptoId = @CryptoId) AS TotalTransfers,
    (SELECT SUM(sr.MonthlyReward) FROM Staking.StakingRewards sr WITH (NOLOCK)
     WHERE sr.WalletId = @WalletId AND sr.CryptoId = @CryptoId) AS TotalRewards
```

### 8.3 Top wallets by total staked
```sql
SELECT s.WalletId, SUM(s.Amount) AS TotalStaked
FROM Staking.Staking s WITH (NOLOCK)
INNER JOIN Staking.StakingStatuses ss WITH (NOLOCK) ON ss.StakingId = s.Id
WHERE ss.StakingStatusId = 3
GROUP BY s.WalletId
ORDER BY TotalStaked DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Staking](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/2022637656/Staking) | Confluence | Users can view their staking totals and reward history through the platform |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Staking.GetStakingTotals | Type: Stored Procedure | Source: WalletDB/Staking/Stored Procedures/Staking.GetStakingTotals.sql*
