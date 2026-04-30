# Trade.InstrumentMaxStopLossPercentage

> Simple 2-column projection exposing the maximum stop-loss percentage allowed per instrument from Trade.ProviderToInstrument.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.InstrumentMaxStopLossPercentage exposes the maximum stop-loss percentage allowed per instrument. It is a direct projection of InstrumentID and MaxStopLossPercentage from Trade.ProviderToInstrument, providing the upper bound that order validation uses to enforce stop-loss limits when customers open or edit positions.

This view exists because stop-loss percentages must be constrained per instrument to manage risk. When a customer sets a stop-loss above MaxStopLossPercentage, the order is rejected. Without this abstraction, consumers would query ProviderToInstrument and extract only these two columns for validation logic.

The view performs a simple SELECT with no filters or JOINs. Output rows mirror ProviderToInstrument - one row per (ProviderID, InstrumentID) - exposing only InstrumentID and MaxStopLossPercentage for use in order validation and position edit flows.

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
| 2 | MaxStopLossPercentage | decimal(18,8) | YES | - | CODE-BACKED | Maximum allowed stop-loss percentage. Used by order validation to enforce SL limits when opening or editing positions. |

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
Trade.InstrumentMaxStopLossPercentage (view)
    |
    +-- Trade.ProviderToInstrument (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | FROM - source of InstrumentID, MaxStopLossPercentage |

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

### 8.1 Get max SL percentage for instruments
```sql
SELECT InstrumentID, MaxStopLossPercentage
FROM Trade.InstrumentMaxStopLossPercentage WITH (NOLOCK)
WHERE InstrumentID IN (1, 2, 3)
```

### 8.2 Instruments with defined max SL
```sql
SELECT InstrumentID, MaxStopLossPercentage
FROM Trade.InstrumentMaxStopLossPercentage WITH (NOLOCK)
WHERE MaxStopLossPercentage IS NOT NULL
ORDER BY InstrumentID
```

### 8.3 Validate SL against max for order
```sql
SELECT v.InstrumentID, v.MaxStopLossPercentage
FROM Trade.InstrumentMaxStopLossPercentage v WITH (NOLOCK)
WHERE v.InstrumentID = @InstrumentID
  AND (@RequestedSLPct IS NULL OR v.MaxStopLossPercentage IS NULL OR @RequestedSLPct <= v.MaxStopLossPercentage)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentMaxStopLossPercentage | Type: View | Source: etoro/etoro/Trade/Views/Trade.InstrumentMaxStopLossPercentage.sql*
