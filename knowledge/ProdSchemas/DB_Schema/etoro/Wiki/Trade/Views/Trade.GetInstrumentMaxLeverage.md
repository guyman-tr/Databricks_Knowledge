# Trade.GetInstrumentMaxLeverage

> Returns the maximum available leverage (across all providers) for each tradeable instrument, derived from Trade.ProviderInstrumentToLeverage and Dictionary.Leverage.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentMaxLeverage answers: "What is the highest leverage a user can select for instrument X?" For each instrument, the view aggregates all leverage tiers from Trade.ProviderInstrumentToLeverage (across all providers) and returns MAX(Dictionary.Leverage.Value) as MaxLeverage. This is used by API consumers and validation logic to know the upper bound of allowed leverage before a user opens a position.

The view exists because different providers offer different leverage tiers per instrument (e.g., Provider 1 offers 1x-100x for EUR/USD, Provider 2 offers 1x-200x). The platform needs a single "cap" per instrument for display (e.g., "Up to 400x") and for regulatory/risk checks. Without it, callers would need to query ProviderInstrumentToLeverage and compute the max themselves.

Data flows: The view reads Trade.ProviderInstrumentToLeverage and Dictionary.Leverage. Trade.GetInstrumentDataForAPI and Trade.GetInstrumentDataForAPITest use this view (per Trade.ProviderInstrumentToLeverage dependencies) to enrich API responses with max leverage. No procedures write to this view; it is read-only.

---

## 2. Business Logic

### 2.1 Max Leverage per Instrument

**What**: The view returns one row per instrument with the highest leverage value available across all providers.

**Columns/Parameters Involved**: `InstrumentID`, `MaxLeverage`, `DL.Value`, `PITL.LeverageID`

**Rules**:
- GROUP BY PITL.InstrumentID - one row per instrument
- MAX(DL.Value) - picks the highest numeric leverage (e.g., 1, 2, 5, 10, 20, 30, 50, 100, 200, 400 from Dictionary.Leverage)
- Instruments with no ProviderInstrumentToLeverage rows do not appear in the view
- Trade.CheckValidInstruments raises an error if an instrument has no ProviderInstrumentToLeverage rows

**Diagram**:
```
Trade.ProviderInstrumentToLeverage (InstrumentID, LeverageID) -> multiple providers
    |
    v
Dictionary.Leverage (LeverageID, Value) -> 1, 2, 5, 10, 20, 30, 50, 100, 200, 400
    |
    v
MAX(Value) per InstrumentID
```

---

## 3. Data Overview

| InstrumentID | MaxLeverage | Meaning |
|---|---|---|
| 1 | 400 | EUR/USD - highest tier 400x available from at least one provider |
| 2 | 200 | GBP - max 200x |
| 3 | 400 | NZD/USD - max 400x |
| 4 | 400 | USD/CAD - max 400x |
| 5 | 400 | USD/JPY - max 400x |

**Selection criteria**: From live MCP sample. Major forex pairs (1-5) show max leverage 200-400. Instrument 2 (GBP) has 200; others 400.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. Identifies the tradeable instrument. From Trade.ProviderInstrumentToLeverage. |
| 2 | MaxLeverage | int | YES | - | CODE-BACKED | Computed: MAX(DL.Value). Highest leverage value available for this instrument across all providers. Dictionary.Leverage values: 1, 2, 5, 10, 20, 30, 50, 100, 200, 400. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Lookup | Core instrument definition |
| InstrumentID, LeverageID | Trade.ProviderInstrumentToLeverage | Base | Per-provider leverage tiers |
| LeverageID | Dictionary.Leverage | Lookup | Numeric leverage value |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetInstrumentDataForAPI | pitl | FROM | API instrument data with max leverage |
| Trade.GetInstrumentDataForAPITest | pitl | FROM | Test API instrument data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentMaxLeverage (view)
├── Trade.ProviderInstrumentToLeverage (table)
└── Dictionary.Leverage (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderInstrumentToLeverage | Table | FROM, JOIN - per-provider leverage tiers |
| Dictionary.Leverage | Table | JOIN - resolve LeverageID to Value |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrumentDataForAPI | Procedure | FROM - max leverage for API |
| Trade.GetInstrumentDataForAPITest | Procedure | FROM - test API data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get max leverage for specific instruments
```sql
SELECT InstrumentID, MaxLeverage
  FROM Trade.GetInstrumentMaxLeverage WITH (NOLOCK)
 WHERE InstrumentID IN (1, 2, 5, 1001)
```

### 8.2 Instruments with highest leverage tier (400x)
```sql
SELECT InstrumentID, MaxLeverage
  FROM Trade.GetInstrumentMaxLeverage WITH (NOLOCK)
 WHERE MaxLeverage = 400
 ORDER BY InstrumentID
```

### 8.3 Max leverage with instrument name
```sql
SELECT GIML.InstrumentID, GI.Name, GIML.MaxLeverage
  FROM Trade.GetInstrumentMaxLeverage GIML WITH (NOLOCK)
  JOIN Trade.GetInstrument GI WITH (NOLOCK) ON GI.InstrumentID = GIML.InstrumentID
 WHERE GIML.InstrumentID < 100
 ORDER BY GIML.MaxLeverage DESC, GIML.InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentMaxLeverage | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetInstrumentMaxLeverage.sql*
