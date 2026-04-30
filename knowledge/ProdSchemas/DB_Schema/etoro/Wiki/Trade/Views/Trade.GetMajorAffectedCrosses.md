# Trade.GetMajorAffectedCrosses

> Maps major forex instruments to cross forex instruments that share at least one currency, used for dependency analysis when major rates change.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID, CrossInstrument |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetMajorAffectedCrosses identifies which minor (cross) forex instruments are affected when a major forex instrument's rate changes. Each row pairs a major instrument (TI1.InstrumentID, where IsMajor=1) with a cross instrument (TI2.InstrumentID, where IsMajor=0 and InstrumentTypeID=1) that shares at least one currency - either BuyCurrencyID or SellCurrencyID - with the major instrument.

This view exists because forex rate propagation logic needs to know: "When EUR/USD (major) changes, which cross pairs (e.g., EUR/JPY) are affected?" Cross pairs are typically quoted against a major (e.g., USD); when a major rate moves, crosses that contain one of those currencies need recalculation. Used for pricing, exposure aggregation, or rate dependency graphs.

Data flows: The view reads Trade.Instrument (TI1) and Trade.GetInstrument (TI2) with NOLOCK. JOIN condition matches when any of the four currency combinations overlap. WHERE filters TI1.IsMajor=1, TI2.IsMajor=0, TI2.InstrumentTypeID=1 (forex only).

---

## 2. Business Logic

### 2.1 Currency Overlap Condition

**What**: A cross instrument is "affected" by a major instrument if they share at least one currency.

**Columns/Parameters Involved**: `TI1.BuyCurrencyID`, `TI1.SellCurrencyID`, `TI2.BuyCurrencyID`, `TI2.SellCurrencyID`

**Rules**:
- JOIN ON (TI1.BuyCurrencyID = TI2.BuyCurrencyID OR TI1.BuyCurrencyID = TI2.SellCurrencyID OR TI1.SellCurrencyID = TI2.BuyCurrencyID OR TI1.SellCurrencyID = TI2.SellCurrencyID)
- Example: EUR/USD (Buy=EUR, Sell=USD) affects EUR/JPY (Buy=EUR, Sell=JPY) via shared EUR
- Example: EUR/USD affects USD/JPY (Buy=USD, Sell=JPY) via shared USD

**Diagram**:
```
Major: EUR/USD (1)  ->  Cross: EUR/JPY (7)   [shared EUR]
Major: EUR/USD (1)  ->  Cross: USD/JPY (5)   [shared USD]
Major: GBP/USD (2)  ->  Cross: USD/JPY (5)  [shared USD]
```

### 2.2 Major vs Cross Filtering

**What**: Only major instruments drive the mapping; only forex crosses are targets.

**Columns/Parameters Involved**: `TI1.IsMajor`, `TI2.IsMajor`, `TI2.InstrumentTypeID`

**Rules**:
- TI1.IsMajor = 1: Source instrument must be major (e.g., EUR/USD, GBP/USD)
- TI2.IsMajor = 0: Target must be cross (non-major forex)
- TI2.InstrumentTypeID = 1: Target must be forex (excludes stocks, crypto, etc.)

---

## 3. Data Overview

| InstrumentID | CrossInstrument | Meaning |
|--------------|-----------------|---------|
| 1 | 5 | EUR/USD (1) affects USD/JPY (5) - shared USD. |
| 2 | 5 | GBP/USD (2) affects USD/JPY (5) - shared USD. |
| 3 | 5 | NZD/USD (3) affects USD/JPY (5) - shared USD. |
| 4 | 5 | USD/CAD (4) affects USD/JPY (5) - shared USD. |
| 6 | 5 | AUD/USD (6) affects USD/JPY (5) - shared USD. |

**Selection criteria**: Live sample. Multiple majors map to same cross (USD/JPY=5) because all share USD. InstrumentID 1-6 are major forex pairs.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Major instrument ID from Trade.Instrument (TI1). The rate-change source. |
| 2 | CrossInstrument | int | NO | - | CODE-BACKED | Cross instrument ID from Trade.GetInstrument (TI2). The affected forex pair. Alias for TI2.InstrumentID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FROM/JOIN | Major instrument (IsMajor=1) |
| CrossInstrument | Trade.GetInstrument | FROM/JOIN | Cross forex instrument (IsMajor=0, InstrumentTypeID=1) |
| (via GetInstrument) | Trade.Instrument, Dictionary.Currency, Trade.InstrumentMetaData | Implicit | GetInstrument joins Instrument + metadata |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (none found in codebase) | - | - | No direct procedure/view references in etoro/**/*.sql grep |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMajorAffectedCrosses (view)
├── Trade.Instrument (table) [TI1]
└── Trade.GetInstrument (view) [TI2]
    ├── Trade.Instrument (table)
    ├── Dictionary.Currency (table) [buy, sell]
    └── Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FROM TI1 - major instruments |
| Trade.GetInstrument | View | JOIN TI2 - cross instruments with InstrumentTypeID filter |

### 6.2 Objects That Depend On This

No direct dependents found in repository grep. May be used by application code or external systems for rate propagation.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

### 7.3 JOIN Conditions

- ON (TI1.BuyCurrencyID = TI2.BuyCurrencyID OR TI1.BuyCurrencyID = TI2.SellCurrencyID OR TI1.SellCurrencyID = TI2.BuyCurrencyID OR TI1.SellCurrencyID = TI2.SellCurrencyID)
- WHERE TI2.InstrumentTypeID = 1 AND TI1.IsMajor = 1 AND TI2.IsMajor = 0

---

## 8. Sample Queries

### 8.1 All cross instruments affected by a major
```sql
SELECT InstrumentID,
       CrossInstrument
  FROM Trade.GetMajorAffectedCrosses WITH (NOLOCK)
 WHERE InstrumentID = 1
 ORDER BY CrossInstrument;
```

### 8.2 Crosses affected by EUR/USD with instrument names
```sql
SELECT GAC.InstrumentID,
       GAC.CrossInstrument,
       GI1.Name AS MajorName,
       GI2.Name AS CrossName
  FROM Trade.GetMajorAffectedCrosses GAC WITH (NOLOCK)
  JOIN Trade.GetInstrument GI1 WITH (NOLOCK) ON GAC.InstrumentID = GI1.InstrumentID
  JOIN Trade.GetInstrument GI2 WITH (NOLOCK) ON GAC.CrossInstrument = GI2.InstrumentID
 WHERE GAC.InstrumentID = 1;
```

### 8.3 Count of affected crosses per major
```sql
SELECT InstrumentID,
       COUNT(*) AS AffectedCrossCount
  FROM Trade.GetMajorAffectedCrosses WITH (NOLOCK)
 GROUP BY InstrumentID
 ORDER BY AffectedCrossCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.0/10 (Elements: 2/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMajorAffectedCrosses | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetMajorAffectedCrosses.sql*
