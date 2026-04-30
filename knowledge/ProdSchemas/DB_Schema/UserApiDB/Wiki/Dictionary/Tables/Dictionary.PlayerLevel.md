# Dictionary.PlayerLevel

> Reference table defining eToro Club membership tiers with thresholds for cashout speed, equity ranges, and wallet access.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PlayerLevelID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (PK + unique on Name) |

---

## 1. Business Meaning

Dictionary.PlayerLevel defines the eToro Club membership tier system that rewards users based on their realized equity. Higher tiers unlock better benefits: faster withdrawal processing, priority support, and premium features. The tier system incentivizes users to increase their portfolio value and maintain long-term engagement with the platform.

This table is central to the user rewards and retention strategy. Each tier has defined equity thresholds for entry and maintenance, with a grace period (DaysInRiskBeforeDowngrade) before demotion if equity drops below the threshold. The 5% ThresholdPercentToCurrentLevel provides a buffer to prevent frequent tier oscillation from minor equity fluctuations.

Player level is recalculated periodically based on the user's realized equity. When equity rises into a new tier's range, the user is immediately upgraded. When it drops, the DaysInRiskBeforeDowngrade timer starts before downgrade occurs. The Internal tier (4) is reserved for employee and test accounts.

---

## 2. Business Logic

### 2.1 Tier Progression and Benefits

**What**: Equity-based tier system with asymmetric upgrade/downgrade mechanics.

**Columns/Parameters Involved**: `PlayerLevelID`, `RealizedEquityFrom`, `RealizedEquityTo`, `CashoutPendingHours`, `DaysInRiskBeforeDowngrade`, `ThresholdPercentToCurrentLevel`

**Rules**:
- Upgrade: immediate when equity enters new tier range
- Downgrade: delayed by DaysInRiskBeforeDowngrade (0-365 days depending on tier)
- 5% buffer (ThresholdPercentToCurrentLevel) prevents oscillation near boundaries
- Higher tiers get faster withdrawals: 120h (Bronze/Silver) -> 72h (Gold) -> 24h (Platinum+)
- Internal tier (Sort=0) is outside the normal progression

**Diagram**:
```
Bronze(1) $0-5K    [120h cashout, 0 days grace]
  |
Silver(5) $5K-10K  [120h cashout, 180 days grace]
  |
Gold(3) $10K-25K   [72h cashout, 180 days grace]
  |
Platinum(2) $25K-50K [24h cashout, 180 days grace]
  |
Platinum Plus(6) $50K-250K [24h cashout, 365 days grace]
  |
Diamond(7) $250K+   [24h cashout, 365 days grace]

Internal(4) - Employee/test accounts [120h cashout, no equity thresholds]
```

### 2.2 Downgrade Protection

**What**: Grace period mechanism preventing immediate tier loss from temporary equity dips.

**Columns/Parameters Involved**: `DaysInRiskBeforeDowngrade`, `ThresholdPercentToCurrentLevel`

**Rules**:
- Bronze: no grace period (0 days) - this is the base tier
- Silver/Gold/Platinum: 180-day grace period before downgrade
- Platinum Plus/Diamond: 365-day grace period - top tiers are stickier
- 5% threshold: equity must drop more than 5% below tier minimum to trigger the grace timer

---

## 3. Data Overview

