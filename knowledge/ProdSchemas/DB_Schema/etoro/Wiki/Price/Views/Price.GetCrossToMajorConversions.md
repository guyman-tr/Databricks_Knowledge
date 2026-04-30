# Price.GetCrossToMajorConversions

> Maps each cross-currency instrument (Forex/Crypto, InstrumentTypeID 1 or 10) to the USD conversion instruments needed to resolve its constituent non-USD currencies into USD - the pricing engine's routing table for P&L conversion of cross pairs.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | View |
| **Key Identifier** | InstrumentID + CurrencyID (composite - one row per instrument per non-USD currency) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetCrossToMajorConversions answers: "For each cross-currency instrument, how do I convert each of its constituent currencies to USD?" A cross-currency pair (e.g., EUR/GBP) involves two non-USD currencies. To compute P&L in USD, the pricing engine must know: (1) which USD-paired instrument gives the EUR/USD rate, (2) which gives the GBP/USD rate, and (3) whether those rates must be inverted. This view provides exactly those mappings for all active Forex (InstrumentTypeID=1) and Crypto (InstrumentTypeID=10) instruments.

The view exists because P&L and margin calculations always settle in USD. For instruments where neither leg is USD (cross pairs), the pricing engine cannot directly read an exchange rate - it must chain two conversions via USD. This view pre-computes the conversion path per instrument per currency, so the pricing engine can look up "instrument X, currency Y -> buy or sell ConversionInstrumentID at IsReciprocal rate" without re-deriving it at runtime.

Data: 362 rows covering 191 cross instruments (each appearing twice: once per non-USD leg) and 41 non-USD currencies. Each instrument-currency pair maps to a ConversionInstrumentID (the USD pair for that currency) plus IsBuy (buy or sell direction) and IsReciprocal (rate inversion flag). The WHERE clause `InstrumentID != ConversionInstrumentID` excludes direct USD pairs (EUR/USD itself does not need a cross-conversion mapping).

---

## 2. Business Logic

### 2.1 Cross-to-USD Conversion Path per Instrument

**What**: For each cross-currency instrument, the view produces one row per constituent non-USD currency, each row carrying the full conversion instruction.

**Columns/Parameters Involved**: `InstrumentID`, `CurrencyID`, `ConversionInstrumentID`, `IsBuy`, `IsReciprocal`

**Rules**:
- A cross pair like EUR/GBP (InstrumentID=8) generates TWO rows:
  - Row A: CurrencyID=2 (EUR), ConversionInstrumentID=1 (EUR/USD), IsBuy=1, IsReciprocal=0
  - Row B: CurrencyID=3 (GBP), ConversionInstrumentID=2 (GBP/USD), IsBuy=0, IsReciprocal=0
- Direct USD pairs (EUR/USD itself) are excluded by `InstrumentID != ConversionInstrumentID`.
- InstrumentTypeID filter (1=Forex, 10=Crypto) restricts to price-sensitive instruments; other types do not need this routing.

**Diagram**:
```
EUR/GBP (InstrumentID=8)
  -> CurrencyID=2 (EUR): buy EUR/USD (InstrumentID=1, IsBuy=1, IsReciprocal=0)
  -> CurrencyID=3 (GBP): sell GBP/USD (InstrumentID=2, IsBuy=0, IsReciprocal=0)

Some cross Crypto pair (InstrumentID=9)
  -> CurrencyID=2 (EUR):   buy EUR/USD (InstrumentID=1, IsBuy=1, IsReciprocal=0)
  -> CurrencyID=6 (other): use InstrumentID=6 (IsBuy=0, IsReciprocal=1 -> invert rate)
```

### 2.2 IsBuy Direction Flag

**What**: IsBuy tells the pricing engine whether to use the bid or ask side of the conversion instrument when converting to USD.

**Columns/Parameters Involved**: `IsBuy`, `SellCurrencyID`, `CurrencyID`

**Rules**:
- `IsBuy = CASE WHEN i.SellCurrencyID = c.CurrencyID THEN 0 ELSE 1 END`
- IsBuy=0 (sell): the instrument's sell-side currency matches the currency being converted. Use the bid price.
- IsBuy=1 (buy): the instrument's buy-side currency matches the currency being converted. Use the ask price.
- For EUR/GBP converting EUR: SellCurrencyID=GBP != CurrencyID=EUR -> IsBuy=1 (buy EUR/USD to get EUR value).
- For EUR/GBP converting GBP: SellCurrencyID=GBP = CurrencyID=GBP -> IsBuy=0 (sell GBP/USD to get GBP value).

### 2.3 IsReciprocal Rate Inversion

**What**: When the conversion instrument quotes "USD per currency" rather than "currency per USD", the rate must be inverted. Inherited from Trade.GetCurrencyConversionsView.

**Columns/Parameters Involved**: `IsReciprocal`, `ConversionInstrumentID`

**Rules**:
- IsReciprocal=0: the ConversionInstrumentID rate is "currency per USD" - use directly (e.g., EUR/USD: 1.08 means 1.08 EUR per USD).
- IsReciprocal=1: the ConversionInstrumentID rate is "USD per currency" - take reciprocal to get "currency per USD" (e.g., USD/JPY: 150 means 1/150 USD per JPY is wrong; invert to get 150 JPY per USD).

---

## 3. Data Overview

