# Trade.CalcPNLForSpecificRate

> Calculates the profit/loss (PnL) in dollars for an open position at a hypothetical closing rate, using the FnCalculatePnLWrapper function with the position's actual parameters.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ClosingRate (MONEY), @PositionID (BIGINT), @PNL (MONEY OUTPUT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure answers the question "what would the PnL be if this position closed right now at rate X?" It is used for what-if analysis, margin calculations, and pre-close validation - any scenario where the system needs to compute the financial outcome of a position close without actually closing it.

The procedure reads the open position's parameters from `Trade.PositionTbl` (instrument, direction, units, settlement type, open rate, conversion rate, PnL version, markup ratios, currency) and passes them to `Trade.FnCalculatePnLWrapper` along with the hypothetical closing rate. The function handles the complex PnL calculation including forex conversion, spread adjustments, and settlement-type-specific formulas. Only open positions (StatusID=1) are eligible.

The @PositionID parameter also drives a partition-aligned lookup: `PartitionCol = @PositionID % 50`.

---

## 2. Business Logic

### 2.1 PnL Calculation Delegation

**What**: Delegates PnL computation to FnCalculatePnLWrapper with the position's actual parameters and a hypothetical close rate.

**Columns/Parameters Involved**: `InstrumentID`, `IsBuy`, `AmountInUnitsDecimal`, `IsSettled`, `InitForexRate`, `InitConversionRate`, `PnLVersion`, `EstimatedMarkupRatio`, `EstimatedConversionMarkupRatio`, `CurrencyID`

**Rules**:
- Only works for open positions (WHERE StatusID = 1)
- Uses partition elimination (PartitionCol = @PositionID % 50) for efficient lookup
- The last 4 parameters to FnCalculatePnLWrapper are: @ClosingRate, 0 (closing conversion override), NULL, NULL
- Output is PnLInDollars - the net profit/loss denominated in USD
- If position is not found or not open, @PNL remains NULL

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ClosingRate | MONEY | NO | - | CODE-BACKED | Hypothetical closing rate to use for PnL calculation. The instrument price at which to simulate the position close. |
| 2 | @PositionID | BIGINT | NO | - | CODE-BACKED | The position to calculate PnL for. Must be open (StatusID=1) in Trade.PositionTbl. Also used to derive PartitionCol via modulo 50. Changed from INT to BIGINT on 17/11/2021 by Bonnie. |
| 3 | @PNL | MONEY OUTPUT | YES | - | CODE-BACKED | Returns the calculated profit/loss in dollars. NULL if position not found or not open. Positive = profit, negative = loss. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | Trade.PositionTbl | READER | Reads position parameters for PnL calculation |
| CROSS APPLY | Trade.FnCalculatePnLWrapper | Function call | Delegates PnL computation with position params + hypothetical close rate |

### 5.2 Referenced By (other objects point to this)

Called by margin validation, what-if analysis, and pre-close checks.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CalcPNLForSpecificRate (procedure)
+-- Trade.PositionTbl (table)
+-- Trade.FnCalculatePnLWrapper (function)
      +-- Trade.FnCalculateCurrentPnL (function)
      +-- Trade.FnCalculatePnLByRates (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | READER - position parameters (rates, amounts, flags) |
| Trade.FnCalculatePnLWrapper | Function | CROSS APPLY - PnL calculation engine |

### 6.2 Objects That Depend On This

No SQL-level dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| StatusID = 1 | Business filter | Only open positions can have hypothetical PnL calculated |
| PartitionCol = @PositionID % 50 | Partition elimination | Efficient lookup on partitioned PositionTbl |

---

## 8. Sample Queries

### 8.1 Calculate PnL for a position at a specific rate

```sql
DECLARE @PNL MONEY;
EXEC Trade.CalcPNLForSpecificRate @ClosingRate = 150.25, @PositionID = 100001, @PNL = @PNL OUTPUT;
SELECT @PNL AS EstimatedPnL;
```

### 8.2 Calculate PnL at current market rate

```sql
DECLARE @PNL MONEY, @Rate MONEY;
SELECT @Rate = Ask FROM Trade.CurrencyPrice WITH (NOLOCK)
WHERE InstrumentID = (SELECT InstrumentID FROM Trade.PositionTbl WITH (NOLOCK) WHERE PositionID = 100001);
EXEC Trade.CalcPNLForSpecificRate @ClosingRate = @Rate, @PositionID = 100001, @PNL = @PNL OUTPUT;
SELECT @PNL AS CurrentPnL;
```

### 8.3 Verify position is eligible for calculation

```sql
SELECT  PositionID, InstrumentID, IsBuy, AmountInUnitsDecimal, InitForexRate, StatusID
FROM    Trade.PositionTbl WITH (NOLOCK)
WHERE   PositionID = 100001
        AND PartitionCol = 100001 % 50;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CalcPNLForSpecificRate | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CalcPNLForSpecificRate.sql*
