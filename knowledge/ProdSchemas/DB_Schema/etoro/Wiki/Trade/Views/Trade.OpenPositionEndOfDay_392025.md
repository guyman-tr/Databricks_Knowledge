# Trade.OpenPositionEndOfDay_392025

> Versioned end-of-day open position PnL view (March 9, 2025 iteration) using History.CurrencyPriceMaxDateWithSplitView for split-adjusted max-date prices, with percentage-based close fee estimation and stubbed Close_* columns for schema compatibility.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID (from Trade.PositionForExternalUse) |
| **Partition** | N/A |
| **Indexes** | N/A |
| **Status** | Legacy/versioned variant of Trade.OpenPositionEndOfDay |

---

## 1. Business Meaning

Trade.OpenPositionEndOfDay_392025 is a date-versioned variant of the Trade.OpenPositionEndOfDay view, preserved as a rollback point from approximately March 9, 2025. It computes end-of-day PnL for all open positions using split-adjusted historical prices from History.CurrencyPriceMaxDateWithSplitView.

Unlike the current main view, this variant: (1) uses FnGetCloseFeeInPercentage for fee estimation instead of FnGetCloseFee/FnGetCloseFeeOnOpen, (2) calculates close fees inline using percentage-based formulas, (3) outputs Close_* columns as hardcoded zeros for schema compatibility with consumers expecting dual PnL output.

The view exists for backward compatibility and rollback safety. If the current OpenPositionEndOfDay view causes issues, consumers can be redirected to this variant.

---

## 2. Business Logic

### 2.1 Single PnL with Stub Close Columns

**What**: Computes only one PnL (max-date rate) but provides Close_* columns as zeros for schema compatibility.

**Columns/Parameters Involved**: `PnLInDollars`, `Close_PnLInDollars` (always 0)

**Rules**:
- PnL calculated via Trade.FnCalculatePnLWrapper using max-date rate from History.CurrencyPriceMaxDateWithSplitView
- Close_PnLInDollars, Close_CalculationRate, Close_ConversionRate all stubbed as 0
- EstimateCloseFeeForCFD calculated inline: `Round((Units * ClosingRate * ConversionRate * FeePercent) / 100, 2)`
- EstimateCloseFeeOnOpen calculated inline using OpenTotalFees and OpenMarketSpread

---

## 3. Data Overview

