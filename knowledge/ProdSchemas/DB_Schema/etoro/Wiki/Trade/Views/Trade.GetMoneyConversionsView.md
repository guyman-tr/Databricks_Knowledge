# Trade.GetMoneyConversionsView

> Provides a complete currency-to-USD conversion mapping by combining Trade.GetCurrencyConversionsView with Dictionary.Currency, plus a hardcoded USD row (ShouldConvert=0) so every CurrencyTypeID=1 currency has a conversion entry.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | CurrencyID (from Dictionary.Currency) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetMoneyConversionsView answers: "For any given currency, how do I convert it to USD?" It provides the ConversionInstrumentID (the forex instrument used for conversion), the IsReciprocal flag (whether to divide instead of multiply by the rate), and a ShouldConvert flag. USD itself gets a hardcoded row with ShouldConvert=0 because no conversion is needed.

This view exists because many financial calculations (dividend payments, equity computations, fee calculations) need to convert between currencies and USD. The view provides a single lookup: given a CurrencyID, get the instrument to use for conversion and whether the rate is reciprocal. Trade.GetRateInDollarsForDividends and Trade.GetCIDsForIndexDividends both depend on this view for their conversion logic.

Data flows: The view reads Dictionary.Currency for currency metadata (name, abbreviation) and Trade.GetCurrencyConversionsView for the conversion mappings. It UNION ALLs a hardcoded row (CurrencyID=1, ConversionInstrumentID=-1, IsReciprocal=-1, ShouldConvert=0) to represent USD (no conversion needed). The WHERE filter CurrencyTypeID=1 limits to real/primary currencies.

---

## 2. Business Logic

### 2.1 USD No-Conversion Sentinel Row

**What**: USD (CurrencyID=1) gets a hardcoded row with ShouldConvert=0, indicating no conversion is necessary.

**Columns/Parameters Involved**: `CurrencyID`, `ConversionInstrumentID`, `IsReciprocal`, `ShouldConvert`

**Rules**:
- The UNION ALL adds a synthetic row: CurrencyID=1, ConversionInstrumentID=-1, IsReciprocal=-1, ShouldConvert=0
- ShouldConvert=0 tells callers to skip conversion entirely (the value is already in USD)
- ConversionInstrumentID=-1 and IsReciprocal=-1 are sentinel values - they should never be used for actual lookups

**Diagram**:
```
Trade.GetCurrencyConversionsView
  CurrencyID=2 (EUR), ConversionInstrumentID=1 (EUR/USD), IsReciprocal=0, ShouldConvert=1
  CurrencyID=3 (GBP), ConversionInstrumentID=2 (GBP/USD), IsReciprocal=0, ShouldConvert=1
  ...
UNION ALL
  CurrencyID=1 (USD), ConversionInstrumentID=-1, IsReciprocal=-1, ShouldConvert=0

JOIN Dictionary.Currency ON CurrencyID WHERE CurrencyTypeID=1
  -> Result: All primary currencies with conversion instructions
```

### 2.2 Reciprocal Rate Handling

**What**: Some currency conversions require dividing by the rate instead of multiplying.

**Columns/Parameters Involved**: `IsReciprocal`

**Rules**:
- IsReciprocal=0: multiply the amount by the instrument's rate to get USD (e.g., EUR * EUR/USD rate)
- IsReciprocal=1: divide the amount by the instrument's rate to get USD (e.g., JPY / USD/JPY rate)
- IsReciprocal=-1: sentinel for USD (ShouldConvert=0, so this is never used)

---

## 3. Data Overview

