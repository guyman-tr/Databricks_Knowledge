# Trade.OpenPositionEndOfDay

> End-of-day reporting view that combines open position data with historical closing prices to compute PnL at both the max-date rate and the official closing rate, including close fee estimates, for end-of-day account snapshots and reconciliation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID (from Trade.PositionForExternalUse) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.OpenPositionEndOfDay provides a comprehensive end-of-day snapshot of all open positions enriched with PnL calculations using historical end-of-day prices. Unlike live PnL views that use current market rates, this view uses closing prices from History.CurrencyPriceMaxDateClosingPriceWithSplitView to compute what each position was worth at market close. This is the authoritative view for daily reporting, regulatory snapshots, and overnight fee calculations.

Without this view, end-of-day reports and account statements would either use stale live rates or require ad-hoc PnL recalculation against historical prices. The view centralizes the complex logic of selecting the correct bid/ask/spread price based on position direction (buy/sell) and settlement type (real/CFD), applying conversion rates, and computing both a "max" PnL and a "close" PnL for each position.

Data flows from Trade.PositionForExternalUse (open positions), joined with historical prices from History.CurrencyPriceMaxDateClosingPriceWithSplitView. Two PnL calculations are performed via Trade.FnCalculatePnLWrapper: one using the max-date rate and one using the closing rate. Close fee estimates are computed via Trade.FnGetCloseFee and Trade.FnGetCloseFeeOnOpen.

---

## 2. Business Logic

### 2.1 Dual PnL Calculation (Max Rate vs Close Rate)

**What**: Computes PnL at two different price points for each position - the max-date rate and the official closing rate.

**Columns/Parameters Involved**: `PnLInDollars`, `PnLInCents`, `CurrentCalculationRate`, `Close_PnLInDollars`, `Close_PnLInCents`, `Close_CalculationRate`

**Rules**:
- Max PnL (Max_PnL): Uses the max-date price from the PriceMaxData CTE. This represents the position value at the highest available price timestamp.
- Close PnL (Close_PnL): Uses the official closing price (Close_* columns from History.CurrencyPriceMaxDateClosingPriceWithSplitView). This is the regulated market close price.
- Both PnL calculations use Trade.FnCalculatePnLWrapper with the same position parameters but different rate inputs.
- Price selection follows the direction/settlement matrix: Buy+CFD=BidSpreaded, Buy+Real=Bid, Sell+CFD=AskSpreaded, Sell+Real=Ask.

### 2.2 Close Fee Estimation

**What**: Estimates the fee that would be charged if the position were closed at end-of-day prices.

**Columns/Parameters Involved**: `EstimateCloseFeeForCFD`, `EstimateCloseFeeOnOpen`, `EstimateCloseFeeOnOpenByUnits`

**Rules**:
- EstimateCloseFeeForCFD: Via Trade.FnGetCloseFee using max-rate PnL closing rate and conversion rate
- EstimateCloseFeeOnOpen: Via Trade.FnGetCloseFeeOnOpen using the position's open fee data, initial lot count, and market spread at open
- These are estimates for reporting purposes, not actual charges

### 2.3 Conversion Rate Calculation

**What**: Determines the currency conversion rate from instrument currency to customer account currency using end-of-day prices.

**Columns/Parameters Involved**: `CurrentConversionRate`, `CurrentConversionRateID`

**Rules**:
- Uses Trade.FnGetConversionInstrument to find the conversion instrument for the pair
- Applies IsReciprocal flag: if reciprocal, conversion = 1/rate; otherwise direct rate
- Selects bid/ask based on direction (buy/sell) and settlement (real/CFD)
- Uses end-of-day prices from PriceMaxData CTE, not live rates

---

## 3. Data Overview

