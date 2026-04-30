# Trade.OpenPositionEndOfDay_Test4Pini

> Test/debug variant of the end-of-day PnL view using History.CurrencyPriceMaxDate (without split adjustments), with a feature flag check for new PnL calculation and simplified conversion logic.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID (from Trade.PositionForExternalUse) |
| **Partition** | N/A |
| **Indexes** | N/A |
| **Status** | Test/debug variant - not for production use |

---

## 1. Business Meaning

Trade.OpenPositionEndOfDay_Test4Pini is a test variant created by developer "Pini" for debugging end-of-day PnL calculations. It differs from production variants by using History.CurrencyPriceMaxDate directly (without split adjustments), including a feature flag check (Maintenance.Feature FeatureID=119 for IsNewPnlCalculation), and using a simplified conversion rate selection that always uses spreaded prices regardless of real/CFD classification.

This view exists for debugging PnL discrepancies by comparing results with and without split adjustments and with the old vs new PnL calculation paths. It should not be used for production reporting.

---

## 2. Business Logic

### 2.1 Simplified Conversion Rate Logic

**What**: Uses spreaded bid/ask for ALL positions regardless of real/CFD classification.

**Columns/Parameters Involved**: ConversionRate

**Rules**:
- Unlike production views that differentiate between Bid (real) and BidSpreaded (CFD), this test view always uses BidSpreaded/AskSpreaded for conversion rates
- Feature flag FeatureID=119 is queried but not used in the PnL calculation (read as IsNewPnlCalculation for debugging context)

---

## 3. Data Overview

N/A - test view, same base data with different price source and simplified conversion.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TPOS.* | (all) | - | - | VERIFIED | All columns from Trade.PositionForExternalUse. |
| 2 | PnLInDollars | money | YES | - | CODE-BACKED | PnL using non-split-adjusted CurrencyPriceMaxDate with simplified conversion. |
| 3 | PnLInCents | bigint | YES | - | CODE-BACKED | PnL in cents. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TPOS.* | Trade.PositionForExternalUse | FROM | Open position data |
| PriceMaxData | History.CurrencyPriceMaxDate | LEFT JOIN | Non-split-adjusted max-date prices |
| (function) | Trade.FnIsRealPosition | CROSS APPLY | Real/CFD classification |
| (function) | Trade.FnGetConversionInstrument | CROSS APPLY | Conversion instrument |
| (function) | Trade.FnCalculatePnLWrapper | CROSS APPLY | PnL calculation |
| (table) | Maintenance.Feature | CROSS APPLY | Feature flag FeatureID=119 |

### 5.2 Referenced By (other objects point to this)

No dependents found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OpenPositionEndOfDay_Test4Pini (view)
+-- Trade.PositionForExternalUse (view)
+-- History.CurrencyPriceMaxDate (view) [cross-schema]
+-- Trade.FnIsRealPosition (function)
+-- Trade.FnGetConversionInstrument (function)
+-- Trade.FnCalculatePnLWrapper (function)
+-- Maintenance.Feature (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionForExternalUse | View | FROM |
| History.CurrencyPriceMaxDate | View | LEFT JOIN - non-split-adjusted prices |
| Trade.FnIsRealPosition | Function | CROSS APPLY |
| Trade.FnGetConversionInstrument | Function | CROSS APPLY |
| Trade.FnCalculatePnLWrapper | Function | CROSS APPLY |
| Maintenance.Feature | Table | CROSS APPLY - feature flag 119 |

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

### 8.1 Debug PnL with non-split-adjusted prices
```sql
SELECT  PositionID, InstrumentID, PnLInDollars
FROM    Trade.OpenPositionEndOfDay_Test4Pini WITH (NOLOCK)
WHERE   CID = 12345;
```

### 8.2 Compare split-adjusted vs non-split-adjusted PnL
```sql
SELECT  a.PositionID, a.PnLInDollars AS NoSplitPnL, b.PnLInDollars AS SplitAdjPnL
FROM    Trade.OpenPositionEndOfDay_Test4Pini a WITH (NOLOCK)
JOIN    Trade.OpenPositionEndOfDay_before0192025 b WITH (NOLOCK) ON a.PositionID = b.PositionID
WHERE   a.PnLInDollars <> b.PnLInDollars;
```

### 8.3 Count positions
```sql
SELECT  COUNT(*) AS TotalPositions FROM Trade.OpenPositionEndOfDay_Test4Pini WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. Developer test/debug variant.

---

*Generated: 2026-03-15 | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OpenPositionEndOfDay_Test4Pini | Type: View | Source: etoro/etoro/Trade/Views/Trade.OpenPositionEndOfDay_Test4Pini.sql*
