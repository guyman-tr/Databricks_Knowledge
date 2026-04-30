# Trade.InstrumentNWADecreasePercentage

> Simple 2-column projection exposing NWA (Net Withdrawable Amount) decrease percentage per instrument from Trade.ProviderToInstrument.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.InstrumentNWADecreasePercentage exposes the NWA (Net Withdrawable Amount) decrease percentage per instrument. It is a direct projection of InstrumentID and BonusCreditUsePercent from Trade.ProviderToInstrument. BonusCreditUsePercent controls how much bonus credit can be used for this instrument, which affects NWA calculations when positions are open.

This view exists because NWA - the amount a customer can withdraw - is reduced when bonus credit is tied to open positions. Each instrument contributes to that reduction based on BonusCreditUsePercent. Without this abstraction, consumers would query ProviderToInstrument and extract only these two columns for NWA calculation logic.

The view performs a simple SELECT with no filters or JOINs. Output rows mirror ProviderToInstrument - one row per (ProviderID, InstrumentID) - exposing InstrumentID and BonusCreditUsePercent for use in NWA and bonus-related flows.

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
| 2 | BonusCreditUsePercent | decimal(18,8) | YES | - | CODE-BACKED | Percentage of bonus credit that can be used for this instrument. Affects NWA (Net Withdrawable Amount) calculations when positions are open. |

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
Trade.InstrumentNWADecreasePercentage (view)
    |
    +-- Trade.ProviderToInstrument (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | FROM - source of InstrumentID, BonusCreditUsePercent |

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

### 8.1 Get NWA decrease percentage for instruments
```sql
SELECT InstrumentID, BonusCreditUsePercent
FROM Trade.InstrumentNWADecreasePercentage WITH (NOLOCK)
WHERE InstrumentID IN (1, 2, 3)
```

### 8.2 Instruments with NWA impact
```sql
SELECT InstrumentID, BonusCreditUsePercent
FROM Trade.InstrumentNWADecreasePercentage WITH (NOLOCK)
WHERE BonusCreditUsePercent IS NOT NULL AND BonusCreditUsePercent > 0
ORDER BY InstrumentID
```

### 8.3 NWA calculation input by instrument
```sql
SELECT v.InstrumentID, v.BonusCreditUsePercent
FROM Trade.InstrumentNWADecreasePercentage v WITH (NOLOCK)
JOIN Trade.Instrument i WITH (NOLOCK) ON v.InstrumentID = i.InstrumentID
WHERE v.BonusCreditUsePercent IS NOT NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentNWADecreasePercentage | Type: View | Source: etoro/etoro/Trade/Views/Trade.InstrumentNWADecreasePercentage.sql*
