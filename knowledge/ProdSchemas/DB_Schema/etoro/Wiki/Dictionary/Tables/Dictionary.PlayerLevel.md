# Dictionary.PlayerLevel

> Lookup table defining the 7 customer loyalty tiers — Bronze through Diamond plus Internal — with tier-specific cashout wait times, equity thresholds, and downgrade protection rules.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PlayerLevelID (INT, PK CLUSTERED) |
| **Partition** | DICTIONARY filegroup |
| **Row Count** | 7 (MCP verified) |
| **Indexes** | 2 active (PK clustered + unique NC on Name) |

---

## 1. Business Meaning

Dictionary.PlayerLevel defines the eToro Club loyalty program tiers that segment customers by their realized equity (account value). Each tier grants progressively better benefits: faster cashout processing, higher service priority, and dedicated account management. The tiers, in ascending order, are: Bronze → Silver → Gold → Platinum → Platinum Plus → Diamond, plus a special Internal tier for employee/test accounts.

The primary qualification metric is **RealizedEquityFrom/To** — the customer's realized equity (deposits minus withdrawals plus realized P&L) determines which tier they qualify for. Legacy columns FromSumLotCount/ToSumLotCount and FromSumDeposit/ToSumDeposit exist from an older tier model but are set to -1 for upper tiers, indicating they're no longer used for qualification.

The most impactful tier benefit is **CashoutPendingHours** — Bronze customers wait up to 120 hours (5 business days) for cashout processing, while Platinum/Diamond customers get 24-hour processing. The **DaysInRiskBeforeDowngrade** column provides grace periods — Silver/Gold customers get 180 days before being downgraded if their equity drops, while Platinum Plus/Diamond get 365 days.

PlayerLevelID=4 (Internal) is frequently excluded in business logic with `WHERE PlayerLevelID <> 4`, as internal accounts should not appear in customer-facing reports or BSL (Below Stop Loss) processing.

---

## 2. Business Logic

### 2.1 Tier Qualification by Realized Equity

**What**: How customers are assigned to tiers based on their account value.

**Columns/Parameters Involved**: `PlayerLevelID`, `RealizedEquityFrom`, `RealizedEquityTo`, `Sort`

**Rules**:
- Tiers are evaluated by checking if customer's realized equity falls within [RealizedEquityFrom, RealizedEquityTo]
- **Bronze (1)**: -$100,000 to $5,000 — entry level, all new customers
- **Silver (5)**: $5,000 to $10,000
- **Gold (3)**: $10,000 to $25,000
- **Platinum (2)**: $25,000 to $50,000
- **Platinum Plus (6)**: $50,000 to $250,000
- **Diamond (7)**: $250,000 to $100,000,000
- **Internal (4)**: All zeros — not qualified by equity, assigned administratively
- Sort column defines display order (0=Internal, 1=Bronze, 2=Silver, 3=Gold, 4=Platinum, 5=Platinum Plus, 6=Diamond)

**Diagram**:
```
Realized Equity Tiers:
  -$100K ──────── $5K ──── $10K ──── $25K ──── $50K ──── $250K ──── $100M
  │    Bronze    │ Silver │  Gold  │ Plat  │ Plat+  │   Diamond   │
  │  (Level 1)  │(Lvl 5) │(Lvl 3)│(Lvl 2)│(Lvl 6) │  (Level 7)  │
```

### 2.2 Cashout Processing Speed

**What**: Tier-based withdrawal processing time.

**Columns/Parameters Involved**: `CashoutPendingHours`

**Rules**:
- **Bronze/Silver/Internal**: 120 hours (5 business days)
- **Gold**: 72 hours (3 business days)
- **Platinum/Platinum Plus/Diamond**: 24 hours (1 business day)
- Higher tiers get priority cashout processing as a loyalty benefit

### 2.3 Downgrade Protection

**What**: Grace period before a customer is downgraded when their equity drops.

**Columns/Parameters Involved**: `DaysInRiskBeforeDowngrade`, `ThresholdPercentToCurrentLevel`

**Rules**:
- **Bronze/Internal**: 0 days — immediate downgrade (or no downgrade possible for Bronze)
- **Silver/Gold**: 180 days grace period before downgrade
- **Platinum Plus/Diamond**: 365 days grace period
- ThresholdPercentToCurrentLevel (20%) — customer must fall to 80% of tier minimum before downgrade risk begins
- IsWalletRedeemAllowed=1 for all tiers — wallet redemption is permitted regardless of tier

---

## 3. Data Overview

