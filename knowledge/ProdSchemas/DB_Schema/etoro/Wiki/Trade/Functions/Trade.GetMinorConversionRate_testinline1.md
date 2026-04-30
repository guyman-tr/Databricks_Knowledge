# Trade.GetMinorConversionRate_testinline1

> Second test variant of the minor currency conversion rate function that uses OUTER APPLY with TOP 1 subquery instead of LEFT OUTER JOINs.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns TABLE(ConversionRate) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetMinorConversionRate_testinline1 is the second test variant of the minor currency conversion rate function. Like its sibling (testinline), it computes the conversion rate from an instrument's sell currency to USD. The key difference is the query pattern: this variant uses OUTER APPLY with a TOP 1 subquery to join the currency conversions view and currency prices, whereas testinline uses standard LEFT OUTER JOINs.

This function exists for performance comparison testing. Both variants produce identical results, but the OUTER APPLY + TOP 1 pattern may produce a different execution plan that could perform better or worse depending on data distribution and index availability.

Data flow is identical to the testinline variant: Trade.Instrument provides SellCurrencyID, Trade.GetCurrencyConversionsView maps to conversion instrument and reciprocal flag, and Trade.CurrencyPrice provides the live Bid. The OUTER APPLY subselects TOP 1 from the joined conversion view and currency price in a single correlated subquery.

---

## 2. Business Logic

### 2.1 Currency Conversion Logic (OUTER APPLY Pattern)

**What**: Same conversion logic as testinline but using OUTER APPLY TOP 1 for the currency lookup.

**Columns/Parameters Involved**: `@InstrumentID`, `SellCurrencyID`, `IsReciprocal`, `Bid`

**Rules**:
- If SellCurrencyID = 1 (USD), ConversionRate = 1 (no conversion needed)
- If SellCurrencyID != 1, OUTER APPLY retrieves TOP 1 Bid and IsReciprocal from the join of GetCurrencyConversionsView and CurrencyPrice
- If IsReciprocal = 1, ConversionRate = 1 / Bid
- If IsReciprocal = 0, ConversionRate = Bid
- The TOP 1 in the OUTER APPLY handles the (unlikely) case of multiple currency price rows per conversion instrument

**Diagram**:
```
  Instrument(SellCurrencyID)
       |
       v
  SellCurrencyID = 1? --> YES --> ConversionRate = 1
       |
       NO
       |
       v
  OUTER APPLY (
    TOP 1: GetCurrencyConversionsView JOIN CurrencyPrice
    WHERE CurrencyID = SellCurrencyID
  ) --> Bid, IsReciprocal
       |
       v
  IsReciprocal=1? --> 1/Bid
  IsReciprocal=0? --> Bid
```

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INTEGER | NO | - | CODE-BACKED | The eToro instrument identifier to look up the conversion rate for. Determines which instrument's sell currency needs conversion to USD. FK to Trade.Instrument. |
| 2 | ConversionRate (return) | Computed | YES | - | CODE-BACKED | The conversion rate from the instrument's sell currency to USD. Value of 1.0 when instrument is USD-denominated. For non-USD: Bid or 1/Bid depending on IsReciprocal. NULL if currency data is missing (OUTER APPLY returns no rows). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.Instrument | FROM (WHERE) | Filtered by InstrumentID to retrieve SellCurrencyID |
| SellCurrencyID | Trade.GetCurrencyConversionsView | OUTER APPLY subquery | Joined on CurrencyID to find conversion instrument and reciprocal flag |
| ConversionInstrumentID | Trade.CurrencyPrice | LEFT OUTER JOIN (in subquery) | Joined to get the live Bid rate for the conversion instrument |

### 5.2 Referenced By (other objects point to this)

No direct consumers found. The production version Trade.GetMinorConversionRate is used instead.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMinorConversionRate_testinline1 (function)
  +-- Trade.Instrument (table)
  +-- Trade.GetCurrencyConversionsView (view)
  +-- Trade.CurrencyPrice (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | Queried to get SellCurrencyID for the given InstrumentID |
| Trade.GetCurrencyConversionsView | View | OUTER APPLY subquery to map SellCurrencyID to conversion instrument and IsReciprocal flag |
| Trade.CurrencyPrice | Table | LEFT OUTER JOINed within the OUTER APPLY subquery to get the live Bid rate |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get conversion rate for a specific instrument
```sql
SELECT ConversionRate
FROM   Trade.GetMinorConversionRate_testinline1(1001)
```

### 8.2 Compare both test variants side by side
```sql
SELECT I.InstrumentID,
       I.DisplayName,
       T1.ConversionRate AS TestInline,
       T2.ConversionRate AS TestInline1
FROM   Trade.Instrument I WITH (NOLOCK)
CROSS APPLY Trade.GetMinorConversionRate_testinline(I.InstrumentID) T1
CROSS APPLY Trade.GetMinorConversionRate_testinline1(I.InstrumentID) T2
WHERE  I.InstrumentID IN (1, 5, 10, 100, 1000)
```

### 8.3 Use conversion rate to calculate P&L in USD
```sql
SELECT TP.PositionID,
       TP.InstrumentID,
       CR.ConversionRate,
       (TP.CloseRate - TP.OpenRate) * TP.AmountInUnitsDecimal * CR.ConversionRate AS PnlUSD
FROM   Trade.PositionTbl TP WITH (NOLOCK)
CROSS APPLY Trade.GetMinorConversionRate_testinline1(TP.InstrumentID) CR
WHERE  TP.PositionID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this test variant function.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMinorConversionRate_testinline1 | Type: Inline Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.GetMinorConversionRate_testinline1.sql*