| InstrumentID | IsBuy | CurrencyID | ConversionCurrencyID | ConversionInstrumentID | IsReciprocal | Meaning |
|---|---|---|---|---|---|---|
| 8 | 1 | 2 | 1 | 1 | 0 | EUR/GBP's EUR leg: buy EUR/USD (instrument 1) at ask to convert EUR to USD. Rate used directly (IsReciprocal=0). |
| 8 | 0 | 3 | 1 | 2 | 0 | EUR/GBP's GBP leg: sell GBP/USD (instrument 2) at bid to convert GBP to USD. |
| 9 | 1 | 2 | 1 | 1 | 0 | Another cross pair's EUR leg - same EUR/USD conversion path as all EUR-involving crosses. |
| 9 | 0 | 6 | 1 | 6 | 1 | Instrument 9's second leg via currency 6: use instrument 6, invert rate (IsReciprocal=1 - USD is base currency of the conversion instrument). |
| 10 | 1 | 2 | 1 | 1 | 0 | Yet another EUR-leg cross instrument: EUR always converts via EUR/USD (InstrumentID=1). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | eToro instrument identifier for the cross-currency instrument being mapped. From Trade.GetInstrument. Only Forex (InstrumentTypeID=1) and Crypto (InstrumentTypeID=10) instruments appear. Always a cross pair (both legs non-USD, or crypto vs non-USD). |
| 2 | IsBuy | int | NO | - | CODE-BACKED | Direction of the conversion trade: 0=sell the ConversionInstrumentID to convert, 1=buy the ConversionInstrumentID to convert. Computed: `CASE WHEN i.SellCurrencyID = c.CurrencyID THEN 0 ELSE 1 END`. Drives bid vs ask rate selection in the pricing engine. |
| 3 | CurrencyID | int | NO | - | CODE-BACKED | The non-USD currency of this row's conversion leg. From Trade.GetCurrencyConversionsView. CurrencyID 0 and 1 (USD) are excluded by WHERE clause. FK to Dictionary.Currency. Each cross instrument appears twice - once per non-USD leg. |
| 4 | ConversionCurrencyID | int | NO | - | CODE-BACKED | Always 1 (USD) in this view. Inherited from Trade.GetCurrencyConversionsView (ConversionCurrencyID = 1 is enforced by WHERE clause). Confirms all conversions target USD. |
| 5 | ConversionInstrumentID | int | NO | - | CODE-BACKED | The USD-paired instrument that gives the conversion rate for CurrencyID to USD. Inherited from Trade.GetCurrencyConversionsView. FK to Trade.Instrument. Example: CurrencyID=2 (EUR) -> ConversionInstrumentID=1 (EUR/USD). |
| 6 | IsReciprocal | int | NO | - | CODE-BACKED | Whether to invert the ConversionInstrumentID rate: 0=use rate directly (currency/USD pair like EUR/USD), 1=invert rate (USD/currency pair like USD/JPY - multiply by reciprocal). Inherited from Trade.GetCurrencyConversionsView. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Lookup (via GetInstrument) | The cross-currency instrument being mapped |
| CurrencyID | Dictionary.Currency | Lookup (via GetCurrencyConversionsView) | The non-USD currency needing USD conversion |
| ConversionInstrumentID | Trade.Instrument | Lookup (via GetCurrencyConversionsView) | The USD-paired instrument providing the conversion rate |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no stored procedures found referencing this view directly in the Price schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetCrossToMajorConversions (view)
├── Trade.GetCurrencyConversionsView (view)
│     ├── Dictionary.Currency (table)
│     └── Trade.Instrument (table)
└── Trade.GetInstrument (view)
      ├── Trade.Instrument (table)
      ├── Dictionary.Currency (table)
      └── Trade.InstrumentMetaData (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetCurrencyConversionsView | View | FROM - provides non-USD-to-USD currency conversion mapping (CurrencyID, ConversionInstrumentID, IsReciprocal) |
| Trade.GetInstrument | View | INNER JOIN on (SellCurrencyID = CurrencyID OR BuyCurrencyID = CurrencyID) - finds cross instruments involving each non-USD currency; provides InstrumentTypeID for filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Price schema | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. No SCHEMABINDING. Effective filters: CurrencyID NOT IN (0,1), ConversionCurrencyID=1, InstrumentID != ConversionInstrumentID, InstrumentTypeID IN (1,10).

---

## 8. Sample Queries

### 8.1 Find conversion paths for a specific cross instrument

```sql
SELECT InstrumentID, IsBuy, CurrencyID, ConversionInstrumentID, IsReciprocal
FROM Price.GetCrossToMajorConversions WITH (NOLOCK)
WHERE InstrumentID = 8
ORDER BY CurrencyID;
```

### 8.2 All cross instruments that use EUR/USD as a conversion leg

```sql
SELECT InstrumentID, IsBuy, CurrencyID, ConversionInstrumentID, IsReciprocal
FROM Price.GetCrossToMajorConversions WITH (NOLOCK)
WHERE ConversionInstrumentID = 1  -- EUR/USD
ORDER BY InstrumentID;
```

### 8.3 Instruments requiring rate inversion (IsReciprocal=1)

```sql
SELECT GCTMC.InstrumentID, GCTMC.CurrencyID, GCTMC.ConversionInstrumentID,
       GI.Name AS InstrumentName
FROM Price.GetCrossToMajorConversions GCTMC WITH (NOLOCK)
JOIN Trade.GetInstrument GI WITH (NOLOCK)
    ON GI.InstrumentID = GCTMC.InstrumentID
WHERE GCTMC.IsReciprocal = 1
ORDER BY GCTMC.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 5, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetCrossToMajorConversions | Type: View | Source: etoro/etoro/Price/Views/Price.GetCrossToMajorConversions.sql*
