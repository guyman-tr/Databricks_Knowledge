# Trade.Bsl_MultiTEST

> Test variant of the BSL (Buy-Sell Logic) P&L calculation that computes profit/loss for a single position given its direction, rates, units, and currency conversion.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table-Valued Function |
| **Key Identifier** | Returns TABLE(Pnl decimal(18,6)) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.Bsl_MultiTEST is a test/debug version of the core BSL (Buy-Sell Logic) P&L calculation engine. It computes the profit or loss for a trading position given the position's direction (buy/sell), opening rate, current/closing rate, unit count, and a currency conversion rate. The "TEST" suffix indicates this is a sandbox version used for validating P&L formulas outside the production BSL pipeline.

The function exists to allow developers and QA to verify that the fundamental P&L arithmetic is correct in isolation, without needing to invoke the full production BSL framework that includes additional logic like spread adjustments, fee deductions, and multi-currency cascading.

This is a pure computational function with no table references. It accepts all inputs as parameters, performs a single arithmetic operation, and returns the result. It is not called by any views or stored procedures in the production codebase.

---

## 2. Business Logic

### 2.1 P&L Calculation Formula

**What**: Core position P&L computation using the standard rate-difference model.

**Columns/Parameters Involved**: `@IsBuy`, `@InitRate`, `@EndRate`, `@Units`, `@ConversionRate`

**Rules**:
- P&L = (EndRate - InitRate) * DirectionMultiplier * Units * ConversionRate
- For BUY positions (@IsBuy=1), direction multiplier is +1 (profit when EndRate > InitRate)
- For SELL positions (@IsBuy=0), direction multiplier is -1 (profit when EndRate < InitRate)
- ConversionRate converts the result from the instrument's currency to the account's base currency (typically USD)

**Diagram**:
```
  @EndRate - @InitRate = RateDiff
  RateDiff * (IsBuy ? +1 : -1) = DirectionalDiff
  DirectionalDiff * @Units = RawPnL (in instrument currency)
  RawPnL * @ConversionRate = Pnl (in account base currency)
```

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IsBuy | BIT | NO | - | CODE-BACKED | Position direction flag: 1 = BUY position (long - profits when price rises), 0 = SELL position (short - profits when price falls). Drives the sign of the P&L calculation via CASE expression. |
| 2 | @InitRate | DECIMAL(16,8) | NO | - | CODE-BACKED | The opening/entry rate of the position at the time it was opened. Subtracted from @EndRate to compute the rate differential. |
| 3 | @EndRate | DECIMAL(16,8) | NO | - | CODE-BACKED | The current market rate or closing rate used to evaluate unrealized or realized P&L. The difference from @InitRate determines profit or loss magnitude. |
| 4 | @Units | DECIMAL(16,6) | NO | - | CODE-BACKED | The position size in instrument units (e.g., number of shares, contracts, or crypto units). Multiplied by the rate difference to scale P&L proportionally to position size. |
| 5 | @ConversionRate | DECIMAL(16,8) | NO | - | CODE-BACKED | Currency conversion factor from the instrument's price currency to the account's base currency (typically USD). A rate of 1.0 means the instrument is already priced in the base currency. |
| 6 | Pnl (return) | DECIMAL(18,6) | NO | - | CODE-BACKED | The computed profit or loss in account base currency. Positive = profit, negative = loss. Formula: (@EndRate - @InitRate) * IsBuyDirection * @Units * @ConversionRate. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. It is a pure mathematical function with no table or view dependencies.

### 5.2 Referenced By (other objects point to this)

No production consumers found. This is a standalone test utility function.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Calculate P&L for a BUY position
```sql
SELECT Pnl
FROM   Trade.Bsl_MultiTEST(1, 150.00000000, 155.50000000, 10.000000, 1.00000000)
```

### 8.2 Calculate P&L for a SELL position
```sql
SELECT Pnl
FROM   Trade.Bsl_MultiTEST(0, 1.12500000, 1.11000000, 100000.000000, 1.00000000)
```

### 8.3 Compare BUY vs SELL P&L at the same rates
```sql
SELECT 'BUY' AS Direction, Pnl FROM Trade.Bsl_MultiTEST(1, 100.00000000, 105.00000000, 50.000000, 0.85000000)
UNION ALL
SELECT 'SELL', Pnl FROM Trade.Bsl_MultiTEST(0, 100.00000000, 105.00000000, 50.000000, 0.85000000)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. This is a test/debug utility function with no Confluence or Jira documentation.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 2/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Bsl_MultiTEST | Type: Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.Bsl_MultiTEST.sql*
