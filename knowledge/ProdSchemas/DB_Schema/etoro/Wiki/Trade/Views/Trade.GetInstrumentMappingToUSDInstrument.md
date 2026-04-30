# Trade.GetInstrumentMappingToUSDInstrument

> Maps each forex instrument to the USD-quoted instrument used to calculate exposure in USD, with an IsSellCurrency flag indicating whether USD is the quote (sell) or base (buy) currency.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID (from TGI1) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentMappingToUSDInstrument creates a mapping between a given instrument and the instrument used to calculate exposure in USD. The view answers: "For forex instrument X, which Trade.Instrument row provides the rate to convert position value to USD, and is USD the base or quote currency?" This is critical for P&L, margin, and exposure aggregation - the platform must convert all positions to a common USD base for risk and reporting.

The view exists because Internal.GetNetOpenInUSD and History.GetNetOpenInUSD need to resolve how to get a USD rate for each instrument. For forex, the mapping is either the instrument itself (e.g., EUR/USD) or a related USD pair (e.g., GBP/USD for GBP-denominated exposure). The IsSellCurrency flag tells the formula whether to use the rate directly (Ask/Bid) or invert it (1/Ask, 1/Bid). The comment in DDL notes a TODO: client does not yet support multi-currency, so Commodities/Indices/CFDs are traded in USD and require no rate multiplication.

Data flows: The view performs a cross join of Trade.GetInstrument with itself (TGI1, TGI2). TGI1 is the source instrument; TGI2 is the USD instrument. The WHERE filters for InstrumentTypeID=1 (Forex only) and matches currency sides. Internal.GetNetOpenInUSD and History.GetNetOpenInUSD JOIN to this view. When an instrument is not found, they fall back to a rate of 1 (no conversion).

---

## 2. Business Logic

### 2.1 Forex-to-USD Instrument Mapping

**What**: For forex instruments, find the Trade.Instrument that provides the USD conversion rate - either the same instrument or a paired USD instrument.

**Columns/Parameters Involved**: `InstrumentID`, `USDInstrumentID`, `IsSellCurrency`, `TGI1.BuyCurrencyID`, `TGI1.SellCurrencyID`, `TGI2.BuyCurrencyID`, `TGI2.SellCurrencyID`

**Rules**:
- Only InstrumentTypeID=1 (Forex) instruments are included. Commodities/Indices/CFDs are excluded (per DDL TODO - traded in USD).
- Branch 1: TGI1.BuyCurrencyID = TGI2.BuyCurrencyID AND TGI2.SellCurrencyID = 1. USD is quote currency (e.g., EUR/USD). IsSellCurrency=1.
- Branch 2: TGI1.BuyCurrencyID = TGI2.SellCurrencyID AND TGI2.BuyCurrencyID = 1. USD is base currency (e.g., USD/JPY). IsSellCurrency=0.
- IsSellCurrency = CASE WHEN TGI2.SellCurrencyID = 1 THEN 1 ELSE 0 END. 1 = use rate as "currency per USD"; 0 = invert rate.

**Diagram**:
```
EUR/USD (InstrumentID=1): USDInstrumentID=1, IsSellCurrency=1 (USD is sell/quote)
USD/JPY (InstrumentID=5): USDInstrumentID=5, IsSellCurrency=0 (USD is buy/base)
GBP/USD: Maps to GBP/USD itself, IsSellCurrency=1
```

### 2.2 Rate Application in GetNetOpenInUSD

**What**: Internal.GetNetOpenInUSD and History.GetNetOpenInUSD use IsSellCurrency to choose how to apply the rate.

**Columns/Parameters Involved**: `IsSellCurrency`, `Ask`, `Bid`, `OpenedUnits`

**Rules**:
- When IsSellCurrency=1: Rate = Ask (if long) or Bid (if short). Use directly.
- When IsSellCurrency=0: Rate = 1/Ask or 1/Bid. Invert for "currency per USD".
- IsMajor=1 AND IsSellCurrency=1: multiply by -1 (sign adjustment for major forex convention).

