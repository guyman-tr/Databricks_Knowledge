# Trade.InstrumentMinPositionAmount

> Simple 2-column projection exposing the minimum position amount per instrument from Trade.ProviderToInstrument.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.InstrumentMinPositionAmount exposes the minimum position amount per instrument. It is a direct projection of InstrumentID and MinPositionAmount from Trade.ProviderToInstrument, providing the floor that order validation uses to enforce minimum trade sizes when customers open positions.

This view exists because every instrument has a minimum trade size to avoid dust positions and ensure economic viability. When a customer attempts to open a position below MinPositionAmount, the order is rejected. Without this abstraction, consumers would query ProviderToInstrument and extract only these two columns for validation logic.

The view performs a simple SELECT with no filters or JOINs. Output rows mirror ProviderToInstrument - one row per (ProviderID, InstrumentID) - exposing only InstrumentID and MinPositionAmount for use in order validation flows.

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
| 2 | MinPositionAmount | money | YES | - | CODE-BACKED | Minimum position amount in denomination currency. Used by order validation to enforce minimum trade sizes. |

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
Trade.InstrumentMinPositionAmount (view)
    |
    +-- Trade.ProviderToInstrument (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | FROM - source of InstrumentID, MinPositionAmount |

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

### 8.1 Get min position amount for instruments
```sql
SELECT InstrumentID, MinPositionAmount
FROM Trade.InstrumentMinPositionAmount WITH (NOLOCK)
WHERE InstrumentID IN (1, 2, 3)
```

### 8.2 Instruments with defined minimum
```sql
SELECT InstrumentID, MinPositionAmount
FROM Trade.InstrumentMinPositionAmount WITH (NOLOCK)
WHERE MinPositionAmount IS NOT NULL
ORDER BY InstrumentID
```

### 8.3 Validate amount against minimum for order
```sql
SELECT v.InstrumentID, v.MinPositionAmount
FROM Trade.InstrumentMinPositionAmount v WITH (NOLOCK)
WHERE v.InstrumentID = @InstrumentID
  AND (@RequestedAmount >= ISNULL(v.MinPositionAmount, 0) OR v.MinPositionAmount IS NULL)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentMinPositionAmount | Type: View | Source: etoro/etoro/Trade/Views/Trade.InstrumentMinPositionAmount.sql*
