# Trade.GetCurrencyConversionsView_test

> Test copy of Trade.GetCurrencyConversionsView. Identical structure and logic - used for validation or deployment testing before switching to the production view.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | CurrencyID + ConversionInstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetCurrencyConversionsView_test is a test/deployment copy of Trade.GetCurrencyConversionsView. The view logic is identical: it maps each non-USD currency to the Trade.Instrument pair needed to convert values to USD (CurrencyID 1). The _test suffix indicates it exists for validation, rollback, or A/B testing before the production view is updated.

This view exists so that deployment scripts or integration tests can validate currency conversion logic against a copy without affecting production consumers. When schema changes are made to GetCurrencyConversionsView, the _test version can be updated first and validated before switching the production view.

Data flows identically to GetCurrencyConversionsView: Dictionary.Currency provides the currency registry; Trade.Instrument provides the forex or denomination pair where one side is USD (CurrencyID=1); the view returns one row per currency with its conversion instrument and reciprocal flag. Procedures that use GetCurrencyConversionsView (GetCurrencyConversions, GetInstrumentsRates, GetProviderToInstrumentData, InsertBSLMessagesIntoQueue, ManualModifySLForCriptoPositions) read from the production view, not the _test copy.

---

## 2. Business Logic

### 2.1 Identical to Production

**What**: Same logic as Trade.GetCurrencyConversionsView. See that view's documentation for full business rules.

**Columns/Parameters Involved**: All output columns match production.

**Rules**:
- Same two-branch UNION: (1) BuyCurrencyID = currency and SellCurrencyID = 1 (USD), or (2) SellCurrencyID = currency and BuyCurrencyID = 1 (USD)
- Excludes CurrencyID in (0, 1)
- IsReciprocal: 0 when SellCurrencyID=1 (direct rate), 1 when BuyCurrencyID=1 (reciprocal needed)

---

## 3. Data Overview

| CurrencyID | ConversionCurrencyID | ConversionInstrumentID | IsReciprocal | Meaning |
|------------|----------------------|-------------------------|--------------|---------|
| 10029 | 1 | 10029 | 0 | Non-USD currency (e.g., stock/crypto) with direct USD instrument. IsReciprocal=0: use rate as-is. |
| 10030 | 1 | 10030 | 0 | Same pattern. Conversion instrument has BuyCurrencyID=CurrencyID, SellCurrencyID=1. |
| 2 | 1 | 1 | 0 | EUR (CurrencyID=2). Instrument 1 is EUR/USD - use directly. |
| 4 | 1 | 5 | 1 | JPY (CurrencyID=4). Instrument 5 is USD/JPY. IsReciprocal=1: invert rate for JPY->USD. |
| 666 | 1 | 2031 | 0 | GBX. Instrument 2031 has SellCurrencyID=GBX, BuyCurrencyID=1 or vice versa. |

**Note**: Sample structure matches production view. In practice, _test is used for deployment validation; production consumers use GetCurrencyConversionsView.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CurrencyID | int | NO | - | CODE-BACKED | Source currency from Dictionary.Currency. Excludes 0 and 1 (USD). Inherited from base table. |
| 2 | ConversionCurrencyID | int | NO | 1 | CODE-BACKED | Constant 1 in view. Target conversion currency (USD). |
| 3 | ConversionInstrumentID | int | NO | - | CODE-BACKED | InstrumentID from Trade.Instrument that defines the conversion pair. One side is the source currency, the other is USD. |
| 4 | IsReciprocal | tinyint | NO | - | CODE-BACKED | Computed: CASE WHEN i.SellCurrencyID=1 THEN 0 ELSE 1 END. 0=use rate directly (e.g., EUR/USD); 1=invert rate (e.g., USD/JPY for JPY->USD). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CurrencyID | Dictionary.Currency | Lookup | Source currency registry |
| ConversionInstrumentID | Trade.Instrument | Lookup | Conversion pair definition |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (none) | - | - | No procedure references - test view. Production consumers use GetCurrencyConversionsView. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCurrencyConversionsView_test (view)
  (identical to GetCurrencyConversionsView)
├── Dictionary.Currency (table)
└── Trade.Instrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Currency | Table | INNER JOIN - currency registry |
| Trade.Instrument | Table | INNER JOIN - conversion pair (Buy/Sell currency) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| None | - | Test view - no production dependents |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Compare test vs production output
```sql
SELECT v.CurrencyID, v.ConversionInstrumentID, v.IsReciprocal
  FROM Trade.GetCurrencyConversionsView_test v WITH (NOLOCK)
EXCEPT
SELECT v.CurrencyID, v.ConversionInstrumentID, v.IsReciprocal
  FROM Trade.GetCurrencyConversionsView v WITH (NOLOCK)
```

### 8.2 Sample rows from test view
```sql
SELECT TOP 5 CurrencyID, ConversionCurrencyID, ConversionInstrumentID, IsReciprocal
  FROM Trade.GetCurrencyConversionsView_test WITH (NOLOCK)
 ORDER BY CurrencyID
```

### 8.3 Resolve currency names in test view
```sql
SELECT t.CurrencyID, c.Abbreviation AS CurrencyCode, t.ConversionInstrumentID, t.IsReciprocal
  FROM Trade.GetCurrencyConversionsView_test t WITH (NOLOCK)
  JOIN Dictionary.Currency c WITH (NOLOCK) ON t.CurrencyID = c.CurrencyID
 WHERE t.CurrencyID IN (2, 4, 666)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.2/10 (Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCurrencyConversionsView_test | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetCurrencyConversionsView_test.sql*
*Note: Test copy of Trade.GetCurrencyConversionsView - identical structure and logic.*