| PlayerLevelID | Name | RealizedEquityFrom | RealizedEquityTo | CashoutPendingHours | Sort | Meaning |
|---|---|---|---|---|---|---|
| 1 | Bronze | -100000 | 5000 | 120 | 1 | Entry tier - all new users start here. Includes negative equity (margin) |
| 5 | Silver | 5000 | 10000 | 120 | 2 | Second tier - modest portfolio, same cashout speed as Bronze |
| 3 | Gold | 10000 | 25000 | 72 | 3 | Mid tier - faster 72h cashout, establishing track record |
| 2 | Platinum | 25000 | 50000 | 24 | 4 | Premium tier - 24h cashout, significant engagement |
| 6 | Platinum Plus | 50000 | 250000 | 24 | 5 | High-value tier - same 24h cashout, longer downgrade protection |
| 7 | Diamond | 250000 | 100000000 | 24 | 6 | Top tier - highest benefits, 365-day downgrade protection |
| 4 | Internal | null | null | 120 | 0 | Employee/test accounts - outside normal tier system |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PlayerLevelID | int | NO | - | CODE-BACKED | Primary key. Tier ID: 1=Bronze, 2=Platinum, 3=Gold, 4=Internal, 5=Silver, 6=Platinum Plus, 7=Diamond. Note: IDs are not in sort order. See [Player Level](_glossary.md#player-level). |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Tier display name shown in user profiles, emails, and rewards pages. Uniquely indexed. |
| 3 | CashoutPendingHours | int | YES | - | CODE-BACKED | Maximum hours for withdrawal processing at this tier. 120h (Bronze/Silver/Internal), 72h (Gold), 24h (Platinum+). Higher tiers = faster withdrawals. |
| 4 | FromSumLotCount | int | NO | - | CODE-BACKED | Legacy minimum lot count threshold. -1 means this criterion is not used for this tier. Replaced by RealizedEquity thresholds. |
| 5 | ToSumLotCount | int | NO | - | CODE-BACKED | Legacy maximum lot count threshold. -1 means this criterion is not used. Replaced by RealizedEquity thresholds. |
| 6 | FromSumDeposit | int | NO | - | CODE-BACKED | Legacy minimum cumulative deposit threshold (USD). -1 means not used. Replaced by RealizedEquity thresholds. |
| 7 | ToSumDeposit | int | NO | - | CODE-BACKED | Legacy maximum cumulative deposit threshold (USD). -1 means not used. Replaced by RealizedEquity thresholds. |
| 8 | Sort | int | NO | - | CODE-BACKED | Display sort order: 0=Internal, 1=Bronze, 2=Silver, 3=Gold, 4=Platinum, 5=Platinum Plus, 6=Diamond. Use this for tier ordering, not PlayerLevelID. |
| 9 | IsWalletRedeemAllowed | bit | NO | 1 | CODE-BACKED | Whether eToro Money wallet redemption is allowed at this tier. Currently true for all tiers. Default: 1 (allowed). |
| 10 | RealizedEquityFrom | int | YES | - | CODE-BACKED | Minimum realized equity (USD) for tier entry. NULL for Internal tier. Ranges: Bronze=-100K, Silver=5K, Gold=10K, Platinum=25K, Platinum Plus=50K, Diamond=250K. |
| 11 | RealizedEquityTo | int | YES | - | CODE-BACKED | Maximum realized equity (USD) for this tier. NULL for Internal. Upper bound before promotion to next tier. |
| 12 | ThresholdPercentToCurrentLevel | int | YES | - | CODE-BACKED | Buffer percentage below tier minimum before downgrade timer starts. 5% for all normal tiers. NULL for Internal. Prevents oscillation from minor equity changes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer user tables | PlayerLevelID | Lookup | Stores user's current eToro Club tier |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in Dictionary schema.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DPLL | CLUSTERED PK | PlayerLevelID | - | - | Active |
| uix_PlayerLevel_Name | NONCLUSTERED UNIQUE | Name | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_PlayerLevel_IsWalletRedeemAllowed | DEFAULT | (1) - wallet redemption allowed by default for all tiers |

---

## 8. Sample Queries

### 8.1 List tiers in progression order
```sql
SELECT PlayerLevelID, Name, RealizedEquityFrom, RealizedEquityTo, CashoutPendingHours
FROM Dictionary.PlayerLevel WITH (NOLOCK)
ORDER BY Sort
```

### 8.2 Find a user's tier and benefits
```sql
SELECT u.CustomerID, pl.Name AS Tier, pl.CashoutPendingHours, pl.RealizedEquityFrom, pl.RealizedEquityTo
FROM Customer.Users u WITH (NOLOCK)
JOIN Dictionary.PlayerLevel pl WITH (NOLOCK) ON u.PlayerLevelID = pl.PlayerLevelID
WHERE u.CustomerID = @CustomerID
```

### 8.3 Determine tier for a given equity
```sql
SELECT Name, CashoutPendingHours
FROM Dictionary.PlayerLevel WITH (NOLOCK)
WHERE @Equity BETWEEN RealizedEquityFrom AND RealizedEquityTo
  AND PlayerLevelID <> 4 -- Exclude Internal
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PlayerLevel | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.PlayerLevel.sql*