| PlayerLevelID | Name | Sort | CashoutPendingHours | RealizedEquityFrom | RealizedEquityTo | DaysInRiskBeforeDowngrade | Meaning |
|---|---|---|---|---|---|---|---|
| 1 | Bronze | 1 | 120 | -100,000 | 5,000 | 0 | Entry-level tier. All new customers start here. 5-day cashout processing. No downgrade protection (already lowest). Legacy lot/deposit thresholds: 1-3000 lots, $0-$999. |
| 2 | Platinum | 4 | 24 | 25,000 | 50,000 | 180 | Premium tier. 24-hour cashout. 180-day downgrade protection. Legacy lot/deposit thresholds disabled (-1). |
| 3 | Gold | 3 | 72 | 10,000 | 25,000 | 180 | Mid-tier. 3-day cashout. 180-day downgrade protection. Legacy: 20,001-100,000 lots, $5,000-$19,999. |
| 4 | Internal | 0 | 120 | NULL | NULL | 0 | Employee/test accounts. Excluded from customer-facing logic via `WHERE PlayerLevelID <> 4`. All qualification thresholds zeroed. |
| 5 | Silver | 2 | 120 | 5,000 | 10,000 | 180 | Second tier. Same cashout speed as Bronze but with 180-day downgrade protection. Legacy: 3,001-20,000 lots, $1,000-$4,999. |
| 6 | Platinum Plus | 5 | 24 | 50,000 | 250,000 | 365 | High-value tier. 24-hour cashout. Full year downgrade protection. Legacy thresholds disabled (-1). |
| 7 | Diamond | 6 | 24 | 250,000 | 100,000,000 | 365 | Top tier. 24-hour cashout. Full year downgrade protection. VIP treatment with dedicated account management. Legacy thresholds disabled (-1). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PlayerLevelID | int | NO | - | VERIFIED | Primary key identifying the loyalty tier. 1=Bronze, 2=Platinum, 3=Gold, 4=Internal, 5=Silver, 6=Platinum Plus, 7=Diamond. Note: IDs are not in Sort order — use Sort column for display ordering. ID 4 is special (internal/employee) and is excluded from customer-facing queries. FK from Customer.RegistrationRequest and Customer.CustomerStatic. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Tier display name. Unique constraint prevents duplicates. Values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal. Used in BackOffice reporting JOINs and customer-facing UI. |
| 3 | CashoutPendingHours | int | YES | - | VERIFIED | Maximum hours a cashout request waits before processing. 120=5 days (Bronze/Silver/Internal), 72=3 days (Gold), 24=1 day (Platinum+). Key loyalty benefit — higher tiers get faster withdrawals. |
| 4 | FromSumLotCount | int | NO | - | VERIFIED | Legacy: minimum cumulative lot count for tier qualification. Set to -1 for upper tiers (disabled). Superseded by RealizedEquity thresholds. |
| 5 | ToSumLotCount | int | NO | - | VERIFIED | Legacy: maximum cumulative lot count for tier qualification. Set to -1 for upper tiers (disabled). Superseded by RealizedEquity thresholds. |
| 6 | FromSumDeposit | int | NO | - | VERIFIED | Legacy: minimum cumulative deposit amount (USD) for tier qualification. Set to -1 for upper tiers (disabled). Superseded by RealizedEquity thresholds. |
| 7 | ToSumDeposit | int | NO | - | VERIFIED | Legacy: maximum cumulative deposit amount (USD) for tier qualification. Set to -1 for upper tiers (disabled). Superseded by RealizedEquity thresholds. |
| 8 | Sort | int | NO | - | VERIFIED | Display order for tier hierarchy. 0=Internal, 1=Bronze, 2=Silver, 3=Gold, 4=Platinum, 5=Platinum Plus, 6=Diamond. Ascending order matches tier rank. |
| 9 | IsWalletRedeemAllowed | bit | NO | (1) | VERIFIED | Whether wallet/copy-fund redemption is permitted for this tier. Currently 1 (allowed) for all tiers. Default 1. |
| 10 | RealizedEquityFrom | int | YES | - | VERIFIED | Minimum realized equity (USD) to qualify for this tier. Current primary qualification metric. NULL for Internal tier. Range: -100,000 (Bronze) to 250,000 (Diamond). |
| 11 | RealizedEquityTo | int | YES | - | VERIFIED | Maximum realized equity (USD) for this tier. NULL for Internal tier. Range: 5,000 (Bronze) to 100,000,000 (Diamond). |
| 12 | ThresholdPercentToCurrentLevel | int | YES | - | VERIFIED | Percentage threshold before downgrade risk begins. Currently 20 for all customer tiers (customer must fall to 80% of tier minimum). NULL for Internal. |
| 13 | DaysInRiskBeforeDowngrade | int | NO | (0) | VERIFIED | Grace period in days before tier downgrade when equity drops below threshold. 0=immediate (Bronze/Internal), 180=6 months (Silver/Gold), 365=1 year (Platinum+/Diamond). Default 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.RegistrationRequest | PlayerLevelID | Explicit FK | Default tier assigned at registration |
| Customer.CustomerStatic | PlayerLevelID | Implicit FK | Customer's current tier stored here |
| dbo.ClosedPositions | PlayerLevelID | Column | Tier at time of position close |
| Customer.SetPlayerLevel | @PlayerLevelID | Parameter | Updates customer tier |
| Customer.SetPlayerLevelNoLot | - | SELECT from Dictionary.PlayerLevel | Tier evaluation logic |
| Customer.DemographyEdit | @PlayerLevelID | Parameter INSERT | Sets tier during demographic editing |
| BackOffice.GetHistoryCustomer | PlayerLevelID | JOIN Dictionary.PlayerLevel | Resolves tier name for history display |
| BackOffice.InProcessPaymentsToSendPCIVersion | @IgnorePlayerLevelID | Parameter WHERE | Excludes specific tiers from payment reports |
| Billing.GetExchangeRatesForCustomerFunding_v4 | @PlayerLevelID | Parameter WHERE | Exchange rate rules per tier |
| Trade.CheckBSL | PlayerLevelID | WHERE <> 4 | Excludes Internal from BSL processing |
| Trade.GetUsersDataByFilters | PlayerLevelID | JOIN Dictionary.PlayerLevel | User search resolves tier name |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.PlayerLevel (table)
  └── referenced by Customer.RegistrationRequest (FK)
  └── referenced by Customer.CustomerStatic (implicit)
  └── joined by 20+ procedures across BackOffice, Billing, Trade, Customer schemas
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.RegistrationRequest | Table | FK on PlayerLevelID |
| Customer.CustomerStatic | Table | Stores customer's current tier |
| dbo.ClosedPositions | Table | Records tier at position close |
| Customer.SetPlayerLevel | Stored Procedure | Updates customer tier |
| Customer.SetPlayerLevelNoLot | Stored Procedure | Evaluates tier from Dictionary.PlayerLevel |
| BackOffice.GetHistoryCustomer | Stored Procedure | JOINs for tier name |
| BackOffice.GetPlayerLevel | Stored Procedure | Reads tier configuration |
| Billing.GetExchangeRatesForCustomerFunding_v4 | Stored Procedure | Tier-based exchange rate rules |
| Trade.CheckBSL | Stored Procedure | Excludes Internal tier |
| Trade.GetUsersDataByFilters | Stored Procedure | JOINs for tier name |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DPLL | CLUSTERED PK | PlayerLevelID ASC | - | - | Active |
| DPLL_NAME | NONCLUSTERED UNIQUE | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DPLL | PRIMARY KEY | Unique tier identifier, FILLFACTOR 90, DICTIONARY filegroup |
| DPLL_NAME | UNIQUE INDEX | Ensures no duplicate tier names, FILLFACTOR 90 |
| DF_DictionaryPlayerLevel_IsWalletRedeemAllowed | DEFAULT | IsWalletRedeemAllowed defaults to 1 (allowed) |
| df_DaysInRiskBeforeDowngrade | DEFAULT | DaysInRiskBeforeDowngrade defaults to 0 (immediate) |

