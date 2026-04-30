# Staking.GetStakingRewardList

> Retrieves paginated staking reward history for a specific customer and cryptocurrency, ordered by most recent first.

| Property | Value |
|----------|-------|
| **Schema** | Staking |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: staking reward records for a user |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns a customer's staking reward history for a given cryptocurrency, supporting the user-facing reward history display. It joins StakingRewards to Wallet.CustomerWalletsView to filter by Gcid (customer identity) and CryptoId, then returns rewards in reverse chronological order with backward cursor pagination via @FromRecordId.

Called by the staking service API when a user views their reward history. Uses `EXECUTE AS owner` for elevated permissions.

---

## 2. Business Logic

### 2.1 Backward Cursor Pagination

**What**: Uses a descending ID-based cursor for efficient pagination through reward history.

**Columns/Parameters Involved**: `@FromRecordId`, `@RecordsLimit`, `sr.Id`

**Rules**:
- Returns records WHERE sr.Id <= @FromRecordId (backward from a starting point)
- ORDER BY sr.Id DESC gives newest-first ordering
- Default @FromRecordId = 1 would return nothing useful; callers typically pass MAX(Id) or a specific cursor
- Default @RecordsLimit = 10000 provides a large default page size

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint (IN) | NO | - | VERIFIED | Global Customer ID. Used to filter rewards to a specific user via JOIN to Wallet.CustomerWalletsView.Gcid. |
| 2 | @CryptoId | int (IN) | NO | - | VERIFIED | The cryptocurrency to filter rewards for. Filters both StakingRewards.CryptoId and CustomerWalletsView.CryptoId. |
| 3 | @FromRecordId | bigint (IN) | YES | 1 | CODE-BACKED | Backward pagination cursor. Returns rewards with Id <= this value. Pass the last Id from previous page for next page. |
| 4 | @RecordsLimit | int (IN) | YES | 10000 | CODE-BACKED | Maximum records to return. Default 10000 effectively returns all records for most users. |

**Return Columns**: All columns from Staking.StakingRewards (Id, StakingIncomeId, CryptoId, WalletId, StakingMonthId, MonthlyReward, MonthlyYieldPercentage, UserYieldPercentage, IncomeDate, Occurred).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Staking.StakingRewards | SELECT FROM | Source of reward data |
| - | Wallet.CustomerWalletsView | INNER JOIN | Resolves Gcid to WalletId for customer filtering |

### 5.2 Referenced By (other objects point to this)

Called by the staking service API for reward history display.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Staking.GetStakingRewardList (procedure)
+-- Staking.StakingRewards (table)
+-- Wallet.CustomerWalletsView (view)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Staking.StakingRewards | Table | FROM - reward records |
| Wallet.CustomerWalletsView | View | INNER JOIN - customer identity resolution |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| EXECUTE AS owner | Security | Elevated permissions for cross-schema view access |

---

## 8. Sample Queries

### 8.1 Get all ETH rewards for a customer
```sql
EXEC Staking.GetStakingRewardList @Gcid = 14509456, @CryptoId = 2
```

### 8.2 Paginated call (second page)
```sql
EXEC Staking.GetStakingRewardList @Gcid = 14509456, @CryptoId = 2, @FromRecordId = 500, @RecordsLimit = 50
```

### 8.3 Equivalent direct query
```sql
SELECT TOP 50 sr.*
FROM Staking.StakingRewards sr WITH (NOLOCK)
INNER JOIN Wallet.CustomerWalletsView cwv WITH (NOLOCK) ON sr.WalletId = cwv.Id
WHERE cwv.Gcid = 14509456 AND cwv.CryptoId = 2 AND sr.CryptoId = 2 AND sr.Id <= 500
ORDER BY sr.Id DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Staking](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/2022637656/Staking) | Confluence | Reward history is available to users; rewards are monthly distributions based on staked holdings and club tier |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Staking.GetStakingRewardList | Type: Stored Procedure | Source: WalletDB/Staking/Stored Procedures/Staking.GetStakingRewardList.sql*
