# Trade.OpenPositionEndOfDay_before0192025

> Pre-January 9, 2025 version of the end-of-day open position PnL view using History.CurrencyPriceMaxDateWithSplitView, with percentage-based close fee estimation and single PnL calculation (no dual Close_* columns).

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

Trade.OpenPositionEndOfDay_before0192025 is the pre-January 9, 2025 version of the end-of-day PnL view, preserved as a rollback point. It computes a single PnL using split-adjusted max-date prices from History.CurrencyPriceMaxDateWithSplitView and uses FnGetCloseFeeInPercentage for close fee estimation.

Unlike the _392025 variant, this version does NOT include Close_* stub columns - it predates the schema expansion that added dual PnL output. It outputs only the max-date PnL plus inline close fee estimates calculated using percentage-based formulas.

---

## 2. Business Logic

### 2.1 Single PnL Calculation

**What**: Computes PnL at the max-date rate only, with percentage-based close fee estimation.

**Columns/Parameters Involved**: `PnLInDollars`, `EstimateCloseFeeForCFD`, `EstimateCloseFeeOnOpen`

**Rules**:
- PnL via Trade.FnCalculatePnLWrapper using max-date prices from History.CurrencyPriceMaxDateWithSplitView
- Close fee calculated inline: `Round((Units * ClosingRate * ConversionRate * FeePercent) / 100, 2)`
- EstimateCloseFeeOnOpen from OpenTotalFees + spread-adjusted percentage

---

## 3. Data Overview

N/A - same position data as Trade.OpenPositionEndOfDay with single PnL output.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TPOS.* | (all) | - | - | VERIFIED | All columns from Trade.PositionForExternalUse. |
| 2 | PnLInDollars | money | YES | - | CODE-BACKED | Max-date PnL in dollars via FnCalculatePnLWrapper. |
| 3 | PnLInCents | bigint | YES | - | CODE-BACKED | Max-date PnL in cents. |
| 4 | EstimateCloseFeeForCFD | money | YES | - | CODE-BACKED | Percentage-based close fee estimate from FnGetCloseFeeInPercentage. |
| 5 | CurrentCalculationRate | decimal | YES | - | CODE-BACKED | Max-date closing rate. |
| 6 | CurrentCalculationRateID | int | YES | - | CODE-BACKED | Price record ID for max-date rate. |
| 7 | CurrentConversionRate | decimal | YES | - | CODE-BACKED | Currency conversion rate. |
| 8 | CurrentConversionRateID | int | YES | - | CODE-BACKED | Price record ID for conversion. |
| 9 | EstimateCloseFeeOnOpen | money | YES | - | CODE-BACKED | Close fee estimated from open parameters. |
| 10 | EstimateCloseFeeOnOpenByUnits | money | YES | - | CODE-BACKED | Per-unit close fee from open parameters. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TPOS.* | Trade.PositionForExternalUse | FROM | Open position data |
| PriceMaxData | History.CurrencyPriceMaxDateWithSplitView | LEFT JOIN | Split-adjusted max-date prices |
| (function) | Trade.FnIsRealPosition | CROSS APPLY | Real/CFD classification |
| (function) | Trade.FnGetConversionInstrument | CROSS APPLY | Conversion instrument |
| (function) | Trade.FnCalculatePnLWrapper | CROSS APPLY | PnL calculation |
| (function) | Trade.FnGetCloseFeeInPercentage | OUTER APPLY | Percentage-based fee |

### 5.2 Referenced By (other objects point to this)

No dependents found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OpenPositionEndOfDay_before0192025 (view)
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

### 8.1 Get end-of-day PnL
```sql
SELECT  PositionID, InstrumentID, PnLInDollars, EstimateCloseFeeForCFD
FROM    Trade.OpenPositionEndOfDay_before0192025 WITH (NOLOCK)
WHERE   CID = 12345;
```

### 8.2 Compare with current view
```sql
SELECT  a.PositionID, a.PnLInDollars AS Pre0119_PnL, b.PnLInDollars AS Main_PnL
FROM    Trade.OpenPositionEndOfDay_before0192025 a WITH (NOLOCK)
JOIN    Trade.OpenPositionEndOfDay b WITH (NOLOCK) ON a.PositionID = b.PositionID;
```

### 8.3 Summarize by instrument
```sql
SELECT  InstrumentID, COUNT(*) AS Cnt, SUM(PnLInDollars) AS TotalPnL
FROM    Trade.OpenPositionEndOfDay_before0192025 WITH (NOLOCK) GROUP BY InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. Legacy versioned variant preserved for rollback safety.

---

*Generated: 2026-03-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OpenPositionEndOfDay_before0192025 | Type: View | Source: etoro/etoro/Trade/Views/Trade.OpenPositionEndOfDay_before0192025.sql*
