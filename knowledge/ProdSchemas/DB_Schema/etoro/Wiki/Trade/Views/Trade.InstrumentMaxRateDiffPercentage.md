# Trade.InstrumentMaxRateDiffPercentage

> Simple 2-column projection exposing the maximum allowed rate difference percentage per instrument from Trade.ProviderToInstrument.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.InstrumentMaxRateDiffPercentage exposes the maximum allowed rate difference percentage per instrument. It is a direct projection of InstrumentID and AllowedRateDiffPercentage from Trade.ProviderToInstrument, providing the threshold that price feed validation uses to flag instruments where the incoming rate deviates too far from the last known rate.

This view exists because price feeds continuously stream rates into the platform, and the system must detect stale or erroneous prices. When the difference between an incoming rate and the last known rate exceeds AllowedRateDiffPercentage, the system flags the instrument for review or rejects the update. Without this abstraction, every consumer would query ProviderToInstrument directly and select only these two columns.

The view performs a simple SELECT with no filters or JOINs. Output rows mirror ProviderToInstrument - one row per (ProviderID, InstrumentID) - exposing only InstrumentID and AllowedRateDiffPercentage for lightweight lookups in price validation logic.

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
| 2 | AllowedRateDiffPercentage | decimal(18,8) | YES | - | CODE-BACKED | Maximum allowed percentage difference between incoming rate and last known rate. Used by price feed validation to flag instruments where deviation exceeds threshold. |

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
Trade.InstrumentMaxRateDiffPercentage (view)
    |
    +-- Trade.ProviderToInstrument (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | FROM - source of InstrumentID, AllowedRateDiffPercentage |

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

### 8.1 Get rate diff threshold for instruments
```sql
SELECT InstrumentID, AllowedRateDiffPercentage
FROM Trade.InstrumentMaxRateDiffPercentage WITH (NOLOCK)
WHERE InstrumentID IN (1, 2, 3)
```

### 8.2 Instruments with defined rate diff threshold
```sql
SELECT InstrumentID, AllowedRateDiffPercentage
FROM Trade.InstrumentMaxRateDiffPercentage WITH (NOLOCK)
WHERE AllowedRateDiffPercentage IS NOT NULL
ORDER BY InstrumentID
```

### 8.3 Join with instrument for validation context
```sql
SELECT v.InstrumentID, i.SymbolFull, v.AllowedRateDiffPercentage
FROM Trade.InstrumentMaxRateDiffPercentage v WITH (NOLOCK)
JOIN Trade.Instrument i WITH (NOLOCK) ON v.InstrumentID = i.InstrumentID
WHERE v.AllowedRateDiffPercentage IS NOT NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentMaxRateDiffPercentage | Type: View | Source: etoro/etoro/Trade/Views/Trade.InstrumentMaxRateDiffPercentage.sql*
