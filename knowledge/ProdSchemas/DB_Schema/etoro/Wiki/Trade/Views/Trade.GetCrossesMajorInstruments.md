# Trade.GetCrossesMajorInstruments

> Maps every non-major forex cross instrument to its constituent major forex instruments, indicating direction (Inverse) and which currency leg matches (IsFirst) - used for cross-rate calculation via major pairs.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | CrossInstrument + MajorInstrument (composite from base tables) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetCrossesMajorInstruments answers the question: "For a given forex cross pair (e.g., EUR/GBP), which major pairs (e.g., EUR/USD, GBP/USD) can be used to derive its rate?" In forex trading, a cross pair is any currency pair that does not include USD as one of its legs. To calculate the rate of a cross pair, the platform decomposes it into two major pairs that share the cross's constituent currencies. This view provides that decomposition with direction metadata.

This view exists because eToro's pricing and conversion engine needs to know how to derive cross-pair rates from major-pair rates. Major pairs (flagged with IsMajor=1 in Trade.Instrument) have direct price feeds. Cross pairs (IsMajor=0, InstrumentTypeID=1) do not always have direct feeds, so their rates are computed from the two corresponding major pairs. Without this mapping, the system cannot calculate cross-pair prices, P&L conversions, or hedging exposure for cross instruments.

Data flows from Trade.GetInstrument (the primary instrument view, which enriches Trade.Instrument with metadata) and Trade.Instrument (the base instrument table). The view self-joins instruments on currency matching: it takes non-major forex instruments (TGI, WHERE IsMajor=0 AND InstrumentTypeID=1) and pairs them with major instruments (TI, WHERE IsMajor=1) wherever their buy or sell currencies overlap. No stored procedures in the SSDT repo reference this view directly - it is likely consumed by application-layer pricing services or used in ad-hoc rate derivation queries.

---

## 2. Business Logic

### 2.1 Cross-to-Major Currency Decomposition

**What**: Maps each forex cross pair to every major pair that shares one of its currencies.

**Columns/Parameters Involved**: `CrossInstrument`, `MajorInstrument`, `BuyCurrencyID`, `SellCurrencyID`

**Rules**:
- A cross instrument (IsMajor=0, InstrumentTypeID=1) is joined to every major instrument (IsMajor=1) where any of the four currency-matching conditions hold
- The four conditions are: cross Buy = major Buy, cross Sell = major Sell, cross Sell = major Buy, or cross Buy = major Sell
- Each cross pair typically maps to 2+ major pairs (one for each currency leg)
- InstrumentTypeID=1 filters to forex instruments only - stocks, crypto, and other types are excluded

**Diagram**:
```
Cross: EUR/GBP (InstrumentID=5)
  Buy=EUR, Sell=GBP

Major matches:
  EUR/USD (ID=1): Buy=EUR matches Cross Buy=EUR -> Inverse=1, IsFirst=1
  GBP/USD (ID=4): Buy=GBP matches Cross Sell=GBP -> Inverse=-1, IsFirst=0
  
Rate derivation: EUR/GBP = EUR/USD / GBP/USD (adjusted by Inverse flags)
```

### 2.2 Inverse Direction Flag

**What**: Indicates whether the major pair's rate needs to be inverted when computing the cross-pair rate.

**Columns/Parameters Involved**: `Inverse`

