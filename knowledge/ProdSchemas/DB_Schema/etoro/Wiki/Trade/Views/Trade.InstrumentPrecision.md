# Trade.InstrumentPrecision

> Simple 3-column projection exposing price precision settings per instrument from Trade.ProviderToInstrument.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.InstrumentPrecision exposes price precision settings per instrument. It is a direct projection of InstrumentID, Precision, and AboveDollarPrecision from Trade.ProviderToInstrument. Precision defines decimal places for sub-dollar prices; AboveDollarPrecision defines decimal places for above-dollar prices. These values drive price display and rounding logic across the platform.

This view exists because displayed prices must be rounded consistently per instrument. Sub-dollar instruments (e.g., some forex pairs) use Precision; above-dollar instruments (e.g., stocks) use AboveDollarPrecision. Without this abstraction, consumers would query ProviderToInstrument and extract only these columns for display and validation logic.

The view performs a simple SELECT with no filters or JOINs. Output rows mirror ProviderToInstrument - one row per (ProviderID, InstrumentID) - exposing InstrumentID, Precision, and AboveDollarPrecision for use in price formatting and rounding flows.

---

## 2. Business Logic

No complex business logic. This is a direct projection from Trade.ProviderToInstrument.

---

## 3. Data Overview

N/A - output mirrors Trade.ProviderToInstrument. See [Trade.ProviderToInstrument](../Tables/Trade.ProviderToInstrument.md) for data overview.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. Identifies the tradeable instrument. |
| 2 | Precision | int | YES | - | CODE-BACKED | Decimal places for sub-dollar prices. Used by price display and rounding logic. |
| 3 | AboveDollarPrecision | int | YES | - | CODE-BACKED | Decimal places for above-dollar prices. Used by price display and rounding logic when price >= 1. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit FK | Via ProviderToInstrument.InstrumentID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InstrumentPrecision (view)
    |
    +-- Trade.ProviderToInstrument (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | FROM - source of InstrumentID, Precision, AboveDollarPrecision |

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

### 8.1 Get precision for instruments
```sql
SELECT InstrumentID, Precision, AboveDollarPrecision
FROM Trade.InstrumentPrecision WITH (NOLOCK)
WHERE InstrumentID IN (1, 2, 3)
```

### 8.2 Instruments with sub-dollar precision
```sql
SELECT InstrumentID, Precision, AboveDollarPrecision
FROM Trade.InstrumentPrecision WITH (NOLOCK)
WHERE Precision IS NOT NULL
ORDER BY InstrumentID
```

### 8.3 Round price by instrument precision
```sql
SELECT v.InstrumentID, v.Precision, v.AboveDollarPrecision
FROM Trade.InstrumentPrecision v WITH (NOLOCK)
WHERE v.InstrumentID = @InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentPrecision | Type: View | Source: etoro/etoro/Trade/Views/Trade.InstrumentPrecision.sql*
