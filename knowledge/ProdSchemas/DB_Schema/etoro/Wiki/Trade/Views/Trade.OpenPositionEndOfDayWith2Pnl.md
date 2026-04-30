# Trade.OpenPositionEndOfDayWith2Pnl

> Near-production end-of-day PnL view with dual PnL calculation (max-rate and close-rate), close fee estimation (CFD + open-based), using split-adjusted dual-price source from History.CurrencyPriceMaxDateClosingPriceWithSplitView.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID (from Trade.PositionForExternalUse) |
| **Partition** | N/A |
| **Indexes** | N/A |
| **Status** | Near-production variant / prototype for Trade.OpenPositionEndOfDay |

---

## 1. Business Meaning

Trade.OpenPositionEndOfDayWith2Pnl is the closest variant to the production `Trade.OpenPositionEndOfDay` view. It implements the complete dual-PnL calculation pattern:

1. **Max_PnL**: PnL using the maximum rate observed during the day (MaxDate_* columns) -- for mark-to-market valuations
2. **Close_PnL**: PnL using the closing rate (standard Bid/Ask columns) -- for settlement/reconciliation

Both use `History.CurrencyPriceMaxDateClosingPriceWithSplitView` as the price source, which provides both max-date and closing prices in a single row. This is the same source as the production view.

The view also includes close fee estimation using percentage-based fees and open-position-based fee calculation with unit-proportional adjustment.

---

## 2. Business Logic

### 2.1 Dual PnL Calculation

**What**: Two separate calls to `Trade.FnCalculatePnLWrapper` with different rate inputs.

**Rules**:
- **Close_PnL**: Uses `ClosingRate.Close_Rate` (from Close_Bid/Close_BidSpreaded/Close_Ask/Close_AskSpreaded) and `Close_PriceRateID`
- **Max_PnL**: Uses `MaxRate.Max_Rate` (from MaxDate_Bid/MaxDate_BidSpreaded/MaxDate_Ask/MaxDate_AskSpreaded) and `MaxDate_PriceRateID`
- Both share the same conversion rate

### 2.2 Close Fee Estimation

**What**: Three fee estimates provided.

**Rules**:
- **EstimateCloseFeeForCFD**: `Round((Units * Max_ClosingRate * ConversionRate * FeeValue) / 100, 2)` - uses max-rate PnL closing rate
- **EstimateCloseFeeOnOpen**: Uses open fees + spread adjustment; zero when OpenTotalFees=0
- **EstimateCloseFeeOnOpenByUnits**: Proportional to current vs initial units

---

## 3. Data Overview

N/A - view produces same position dataset as other EOD views.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TPOS.* | (all) | - | - | VERIFIED | All columns from Trade.PositionForExternalUse. |
| 2 | EstimateCloseFeeForCFD | money | YES | - | CODE-BACKED | Close fee based on current value using max-rate. |
| 3 | PnLInDollars | money | YES | - | CODE-BACKED | Max-rate PnL in dollars. |
| 4 | PnLInCents | bigint | YES | - | CODE-BACKED | Max-rate PnL in cents. |
| 5 | CurrentCalculationRate | decimal | YES | - | CODE-BACKED | Max-rate used for PnL. |
| 6 | CurrentCalculationRateID | bigint | YES | - | CODE-BACKED | PriceRateID of max rate. |
| 7 | CurrentConversionRate | money | YES | - | CODE-BACKED | Conversion rate used. |
| 8 | CurrentConversionRateID | bigint | YES | - | CODE-BACKED | PriceRateID of conversion. |
| 9 | CurrentPriceType | int | NO | 0 | CODE-BACKED | Always 0. |
| 10 | CurrentOccurred | datetime | YES | - | CODE-BACKED | Timestamp of max-rate price. |
| 11 | Close_PnLInDollars | money | YES | - | CODE-BACKED | Close-rate PnL in dollars. |
| 12 | Close_PnLInCents | bigint | YES | - | CODE-BACKED | Close-rate PnL in cents. |
| 13 | Close_CalculationRate | decimal | YES | - | CODE-BACKED | Closing rate used for close PnL. |
| 14 | Close_CalculationRateID | bigint | YES | - | CODE-BACKED | PriceRateID of closing rate. |
| 15 | Close_ConversionRate | money | YES | - | CODE-BACKED | Conversion rate for close PnL (same as max). |
| 16 | Close_ConversionRateID | bigint | YES | - | CODE-BACKED | PriceRateID of close conversion. |
| 17 | Close_PriceType | int | YES | - | CODE-BACKED | Price type from source. |
| 18 | Close_Occurred | datetime | YES | - | CODE-BACKED | Timestamp of closing price. |
| 19 | Close_SourceID | int | YES | - | CODE-BACKED | Source ID of closing price. |
| 20 | EstimateCloseFeeOnOpen | money | YES | - | CODE-BACKED | Close fee from open fees. |
| 21 | EstimateCloseFeeOnOpenByUnits | money | YES | - | CODE-BACKED | Close fee proportional to units. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TPOS.* | Trade.PositionForExternalUse | FROM | Open position data |
| PriceMaxData | History.CurrencyPriceMaxDateClosingPriceWithSplitView | LEFT JOIN | Dual-price (max + close) split-adjusted |
| (function) | Trade.FnIsRealPosition | CROSS APPLY | Real/CFD classification |
| (function) | Trade.FnGetConversionInstrument | CROSS APPLY | Conversion instrument |
| (function) | Trade.FnCalculatePnLWrapper | CROSS APPLY x2 | Close_PnL + Max_PnL |
| (function) | Trade.FnGetCloseFeeInPercentage | OUTER APPLY | Percentage-based close fee |

### 5.2 Referenced By (other objects point to this)

No dependents found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OpenPositionEndOfDayWith2Pnl (view)
+-- Trade.PositionForExternalUse (view)
+-- History.CurrencyPriceMaxDateClosingPriceWithSplitView (view) [cross-schema]
+-- Trade.FnIsRealPosition (function)
+-- Trade.FnGetConversionInstrument (function)
+-- Trade.FnCalculatePnLWrapper (function) [called 2x]
+-- Trade.FnGetCloseFeeInPercentage (function)
```

---

## 7. Technical Details

### 7.1 Relationship to Production

This view is nearly identical to the production `Trade.OpenPositionEndOfDay` but uses `Trade.FnGetCloseFeeInPercentage` for fee estimation instead of `Trade.FnGetCloseFeeOnOpen` + `Trade.FnGetCloseFee`. The production view later switched to more precise fee calculation functions.

---

## 8. Sample Queries

### 8.1 Compare dual PnL
```sql
SELECT  PositionID,
        PnLInDollars AS MaxRatePnL,
        Close_PnLInDollars AS CloseRatePnL,
        PnLInDollars - Close_PnLInDollars AS PnLDifference
FROM    Trade.OpenPositionEndOfDayWith2Pnl WITH (NOLOCK)
WHERE   CID = 12345;
```

### 8.2 Positions where max-rate vs close-rate diverge significantly
```sql
SELECT  PositionID, InstrumentID, PnLInDollars, Close_PnLInDollars
FROM    Trade.OpenPositionEndOfDayWith2Pnl WITH (NOLOCK)
WHERE   ABS(PnLInDollars - Close_PnLInDollars) > 100
ORDER BY ABS(PnLInDollars - Close_PnLInDollars) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found.

---

*Generated: 2026-03-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OpenPositionEndOfDayWith2Pnl | Type: View | Source: etoro/etoro/Trade/Views/Trade.OpenPositionEndOfDayWith2Pnl.sql*
