# Trade.TradableInstrumentMaxRateDiffPercentage

> Filtered projection of AllowedRateDiffPercentage for tradable instruments only (InstrumentMetaData.Tradable=1), used by price feed validation for currently active instruments.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.TradableInstrumentMaxRateDiffPercentage exposes the maximum allowed rate difference percentage per instrument for instruments that are currently tradable (InstrumentMetaData.Tradable = 1). Unlike Trade.InstrumentMaxRateDiffPercentage which returns all instruments from ProviderToInstrument, this view filters to only those that are actively tradable. Each row provides InstrumentID and AllowedRateDiffPercentage - the threshold used by price feed validation to flag instruments where the incoming rate deviates too far from the last known rate.

This view exists because price feed validation should only apply rate-diff checks to instruments that are currently tradable. Non-tradable or retired instruments may have stale config and should not trigger validation logic. The JOIN to InstrumentMetaData with Tradable=1 ensures only active instruments are included. Used by price feed validation for currently active instruments.

The view performs an INNER JOIN of Trade.ProviderToInstrument and Trade.InstrumentMetaData on InstrumentID, filtered by imd.Tradable = 1. Both tables use WITH (NOLOCK). Output columns: InstrumentID, AllowedRateDiffPercentage.

---

## 2. Business Logic

Filtered projection. INNER JOIN ProviderToInstrument and InstrumentMetaData on InstrumentID. WHERE InstrumentMetaData.Tradable = 1. Select pti.InstrumentID, pti.AllowedRateDiffPercentage. Excludes instruments that are not tradable (retired, disabled, or not yet active).

---

## 3. Data Overview

N/A - output is filtered projection from Trade.ProviderToInstrument and Trade.InstrumentMetaData. See [Trade.ProviderToInstrument](../Tables/Trade.ProviderToInstrument.md) and [Trade.InstrumentMetaData](../Tables/Trade.InstrumentMetaData.md) for base semantics.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. Tradable instrument identifier. |
| 2 | AllowedRateDiffPercentage | decimal(18,8) | YES | - | CODE-BACKED | Maximum allowed percentage difference between incoming rate and last known rate. Used by price feed validation to flag instruments where deviation exceeds threshold. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit FK | Via ProviderToInstrument and InstrumentMetaData |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TradableInstrumentMaxRateDiffPercentage (view)
    |
    +-- Trade.ProviderToInstrument (table)
    |
    +-- Trade.InstrumentMetaData (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | FROM - source of InstrumentID, AllowedRateDiffPercentage |
| Trade.InstrumentMetaData | Table | INNER JOIN - filter Tradable=1 |

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

### 8.1 Rate diff thresholds for all tradable instruments

```sql
SELECT InstrumentID, AllowedRateDiffPercentage
FROM Trade.TradableInstrumentMaxRateDiffPercentage WITH (NOLOCK);
```

### 8.2 Lookup threshold for price validation

```sql
SELECT AllowedRateDiffPercentage
FROM Trade.TradableInstrumentMaxRateDiffPercentage WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID;
```

### 8.3 Instruments with custom rate diff threshold

```sql
SELECT InstrumentID, AllowedRateDiffPercentage
FROM Trade.TradableInstrumentMaxRateDiffPercentage WITH (NOLOCK)
WHERE AllowedRateDiffPercentage <> 90;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 8.6/10, Relationships: 8.6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TradableInstrumentMaxRateDiffPercentage | Type: View | Source: etoro/etoro/Trade/Views/Trade.TradableInstrumentMaxRateDiffPercentage.sql*
