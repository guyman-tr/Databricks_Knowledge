# Wallet.GetStakingRewardsList

> Returns a paginated list of staking reward income records for a specific customer wallet and crypto asset, ordered by most recent first.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Multi-Statement TVF |
| **Key Identifier** | Returns one row per staking reward income record (RecordId / StakingIncomeId) |

---

## 1. Business Meaning

eToro wallet customers who stake eligible cryptocurrencies earn periodic rewards credited to their wallet balance. This function retrieves the staking reward income history for a specific customer and crypto asset, providing the data needed to display the staking rewards tab in the wallet UI and to support reward reconciliation in back-office workflows.

Each row in the result represents a single monthly staking reward distribution, identified by `StakingIncomeId`. The function exposes the reward amount, the user's effective yield percentage for the period, the crypto asset, and the staking month reference. Unlike the transaction list functions, this function is not built on the `Wallet.Requests` request pipeline — staking rewards are credited directly to wallets by the Staking subsystem (`Staking.StakingRewards`) and are not initiated by customer requests. The function uses `WITH EXECUTE AS owner` to handle cross-schema access between the `Wallet` and `Staking` schemas.

---

## 2. Business Logic

**Single CTE:**

- **`rewards`** — Selects `TOP @RecordsLimit` from `Staking.StakingRewards` joined to `Wallet.CustomerWalletsView` on `WalletId = cwv.Id`. Filtered by `cwv.Gcid = @Gcid`, `cwv.CryptoId = @CryptoId`, `sr.CryptoId = @CryptoId` (double-check), and `sr.IncomeDate < ISNULL(@BeginDateBefore, '2100-01-01')`. Note: there is no `@BeginDateAfter` parameter — this function only supports an upper-bound date filter, not a lower bound. Ordered by `sr.IncomeDate DESC`.

**INSERT**: Direct projection of the `rewards` CTE — no additional joins or transformations needed.

**Execution context**: The function declares `WITH EXECUTE AS owner` to permit the cross-schema `JOIN` from `Wallet.CustomerWalletsView` to `Staking.StakingRewards` under the owner's security context.

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

### Parameters (IN)

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `@Gcid` | BIGINT | required | Customer global customer ID |
| `@CryptoId` | INT | required | Specific crypto asset (required; not nullable like other functions) |
| `@BeginDateBefore` | DATETIME2(7) | required | Upper bound on IncomeDate (NULL = 2100-01-01); **no lower-bound parameter** |
| `@RecordsLimit` | INT | 10000 | Maximum rows returned |

### Return Columns (OUT)

| Column | Type | Description |
|--------|------|-------------|
| `RecordId` | BIGINT | Unique staking income record ID (`StakingIncomeId`) |
| `BeginDate` | DATETIME2(7) | Date the staking reward income was recorded (`IncomeDate`) |
| `Amount` | DECIMAL(36,18) | Reward amount credited to the wallet (`MonthlyReward`) |
| `YieldPercentage` | DECIMAL(36,18) | User's effective annualized yield percentage for the period |
| `CryptoId` | INT | Crypto asset ID for the reward |
| `StakingMonthId` | INT | Reference to the staking month record this reward belongs to |

---

## 5. Relationships

### 5.1 References To

| Object | Schema | Type | Purpose |
|--------|--------|------|---------|
| `StakingRewards` | Staking | Table | Primary source for staking reward income records |
| `CustomerWalletsView` | Wallet | View | Links Gcid + CryptoId to a wallet ID for filtering |

### 5.2 Referenced By

| Object | Type | Notes |
|--------|------|-------|
| Wallet staking rewards history API procedures | Stored Procedure | Customer-facing staking rewards display |
| Back-office staking reconciliation reports | Ad-hoc | Reward distribution audit queries |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetStakingRewardsList
├── Staking.StakingRewards
└── Wallet.CustomerWalletsView
```

### 6.1 Objects This Depends On

- `Staking.StakingRewards`
- `Wallet.CustomerWalletsView`

### 6.2 Objects That Depend On This

- Wallet staking rewards history stored procedures
- Back-office staking reward reporting queries

---

## 7. Technical Details

N/A for function.

---

## 8. Sample Queries

**1. Get staking rewards for a customer and crypto up to today:**
```sql
SELECT *
FROM Wallet.GetStakingRewardsList(
    123456,          -- @Gcid
    3,               -- @CryptoId (e.g., ETH)
    GETUTCDATE(),    -- @BeginDateBefore
    1000             -- @RecordsLimit
)
ORDER BY BeginDate DESC;
```

**2. Sum total staking rewards earned over all time for a customer:**
```sql
SELECT CryptoId,
       COUNT(*) AS RewardPeriods,
       SUM(Amount) AS TotalRewardAmount,
       AVG(YieldPercentage) AS AvgYield
FROM Wallet.GetStakingRewardsList(
    123456, 3, NULL, 10000
)
GROUP BY CryptoId;
```

**3. Retrieve rewards for a specific staking month:**
```sql
SELECT RecordId, BeginDate, Amount, YieldPercentage
FROM Wallet.GetStakingRewardsList(
    123456, 3,
    '2026-01-01',  -- Only rewards before Jan 2026
    10000
)
WHERE StakingMonthId = 42;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetStakingRewardsList | Type: Table-Valued Function | Source: WalletDB/Wallet/Functions/Wallet.GetStakingRewardsList.sql*
