# Trade.OpenPositionEndOfDaytest

> Test variant of end-of-day PnL view using split-adjusted prices, full Real/CFD-aware conversion rates, and an added EstimateCloseFeeForCFD column using percentage-based fee calculation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID (from Trade.PositionForExternalUse) |
| **Partition** | N/A |
| **Indexes** | N/A |
| **Status** | Test/debug variant - near-production quality |

---

## 1. Business Meaning

Trade.OpenPositionEndOfDaytest is a test variant that closely approximates production behavior. It uses the correct split-adjusted price source (History.CurrencyPriceMaxDateWithSplitView), has the full Real/CFD-aware conversion rate logic (10-case CASE statement differentiating Bid vs BidSpreaded based on IsRealPosition), and adds an `EstimateCloseFeeForCFD` column via `Trade.FnGetCloseFeeInPercentage`.

This variant was likely used to test the addition of close-fee estimation before promoting the change to production.

---

## 2. Business Logic

### 2.1 Close Fee Estimation for CFD

**What**: Calculates an estimated close fee for CFD positions using percentage-based fee rates.

**Columns/Parameters Involved**: `EstimateCloseFeeForCFD`, `AmountInUnitsDecimal`, `CurrentClosingRate`, `ConversionRate`, `FeeValue`

**Rules**:
- For real positions (IsSettled=1): NULL (no close fee estimation)
- For CFD positions: `Round((Units * ClosingRate * ConversionRate * FeeValue) / 100.00, 2)`
- FeeValue from `Trade.FnGetCloseFeeInPercentage(InstrumentID, IsSettled)`

### 2.2 Full Real/CFD Conversion Rates

**What**: Full 10-case CASE statement for conversion rates, properly selecting Bid/Ask vs BidSpreaded/AskSpreaded.

**Rules**:
- Same instrument + non-reciprocal = 1
- Reciprocal + Real + Buy = 1/Bid; Reciprocal + CFD + Buy = 1/BidSpreaded
- Non-reciprocal + Real + Buy = Bid; Non-reciprocal + CFD + Buy = BidSpreaded
- (Same pattern for Sell with Ask/AskSpreaded)

---

## 3. Data Overview

N/A - test view.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TPOS.* | (all) | - | - | VERIFIED | All columns from Trade.PositionForExternalUse. |
| 2 | PnLInDollars | money | YES | - | CODE-BACKED | PnL using split-adjusted prices, full Real/CFD conversion. |
| 3 | PnLInCents | bigint | YES | - | CODE-BACKED | PnL in cents. |
| 4 | EstimateCloseFeeForCFD | money | YES | - | CODE-BACKED | Estimated close fee for CFD positions. NULL for real. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TPOS.* | Trade.PositionForExternalUse | FROM | Open position data |
| PriceMaxData | History.CurrencyPriceMaxDateWithSplitView | LEFT JOIN | Split-adjusted prices |
| (function) | Trade.FnIsRealPosition | CROSS APPLY | Real/CFD classification |
| (function) | Trade.FnGetConversionInstrument | CROSS APPLY | Conversion instrument |
| (function) | Trade.FnCalculatePnLWrapper | CROSS APPLY | PnL calculation |
| (function) | Trade.FnGetCloseFeeInPercentage | OUTER APPLY | Percentage-based close fee |

### 5.2 Referenced By (other objects point to this)

No dependents found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OpenPositionEndOfDaytest (view)
+-- Trade.PositionForExternalUse (view)
+-- History.CurrencyPriceMaxDateWithSplitView (view) [cross-schema]
+-- Trade.FnIsRealPosition (function)
+-- Trade.FnGetConversionInstrument (function)
+-- Trade.FnCalculatePnLWrapper (function)
+-- Trade.FnGetCloseFeeInPercentage (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionForExternalUse | View | FROM |
| History.CurrencyPriceMaxDateWithSplitView | View | LEFT JOIN |
| Trade.FnIsRealPosition | Function | CROSS APPLY |
| Trade.FnGetConversionInstrument | Function | CROSS APPLY |
| Trade.FnCalculatePnLWrapper | Function | CROSS APPLY |
| Trade.FnGetCloseFeeInPercentage | Function | OUTER APPLY - fee estimation |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Key Differences from Production

| Aspect | Production (OpenPositionEndOfDay) | This Test View |
|--------|-----------------------------------|----------------|
| Price Source | CurrencyPriceMaxDateClosingPriceWithSplitView (dual) | CurrencyPriceMaxDateWithSplitView (max-date only) |
| PnL Calculation | Two passes (Max_PnL + Close_PnL) | Single pass |
| Close Fee | FnGetCloseFeeOnOpen + FnGetCloseFee | FnGetCloseFeeInPercentage only |
| Close_* columns | Full close-price PnL | Not present |

---

## 8. Sample Queries

### 8.1 View close fee estimates for CFD positions
```sql
SELECT  PositionID, InstrumentID, PnLInDollars, EstimateCloseFeeForCFD
FROM    Trade.OpenPositionEndOfDaytest WITH (NOLOCK)
WHERE   EstimateCloseFeeForCFD IS NOT NULL
ORDER BY EstimateCloseFeeForCFD DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found.

---

*Generated: 2026-03-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OpenPositionEndOfDaytest | Type: View | Source: etoro/etoro/Trade/Views/Trade.OpenPositionEndOfDaytest.sql*
