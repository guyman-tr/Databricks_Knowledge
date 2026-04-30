# Trade.InstrumentMarketRange

> Projection of InstrumentID and MarketRange from Trade.ProviderToInstrument (one row per provider-instrument) for order validation and config display.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InstrumentMarketRange exposes the market range limit per instrument-provider pair - the maximum allowed price distance (or similar validation threshold) for order placement. It is a thin projection from Trade.ProviderToInstrument. This view supports order validation (ensuring user-entered prices stay within allowed range), operational config display, and the Trade.UpdateInstrumentsMarketRange procedure's config table shape (Trade.InstrumentMarketRangeConfigTable).

Without this view, callers would need to query ProviderToInstrument. The view returns one row per (ProviderID, InstrumentID) in ProviderToInstrument. If an instrument has multiple providers with different MarketRange values, the view will return multiple rows per instrument.

---

## 2. Business Logic

### 2.1 Market Range Projection

**What**: Expose InstrumentID and MarketRange from ProviderToInstrument for validation and config.

**Columns/Parameters Involved**: `InstrumentID`, `MarketRange`

**Rules**:
- Direct SELECT from Trade.ProviderToInstrument with no filters.
- One row per (ProviderID, InstrumentID) in ProviderToInstrument.
- MarketRange is nullable (int). Used for market order price validation - order price must be within range of current market.
- Trade.UpdateInstrumentsMarketRange updates ProviderToInstrument.MarketRange (and MarketRangePercentage, MarketRangeValidationType) from a config table shaped like this view; the procedure writes to the base table, not the view.

**Diagram**:
```
Trade.ProviderToInstrument (ProviderID, InstrumentID, MarketRange, ...)
    |
    v
Trade.InstrumentMarketRange (InstrumentID, MarketRange)
```

---

## 3. Data Overview

| InstrumentID | MarketRange | Meaning |
|--------------|-------------|---------|
| 1 | 10000000 | EUR/USD: 10M unit range for validation |
| 2 | 10000000 | GBP: same default |
| 3 | 10000000 | NZD/USD: same |
| 4 | 10000000 | Same pattern |
| 5 | 10000000 | Same pattern |

**Selection criteria for the 5 rows:** TOP 5 from live query. All samples show MarketRange = 10000000. NULL possible when ProviderToInstrument.MarketRange is NULL.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. From ProviderToInstrument. Identifies the tradeable instrument. |
| 2 | MarketRange | int | YES | - | CODE-BACKED | Market range validation limit. From ProviderToInstrument.MarketRange. Used to validate order prices stay within allowed distance from market. Sample: 10000000. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit FK | Via ProviderToInstrument.InstrumentID |

### 5.2 Base Tables (FROM)

| Table | How Used |
|-------|----------|
| Trade.ProviderToInstrument | Direct SELECT of InstrumentID, MarketRange |

### 5.3 Referenced By (other objects point to this)

| Source Object | Role | Description |
|---------------|------|-------------|
| Trade.InstrumentMarketRangeConfigTable | UDT | Table-valued type with InstrumentID, MarketRange (and related fields); used by UpdateInstrumentsMarketRange |
| Trade.UpdateInstrumentsMarketRange | MODIFIER | Updates ProviderToInstrument.MarketRange from config table; does not read this view |

*Note: The view is not directly referenced in procedure FROM clauses in the scanned codebase. It serves as a read interface for MarketRange per instrument/provider-instrument. The related procedure updates the base table.*

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InstrumentMarketRange (view)
    |
    +-- Trade.ProviderToInstrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | FROM - source of InstrumentID, MarketRange |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMarketRangeConfigTable | UDT | Config shape aligned with view concept |
| Trade.UpdateInstrumentsMarketRange | Procedure | Updates base table; config table shape mirrors view columns |

---

## 7. Technical Details

### 7.1 DDL Summary

- **Base table**: Trade.ProviderToInstrument
- **Logic**: SELECT InstrumentID, MarketRange. No WHERE, no JOINs.
- **Output**: InstrumentID, MarketRange. Row count = ProviderToInstrument row count (one per provider-instrument).

### 7.2 Column Sources

| Output Column | Source Table | Source Column |
|---------------|--------------|---------------|
| InstrumentID | Trade.ProviderToInstrument | InstrumentID |
| MarketRange | Trade.ProviderToInstrument | MarketRange |

---

## 8. Sample Queries

### 8.1 Get market range for instruments
```sql
SELECT InstrumentID, MarketRange
FROM Trade.InstrumentMarketRange WITH (NOLOCK)
WHERE InstrumentID IN (1, 2, 3)
ORDER BY InstrumentID;
```

### 8.2 Instruments with non-default market range
```sql
SELECT InstrumentID, MarketRange
FROM Trade.InstrumentMarketRange WITH (NOLOCK)
WHERE MarketRange IS NOT NULL AND MarketRange != 10000000
ORDER BY InstrumentID;
```

### 8.3 Join with ProviderToInstrument for provider context
```sql
SELECT imr.InstrumentID, imr.MarketRange, pti.ProviderID, pti.PresentationCode
FROM Trade.InstrumentMarketRange imr WITH (NOLOCK)
JOIN Trade.ProviderToInstrument pti WITH (NOLOCK)
  ON imr.InstrumentID = pti.InstrumentID AND pti.MarketRange = imr.MarketRange
WHERE imr.InstrumentID <= 10
ORDER BY imr.InstrumentID, pti.ProviderID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentMarketRange | Type: View | Source: etoro/etoro/Trade/Views/Trade.InstrumentMarketRange.sql*
