# Trade.GetPriceConversionInstrumentToUSD

> Maps each instrument to its USD conversion instrument by self-joining Trade.GetInstrument to find the forex pair that converts the instrument's sell currency to USD, with a reciprocal flag indicating the direction.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID + ConversionInstrumentID |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.GetPriceConversionInstrumentToUSD resolves the **USD conversion path** for every tradable instrument. Since eToro's base reporting currency is USD, every non-USD instrument needs a forex conversion instrument to translate prices and PnL to dollars. This view self-joins Trade.GetInstrument to find the matching forex pair.

This view exists because instruments trade in various currency pairs (EUR/GBP, AUD/JPY, etc.) and the system needs to know which other instrument (forex pair) can convert the sell-side currency to USD. For instruments already denominated in USD (BuyCurrencyID=1 or SellCurrencyID=1), the instrument maps to itself. For cross-currency instruments, the view finds the bridge instrument where the sell currency matches and USD is on the other side.

The `IsReciprocal` flag indicates whether the conversion instrument's quote needs to be inverted: when BuyCurrencyID=1 on the conversion instrument, the rate is already "X per USD" (IsReciprocal=1); otherwise it needs inversion (IsReciprocal=0).

---

## 2. Business Logic

### 2.1 USD Conversion Path Resolution

**What**: Three-way logic to find the USD conversion instrument for any instrument.

**Columns/Parameters Involved**: `InstrumentID`, `ConversionInstrumentID`, `IsReciprocal`

**Rules**:
- If the instrument already has USD on one side (BuyCurrencyID=1 OR SellCurrencyID=1): ConversionInstrumentID = InstrumentID itself.
- If the instrument is cross-currency (neither side is USD): find another instrument where SellCurrencyID of the original matches BuyCurrencyID of the conversion AND the conversion's SellCurrencyID = 1 (USD). OR where SellCurrencyIDs match and the conversion's BuyCurrencyID = 1.
- IsReciprocal = 1 when the conversion instrument's BuyCurrencyID = 1 (rate already in "per USD" form). IsReciprocal = 0 when the conversion instrument's SellCurrencyID = 1 (rate needs inversion).

**Diagram**:
```
EUR/GBP instrument -> Find GBP/USD instrument -> IsReciprocal=0 (USD is sell-side)
AUD/JPY instrument -> Find JPY/USD instrument -> IsReciprocal=1 if USD is buy-side
USD/JPY instrument -> Maps to itself         -> IsReciprocal=1 (USD is buy-side)
```

---

## 3. Data Overview

N/A for view - self-join result depends on instrument master data. Each instrument maps to one or more conversion instruments.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | The source instrument to convert. FK to Trade.Instrument. |
| 2 | ConversionInstrumentID | int | NO | - | CODE-BACKED | The forex instrument used to convert the source instrument's price to USD. May equal InstrumentID if the instrument already has USD on one side. |
| 3 | IsReciprocal | int | NO | - | CODE-BACKED | Computed: 1 = conversion instrument has BuyCurrencyID=1 (rate is already "X per USD"), 0 = rate needs inversion (SellCurrencyID=1). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.GetInstrument (view) | Self-JOIN | Source instrument. GetInstrument wraps Trade.Instrument with CurrencyPrice JOINs. |
| ConversionInstrumentID | Trade.GetInstrument (view) | Self-JOIN | USD conversion instrument. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPriceConversionInstrumentToUSD (view)
+-- Trade.GetInstrument (view)
      +-- Trade.Instrument (table)
      +-- Trade.CurrencyPrice (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrument | View | Self-JOIN (TGI1, TGI2) on currency pairs to find USD conversion path |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Find USD conversion instrument for a specific instrument

```sql
SELECT InstrumentID, ConversionInstrumentID, IsReciprocal
FROM Trade.GetPriceConversionInstrumentToUSD WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID
```

### 8.2 All instruments with their conversion paths

```sql
SELECT gpc.InstrumentID, i.SymbolFull, gpc.ConversionInstrumentID,
       ci.SymbolFull AS ConversionSymbol, gpc.IsReciprocal
FROM Trade.GetPriceConversionInstrumentToUSD gpc WITH (NOLOCK)
JOIN Trade.Instrument i WITH (NOLOCK) ON gpc.InstrumentID = i.InstrumentID
JOIN Trade.Instrument ci WITH (NOLOCK) ON gpc.ConversionInstrumentID = ci.InstrumentID
```

### 8.3 Cross-currency instruments requiring a bridge

```sql
SELECT InstrumentID, ConversionInstrumentID, IsReciprocal
FROM Trade.GetPriceConversionInstrumentToUSD WITH (NOLOCK)
WHERE InstrumentID <> ConversionInstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.2/10 (Elements: 10.0/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPriceConversionInstrumentToUSD | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetPriceConversionInstrumentToUSD.sql*