N/A - same position data as Trade.OpenPositionEndOfDay with single PnL and zero-valued Close_* columns.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TPOS.* | (all) | - | - | VERIFIED | All columns from Trade.PositionForExternalUse. See PositionForExternalUse docs. |
| 2 | PnLInDollars | money | YES | - | CODE-BACKED | Max-date PnL in dollars via FnCalculatePnLWrapper. |
| 3 | PnLInCents | bigint | YES | - | CODE-BACKED | Max-date PnL in cents. |
| 4 | EstimateCloseFeeForCFD | money | YES | - | CODE-BACKED | Inline percentage-based close fee: `Round((Units * Rate * Conv * FeePercent) / 100, 2)`. From FnGetCloseFeeInPercentage. |
| 5 | CurrentCalculationRate | decimal | YES | - | CODE-BACKED | Max-date closing rate from FnCalculatePnLWrapper. |
| 6 | CurrentCalculationRateID | int | YES | - | CODE-BACKED | Price record ID for max-date rate. |
| 7 | CurrentConversionRate | decimal | YES | - | CODE-BACKED | Currency conversion rate at max-date. |
| 8 | CurrentConversionRateID | int | YES | - | CODE-BACKED | Price record ID for conversion rate. |
| 9 | EstimateCloseFeeOnOpen | money | YES | - | CODE-BACKED | Close fee estimated from open parameters using FnGetCloseFeeInPercentage. |
| 10 | EstimateCloseFeeOnOpenByUnits | money | YES | - | CODE-BACKED | Per-unit close fee from open parameters. |
| 11 | CurrentPriceType | int | NO | - | CODE-BACKED | Hardcoded 0. |
| 12 | CurrentOccurred | datetime | NO | - | CODE-BACKED | Set to GETDATE() (not from price source). |
| 13 | Close_PnLInDollars | decimal(38,6) | NO | - | CODE-BACKED | **Stubbed as 0** - no close PnL calculation in this variant. |
| 14 | Close_PnLInCents | decimal(38,6) | NO | - | CODE-BACKED | **Stubbed as 0**. |
| 15 | Close_CalculationRate | decimal(16,8) | NO | - | CODE-BACKED | **Stubbed as 0**. |
| 16 | Close_CalculationRateID | bigint | NO | - | CODE-BACKED | **Stubbed as 0**. |
| 17 | Close_ConversionRate | decimal(26,17) | NO | - | CODE-BACKED | **Stubbed as 0**. |
| 18 | Close_ConversionRateID | bigint | NO | - | CODE-BACKED | **Stubbed as 0**. |
| 19 | Close_PriceType | int | NO | - | CODE-BACKED | **Stubbed as 0**. |
| 20 | Close_Occurred | datetime | NO | - | CODE-BACKED | Set to getdate(). |
| 21 | Close_SourceID | int | NO | - | CODE-BACKED | **Stubbed as 0**. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TPOS.* | Trade.PositionForExternalUse | FROM | Open position data |
| PriceMaxData | History.CurrencyPriceMaxDateWithSplitView | LEFT JOIN | Split-adjusted max-date prices |
| (function) | Trade.FnIsRealPosition | CROSS APPLY | Real/CFD classification |
| (function) | Trade.FnGetConversionInstrument | CROSS APPLY | Conversion instrument lookup |
| (function) | Trade.FnCalculatePnLWrapper | CROSS APPLY | PnL calculation at max-date rate |
| (function) | Trade.FnGetCloseFeeInPercentage | OUTER APPLY | Percentage-based close fee |

### 5.2 Referenced By (other objects point to this)

No dependents found in the SSDT repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OpenPositionEndOfDay_392025 (view)
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
| Trade.PositionForExternalUse | View | FROM - base open position data |
| History.CurrencyPriceMaxDateWithSplitView | View | LEFT JOIN - split-adjusted prices |
| Trade.FnIsRealPosition | Function | CROSS APPLY |
| Trade.FnGetConversionInstrument | Function | CROSS APPLY |
| Trade.FnCalculatePnLWrapper | Function | CROSS APPLY |
| Trade.FnGetCloseFeeInPercentage | Function | OUTER APPLY |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Get end-of-day PnL for a customer
```sql
SELECT  PositionID, InstrumentID, PnLInDollars, EstimateCloseFeeForCFD
FROM    Trade.OpenPositionEndOfDay_392025 WITH (NOLOCK)
WHERE   CID = 12345;
```

### 8.2 Compare with main view
```sql
SELECT  a.PositionID, a.PnLInDollars AS V392025_PnL, b.PnLInDollars AS Main_PnL
FROM    Trade.OpenPositionEndOfDay_392025 a WITH (NOLOCK)
JOIN    Trade.OpenPositionEndOfDay b WITH (NOLOCK) ON a.PositionID = b.PositionID;
```

### 8.3 Summarize by instrument
```sql
SELECT  InstrumentID, COUNT(*) AS Positions, SUM(PnLInDollars) AS TotalPnL
FROM    Trade.OpenPositionEndOfDay_392025 WITH (NOLOCK)
GROUP BY InstrumentID ORDER BY TotalPnL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. This is a date-versioned rollback variant of Trade.OpenPositionEndOfDay.

---

*Generated: 2026-03-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OpenPositionEndOfDay_392025 | Type: View | Source: etoro/etoro/Trade/Views/Trade.OpenPositionEndOfDay_392025.sql*
