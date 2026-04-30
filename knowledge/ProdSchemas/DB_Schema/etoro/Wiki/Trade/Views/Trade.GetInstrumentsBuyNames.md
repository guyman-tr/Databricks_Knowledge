# Trade.GetInstrumentsBuyNames

> Provides a display-ready instrument abbreviation for every tradeable instrument: single abbreviation for non-forex assets, or "BUY\SELL" format for forex pairs.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentsBuyNames is a thin projection view that produces a human-readable display name for every instrument in the Trade schema. For forex pairs (CurrencyTypeID=1), the abbreviation uses the format "Base\Quote" (e.g., EUR\USD) with a backslash separator. For non-forex assets (stocks, ETFs, crypto, commodities, indices), it shows only the single abbreviation of the buy-side asset (e.g., AAPL.US, BTC, PARAA).

This view exists because the UI, reports, and APIs need a consistent display label for instruments without re-implementing the currency-pair logic. Without it, each consumer would need to JOIN Instrument to Dictionary.Currency twice and apply the CASE logic. dbo.GetIBTraderActivityInfo JOINs this view to resolve instrument labels for IB trader activity reports.

Data flows from Trade.Instrument through two Dictionary.Currency JOINs (buy and sell). The view is read-only; no procedures modify it. Consumers query it with WITH (NOLOCK) for read-uncommitted isolation.

---

## 2. Business Logic

### 2.1 Abbreviation Display Format by Asset Type

**What**: The display name format depends on whether the instrument is a forex pair (two actual currencies) or a single-asset instrument.

**Columns/Parameters Involved**: `Abbreviation` (computed), `Instrument.InstrumentID`, `Dictionary.Currency.CurrencyTypeID`, `Dictionary.Currency.Abbreviation`

**Rules**:
- When BuyCurrencyID's CurrencyTypeID <> 1 (not forex): Abbreviation = single Abbreviation of the buy currency (e.g., "AAPL.US" for stocks, "BTC" for crypto).
- When CurrencyTypeID = 1 (forex): Abbreviation = BuyAbbreviation + '\' + SellAbbreviation (e.g., "EUR\USD"). Note: backslash, not forward slash.
- The buy-side Currency (from Instrument.BuyCurrencyID) drives the CurrencyTypeID check. For forex, both buy and sell are actual currencies; for stocks, buy is the asset, sell is the denomination currency.

**Diagram**:
```
Forex (CurrencyTypeID=1):   EUR + USD  -> "EUR\USD"
Stock (CurrencyTypeID=5):   AAPL.US + USD -> "AAPL.US"
Crypto (CurrencyTypeID=10): BTC + USD  -> "BTC"
```

---

## 3. Data Overview

| InstrumentID | Abbreviation | Meaning |
|--------------|--------------|---------|
| 0 | 000\000 | System placeholder instrument. Zeroed buy/sell currencies produce placeholder abbreviations. |
| 10029 | PARAA | Stock instrument - single abbreviation only. Non-forex display format. |
| 10030 | IQ.US | US stock (IQVIA). Ticker-style display. |
| 10031 | TFSL | Stock ticker. Single asset abbreviation. |
| 10032 | OLK | Stock ticker. Non-forex format. |

**Selection criteria**: Mixed system placeholder, stocks with varying ticker formats. Forex rows would show "EUR\USD" style; sample emphasizes non-forex variety.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Primary key from Trade.Instrument. Identifies the tradeable instrument. Inherited from Trade.Instrument. |
| 2 | Abbreviation | varchar (computed) | NO | - | CODE-BACKED | Computed: CASE WHEN Currency.CurrencyTypeID <> 1 THEN Currency.Abbreviation ELSE Currency.Abbreviation + '\' + C2.Abbreviation END. For forex: "BUY\SELL" (backslash). For non-forex: single asset abbreviation. Display-ready label for UI and reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | JOIN (base table) | Base instrument definition |
| (via BuyCurrencyID) | Dictionary.Currency | JOIN | Buy-side currency/asset for abbreviation and CurrencyTypeID |
| (via SellCurrencyID) | Dictionary.Currency | JOIN | Sell-side currency for forex pair suffix |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.GetIBTraderActivityInfo | tg (alias) | LEFT JOIN | Resolves instrument display name for IB trader activity reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentsBuyNames (view)
├── Trade.Instrument (table)
└── Dictionary.Currency (table) [used twice: buy and sell]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FROM - base table for all instruments |
| Dictionary.Currency | Table | INNER JOIN (buy) - Abbreviation and CurrencyTypeID |
| Dictionary.Currency | Table | INNER JOIN (sell) - Abbreviation for forex pair |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.GetIBTraderActivityInfo | Procedure | LEFT JOIN for instrument display names |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get display names for a set of instrument IDs
```sql
SELECT InstrumentID, Abbreviation
  FROM Trade.GetInstrumentsBuyNames WITH (NOLOCK)
 WHERE InstrumentID IN (1, 5, 10029, 100001)
 ORDER BY InstrumentID
```

### 8.2 Resolve instrument IDs to display names in a report
```sql
SELECT o.OrderID, o.InstrumentID, g.Abbreviation AS InstrumentName
  FROM Trade.[Order] o WITH (NOLOCK)
  LEFT JOIN Trade.GetInstrumentsBuyNames g WITH (NOLOCK)
    ON g.InstrumentID = o.InstrumentID
 WHERE o.OrderDate >= DATEADD(day, -7, GETUTCDATE())
```

### 8.3 Find forex instruments (those with backslash in abbreviation)
```sql
SELECT InstrumentID, Abbreviation
  FROM Trade.GetInstrumentsBuyNames WITH (NOLOCK)
 WHERE Abbreviation LIKE '%\%'
 ORDER BY InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 7.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetInstrumentsBuyNames | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetInstrumentsBuyNames.sql*
