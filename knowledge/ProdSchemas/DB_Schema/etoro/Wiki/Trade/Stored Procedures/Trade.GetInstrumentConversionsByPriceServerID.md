# Trade.GetInstrumentConversionsByPriceServerID

> Returns currency conversion configuration for all instruments on a specific price server - needed for real-time PnL and rate conversion.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | InstrumentID (result set) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the currency conversion mapping for each instrument assigned to a specific price server. For every instrument, it identifies: the base currency, the conversion currency, which instrument provides the conversion rate, and whether the rate should be reciprocated. This data is essential for the price server to convert instrument prices to account currencies in real-time.

The procedure exists to support price server initialization and rate conversion logic. When the server needs to convert a stock price from GBP to USD for a USD-denominated account, it needs to know which forex pair provides the conversion rate and whether to use it directly or as a reciprocal.

Data flow: caller passes @PriceServerID (defaults to 100). The SP reads Trade.GetInstrumentConversions (a view) and joins to Trade.Instrument to filter by PriceServerID. Returns conversion configuration per instrument.

---

## 2. Business Logic

### 2.1 Reciprocal Conversion Flag

**What**: Indicates whether the conversion rate should be inverted.

**Columns/Parameters Involved**: `ReciprocalForConversion`, `IsReciprocal`

**Rules**:
- IsReciprocal = 1: use 1/rate (e.g., if conversion instrument quotes EUR/USD but we need USD/EUR)
- IsReciprocal = 0: use rate directly
- Cast to BIT from source column ReciprocalForConversion

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PriceServerID | INT | NO | 100 | CODE-BACKED | Price server to load conversion configs for. Default 100 (primary server). |
| 2 | InstrumentID (output) | INT | NO | - | CODE-BACKED | Instrument requiring currency conversion. |
| 3 | ConversionBaseCurrency (output) | INT | - | - | CODE-BACKED | Base currency ID for conversion (aliased from InstrumentBaseCurrencyID). FK to Dictionary.Currency. |
| 4 | ConversionCurrency (output) | INT | - | - | CODE-BACKED | Target conversion currency ID (aliased from ConversionCurrencyID). FK to Dictionary.Currency. |
| 5 | ConversionInstrumentID (output) | INT | - | - | CODE-BACKED | The forex instrument that provides the conversion rate between base and target currencies. |
| 6 | IsReciprocal (output) | BIT | - | - | CODE-BACKED | Whether to use 1/rate instead of rate directly. Cast from ReciprocalForConversion. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.GetInstrumentConversions | FROM (view) | Source of conversion configuration |
| (body) | Trade.Instrument | JOIN | Filter by PriceServerID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentConversionsByPriceServerID (procedure)
+-- Trade.GetInstrumentConversions (view)
+-- Trade.Instrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrumentConversions | View | FROM - conversion configuration data |
| Trade.Instrument | Table | JOIN - filters by PriceServerID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute for default price server

```sql
EXEC Trade.GetInstrumentConversionsByPriceServerID;
```

### 8.2 Execute for specific price server

```sql
EXEC Trade.GetInstrumentConversionsByPriceServerID @PriceServerID = 200;
```

### 8.3 Join with currency names

```sql
SELECT  gic.InstrumentID,
        cb.CurrencyName AS BaseCurrency,
        cc.CurrencyName AS ConversionCurrency,
        gic.ConversionInstrumentID,
        gic.IsReciprocal
FROM    Trade.GetInstrumentConversions gic WITH (NOLOCK)
JOIN    Trade.Instrument ins WITH (NOLOCK) ON gic.InstrumentID = ins.InstrumentID
JOIN    Dictionary.Currency cb WITH (NOLOCK) ON gic.InstrumentBaseCurrencyID = cb.CurrencyID
JOIN    Dictionary.Currency cc WITH (NOLOCK) ON gic.ConversionCurrencyID = cc.CurrencyID
WHERE   ins.PriceServerID = 100;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.8/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentConversionsByPriceServerID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentConversionsByPriceServerID.sql*
