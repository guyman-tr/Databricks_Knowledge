# Trade.ChangeTreeInfoPerInstrument

> Multi-statement TVF that computes proposed Take Profit (TP) and Stop Loss (SL) adjustments for manual (non-copy) positions of a given instrument, based on configurable rate-difference percentage limits and current market prices.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Multi-Statement Table-Valued Function |
| **Key Identifier** | Returns TABLE with TreeID, CurrentRate, OrigTakeProfit, NewTakeProfit, CID, InstrumentID, OrigStopLoss, NewStopLoss, IsBuy, IsTslEnabled |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ChangeTreeInfoPerInstrument computes proposed TP and SL adjustments for manual positions (MirrorID=0) of a specific instrument. It applies rate-difference percentage limits to cap how far the new TP and SL can move from their original values or from current market. The function is used when bulk-updating TP/SL across many positions on the same instrument (e.g., via Trade.ChangeTreePropertiesPerInstrument).

This function exists because TP/SL updates must respect business rules that limit movement based on position size and notional exposure. The rate-difference percentages translate into absolute price moves that are compared against the current LimitRate (TP) and StopRate (SL). The proposed NewTakeProfit and NewStopLoss are rounded to the instrument's precision (from Trade.ProviderToInstrument).

Data flows: called by Trade.ChangeTreePropertiesPerInstrument with @InstrumentID, @TPPercentage (@RateDiffPercentageLimitRate), @SLPercentage (@RateDiffPercentageStopRate), and optional @NewTSL. Returns one row per manual position (tree) for that instrument, with original and proposed TP/SL values.

---

## 2. Business Logic

### 2.1 Take Profit Adjustment Logic

**What**: NewTakeProfit is computed as a function of current bid/ask, original LimitRate, and @RateDiffPercentageLimitRate.

**Columns/Parameters Involved**: `@RateDiffPercentageLimitRate`, `LimitRate`, `CP.Bid`, `CP.Ask`, `AmountInUnitsDecimal`, `InitialAmountCents`, `@ConversionRate`, `IsBuy`

**Rules**:
- For Buy positions: NewTakeProfit = MAX(LimitRate, Bid + (RateDiff% × InitialAmountCents/100) / (Units × ConversionRate)), capped by current bid movement
- For Sell positions: NewTakeProfit = MIN(LimitRate, Ask - (RateDiff% × InitialAmountCents/100) / (Units × ConversionRate))
- Divide-by-zero guard: when (AmountInUnitsDecimal × @ConversionRate) = 0, use LimitRate as-is
- Result rounded to @Precision from ProviderToInstrument

### 2.2 Stop Loss Adjustment Logic

**What**: NewStopLoss is computed from InitForexRate, original StopRate, and @RateDiffPercentageStopRate.

**Columns/Parameters Involved**: `@RateDiffPercentageStopRate`, `StopRate`, `InitForexRate`, `AmountInUnitsDecimal`, `InitialAmountCents`, `@ConversionRate`, `IsBuy`

**Rules**:
- For Buy positions: NewStopLoss = MIN(StopRate, InitForexRate - (RateDiff% × InitialAmountCents/100) / (Units × ConversionRate))
- For Sell positions: NewStopLoss = MAX(StopRate, InitForexRate + (RateDiff% × InitialAmountCents/100) / (Units × ConversionRate))
- Divide-by-zero guard: when (AmountInUnitsDecimal × @ConversionRate) = 0, use StopRate as-is
- Result rounded to @Precision

### 2.3 Manual-Only Filter

**What**: Only positions with MirrorID=0 (manual, non-copy) are included.

