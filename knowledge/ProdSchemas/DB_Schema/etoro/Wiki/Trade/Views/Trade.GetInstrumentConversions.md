# Trade.GetInstrumentConversions

> Maps minor (non-major) instruments to their currency conversion instrument and reciprocal flag - used for converting position values and P&L to USD for instruments that are not major forex pairs.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID, InstrumentBaseCurrencyID, ConversionCurrencyID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentConversions extends Trade.GetCurrencyConversionsView by applying it to **minor instruments only** (IsMajor=0). Each row maps a minor instrument to the forex instrument that provides its conversion rate to USD. The view answers: "For this non-major instrument, which forex pair do I use to convert its value to USD, and do I invert the rate?"

The view exists because major forex pairs (EUR/USD, GBP/USD, etc.) are traded directly in USD terms and typically do not need conversion. Minor instruments - stocks, crypto, commodities, minor forex crosses - have values in their base or denomination currency and must be converted to USD for aggregation, margin calculation, and P&L. Trade.GetInstrumentConversionsByPriceServerID uses this view to filter conversions by price server when retrieving instrument rates.

Data flows: The view joins Trade.Instrument (WHERE IsMajor=0) with Trade.GetCurrencyConversionsView on SellCurrencyID = CurrencyID. Each minor instrument inherits the conversion mapping from its sell-side currency. The Dictionary.Currency JOIN validates that the currency exists. Rows are consumed by Trade.GetInstrumentConversionsByPriceServerID.

---

## 2. Business Logic

### 2.1 Minor Instruments Only

**What**: Only instruments with IsMajor=0 appear. Major forex pairs are excluded.

**Columns/Parameters Involved**: `TI.IsMajor`, `InstrumentID`

**Rules**:
- IsMajor=1: Major forex pairs (EUR/USD, GBP/USD, etc.) - excluded. These are already in USD terms.
- IsMajor=0: Minor instruments (stocks, crypto, commodities, minor crosses) - included. These need conversion to USD.

**Diagram**:
```
Trade.Instrument (IsMajor=0)
    |
    v
SellCurrencyID -> Trade.GetCurrencyConversionsView (CurrencyID -> ConversionInstrumentID, IsReciprocal)
    |
    v
Output: InstrumentID, InstrumentBaseCurrencyID, ConversionCurrencyID=1, ConversionInstrumentID, ReciprocalForConversion
```

### 2.2 ReciprocalForConversion from GetCurrencyConversionsView

**What**: Indicates whether the conversion instrument rate must be inverted for "currency per USD".

**Columns/Parameters Involved**: `ReciprocalForConversion`, `IC.IsReciprocal`

**Rules**:
- ReciprocalForConversion = IC.IsReciprocal (renamed from IsReciprocal in base view)
- 0 = use rate directly (e.g., EUR/USD - rate is already "currency per USD")
- 1 = invert rate (e.g., USD/JPY - rate is "USD per currency", invert for "currency per USD")

---

## 3. Data Overview

| InstrumentID | InstrumentBaseCurrencyID | ConversionCurrencyID | ConversionInstrumentID | ReciprocalForConversion | Meaning |
|---|---|---|---|---|---|
| 100195 | 100004 | 1 | 100004 | 0 | Minor instrument. Converts via Instrument 100004 (likely XXX/USD). Direct rate. |
| 100208 | 100004 | 1 | 100004 | 0 | Same conversion instrument - multiple minor instruments share same sell currency. |
| 100216 | 100004 | 1 | 100004 | 0 | All ConversionCurrencyID=1 (USD). ReciprocalForConversion=0 for direct pairs. |
| 100245 | 100004 | 1 | 100004 | 0 | ConversionInstrumentID often equals InstrumentID for instruments where sell currency is the conversion pair. |
| 100250 | 100004 | 1 | 100004 | 0 | Sample shows variety of minor instruments sharing one conversion instrument. |

**Selection criteria**: From live MCP sample. All IsMajor=0. ConversionCurrencyID always 1 (USD). ReciprocalForConversion=0 for direct pairs; inverse pairs (e.g., USD/JPY) would have ReciprocalForConversion=1.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. The minor instrument that needs conversion to USD. From Trade.Instrument. |
| 2 | InstrumentBaseCurrencyID | int | NO | - | CODE-BACKED | From IC.CurrencyID (GetCurrencyConversionsView). The sell-side currency of the instrument - the currency that defines the conversion. Inherited from Trade.GetCurrencyConversionsView. |
| 3 | ConversionCurrencyID | int | NO | - | CODE-BACKED | View-computed in GetCurrencyConversionsView: always 1 (USD). Target currency for conversion. |
| 4 | ConversionInstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. The forex instrument providing the conversion rate (e.g., EUR/USD, USD/JPY). From Trade.GetCurrencyConversionsView. |
| 5 | ReciprocalForConversion | int | NO | - | CODE-BACKED | Renamed from IC.IsReciprocal. 0 = use rate directly; 1 = invert rate for "currency per USD". From Trade.GetCurrencyConversionsView. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Base | Minor instruments (IsMajor=0) |
| InstrumentBaseCurrencyID, ConversionCurrencyID, ConversionInstrumentID | Trade.GetCurrencyConversionsView | JOIN | Conversion mapping by sell currency |
| (via IC) | Dictionary.Currency | Lookup | Validates currency exists |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetInstrumentConversionsByPriceServerID | FROM | Reader | Filters conversions by PriceServerID for instrument rate retrieval |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentConversions (view)
├── Trade.Instrument (table)
├── Trade.GetCurrencyConversionsView (view)
│     ├── Dictionary.Currency (table)
│     └── Trade.Instrument (table)
└── Dictionary.Currency (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FROM - base instruments, WHERE IsMajor=0 |
| Trade.GetCurrencyConversionsView | View | JOIN on TI.SellCurrencyID = IC.CurrencyID |
| Dictionary.Currency | Table | JOIN on DC.CurrencyID = IC.CurrencyID (validation) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrumentConversionsByPriceServerID | Procedure | FROM Trade.GetInstrumentConversions, filters by PriceServerID |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 All minor instrument conversions
```sql
SELECT InstrumentID, InstrumentBaseCurrencyID, ConversionCurrencyID,
       ConversionInstrumentID, ReciprocalForConversion
  FROM Trade.GetInstrumentConversions WITH (NOLOCK)
 ORDER BY InstrumentID
```

### 8.2 Conversions for instruments on a specific price server
```sql
SELECT gic.InstrumentID, gic.InstrumentBaseCurrencyID, gic.ConversionInstrumentID,
       gic.ReciprocalForConversion
  FROM Trade.GetInstrumentConversions gic WITH (NOLOCK)
  INNER JOIN Trade.Instrument ins WITH (NOLOCK) ON gic.InstrumentID = ins.InstrumentID
 WHERE ins.PriceServerID = 100
 ORDER BY gic.InstrumentID
```

### 8.3 Count conversions by conversion instrument
```sql
SELECT ConversionInstrumentID, ReciprocalForConversion, COUNT(*) AS InstrumentCount
  FROM Trade.GetInstrumentConversions WITH (NOLOCK)
 GROUP BY ConversionInstrumentID, ReciprocalForConversion
 ORDER BY InstrumentCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentConversions | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetInstrumentConversions.sql*
