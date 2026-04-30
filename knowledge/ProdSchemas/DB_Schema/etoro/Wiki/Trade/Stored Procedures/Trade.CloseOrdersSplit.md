# Trade.CloseOrdersSplit

> Adjusts historical closed order prices and amounts to reflect a stock split by multiplying rates by the price ratio and lot counts by the amount ratio for all orders opened before the split date.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @SplitID (identifies the split event from History.SplitRatio) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CloseOrdersSplit is part of the stock split processing pipeline. When a company undergoes a stock split (e.g., 2:1, 3:1), all historical order records for that instrument must be adjusted so that price charts, PnL calculations, and order history remain consistent. This procedure handles the adjustment of closed/historical orders in History.Orders.

For example, in a 2:1 split, a stock priced at $200 becomes $100, and a customer who held 10 shares now holds 20. The PriceRatio would be 0.5 and AmountRatio would be 2.0. This procedure multiplies all historical rates (RateFrom, RateTo, StopLosRate, TakeProfitRate, LastOpPriceRate) by the PriceRatio and LotCountDecimal by the AmountRatio, rounding to the instrument's configured precision.

The procedure validates that the instrument uses the regular trading system (Trade.ProviderToInstrument.Enabled=1) - some legacy stock instruments used a separate system with their own split procedure (StocksCloseOrdersSplit).

---

## 2. Business Logic

### 2.1 Split Ratio Application to Historical Orders

**What**: Adjusts all rate and amount columns in History.Orders for orders opened before the split date.

**Columns/Parameters Involved**: `@SplitID`, `PriceRatioUnAdjusted`, `AmountRatioUnAdjusted`, `InstrumentID`, `MinDate`

**Rules**:
- Reads PriceRatioUnAdjusted and AmountRatioUnAdjusted from History.SplitRatio WHERE ID = @SplitID AND IsCompletedCloseOrders = 0
- If split doesn't exist or already completed: RAISERROR
- Validates instrument is on regular trading system (Trade.ProviderToInstrument.Enabled=1)
- Updates History.Orders WHERE InstrumentID matches AND OpenOccurred < MinDate
- Rate columns multiplied by PriceRatio: RateFrom, RateTo, StopLosRate, TakeProfitRate, LastOpPriceRate
- Amount column multiplied by AmountRatio: LotCountDecimal
- All rate adjustments rounded to instrument's Precision from Trade.ProviderToInstrument
- After successful update, marks IsCompletedCloseOrders = 1 in History.SplitRatio

**Diagram**:
```
History.SplitRatio (ID = @SplitID, IsCompletedCloseOrders = 0)
          |
          Read PriceRatio, AmountRatio, InstrumentID, MinDate
          |
Trade.ProviderToInstrument (Enabled=1, get Precision)
          |
History.Orders (InstrumentID, OpenOccurred < MinDate)
          |
     UPDATE:
       RateFrom       *= PriceRatio (rounded)
       RateTo         *= PriceRatio (rounded)
       StopLosRate    *= PriceRatio (rounded)
       TakeProfitRate *= PriceRatio (rounded)
       LastOpPriceRate*= PriceRatio (rounded)
       LotCountDecimal*= AmountRatio
          |
History.SplitRatio -> IsCompletedCloseOrders = 1
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SplitID | INT | NO | - | CODE-BACKED | Identifier of the split event in History.SplitRatio. Must reference an incomplete split (IsCompletedCloseOrders=0). After processing, the split is marked as completed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SplitID | History.SplitRatio | READ + UPDATE | Reads split ratios and instrument; marks IsCompletedCloseOrders=1 after processing |
| InstrumentID | Trade.ProviderToInstrument | READ | Validates Enabled=1 and reads Precision for rounding |
| InstrumentID | History.Orders | UPDATE | Adjusts all rate/amount columns for historical orders before the split date |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Split processing pipeline | External | EXEC | Called as part of multi-step stock split processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CloseOrdersSplit (procedure)
+-- History.SplitRatio (table)
+-- Trade.ProviderToInstrument (table)
+-- History.Orders (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.SplitRatio | Table | READ (split ratios) + UPDATE (mark completed) |
| Trade.ProviderToInstrument | Table | READ (Enabled check + Precision for rounding) |
| History.Orders | Table | UPDATE (adjust rates and amounts for the split) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Stock split pipeline | External | One step in the multi-table split adjustment process |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Idempotency guard | Safety | IsCompletedCloseOrders=0 check prevents double-processing |
| TRY/CATCH with THROW | Error handling | Re-throws exceptions; RETURN -1 on failure |
| ROUND to Precision | Accuracy | All rate adjustments rounded to instrument-specific decimal places |

---

## 8. Sample Queries

### 8.1 Check pending split operations for close orders

```sql
SELECT ID AS SplitID, InstrumentID, PriceRatioUnAdjusted, AmountRatioUnAdjusted, MinDate
FROM   History.SplitRatio WITH (NOLOCK)
WHERE  IsCompletedCloseOrders = 0
ORDER BY MinDate;
```

### 8.2 Preview orders affected by a pending split

```sql
DECLARE @SplitID INT = 42;
SELECT COUNT(*) AS AffectedOrders
FROM   History.Orders o WITH (NOLOCK)
       INNER JOIN History.SplitRatio sr WITH (NOLOCK) ON sr.InstrumentID = o.InstrumentID
WHERE  sr.ID = @SplitID
  AND  o.OpenOccurred < sr.MinDate;
```

### 8.3 Verify split completion status across all steps

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
*Object: Trade.CloseOrdersSplit | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CloseOrdersSplit.sql*