---

## 3. Data Overview

| InstrumentID | USDInstrumentID | IsSellCurrency | Meaning |
|---|---|---|---|
| 1 | 1 | 1 | EUR/USD. Maps to itself. USD is quote (sell). Rate used directly. |
| 2 | 2 | 1 | GBP/USD. Same pattern. |
| 5 | 5 | 0 | USD/JPY. Maps to itself. USD is base (buy). Rate inverted for conversion. |
| 4 | 4 | 0 | USD/CAD. USD base. Rate inverted. |
| 3 | 3 | 1 | NZD/USD. USD quote. Rate used directly. |

**Selection criteria**: From DDL logic. Live query timed out (view uses cross join of GetInstrument). Pattern: forex pairs with USD as quote have IsSellCurrency=1; USD as base have IsSellCurrency=0.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | From TGI1. FK to Trade.Instrument. The source forex instrument being mapped. Identifies the instrument whose exposure is calculated. |
| 2 | USDInstrumentID | int | NO | - | CODE-BACKED | From TGI2.InstrumentID. The Trade.Instrument used to get the USD conversion rate. Often equals InstrumentID when the instrument is a USD pair (e.g., EUR/USD). |
| 3 | IsSellCurrency | int | NO | - | CODE-BACKED | Computed: CASE WHEN TGI2.SellCurrencyID = 1 THEN 1 ELSE 0 END. 1 = USD is quote (sell) currency - use Ask/Bid directly. 0 = USD is base (buy) currency - invert rate (1/Ask or 1/Bid) for conversion. Used by GetNetOpenInUSD formula. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID, USDInstrumentID | Trade.GetInstrument | Base | Both from Trade.GetInstrument (TGI1, TGI2). GetInstrument depends on Trade.Instrument, Dictionary.Currency, Trade.InstrumentMetaData. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Internal.GetNetOpenInUSD | GI | INNER JOIN | Resolves USD instrument and IsSellCurrency for exposure calculation. Falls back to rate=1 when instrument not found. |
| History.GetNetOpenInUSD | GI | INNER JOIN | Same for historical exposure. Falls back when instrument not in mapping. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentMappingToUSDInstrument (view)
└── Trade.GetInstrument (view)
      ├── Trade.Instrument (table)
      ├── Dictionary.Currency (table) [buy]
      ├── Dictionary.Currency (table) [sell]
      └── Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrument | View | FROM (twice as TGI1, TGI2) - cross join for forex-to-USD mapping |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetNetOpenInUSD | Function | INNER JOIN - exposure to USD |
| History.GetNetOpenInUSD | Function | INNER JOIN - historical exposure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get mapping for a specific instrument
```sql
SELECT InstrumentID, USDInstrumentID, IsSellCurrency
  FROM Trade.GetInstrumentMappingToUSDInstrument WITH (NOLOCK)
 WHERE InstrumentID = 1
```

### 8.2 List all forex instruments with USD-as-quote vs USD-as-base
```sql
SELECT InstrumentID, USDInstrumentID, IsSellCurrency,
       CASE WHEN IsSellCurrency = 1 THEN 'USD quote (direct rate)'
            ELSE 'USD base (invert rate)' END AS RateUsage
  FROM Trade.GetInstrumentMappingToUSDInstrument WITH (NOLOCK)
 ORDER BY IsSellCurrency, InstrumentID
```

### 8.3 Count by IsSellCurrency
```sql
SELECT IsSellCurrency,
       COUNT(*) AS InstrumentCount
  FROM Trade.GetInstrumentMappingToUSDInstrument WITH (NOLOCK)
 GROUP BY IsSellCurrency
 ORDER BY IsSellCurrency
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.3/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentMappingToUSDInstrument | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetInstrumentMappingToUSDInstrument.sql*
