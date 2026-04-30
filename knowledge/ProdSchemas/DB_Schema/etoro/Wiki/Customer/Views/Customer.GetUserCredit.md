# Customer.GetUserCredit

> Customer balance in cents: returns CID and Credit*100 as UserCredit, with three legacy game-integration columns (GameCredit, TotalBet, TotalProfit) hardcoded to 0. Excludes the system account (CID=0).

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | View |
| **Key Identifier** | CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetUserCredit converts the customer's Credit balance from the decimal money type (dollars) to integer cents (Credit*100 AS UserCredit), a format commonly expected by game systems and legacy credit APIs. The view filters out CID=0 (the system/sentinel account) with WHERE CID != 0.

The three additional columns (GameCredit, TotalBet, TotalProfit) are hardcoded to 0 with commented-out original logic that would have calculated real values from game sessions. The original GameCredit used Internal.GetGameBetInCents; TotalBet and TotalProfit referenced a BackOffice aggregate table (BackOffice.CustomerAllTimeAggregatedData). All three were disabled when the game/credit hybrid system was decommissioned, but the columns remain to preserve interface compatibility with downstream consumers.

---

## 2. Business Logic

### 2.1 Credit in Cents Conversion

**What**: UserCredit = CAST(Credit * 100 AS INTEGER) converts the money-typed Credit to integer cents.

**Columns/Parameters Involved**: `Credit`, `UserCredit`

**Rules**:
- Credit (money type) is in dollars with up to 4 decimal places
- UserCredit = CAST(Credit * 100 AS INTEGER) - truncates to whole cents
- CID=0 is excluded (system account sentinel): WHERE CCST.CID != 0
- Example: Credit=1000.50 -> UserCredit=100050

### 2.2 Disabled Legacy Game Columns

**What**: GameCredit, TotalBet, TotalProfit are interface-compatibility placeholders hardcoded to 0.

**Columns/Parameters Involved**: `GameCredit`, `TotalBet`, `TotalProfit`

**Rules**:
- GameCredit: was `SUM(Internal.GetGameBetInCents(ForexResultID))` - sum of game bet values in cents
- TotalBet: was `CAST(BackOffice.CustomerAllTimeAggregatedData.TotalInvestment*100 AS INTEGER)`
- TotalProfit: was `CAST(BackOffice.CustomerAllTimeAggregatedData.TotalProfit*100 AS INTEGER)`
- All three now return 0 permanently

---

## 3. Data Overview

N/A for view - data is Customer.Customer (one row per customer with CID != 0) with Credit converted to cents.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer ID. From Customer.Customer. System account (CID=0) is excluded via WHERE CID != 0. |
| 2 | UserCredit | int | YES | - | VERIFIED | Customer's available balance in integer cents: CAST(Credit * 100 AS INTEGER). NULL if CustomerMoney.Credit is NULL (LEFT JOIN in base view). Represents spending power in cent-precision for game/credit APIs. |
| 3 | GameCredit | int | NO | - | VERIFIED | Always 0. Originally: sum of game bet amounts in cents from Internal.GetGameBetInCents per ForexResultID. Disabled when game system was decommissioned. Preserved for interface compatibility. |
| 4 | TotalBet | int | NO | - | VERIFIED | Always 0. Originally: CAST(TotalInvestment*100 AS INTEGER) from BackOffice.CustomerAllTimeAggregatedData. Disabled. Preserved for interface compatibility. |
| 5 | TotalProfit | int | NO | - | VERIFIED | Always 0. Originally: CAST(TotalProfit*100 AS INTEGER) from BackOffice.CustomerAllTimeAggregatedData. Disabled. Preserved for interface compatibility. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.Customer | FROM (NOLOCK) | Source for CID and Credit |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetUserCredit (view)
└── Customer.Customer (view)
      ├── Customer.CustomerStatic (table)
      └── Customer.CustomerMoney (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM NOLOCK - source for CID and Credit |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None. No SCHEMABINDING declared.

---

## 8. Sample Queries

### 8.1 Get credit in cents for a specific customer
```sql
SELECT CID, UserCredit, GameCredit, TotalBet, TotalProfit
FROM Customer.GetUserCredit WITH (NOLOCK)
WHERE CID = 12345;
```

### 8.2 Find customers with credit above a threshold (in cents)
```sql
SELECT CID, UserCredit
FROM Customer.GetUserCredit WITH (NOLOCK)
WHERE UserCredit > 100000  -- More than $1000
ORDER BY UserCredit DESC;
```

### 8.3 Count customers by credit range
```sql
SELECT
    CASE
        WHEN UserCredit = 0 THEN '0'
        WHEN UserCredit BETWEEN 1 AND 10000 THEN '$0.01-$100'
        WHEN UserCredit BETWEEN 10001 AND 100000 THEN '$100-$1000'
        ELSE '>$1000'
    END AS CreditRange,
    COUNT(*) AS CustomerCount
FROM Customer.GetUserCredit WITH (NOLOCK)
GROUP BY
    CASE
        WHEN UserCredit = 0 THEN '0'
        WHEN UserCredit BETWEEN 1 AND 10000 THEN '$0.01-$100'
        WHEN UserCredit BETWEEN 10001 AND 100000 THEN '$100-$1000'
        ELSE '>$1000'
    END
ORDER BY CustomerCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (view) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetUserCredit | Type: View | Source: etoro/etoro/Customer/Views/Customer.GetUserCredit.sql*