| CurrencyID | Name | Abbreviation | ConversionInstrumentID | IsReciprocal | ShouldConvert | Meaning |
|---|---|---|---|---|---|---|
| 2 | European Economic and Monetary Union, Euro | EUR | 1 | 0 | 1 | EUR converts to USD via InstrumentID=1 (EUR/USD) by multiplying by the rate |
| 3 | Great Britain, Pound Sterling | GBP | 2 | 0 | 1 | GBP converts via InstrumentID=2 (GBP/USD), multiply by rate |
| 4 | Japan, Yen | JPY | 5 | 0 | 1 | JPY converts via InstrumentID=5, multiply by rate |
| 6 | Switzerland, Franc | CHF | 6 | 1 | 1 | CHF converts via InstrumentID=6 (USD/CHF), reciprocal - divide by rate |
| 1 | United States, Dollar | USD | -1 | -1 | 0 | USD sentinel - no conversion needed (ShouldConvert=0) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CurrencyID | int | NO | - | CODE-BACKED | Primary currency identifier from Dictionary.Currency. Uniquely identifies the source currency to convert from. Only currencies with CurrencyTypeID=1 (primary currencies) appear. |
| 2 | Name | nchar(50) | YES | - | CODE-BACKED | Full currency name from Dictionary.Currency. E.g., "European Economic and Monetary Union (EMU), Euro". Used for display purposes. |
| 3 | Abbreviation | nchar(10) | YES | - | CODE-BACKED | Standard currency abbreviation from Dictionary.Currency. E.g., EUR, GBP, JPY, USD. Used in UI display and reporting. |
| 4 | ConversionInstrumentID | int | NO | - | CODE-BACKED | The InstrumentID of the forex pair used to convert this currency to USD. E.g., EUR uses InstrumentID=1 (EUR/USD). Value -1 is a sentinel for USD (no conversion). FK to Trade.Instrument.InstrumentID. From Trade.GetCurrencyConversionsView or hardcoded UNION row. |
| 5 | IsReciprocal | int | NO | - | CODE-BACKED | Direction flag for rate usage: 0 = multiply by the instrument's rate (e.g., EUR amount * EUR/USD rate), 1 = divide by the rate (e.g., CHF amount / USD/CHF rate), -1 = sentinel for USD. From Trade.GetCurrencyConversionsView or hardcoded UNION row. |
| 6 | ShouldConvert | int | NO | - | CODE-BACKED | Conversion flag: 1 = this currency needs conversion to USD (use ConversionInstrumentID and IsReciprocal), 0 = already in USD (skip conversion). The only currency with ShouldConvert=0 is USD (CurrencyID=1). Computed in view: 1 from GetCurrencyConversionsView rows, 0 from the hardcoded UNION row. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CurrencyID, Name, Abbreviation | Dictionary.Currency | INNER JOIN | Currency master for names and abbreviations; filtered to CurrencyTypeID=1 |
| ConversionInstrumentID, IsReciprocal | Trade.GetCurrencyConversionsView | Subquery (UNION ALL) | Currency-to-instrument conversion mappings |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetRateInDollarsForDividends | CurrencyID | READER | Uses this view to determine the conversion instrument for dividend rate calculations |
| Trade.GetCIDsForIndexDividends | CurrencyID | READER | Uses this view to convert dividend amounts to USD for index dividend processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMoneyConversionsView (view)
+-- Dictionary.Currency (table)
+-- Trade.GetCurrencyConversionsView (view)
      +-- Trade.InstrumentConversion (table)
      +-- Trade.Instrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Currency | Table | INNER JOIN on CurrencyID for currency names and abbreviations |
| Trade.GetCurrencyConversionsView | View | Subquery via UNION ALL for conversion instrument mappings |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetRateInDollarsForDividends | Stored Procedure | Reads for currency-to-USD conversion during dividend calculations |
| Trade.GetCIDsForIndexDividends | Stored Procedure | Reads for currency conversion in index dividend processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Get the conversion instrument for a specific currency

```sql
SELECT  CurrencyID,
        Abbreviation,
        ConversionInstrumentID,
        IsReciprocal,
        ShouldConvert
FROM    Trade.GetMoneyConversionsView WITH (NOLOCK)
WHERE   Abbreviation = 'EUR'
```

### 8.2 List all currencies that require reciprocal conversion

```sql
SELECT  CurrencyID,
        Abbreviation,
        ConversionInstrumentID
FROM    Trade.GetMoneyConversionsView WITH (NOLOCK)
WHERE   IsReciprocal = 1
ORDER BY Abbreviation
```

### 8.3 Join with instrument to show conversion pair names

```sql
SELECT  mcv.Abbreviation AS SourceCurrency,
        gi.Name AS ConversionPair,
        mcv.IsReciprocal,
        mcv.ShouldConvert
FROM    Trade.GetMoneyConversionsView mcv WITH (NOLOCK)
LEFT JOIN Trade.GetInstrument gi WITH (NOLOCK) ON mcv.ConversionInstrumentID = gi.InstrumentID
ORDER BY mcv.CurrencyID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMoneyConversionsView | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetMoneyConversionsView.sql*