N/A - view output is too wide (all PositionForExternalUse columns + 14 additional computed columns). Key output columns are the PnL calculations and fee estimates overlaid on the base position data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TPOS.* | (all) | - | - | VERIFIED | All columns from Trade.PositionForExternalUse (open position data including CID, PositionID, InstrumentID, IsBuy, AmountInUnitsDecimal, etc.). See Trade.PositionForExternalUse documentation for full column descriptions. |
| 2 | EstimateCloseFeeForCFD | money | YES | - | CODE-BACKED | Estimated close fee for CFD positions at end-of-day rates. From Trade.FnGetCloseFee using max-rate closing rate and conversion rate. For real stock positions, this may be 0 or NULL. |
| 3 | PnLInDollars | money | YES | - | CODE-BACKED | Max-rate PnL in dollars. From Trade.FnCalculatePnLWrapper using the max-date market rate. Represents unrealized profit/loss at the highest available price timestamp. |
| 4 | PnLInCents | bigint | YES | - | CODE-BACKED | Max-rate PnL in cents (PnLInDollars * 100). From Trade.FnCalculatePnLWrapper. Integer representation for systems that use cent-based accounting. |
| 5 | CurrentCalculationRate | decimal | YES | - | CODE-BACKED | The max-date closing rate used for PnL calculation. From Trade.FnCalculatePnLWrapper.CurrentClosingRate. The bid or ask price selected based on IsBuy and IsRealPosition. |
| 6 | CurrentCalculationRateID | int | YES | - | CODE-BACKED | Price record ID for the max-date rate. From Trade.FnCalculatePnLWrapper.CurrentClosingRateID. References History.CurrencyPriceMaxDateClosingPriceWithSplitView.PriceRateID. |
| 7 | CurrentConversionRate | decimal | YES | - | CODE-BACKED | Currency conversion rate at end-of-day for the max-rate PnL. Computed from PriceMaxData using the conversion instrument pair, direction, and settlement type. |
| 8 | CurrentConversionRateID | int | YES | - | CODE-BACKED | Price record ID for the conversion rate. From the conversion instrument's PriceMaxData entry. |
| 9 | CurrentPriceType | int | NO | - | CODE-BACKED | Hardcoded to 0 for max-rate calculation. Distinguishes from the close-price calculation. |
| 10 | CurrentOccurred | datetime | YES | - | CODE-BACKED | Timestamp of the end-of-day price used for max-rate calculation. From History.CurrencyPriceMaxDateClosingPriceWithSplitView.Occurred. |
| 11 | Close_PnLInDollars | money | YES | - | CODE-BACKED | Official closing-rate PnL in dollars. From Trade.FnCalculatePnLWrapper using the Close_* prices. The regulated end-of-day position value. |
| 12 | Close_PnLInCents | bigint | YES | - | CODE-BACKED | Official closing-rate PnL in cents. Integer representation of Close_PnLInDollars. |
| 13 | Close_CalculationRate | decimal | YES | - | CODE-BACKED | Official closing rate used for close PnL. Selected from Close_Bid/Close_Ask/Close_BidSpreaded/Close_AskSpreaded based on direction and settlement. |
| 14 | Close_CalculationRateID | int | YES | - | CODE-BACKED | Price record ID for the official closing rate. |
| 15 | Close_ConversionRate | decimal | YES | - | CODE-BACKED | Conversion rate at official close. Same calculation as CurrentConversionRate but at the closing price point. |
| 16 | Close_ConversionRateID | int | YES | - | CODE-BACKED | Price record ID for the close conversion rate. |
| 17 | Close_PriceType | int | YES | - | CODE-BACKED | Price type indicator for the closing price. From History.CurrencyPriceMaxDateClosingPriceWithSplitView.PriceType. |
| 18 | Close_Occurred | datetime | YES | - | CODE-BACKED | Timestamp of the official closing price. |
| 19 | Close_SourceID | int | YES | - | CODE-BACKED | Source identifier for the closing price data. From History.CurrencyPriceMaxDateClosingPriceWithSplitView.Close_SourceID. |
| 20 | EstimateCloseFeeOnOpen | money | YES | - | CODE-BACKED | Estimated close fee calculated based on position open parameters. From Trade.FnGetCloseFeeOnOpen using OpenTotalFees, InitialLotCount, IsBuy, OpenMarketSpread, units. |
| 21 | EstimateCloseFeeOnOpenByUnits | money | YES | - | CODE-BACKED | Estimated close fee per unit, calculated from open parameters. From Trade.FnGetCloseFeeOnOpen. Alternative fee calculation method based on unit count. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TPOS.* | Trade.PositionForExternalUse | FROM (base view) | All open position data |
| PriceMaxData CTE | History.CurrencyPriceMaxDateClosingPriceWithSplitView | LEFT JOIN | End-of-day historical prices with split adjustments |
| (function) | Trade.FnIsRealPosition | CROSS APPLY | Classifies position as real stock vs CFD |
| (function) | Trade.FnGetConversionInstrument | CROSS APPLY | Finds conversion instrument for currency pair |
| (function) | Trade.FnCalculatePnLWrapper | CROSS APPLY (x2) | Computes PnL at max-rate and close-rate |
| (function) | Trade.FnGetCloseFeeOnOpen | OUTER APPLY | Estimates close fee from open parameters |
| (function) | Trade.FnGetCloseFee | OUTER APPLY | Estimates close fee at current rates |

