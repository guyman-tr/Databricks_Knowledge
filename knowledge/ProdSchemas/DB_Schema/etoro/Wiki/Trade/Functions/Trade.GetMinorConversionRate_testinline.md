# Trade.GetMinorConversionRate_testinline

> Test variant of the minor currency conversion rate function that returns the conversion rate from an instrument's sell currency to USD using an inline table-valued approach with LEFT OUTER JOINs.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns TABLE(ConversionRate) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetMinorConversionRate_testinline is a test version of the minor currency conversion rate function. It resolves the conversion rate needed to convert an instrument's P&L from the instrument's sell (quote) currency into USD (the platform's base currency). "Minor" refers to non-USD currencies that require an intermediate conversion step through a currency pair.

This function exists because eToro's instruments are denominated in various currencies (EUR, GBP, JPY, etc.), but customer accounts and P&L reporting are typically in USD. Every P&L calculation must multiply by a conversion rate to normalize to USD. This test variant uses an inline TVF approach (vs. the production multi-statement version Trade.GetMinorConversionRate) to evaluate performance differences.

Data flows through three tables: Trade.Instrument provides the SellCurrencyID for the given instrument, Trade.GetCurrencyConversionsView_test maps each currency to its conversion instrument and reciprocal flag, and Trade.CurrencyPrice provides the live Bid rate for that conversion instrument. If SellCurrencyID=1 (USD), the rate is 1 (no conversion needed).

---

## 2. Business Logic

### 2.1 Currency Conversion Logic

**What**: Resolves the conversion rate from instrument sell currency to USD with reciprocal handling.

**Columns/Parameters Involved**: `@InstrumentID`, `SellCurrencyID`, `IsReciprocal`, `Bid`

**Rules**:
- If SellCurrencyID = 1 (USD), ConversionRate = 1 (no conversion needed)
- If SellCurrencyID != 1, look up the conversion instrument via GetCurrencyConversionsView_test
- If IsReciprocal = 1, ConversionRate = 1 / Bid (inverse rate, e.g., for EUR/USD where USD is the quote currency)
- If IsReciprocal = 0, ConversionRate = Bid (direct rate)

**Diagram**:
```
  Instrument(SellCurrencyID)
       |
       v
  SellCurrencyID = 1 (USD)? --> YES --> ConversionRate = 1
       |
       NO
       |
       v
  GetCurrencyConversionsView_test(CurrencyID) --> ConversionInstrumentID
       |
       v
  CurrencyPrice(InstrumentID) --> Bid
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
| 2 | ConversionRate (return) | Computed | YES | - | CODE-BACKED | The conversion rate from the instrument's sell currency to USD. Value of 1.0 when instrument is already USD-denominated. For non-USD instruments, either the Bid rate or 1/Bid depending on whether the currency pair is reciprocal. NULL if currency conversion data is missing (LEFT JOIN). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.Instrument | JOIN (WHERE) | Filtered by InstrumentID to retrieve SellCurrencyID |
| SellCurrencyID | Trade.GetCurrencyConversionsView_test | LEFT OUTER JOIN | Joined on CurrencyID to find conversion instrument and reciprocal flag |
| ConversionInstrumentID | Trade.CurrencyPrice | LEFT OUTER JOIN | Joined to get the live Bid rate for the conversion instrument |

### 5.2 Referenced By (other objects point to this)

No direct consumers found in production code. The production version Trade.GetMinorConversionRate is used instead.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMinorConversionRate_testinline (function)
  +-- Trade.Instrument (table)
  +-- Trade.GetCurrencyConversionsView_test (view)
  +-- Trade.CurrencyPrice (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | JOINed to get SellCurrencyID for the given InstrumentID |
| Trade.GetCurrencyConversionsView_test | View | LEFT OUTER JOINed to map SellCurrencyID to its conversion instrument and IsReciprocal flag |
| Trade.CurrencyPrice | Table | LEFT OUTER JOINed to get the live Bid rate for the conversion currency pair |

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
FROM   Trade.GetMinorConversionRate_testinline(1001)
```

### 8.2 Get conversion rates for all active instruments
```sql
SELECT I.InstrumentID,
       I.DisplayName,
       CR.ConversionRate
FROM   Trade.Instrument I WITH (NOLOCK)
CROSS APPLY Trade.GetMinorConversionRate_testinline(I.InstrumentID) CR
WHERE  I.IsActive = 1
```

### 8.3 Compare test inline vs production conversion rates
```sql
SELECT I.InstrumentID,
       CR_test.ConversionRate AS TestRate,
       Trade.GetMinorConversionRate(I.InstrumentID) AS ProdRate
FROM   Trade.Instrument I WITH (NOLOCK)
CROSS APPLY Trade.GetMinorConversionRate_testinline(I.InstrumentID) CR_test
WHERE  I.InstrumentID IN (1, 5, 10, 100, 1000)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this test variant function.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMinorConversionRate_testinline | Type: Inline Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.GetMinorConversionRate_testinline.sql*
