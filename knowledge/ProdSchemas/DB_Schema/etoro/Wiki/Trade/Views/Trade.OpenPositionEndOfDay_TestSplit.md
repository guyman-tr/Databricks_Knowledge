# Trade.OpenPositionEndOfDay_TestSplit

> Test variant of end-of-day PnL view that sources split-adjusted prices from an external database ([Price].[Candles].[CurrencyPriceMaxDateWithSplitView]) and uses IsDiscounted instead of IsSettled for Real/CFD classification.

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

Trade.OpenPositionEndOfDay_TestSplit is a test variant created to evaluate two specific changes:

1. **External price source**: Uses `[Price].[Candles].[CurrencyPriceMaxDateWithSplitView]` instead of the local `[History].[CurrencyPriceMaxDateWithSplitView]`. This tests migration of price data to a separate "Price" database.
2. **IsDiscounted flag**: Passes `TPOS.IsDiscounted` to `Trade.FnIsRealPosition` instead of `TPOS.IsSettled`. Code comments note: "Should be IsSettled after IsDiscounted project is done", indicating this tests a transitional state of the IsDiscounted/IsSettled refactoring.

The conversion rate logic uses a simplified always-spreaded approach.

---

## 2. Business Logic

### 2.1 IsDiscounted vs IsSettled

**What**: Uses IsDiscounted column instead of IsSettled for position classification.

**Rules**:
- `Trade.FnIsRealPosition(TPOS.IsDiscounted, TPOS.InstrumentID)` - uses IsDiscounted
- `Trade.FnCalculatePnLWrapper(..., TPOS.IsDiscounted, ...)` - uses IsDiscounted
- This is a transitional test; production should use IsSettled after the IsDiscounted project completes

### 2.2 External Price Source

**What**: Queries `[Price].[Candles].[CurrencyPriceMaxDateWithSplitView]` (cross-database reference).

---

## 3. Data Overview

N/A - test view.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TPOS.* | (all) | - | - | VERIFIED | All columns from Trade.PositionForExternalUse. |
| 2 | PnLInDollars | money | YES | - | CODE-BACKED | PnL using external price source, IsDiscounted-based classification. |
| 3 | PnLInCents | bigint | YES | - | CODE-BACKED | PnL in cents. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TPOS.* | Trade.PositionForExternalUse | FROM | Open position data |
| PriceMaxData | [Price].[Candles].[CurrencyPriceMaxDateWithSplitView] | LEFT JOIN | External database split-adjusted prices |
| (function) | Trade.FnIsRealPosition | CROSS APPLY | Real/CFD using IsDiscounted |
| (function) | Trade.FnGetConversionInstrument | CROSS APPLY | Conversion instrument |
| (function) | Trade.FnCalculatePnLWrapper | CROSS APPLY | PnL calculation |
| (table) | Maintenance.Feature | CROSS APPLY | Feature flag FeatureID=119 |

### 5.2 Referenced By (other objects point to this)

No dependents found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OpenPositionEndOfDay_TestSplit (view)
+-- Trade.PositionForExternalUse (view)
+-- [Price].[Candles].[CurrencyPriceMaxDateWithSplitView] [cross-database]
+-- Trade.FnIsRealPosition (function)
+-- Trade.FnGetConversionInstrument (function)
+-- Trade.FnCalculatePnLWrapper (function)
+-- Maintenance.Feature (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionForExternalUse | View | FROM |
| [Price].[Candles].[CurrencyPriceMaxDateWithSplitView] | View | LEFT JOIN - external DB prices |
| Trade.FnIsRealPosition | Function | CROSS APPLY (with IsDiscounted) |
| Trade.FnGetConversionInstrument | Function | CROSS APPLY |
| Trade.FnCalculatePnLWrapper | Function | CROSS APPLY |
| Maintenance.Feature | Table | CROSS APPLY - feature flag 119 |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Key Differences from Production

| Aspect | Production (OpenPositionEndOfDay) | This Test View |
|--------|-----------------------------------|----------------|
| Price Source | History.CurrencyPriceMaxDateClosingPriceWithSplitView | [Price].[Candles].[CurrencyPriceMaxDateWithSplitView] |
| Position Classification | IsSettled | IsDiscounted |
| Conversion Rates | Real/CFD-aware | Always-spreaded |

---

## 8. Sample Queries

### 8.1 Test external price source
```sql
SELECT  PositionID, InstrumentID, PnLInDollars
FROM    Trade.OpenPositionEndOfDay_TestSplit WITH (NOLOCK)
WHERE   CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. Developer test variant for price source migration and IsDiscounted evaluation.

---

*Generated: 2026-03-15 | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OpenPositionEndOfDay_TestSplit | Type: View | Source: etoro/etoro/Trade/Views/Trade.OpenPositionEndOfDay_TestSplit.sql*
