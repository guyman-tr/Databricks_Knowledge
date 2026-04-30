# Trade.BslView

> Risk management view providing open position data with live closing rates, conversion rates, and customer equity for BSL (Below Stop Loss) monitoring, filtering out internal accounts, specific countries, and US-regulated users in certain country groups.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID (from Trade.PositionTbl) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.BslView combines open trading positions with live market rates and customer equity data for risk management monitoring. "BSL" refers to Below Stop Loss - a scenario where a position's current market value has fallen below its stop loss level, typically indicating a risk event that needs attention. The view provides all the data points needed to evaluate each open position's current value against the customer's available equity.

Without this view, risk monitoring tools would need to join multiple tables and call pricing functions inline, increasing complexity and query cost. The view pre-joins positions with live closing rates (via FnGetCurrentClosingRate), currency conversion rates (via FnGetCurrentConversionRate), and customer financial data (BonusCredit, RealizedEquity, BSLRealFunds).

The view excludes internal/employee accounts (PlayerLevelID <> 4), country 250 (specific excluded region), and US-regulated customers (DesignatedRegulationID=8) who belong to CountryGroupID=4. The hardcoded `IsInBlackList = 1` column indicates all positions returned by this view are considered "in the blacklist" for BSL monitoring.

---

## 2. Business Logic

### 2.1 BSL Position Monitoring Scope

**What**: Defines which open positions are subject to BSL risk monitoring.

**Columns/Parameters Involved**: All columns - filter criteria determine the monitored population

**Rules**:
- Only open positions (StatusID=1 in Trade.PositionTbl)
- Excludes internal/employee accounts (Customer.Customer.PlayerLevelID <> 4)
- Excludes country 250
- Excludes US-regulated customers in specific country groups: NOT (BackOffice.Customer.DesignatedRegulationID=8 AND CountryGroupID=4)
- All returned positions are flagged IsInBlackList=1 (hardcoded - every position in this view is a BSL candidate)
- JOINs to Trade.PositionTreeInfo via TreeID for position tree context

### 2.2 Live Rate Calculation

**What**: Retrieves current market rates for PnL evaluation at query time.

**Columns/Parameters Involved**: `CurrentRate`, `PriceRateID`, `ConversionRate`

**Rules**:
- CurrentRate from Trade.FnGetCurrentClosingRate: selects bid/ask based on IsBuy and IsSettled (real vs CFD)
- ConversionRate from Trade.FnGetCurrentConversionRate: converts from instrument currency to customer's account currency
- These are live rates computed at query time, not stored values

---

## 3. Data Overview

| CID | PositionID | InstrumentID | IsBuy | AmountInUnitsDecimal | InitForexRate | CurrentRate | ConversionRate | Meaning |
|---|---|---|---|---|---|---|---|---|
| 9264614 | 2152043920 | 100017 | Buy | 4.455969 | 0.50441 | 0.25977 | 1 | Open buy position on instrument 100017 with ~4.46 units. Current rate (0.26) well below entry rate (0.50) - significant loss. Conversion rate=1 means account currency matches. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer identifier. From Trade.PositionTbl.CID. References Customer.Customer. Used to join customer equity data (BonusCredit, RealizedEquity, BSLRealFunds). |
| 2 | PositionID | bigint | NO | - | VERIFIED | Unique position identifier. From Trade.PositionTbl.PositionID. The primary key of the underlying position. |
| 3 | InstrumentID | int | NO | - | VERIFIED | Trading instrument identifier. From Trade.PositionTbl.InstrumentID. Determines which market price to use for rate calculations. |
| 4 | IsBuy | bit | NO | - | VERIFIED | Position direction. From Trade.PositionTbl.IsBuy. 1=Buy/Long (closes at bid), 0=Sell/Short (closes at ask). Passed to FnGetCurrentClosingRate and FnGetCurrentConversionRate. |
| 5 | AmountInUnitsDecimal | decimal | YES | - | VERIFIED | Position size in fractional units. From Trade.PositionTbl.AmountInUnitsDecimal. Used to calculate position value: units * rate. |
| 6 | InitForexRate | decimal | YES | - | VERIFIED | The exchange rate at position open time. From Trade.PositionTbl.InitForexRate. Compared with CurrentRate to determine profit/loss direction and magnitude. |
| 7 | CurrentRate | decimal | YES | - | CODE-BACKED | Live closing rate at query time. Aliased from Trade.FnGetCurrentClosingRate.CurrentClosingRate. Selects bid or ask based on IsBuy and IsSettled. The current market value for closing this position. |
| 8 | PriceRateID | int | YES | - | CODE-BACKED | Price snapshot identifier. From Trade.FnGetCurrentClosingRate.PriceRateID. References Trade.CurrencyPrice for audit trail of which exact price was used. |
| 9 | ConversionRate | decimal | YES | - | CODE-BACKED | Currency conversion rate from instrument currency to customer account currency at query time. From Trade.FnGetCurrentConversionRate. 1.0 when currencies match (no conversion needed). |
| 10 | BonusCredit | money | YES | - | VERIFIED | Customer's current bonus credit balance. From Customer.Customer.BonusCredit. Part of the equity calculation for BSL threshold determination. |
| 11 | RealizedEquity | money | YES | - | VERIFIED | Customer's realized equity (cash + realized PnL). From Customer.Customer.RealizedEquity. Core input for determining if customer can sustain open positions. |
| 12 | BSLRealFunds | money | YES | - | CODE-BACKED | Customer's real funds specifically allocated for BSL calculations. From Customer.Customer.BSLRealFunds. Used in margin/equity checks distinct from general equity. |
| 13 | IsInBlackList | int | NO | - | VERIFIED | Hardcoded to 1 for all rows. Indicates every position returned by this view is flagged for BSL monitoring. Not a computed value - all rows are "in the blacklist" by definition of appearing in this view. |
| 14 | PartitionColCID | int | NO | - | CODE-BACKED | Computed partition column: `CID % 10`. Used for partition-aligned joins to other customer-partitioned tables. Derived from CID modulo 10. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, PositionID, InstrumentID, etc. | Trade.PositionTbl | FROM (base table) | Core position data - filtered to StatusID=1 (open) |
| TreeID | Trade.PositionTreeInfo | INNER JOIN | Position tree context via TreeID |
| CID | Customer.Customer | INNER JOIN | Customer equity data (BonusCredit, RealizedEquity, BSLRealFunds) |
| CID | BackOffice.Customer | INNER JOIN | DesignatedRegulationID for US regulation exclusion |
| (function) | Trade.FnGetCurrentClosingRate | CROSS APPLY | Live closing/opening rates based on direction and settlement type |
| (function) | Trade.FnGetCurrentConversionRate | CROSS APPLY | Currency conversion rate from instrument to account currency |