**Rules**:
- Inverse = -1 when cross's SellCurrency matches major's BuyCurrency OR cross's BuyCurrency matches major's SellCurrency (the major pair runs "opposite" to the cross pair's direction)
- Inverse = 1 when cross's BuyCurrency matches major's BuyCurrency OR cross's SellCurrency matches major's SellCurrency (same direction)
- Used by the pricing engine to determine whether to multiply or divide by the major pair's rate

### 2.3 IsFirst Currency Leg Flag

**What**: Identifies which leg of the cross pair (buy-side or sell-side) is matched by this major pair.

**Columns/Parameters Involved**: `IsFirst`

**Rules**:
- IsFirst = 1 when the cross instrument's BuyCurrencyID matches either the major's BuyCurrencyID or SellCurrencyID (i.e., the major pair covers the "first" / buy-side currency of the cross)
- IsFirst = 0 when the match is through the cross's SellCurrencyID (the major pair covers the "second" / sell-side currency)
- Helps the pricing engine determine the order of operations when combining two major rates into a cross rate

---

## 3. Data Overview

| CrossInstrument | MajorInstrument | Inverse | IsFirst | Meaning |
|---|---|---|---|---|
| 5 | 1 | 1 | 0 | Forex cross ID 5 can derive its rate from major pair ID 1 in the same direction; the match is through the cross's sell-side currency |
| 5 | 4 | -1 | 0 | Same cross instrument paired with major ID 4 in inverse direction - the major pair runs opposite, requiring rate inversion during calculation |
| 5 | 1001 | 1 | 0 | Cross ID 5 matched to a high-ID major instrument (likely a newer market or special pair), same direction |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CrossInstrument | int | NO | - | CODE-BACKED | InstrumentID of the non-major forex cross pair (IsMajor=0 AND InstrumentTypeID=1). Sourced from Trade.GetInstrument.InstrumentID. Each cross instrument appears multiple times - once for each major pair it can be decomposed into. FK to Trade.Instrument.InstrumentID. |
| 2 | MajorInstrument | int | NO | - | CODE-BACKED | InstrumentID of the major forex instrument (IsMajor=1) that shares a currency with the cross pair. Sourced from Trade.Instrument.InstrumentID. The rate of this major pair is used in the cross-rate derivation formula. FK to Trade.Instrument.InstrumentID. |
| 3 | Inverse | int | NO | - | CODE-BACKED | Direction flag for rate derivation: 1 = same direction (cross and major share BuyCurrencyID-to-BuyCurrencyID or SellCurrencyID-to-SellCurrencyID), -1 = inverse direction (cross's SellCurrency matches major's BuyCurrency, or cross's BuyCurrency matches major's SellCurrency). Used by the pricing engine to determine whether to multiply or divide by this major pair's rate. Computed in view via CASE expression. |
| 4 | IsFirst | int | NO | - | CODE-BACKED | Currency leg indicator: 1 = the cross pair's BuyCurrencyID matches this major pair's BuyCurrencyID or SellCurrencyID (buy-side match), 0 = the match is through the cross pair's SellCurrencyID (sell-side match). Helps the pricing engine determine the order of operations when combining two major rates. Computed in view via CASE expression. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CrossInstrument | Trade.GetInstrument (view) | JOIN | Source view for non-major forex cross instruments; provides InstrumentID, BuyCurrencyID, SellCurrencyID, IsMajor, InstrumentTypeID |
| MajorInstrument | Trade.Instrument (table) | JOIN | Source table for major instruments; provides InstrumentID, BuyCurrencyID, SellCurrencyID, IsMajor |

### 5.2 Referenced By (other objects point to this)

No stored procedures, views, or functions in the SSDT repo reference this view. It is likely consumed by application-layer pricing services outside the database.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCrossesMajorInstruments (view)
+-- Trade.GetInstrument (view)
|     +-- Trade.Instrument (table)
|     +-- Dictionary.Currency (table)
|     +-- Trade.InstrumentMetaData (table)
+-- Trade.Instrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrument | View | JOINed as TGI - provides non-major forex instruments with currency IDs and metadata |
| Trade.Instrument | Table | JOINed as TI - provides major instruments with BuyCurrencyID and SellCurrencyID |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Find all major pairs for a specific cross instrument

```sql
SELECT  gcmi.CrossInstrument,
        gi_cross.Name AS CrossName,
        gcmi.MajorInstrument,
        gi_major.Name AS MajorName,
        gcmi.Inverse,
        gcmi.IsFirst
FROM    Trade.GetCrossesMajorInstruments gcmi WITH (NOLOCK)
JOIN    Trade.GetInstrument gi_cross WITH (NOLOCK) ON gcmi.CrossInstrument = gi_cross.InstrumentID
JOIN    Trade.GetInstrument gi_major WITH (NOLOCK) ON gcmi.MajorInstrument = gi_major.InstrumentID
WHERE   gcmi.CrossInstrument = 5
```

### 8.2 Find all cross pairs that depend on a specific major pair

```sql
SELECT  gcmi.CrossInstrument,
        gi.Name AS CrossName,
        gcmi.Inverse,
        gcmi.IsFirst
FROM    Trade.GetCrossesMajorInstruments gcmi WITH (NOLOCK)
JOIN    Trade.GetInstrument gi WITH (NOLOCK) ON gcmi.CrossInstrument = gi.InstrumentID
WHERE   gcmi.MajorInstrument = 1
ORDER BY gi.Name
```

### 8.3 Count how many major pairs each cross instrument maps to

```sql
SELECT  gcmi.CrossInstrument,
        gi.Name AS CrossName,
        COUNT(*) AS MajorPairCount
FROM    Trade.GetCrossesMajorInstruments gcmi WITH (NOLOCK)
JOIN    Trade.GetInstrument gi WITH (NOLOCK) ON gcmi.CrossInstrument = gi.InstrumentID
GROUP BY gcmi.CrossInstrument, gi.Name
ORDER BY MajorPairCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCrossesMajorInstruments | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetCrossesMajorInstruments.sql*