### 5.2 Referenced By (other objects point to this)

No direct consumers found in the Trade schema SSDT files. Likely consumed by end-of-day reporting jobs and external systems.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OpenPositionEndOfDay (view)
+-- Trade.PositionForExternalUse (view)
|     +-- Trade.Position (view)
|           +-- Trade.PositionTbl (table)
|           +-- Trade.PositionTreeInfo (table)
+-- History.CurrencyPriceMaxDateClosingPriceWithSplitView (view) [cross-schema]
+-- Trade.FnIsRealPosition (function)
+-- Trade.FnGetConversionInstrument (function)
+-- Trade.FnCalculatePnLWrapper (function)
+-- Trade.FnGetCloseFeeOnOpen (function)
+-- Trade.FnGetCloseFee (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionForExternalUse | View | FROM - base open position data |
| History.CurrencyPriceMaxDateClosingPriceWithSplitView | View | LEFT JOIN - end-of-day historical prices |
| Trade.FnIsRealPosition | Function | CROSS APPLY - real/CFD classification |
| Trade.FnGetConversionInstrument | Function | CROSS APPLY - conversion instrument lookup |
| Trade.FnCalculatePnLWrapper | Function | CROSS APPLY (x2) - PnL at max and close rates |
| Trade.FnGetCloseFeeOnOpen | Function | OUTER APPLY - close fee from open parameters |
| Trade.FnGetCloseFee | Function | OUTER APPLY - close fee at current rates |

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

### 8.1 Get end-of-day PnL for a specific customer
```sql
SELECT  PositionID,
        InstrumentID,
        IsBuy,
        AmountInUnitsDecimal,
        PnLInDollars          AS MaxRatePnL,
        Close_PnLInDollars    AS ClosingPnL,
        CurrentCalculationRate,
        Close_CalculationRate
FROM    Trade.OpenPositionEndOfDay WITH (NOLOCK)
WHERE   CID = 12345;
```

### 8.2 Summarize end-of-day exposure by instrument
```sql
SELECT  InstrumentID,
        COUNT(*)                    AS Positions,
        SUM(Close_PnLInDollars)     AS TotalClosePnL,
        SUM(EstimateCloseFeeForCFD) AS TotalEstClFee
FROM    Trade.OpenPositionEndOfDay WITH (NOLOCK)
GROUP BY InstrumentID
ORDER BY TotalClosePnL;
```

### 8.3 Compare max-rate vs close-rate PnL
```sql
SELECT  TOP 20
        PositionID,
        PnLInDollars             AS MaxRatePnL,
        Close_PnLInDollars       AS ClosePnL,
        PnLInDollars - Close_PnLInDollars AS PnLDifference
FROM    Trade.OpenPositionEndOfDay WITH (NOLOCK)
ORDER BY ABS(PnLInDollars - Close_PnLInDollars) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from DDL analysis and dependency documentation (Trade.PositionForExternalUse, Trade.FnCalculatePnLWrapper, Trade.FnIsRealPosition, Trade.FnGetConversionInstrument).

---

*Generated: 2026-03-15 | Quality: 8.7/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OpenPositionEndOfDay | Type: View | Source: etoro/etoro/Trade/Views/Trade.OpenPositionEndOfDay.sql*