---

## 8. Sample Queries

### 8.1 List all tiers in rank order
```sql
SELECT  PlayerLevelID,
        Name,
        Sort,
        CashoutPendingHours,
        RealizedEquityFrom,
        RealizedEquityTo,
        DaysInRiskBeforeDowngrade
FROM    Dictionary.PlayerLevel WITH (NOLOCK)
ORDER BY Sort;
```

### 8.2 Count customers by tier
```sql
SELECT  dpl.Name            AS Tier,
        dpl.Sort,
        COUNT(*)            AS CustomerCount
FROM    Customer.CustomerStatic cs WITH (NOLOCK)
JOIN    Dictionary.PlayerLevel dpl WITH (NOLOCK)
        ON cs.PlayerLevelID = dpl.PlayerLevelID
WHERE   dpl.PlayerLevelID <> 4  -- exclude Internal
GROUP BY dpl.Name, dpl.Sort
ORDER BY dpl.Sort;
```

### 8.3 Find customers eligible for tier upgrade
```sql
SELECT  cs.CID,
        dpl.Name            AS CurrentTier,
        cs.RealizedEquity
FROM    Customer.CustomerStatic cs WITH (NOLOCK)
JOIN    Dictionary.PlayerLevel dpl WITH (NOLOCK)
        ON cs.PlayerLevelID = dpl.PlayerLevelID
WHERE   dpl.PlayerLevelID <> 4
        AND cs.RealizedEquity > dpl.RealizedEquityTo
ORDER BY cs.RealizedEquity DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from MCP live data and codebase analysis across 25+ procedures in Customer, BackOffice, Billing, and Trade schemas.

---

*Generated: 2026-03-13 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 13 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 25 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PlayerLevel | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PlayerLevel.sql*
