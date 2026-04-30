# Trade.CalcNetProfit

> Simple PnL calculation function that computes net profit using the standard formula: (EndRate - InitRate) * Direction * Units * ConversionRate, without PnL version branching.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns DECIMAL(16,8) - net profit value |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CalcNetProfit is a simplified PnL calculation function that computes the net profit for a trading position using a single formula. Unlike Trade.FnCalculatePnL (which has dual formulas based on PnLVersion and settlement type), CalcNetProfit always uses the standard formula: price difference multiplied by direction, units, and conversion rate.

This function exists as a lightweight alternative to FnCalculatePnL for contexts where the legacy PnL version distinction is not needed - specifically in the Billing.GetRedeemNFTValidationData procedure for NFT redemption validation. It provides a quick scalar PnL calculation without the overhead of the inline TVF pattern.

The function takes the same core inputs as FnCalculatePnL (direction, rates, units, conversion rate) but as a scalar function returning a single decimal value. It does not handle the legacy real-stock formula variant.

---

## 2. Business Logic

### 2.1 Standard PnL Formula

**What**: Single-formula PnL calculation without version branching.

**Columns/Parameters Involved**: `@IsBuy`, `@InitRate`, `@EndRate`, `@Units`, `@ConversionRate`

**Rules**:
- Formula: `(EndRate - InitRate) * Direction * Units * ConversionRate`
- Direction: `IsBuy=1 -> +1` (long profits when price rises), `IsBuy=0 -> -1` (short profits when price falls)
- No ROUND - returns full decimal precision (unlike FnCalculatePnL which rounds to 2)
- No PnLVersion branching - always uses the standard formula

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IsBuy | BIT | NO | - | CODE-BACKED | Trade direction: 1 = Buy/Long, 0 = Sell/Short. Converted to +1/-1 multiplier. |
| 2 | @InitRate | decimal(16,8) | NO | - | CODE-BACKED | Opening price rate at position open. |
| 3 | @EndRate | decimal(16,8) | NO | - | CODE-BACKED | Closing/current price rate. |
| 4 | @Units | decimal(16,6) | NO | - | CODE-BACKED | Number of units in the position. |
| 5 | @ConversionRate | decimal(16,8) | NO | - | CODE-BACKED | Currency conversion rate (instrument currency to account currency). |
| 6 | Return value | DECIMAL(16,8) | NO | - | CODE-BACKED | Net profit in account currency. Positive = profit, negative = loss. Full precision (no rounding). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. Pure calculation function.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetRedeemNFTValidationData | Scalar call | Procedure call | NFT redemption PnL validation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CalcNetProfit (function)
(no dependencies - leaf node, pure calculation)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetRedeemNFTValidationData | Procedure | Scalar call for NFT redemption PnL check |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS DECIMAL(16,8) | Return type | Scalar function with full decimal precision (no rounding) |

---

## 8. Sample Queries

### 8.1 Calculate net profit for a hypothetical trade

```sql
SELECT Trade.CalcNetProfit(1, 150.50, 155.75, 100.0, 1.0) AS NetProfit;
```

### 8.2 Calculate net profit for all open positions

```sql
SELECT  p.PositionID,
        Trade.CalcNetProfit(p.IsBuy, p.InitForexRate, cp.BuyPrice, p.AmountInUnitsDecimal, ISNULL(p.InitConversionRate, 1.0)) AS NetProfit
FROM    Trade.PositionTbl p WITH (NOLOCK)
        CROSS APPLY (
            SELECT TOP 1 BuyPrice FROM Trade.CurrencyPrice WITH (NOLOCK) WHERE InstrumentID = p.InstrumentID
        ) cp
WHERE   p.StatusID = 1
        AND p.CID = 12345678;
```

### 8.3 Compare CalcNetProfit vs FnCalculatePnL

```sql
SELECT  simple.NetProfit,
        full_calc.PnL
FROM    (SELECT Trade.CalcNetProfit(1, 150.50, 155.75, 100.0, 1.0) AS NetProfit) simple
        CROSS JOIN Trade.FnCalculatePnL(1, 100.0, 0, 150.50, 1.0, 155.75, 1.0, 0) full_calc;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CalcNetProfit | Type: Scalar Function | Source: etoro/etoro/Trade/Functions/Trade.CalcNetProfit.sql*