**Rule**: WHERE MirrorID = 0 ensures copy-trading positions are excluded from bulk TP/SL updates.

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | Instrument to process. Filters positions and drives ProviderToInstrument/GetMinorConversionRate lookups. |
| 2 | @RateDiffPercentageLimitRate | decimal(16,8) | NO | 200 | CODE-BACKED | Percentage limit for Take Profit adjustment. Default 200 = 200%. Used to cap TP movement from current price. |
| 3 | @RateDiffPercentageStopRate | decimal(16,8) | NO | - | CODE-BACKED | Percentage limit for Stop Loss adjustment. No default; caller must supply. Used to cap SL movement from InitForexRate. |
| 4 | @NewTSL | INT | YES | NULL | CODE-BACKED | Reserved parameter (trailing stop loss). Declared but not used in current logic. |
| 5 | TreeID (return) | bigint | - | - | CODE-BACKED | PositionID of the manual position, used as tree identifier. |
| 6 | CurrentRate (return) | dbo.dtPrice | - | - | CODE-BACKED | Current market rate: Bid for Buy, Ask for Sell (from Trade.CurrencyPrice). |
| 7 | OrigTakeProfit (return) | dbo.dtPrice | - | - | CODE-BACKED | Original LimitRate (take-profit level) before proposed adjustment. |
| 8 | NewTakeProfit (return) | dbo.dtPrice | - | - | CODE-BACKED | Proposed new take-profit level per rate-diff rules and instrument precision. |
| 9 | CID (return) | INT | - | - | CODE-BACKED | Customer ID of the position. |
| 10 | InstrumentID (return) | INT | - | - | CODE-BACKED | Instrument ID (same as @InstrumentID). |
| 11 | OrigStopLoss (return) | dbo.dtPrice | - | - | CODE-BACKED | Original StopRate (stop-loss level) before proposed adjustment. |
| 12 | NewStopLoss (return) | dbo.dtPrice | - | - | CODE-BACKED | Proposed new stop-loss level per rate-diff rules and instrument precision. |
| 13 | IsBuy (return) | INT | - | - | CODE-BACKED | Trade direction: 1=Buy, 0=Sell. Affects TP/SL direction of adjustment. |
| 14 | IsTslEnabled (return) | INT | - | - | CODE-BACKED | Trailing stop-loss enabled flag from Position. Passed through for caller. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.ProviderToInstrument | Lookup | Precision for rounding |
| @InstrumentID | Trade.GetMinorConversionRate | Scalar call | Conversion rate to USD for notional |
| Position data | Trade.Position | FROM/JOIN | Manual positions for instrument |
| InstrumentID | Trade.CurrencyPrice | JOIN | Current bid/ask for TP calculation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ChangeTreePropertiesPerInstrument | FROM | Procedure reference | Bulk TP/SL update per instrument |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ChangeTreeInfoPerInstrument (function)
├── Trade.ProviderToInstrument (table)
├── Trade.GetMinorConversionRate (scalar function)
├── Trade.Position (table)
└── Trade.CurrencyPrice (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | SELECT Precision for InstrumentID |
| Trade.GetMinorConversionRate | Scalar Function | Conversion rate for notional calculation |
| Trade.Position | Table | JOIN for manual positions (MirrorID=0) |
| Trade.CurrencyPrice | Table | INNER JOIN for current Bid/Ask |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ChangeTreePropertiesPerInstrument | Procedure | FROM ChangeTreeInfoPerInstrument for bulk TP/SL update |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS @T TABLE | Return type | Multi-statement TVF with declared table variable |
| @RateDiffPercentageLimitRate = 200 | Default | Default TP percentage limit |
| dbo.dtPrice | User-defined type | Custom decimal type for price precision |

---

## 8. Sample Queries

### 8.1 Get proposed TP/SL for manual positions on an instrument

```sql
SELECT  TreeID, CID, InstrumentID, CurrentRate, OrigTakeProfit, NewTakeProfit,
        OrigStopLoss, NewStopLoss, IsBuy, IsTslEnabled
FROM    Trade.ChangeTreeInfoPerInstrument(1001, 200, 150, NULL);
```

### 8.2 Compare original vs proposed TP/SL

```sql
SELECT  TreeID, CID,
        OrigTakeProfit, NewTakeProfit,
        OrigStopLoss, NewStopLoss,
        CASE WHEN NewTakeProfit <> OrigTakeProfit OR NewStopLoss <> OrigStopLoss
             THEN 1 ELSE 0 END AS HasChange
FROM    Trade.ChangeTreeInfoPerInstrument(5201, 200, 100, NULL);
```

### 8.3 Call via ChangeTreePropertiesPerInstrument (as used in production)

```sql
EXEC Trade.ChangeTreePropertiesPerInstrument
    @InstrumentID = 1001,
    @TPPercentage = 200,
    @SLPercentage = 150;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: DDL + Procedure scan*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | Corrections: 0 applied*
*Object: Trade.ChangeTreeInfoPerInstrument | Type: Multi-Statement Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.ChangeTreeInfoPerInstrument.sql*
