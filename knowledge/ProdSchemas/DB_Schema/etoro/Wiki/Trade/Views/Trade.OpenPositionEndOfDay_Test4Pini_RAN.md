# Trade.OpenPositionEndOfDay_Test4Pini_RAN

> Test variant of the end-of-day PnL view using non-split-adjusted History.CurrencyPriceMaxDate prices, with proper Real/CFD closing rate selection but simplified (always-spreaded) conversion rates.

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

Trade.OpenPositionEndOfDay_Test4Pini_RAN is a test variant created by developers "Pini" and "RAN" for debugging end-of-day PnL calculations. It shares the same non-split-adjusted price source (History.CurrencyPriceMaxDate) as Test4Pini, but differs in closing rate logic: it correctly selects Bid/BidSpreaded or Ask/AskSpreaded based on the IsRealPosition flag (unlike Test4Pini which always uses spreaded for conversion). The conversion rate logic, however, still uses a simplified always-spreaded approach.

---

## 2. Business Logic

### 2.1 Closing Rate: Real/CFD Aware

**What**: Properly selects non-spreaded prices for real positions and spreaded prices for CFD positions.

**Rules**:
- Buy + Real = Bid; Buy + CFD = BidSpreaded; Sell + Real = Ask; Sell + CFD = AskSpreaded
- Conversion rates: always uses BidSpreaded/AskSpreaded regardless of Real/CFD classification

### 2.2 Feature Flag FeatureID=119

**What**: Queries Maintenance.Feature for IsNewPnlCalculation but doesn't use it in PnL computation. Present for debugging context only.

---

## 3. Data Overview

N/A - test view, same base data as other variants.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TPOS.* | (all) | - | - | VERIFIED | All columns from Trade.PositionForExternalUse. |
| 2 | PnLInDollars | money | YES | - | CODE-BACKED | PnL using non-split-adjusted prices, Real/CFD closing rate, simplified conversion. |
| 3 | PnLInCents | bigint | YES | - | CODE-BACKED | PnL in cents. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TPOS.* | Trade.PositionForExternalUse | FROM | Open position data |
| PriceMaxData | History.CurrencyPriceMaxDate | LEFT JOIN | Non-split-adjusted prices |
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
Trade.OpenPositionEndOfDay_Test4Pini_RAN (view)
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

### 7.1 Key Difference from Test4Pini

The `_RAN` variant corrects the closing rate selection by using Bid (not BidSpreaded) for real positions, while Test4Pini always uses spreaded prices. Both variants keep the simplified always-spreaded conversion rate logic and share the same non-split-adjusted price source.

---

## 8. Sample Queries

### 8.1 Compare closing rates between Test4Pini variants
```sql
SELECT  a.PositionID, a.PnLInDollars AS RAN_PnL, b.PnLInDollars AS Pini_PnL
FROM    Trade.OpenPositionEndOfDay_Test4Pini_RAN a WITH (NOLOCK)
JOIN    Trade.OpenPositionEndOfDay_Test4Pini b WITH (NOLOCK) ON a.PositionID = b.PositionID
WHERE   a.PnLInDollars <> b.PnLInDollars;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. Developer test/debug variant.

---

*Generated: 2026-03-15 | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OpenPositionEndOfDay_Test4Pini_RAN | Type: View | Source: etoro/etoro/Trade/Views/Trade.OpenPositionEndOfDay_Test4Pini_RAN.sql*
