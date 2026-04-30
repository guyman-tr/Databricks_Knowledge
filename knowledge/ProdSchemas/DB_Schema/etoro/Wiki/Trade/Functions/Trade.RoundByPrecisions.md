# Trade.RoundByPrecisions

> Rounds a price rate to the appropriate precision using CEILING (buy) or FLOOR (sell), with different precision levels for rates above and below $1.00.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns DECIMAL(16,8) - rounded rate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.RoundByPrecisions rounds price rates using directional rounding (CEILING for buy, FLOOR for sell) with precision that adapts to the rate magnitude. Rates at or below $1.00 use the full precision (e.g., 4 decimals), while rates above $1.00 use a reduced precision (e.g., 2 decimals). This reflects the financial convention that sub-dollar instruments (like forex minor pairs) need finer precision than dollar-plus instruments.

This function exists because price rounding must always favor the house (platform) to prevent quote arbitrage: buy prices are rounded UP (customer pays more) and sell prices are rounded DOWN (customer receives less). The dual-precision system prevents overly precise quotes on high-value instruments while maintaining sufficient granularity on low-value ones.

---

## 2. Business Logic

### 2.1 Directional Rounding with Dual Precision

**What**: CEILING for buys, FLOOR for sells, with precision adapted to rate magnitude.

**Columns/Parameters Involved**: `@Rate`, `@Precision`, `@AboveDollarPrecision`, `@IsBuy`

**Rules**:
- If @Rate <= 1.00: use @Precision (full precision, e.g., 4 decimals)
- If @Rate > 1.00: use @AboveDollarPrecision (reduced, e.g., 2 decimals)
- @IsBuy = 1: CEILING(Rate * 10^precision) / 10^precision (round UP)
- @IsBuy = 0: FLOOR(Rate * 10^precision) / 10^precision (round DOWN)

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Rate | DECIMAL(16,8) | NO | - | CODE-BACKED | The price rate to round. |
| 2 | @Precision | INT | NO | - | CODE-BACKED | Number of decimal places for rates at or below $1.00 (e.g., 4). |
| 3 | @AboveDollarPrecision | INT | NO | - | CODE-BACKED | Number of decimal places for rates above $1.00 (e.g., 2). |
| 4 | @IsBuy | BIT | NO | - | CODE-BACKED | Direction: 1 = round UP (CEILING, buy side), 0 = round DOWN (FLOOR, sell side). |
| 5 | Return value | DECIMAL(16,8) | NO | - | CODE-BACKED | Rounded rate. Always in the direction favorable to the platform. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. Pure calculation function.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.RoundByPrecisions (function)
(no dependencies - leaf node, pure calculation)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS DECIMAL(16,8) | Return type | Rounded rate with 8-decimal capacity |
| $DollarValue = 1.00 | Threshold | Rate magnitude determines which precision to use |

---

## 8. Sample Queries

### 8.1 Round buy and sell rates with different precision

```sql
SELECT  Trade.RoundByPrecisions(1.34567, 4, 2, 1) AS BuyRate,
        Trade.RoundByPrecisions(1.34567, 4, 2, 0) AS SellRate;
-- BuyRate: 1.35 (CEILING at 2 decimals, above $1)
-- SellRate: 1.34 (FLOOR at 2 decimals, above $1)
```

### 8.2 Show precision switch at $1.00 boundary

```sql
SELECT  Trade.RoundByPrecisions(0.34567, 4, 2, 1) AS SubDollarBuy,
        Trade.RoundByPrecisions(1.34567, 4, 2, 1) AS AboveDollarBuy;
-- SubDollarBuy: 0.3457 (4 decimals, below $1)
-- AboveDollarBuy: 1.35 (2 decimals, above $1)
```

### 8.3 Round conversion rates for position display

```sql
SELECT  cp.InstrumentID,
        cp.BuyPrice AS RawBuy,
        Trade.RoundByPrecisions(cp.BuyPrice, 4, 2, 1) AS RoundedBuy,
        cp.SellPrice AS RawSell,
        Trade.RoundByPrecisions(cp.SellPrice, 4, 2, 0) AS RoundedSell
FROM    Trade.CurrencyPrice cp WITH (NOLOCK)
WHERE   cp.InstrumentID IN (1, 5);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.RoundByPrecisions | Type: Scalar Function | Source: etoro/etoro/Trade/Functions/Trade.RoundByPrecisions.sql*