### 5.2 Referenced By (other objects point to this)

No direct consumers found in the Trade schema. Likely consumed by external monitoring/risk applications.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.BslView (view)
+-- Trade.PositionTbl (table)
+-- Trade.PositionTreeInfo (table)
+-- Customer.Customer (table) [cross-schema]
+-- BackOffice.Customer (table) [cross-schema]
+-- Dictionary.CountryToCountryGroup (table) [cross-schema]
+-- Trade.FnGetCurrentClosingRate (function)
|     +-- Trade.FnIsRealPosition (function)
|     +-- Trade.CurrencyPrice (table)
+-- Trade.FnGetCurrentConversionRate (function)
      +-- Trade.CurrencyPrice (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | FROM - base position data, filtered to open positions |
| Trade.PositionTreeInfo | Table | INNER JOIN on TreeID |
| Customer.Customer | Table | INNER JOIN on CID - equity and customer data |
| BackOffice.Customer | Table | INNER JOIN on CID - regulation filtering |
| Dictionary.CountryToCountryGroup | Table | EXISTS subquery - US country group exclusion |
| Trade.FnGetCurrentClosingRate | Function | CROSS APPLY - live closing rate calculation |
| Trade.FnGetCurrentConversionRate | Function | CROSS APPLY - currency conversion rate |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Find positions with largest unrealized loss
```sql
SELECT  TOP 10
        CID,
        PositionID,
        InstrumentID,
        AmountInUnitsDecimal * (CurrentRate - InitForexRate) * ConversionRate AS UnrealizedPnL,
        RealizedEquity
FROM    Trade.BslView WITH (NOLOCK)
WHERE   IsBuy = 1
ORDER BY AmountInUnitsDecimal * (CurrentRate - InitForexRate) * ConversionRate ASC;
```

### 8.2 Aggregate exposure by customer
```sql
SELECT  CID,
        COUNT(*)             AS OpenPositions,
        RealizedEquity,
        BSLRealFunds,
        BonusCredit
FROM    Trade.BslView WITH (NOLOCK)
GROUP BY CID, RealizedEquity, BSLRealFunds, BonusCredit
ORDER BY OpenPositions DESC;
```

### 8.3 List positions where current rate diverges significantly from entry
```sql
SELECT  CID,
        PositionID,
        InstrumentID,
        InitForexRate,
        CurrentRate,
        CASE WHEN InitForexRate > 0
             THEN ABS(CurrentRate - InitForexRate) / InitForexRate * 100
             ELSE 0 END AS PctChange
FROM    Trade.BslView WITH (NOLOCK)
WHERE   InitForexRate > 0
ORDER BY ABS(CurrentRate - InitForexRate) / InitForexRate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from DDL analysis, live data sampling, and dependency documentation (Trade.PositionTbl, Trade.FnGetCurrentClosingRate, Trade.FnGetCurrentConversionRate).

---

*Generated: 2026-03-15 | Quality: 8.7/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.BslView | Type: View | Source: etoro/etoro/Trade/Views/Trade.BslView.sql*
