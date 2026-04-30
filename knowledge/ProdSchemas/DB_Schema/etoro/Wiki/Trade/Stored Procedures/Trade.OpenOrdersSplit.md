# Trade.OpenOrdersSplit

> Adjusts active pending open orders (Trade.Orders) after a stock split by multiplying rates by the price ratio and lot counts by the amount ratio, using precision-aware rounding via Trade.RoundByPrecisions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @SplitID (identifies the split event from History.SplitRatio) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.OpenOrdersSplit is part of the stock split processing pipeline, adjusting active pending open orders in Trade.Orders to reflect new post-split prices and quantities. When a stock splits, pending entry orders (buy/sell orders that haven't been executed yet) must have their rates and quantities adjusted so they remain economically equivalent after the split.

Unlike Trade.CloseOrdersSplit (which adjusts historical data in History.Orders), this procedure modifies live active orders that customers are waiting to be filled. It uses more sophisticated rounding via Trade.RoundByPrecisions function and handles the "one pip" edge case (stop/take-profit set to the minimum possible value should not be adjusted).

The procedure operates within an explicit transaction and uses full-precision split ratios (AmountRatioUnAdjustedFull, PriceRatioUnAdjustedFull when available) for maximum accuracy.

---

## 2. Business Logic

### 2.1 Split Ratio Application to Active Orders

**What**: Adjusts rate and amount columns in Trade.Orders for active pending orders.

**Columns/Parameters Involved**: `@SplitID`, `PriceRatio`, `AmountRatio`, `InstrumentID`, `MinDate`

**Rules**:
- Uses full-precision ratios when available: ISNULL(AmountRatioUnAdjustedFull, AmountRatioUnAdjusted)
- Validates split exists and is not completed (IsCompletedOpenOrders=0)
- Validates instrument uses regular trading system (ProviderToInstrument.Enabled=1)
- StopLosRate and TakeProfitRate: skipped when equal to OnePip (minimum rate value)
- Rounding uses Trade.RoundByPrecisions(value, Precision, AboveDollarPrecision, IsBuy)
- RateFrom, RateTo, LastOpPriceRate: standard rounding with ROUND(@Precision)
- LotCountDecimal: multiplied by AmountRatio (no rounding - preserves fractional lots)
- Runs within explicit BEGIN TRAN / COMMIT TRAN
- After update: marks IsCompletedOpenOrders=1 in History.SplitRatio

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SplitID | INT | NO | - | CODE-BACKED | Identifier of the split event in History.SplitRatio. Must reference an incomplete split (IsCompletedOpenOrders=0). After processing, the split is marked as completed for open orders. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SplitID | History.SplitRatio | READ + UPDATE | Reads split ratios; marks IsCompletedOpenOrders=1 |
| InstrumentID | Trade.ProviderToInstrument | READ | Validates Enabled=1; reads Precision, AboveDollarPrecision |
| InstrumentID | Trade.Orders | UPDATE | Adjusts rates and lot counts for active pending orders |
| - | Trade.RoundByPrecisions | Function call | Precision-aware rounding for StopLosRate and TakeProfitRate |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ActivateSplit_Inner | (upstream) | EXEC | Called as part of the split activation pipeline |
| Stock split pipeline | External | One step in multi-table split processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OpenOrdersSplit (procedure)
+-- History.SplitRatio (table)
+-- Trade.ProviderToInstrument (table)
+-- Trade.Orders (table)
+-- Trade.RoundByPrecisions (function)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.SplitRatio | Table | READ (split ratios) + UPDATE (mark completed) |
| Trade.ProviderToInstrument | Table | READ (Enabled check + Precision + AboveDollarPrecision) |
| Trade.Orders | Table | UPDATE (adjust rates and lot counts for active orders) |
| Trade.RoundByPrecisions | Function | Called for precision-aware rounding of stop/take-profit rates |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ActivateSplit_Inner | Procedure | EXEC - part of split activation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Explicit transaction | Atomicity | BEGIN TRAN / COMMIT TRAN with ROLLBACK on error |
| Full-precision ratios | Accuracy | Uses DECIMAL(38,19) for PriceRatio and AmountRatio |
| OnePip skip | Business | StopLosRate/TakeProfitRate at minimum pip value are not adjusted |
| TRY/CATCH with THROW | Error handling | ROLLBACK on failure; re-throws exception |

---

## 8. Sample Queries

### 8.1 Check pending split operations for open orders

```sql
SELECT ID AS SplitID, InstrumentID, PriceRatioUnAdjusted, AmountRatioUnAdjusted, MinDate
FROM   History.SplitRatio WITH (NOLOCK)
WHERE  IsCompletedOpenOrders = 0
ORDER BY MinDate;
```

### 8.2 Preview active orders affected by a pending split

```sql
DECLARE @SplitID INT = 42;
SELECT COUNT(*) AS AffectedOrders
FROM   Trade.Orders o WITH (NOLOCK)
       INNER JOIN History.SplitRatio sr WITH (NOLOCK) ON sr.InstrumentID = o.InstrumentID
WHERE  sr.ID = @SplitID
  AND  o.OccurredTime < sr.MinDate;
```

### 8.3 Verify split completion across all steps

```sql
SELECT ID, InstrumentID, IsCompletedOpenPositions, IsCompletedClosePositions,
       IsCompletedOpenOrders, IsCompletedCloseOrders
FROM   History.SplitRatio WITH (NOLOCK)
ORDER BY ID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OpenOrdersSplit | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.OpenOrdersSplit.sql*
