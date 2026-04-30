# Trade.OpenPositionEndOfDayTestElad

> Developer test variant of end-of-day PnL view with full Real/CFD conversion rates, close fee estimation (CFD + open-position-based), and stubbed Close_* columns (all zeros), using split-adjusted prices.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID (from Trade.PositionForExternalUse) |
| **Partition** | N/A |
| **Indexes** | N/A |
| **Status** | Test/debug variant - evolutionary step toward production |

---

## 1. Business Meaning

Trade.OpenPositionEndOfDayTestElad is a developer test variant by "Elad" that represents an evolutionary step toward the production `OpenPositionEndOfDay` view. It includes:

- **Full Real/CFD-aware conversion rates** (10-case CASE statement)
- **EstimateCloseFeeForCFD** using percentage-based fee calculation
- **EstimateCloseFeeOnOpen** and **EstimateCloseFeeOnOpenByUnits** for open-position-based fee estimates
- **Rate transparency columns**: CurrentCalculationRate, CurrentCalculationRateID, CurrentConversionRate, CurrentConversionRateID
- **Stubbed Close_* columns**: All close-price PnL columns are set to 0, indicating this predates the dual-PnL implementation

This view tests the expanded column set that eventually made it into production, with the exception of actual close-price PnL calculation.

---

## 2. Business Logic

### 2.1 Close Fee Estimation (Three Methods)

**What**: Provides multiple close fee estimates.

**Rules**:
- **EstimateCloseFeeForCFD**: `Round((Units * ClosingRate * ConversionRate * FeeValue) / 100, 2)` - based on current position value
- **EstimateCloseFeeOnOpen**: Uses original open fees + spread adjustment: `OpenTotalFees + (BuyDirection * OpenMarketSpread * FeeValue / 100)`; zero if OpenTotalFees=0
- **EstimateCloseFeeOnOpenByUnits**: Proportional to current units vs initial: `EstimateCloseFeeOnOpen * AmountInUnitsDecimal / InitialUnits`; accounts for partial closes

### 2.2 Stubbed Close_* Columns

**What**: All close-price PnL columns are `CAST(0 AS ...)`.

**Rules**:
- Close_PnLInDollars, Close_PnLInCents, Close_CalculationRate, Close_CalculationRateID, Close_ConversionRate, Close_ConversionRateID, Close_PriceType, Close_SourceID = 0
- Close_Occurred = GETDATE() (placeholder)
- This indicates the view was created before close-price PnL was implemented

---

## 3. Data Overview

N/A - test view.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TPOS.* | (all) | - | - | VERIFIED | All columns from Trade.PositionForExternalUse. |
| 2 | PnLInDollars | money | YES | - | CODE-BACKED | Max-rate PnL using split-adjusted prices. |
| 3 | PnLInCents | bigint | YES | - | CODE-BACKED | PnL in cents. |
| 4 | EstimateCloseFeeForCFD | money | YES | - | CODE-BACKED | Estimated close fee based on current position value. |
| 5 | CurrentCalculationRate | decimal | YES | - | CODE-BACKED | Rate used for PnL calculation. |
| 6 | CurrentCalculationRateID | bigint | YES | - | CODE-BACKED | PriceRateID of calculation rate. |
| 7 | CurrentConversionRate | money | YES | - | CODE-BACKED | Currency conversion rate used. |
| 8 | CurrentConversionRateID | bigint | YES | - | CODE-BACKED | PriceRateID of conversion rate. |
| 9 | EstimateCloseFeeOnOpen | money | YES | - | CODE-BACKED | Close fee estimated from open position fees. |
| 10 | EstimateCloseFeeOnOpenByUnits | money | YES | - | CODE-BACKED | Close fee proportional to current vs initial units. |
| 11 | CurrentPriceType | int | NO | 0 | CODE-BACKED | Always 0 (placeholder). |
| 12 | CurrentOccurred | datetime | NO | - | CODE-BACKED | GETDATE() timestamp. |
| 13 | Close_PnLInDollars | decimal(38,6) | NO | 0 | CODE-BACKED | Stubbed to 0. |
| 14 | Close_PnLInCents | decimal(38,6) | NO | 0 | CODE-BACKED | Stubbed to 0. |
| 15 | Close_CalculationRate | decimal(16,8) | NO | 0 | CODE-BACKED | Stubbed to 0. |
| 16 | Close_CalculationRateID | bigint | NO | 0 | CODE-BACKED | Stubbed to 0. |
| 17 | Close_ConversionRate | decimal(26,17) | NO | 0 | CODE-BACKED | Stubbed to 0. |
| 18 | Close_ConversionRateID | bigint | NO | 0 | CODE-BACKED | Stubbed to 0. |
| 19 | Close_PriceType | int | NO | 0 | CODE-BACKED | Stubbed to 0. |
| 20 | Close_Occurred | datetime | NO | - | CODE-BACKED | GETDATE() placeholder. |
| 21 | Close_SourceID | int | NO | 0 | CODE-BACKED | Stubbed to 0. |

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
Trade.OpenPositionEndOfDayTestElad (view)
+-- Trade.PositionForExternalUse (view)
+-- History.CurrencyPriceMaxDateWithSplitView (view) [cross-schema]
+-- Trade.FnIsRealPosition (function)
+-- Trade.FnGetConversionInstrument (function)
+-- Trade.FnCalculatePnLWrapper (function)
+-- Trade.FnGetCloseFeeInPercentage (function)
```

---

## 7. Technical Details

### 7.1 Evolutionary Position

This view appears to be an intermediate step between `OpenPositionEndOfDaytest` (single PnL + fee) and the production `OpenPositionEndOfDay` (dual PnL + actual close-price computation). It introduces the Close_* column schema but stubs all values to zero.

---

## 8. Sample Queries

### 8.1 View fee estimates across methods
```sql
SELECT  PositionID, EstimateCloseFeeForCFD, EstimateCloseFeeOnOpen, EstimateCloseFeeOnOpenByUnits
FROM    Trade.OpenPositionEndOfDayTestElad WITH (NOLOCK)
WHERE   EstimateCloseFeeForCFD IS NOT NULL
ORDER BY EstimateCloseFeeForCFD DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found.

---

*Generated: 2026-03-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OpenPositionEndOfDayTestElad | Type: View | Source: etoro/etoro/Trade/Views/Trade.OpenPositionEndOfDayTestElad.sql*
