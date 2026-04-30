# Trade.InstrumentMaxPositionUnits

> Projection of InstrumentID and MaxPositionUnits from Trade.ProviderToInstrument (one row per provider-instrument) for position size limits and config display.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InstrumentMaxPositionUnits exposes the maximum allowed position size in units per instrument. It is a thin projection from Trade.ProviderToInstrument, providing the cap that validates new positions and order size. This view supports risk limits (Monitor.AlertForTradingConfigurationManager validates MaxPositionUnits * Bid * USDConversionRateBidSpreaded against asset-class limits), operational config display, and the Trade.UpdateInstrumentsMaxPositionUnits procedure's config table shape (Trade.InstrumentMaxPositionUnitsConfigTable).

Without this view, callers would query ProviderToInstrument directly. The view provides a simplified interface when only InstrumentID and MaxPositionUnits are needed. The view returns one row per (ProviderID, InstrumentID) in ProviderToInstrument.

---

## 2. Business Logic

### 2.1 Max Position Units Projection

**What**: Expose InstrumentID and MaxPositionUnits from ProviderToInstrument for validation and config.

**Columns/Parameters Involved**: `InstrumentID`, `MaxPositionUnits`

**Rules**:
- Direct SELECT from Trade.ProviderToInstrument with no filters.
- One row per (ProviderID, InstrumentID) in ProviderToInstrument.
- MaxPositionUnits is decimal(18,4), nullable. CHECK constraint on base table: MaxPositionUnits <= 2147483647.
- Used by Monitor.AlertForTradingConfigurationManager (via ProviderToInstrument, not this view) to validate (MaxPositionUnits * Bid * USDConversionRateBidSpreaded) against asset-class USD limits.
- Trade.UpdateInstrumentsMaxPositionUnits updates ProviderToInstrument.MaxPositionUnits from config table; also inserts into Trade.SyncConfiguration for ConfigurationUpdateTypeID=4.

**Diagram**:
```
Trade.ProviderToInstrument (ProviderID, InstrumentID, MaxPositionUnits, ...)
    |
    v
Trade.InstrumentMaxPositionUnits (InstrumentID, MaxPositionUnits)
```

---

## 3. Data Overview

| InstrumentID | MaxPositionUnits | Meaning |
|--------------|-----------------|---------|
| 1 | 2147483647 | EUR/USD: effectively unlimited (max int) |
| 2 | 2000000 | GBP: 2M unit cap |
| 3 | 2000000 | NZD/USD: same |
| 4 | 2000000 | Same pattern |
| 5 | 2000000 | Same pattern |

**Selection criteria for the 5 rows:** TOP 5 from live query. InstrumentID 1 has max cap (2147483647); others show 2000000. NULL possible when ProviderToInstrument.MaxPositionUnits is NULL.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. From ProviderToInstrument. Identifies the tradeable instrument. |
| 2 | MaxPositionUnits | decimal(18,4) | YES | - | CODE-BACKED | Maximum position size in units. From ProviderToInstrument.MaxPositionUnits. CHECK <= 2147483647. Used for order validation and risk limits. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit FK | Via ProviderToInstrument.InstrumentID |

### 5.2 Base Tables (FROM)

| Table | How Used |
|-------|----------|
| Trade.ProviderToInstrument | Direct SELECT of InstrumentID, MaxPositionUnits |

### 5.3 Referenced By (other objects point to this)

| Source Object | Role | Description |
|---------------|------|-------------|
| Trade.InstrumentMaxPositionUnitsConfigTable | UDT | Table-valued type with InstrumentID, ConfigurationValue; used by UpdateInstrumentsMaxPositionUnits |
| Trade.UpdateInstrumentsMaxPositionUnits | MODIFIER | Updates ProviderToInstrument.MaxPositionUnits from config table; does not read this view |

*Note: Monitor.AlertForTradingConfigurationManager reads ProviderToInstrument directly for MaxPositionUnits validation, not this view. The view provides a read interface for config display or simple lookups.*

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InstrumentMaxPositionUnits (view)
    |
    +-- Trade.ProviderToInstrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | FROM - source of InstrumentID, MaxPositionUnits |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMaxPositionUnitsConfigTable | UDT | Config shape for bulk update |
| Trade.UpdateInstrumentsMaxPositionUnits | Procedure | Updates base table; config table provides InstrumentID + ConfigurationValue |

---

## 7. Technical Details

### 7.1 DDL Summary

- **Base table**: Trade.ProviderToInstrument
- **Logic**: SELECT InstrumentID, MaxPositionUnits. No WHERE, no JOINs.
- **Output**: InstrumentID, MaxPositionUnits. Row count = ProviderToInstrument row count (one per provider-instrument).

### 7.2 Column Sources

| Output Column | Source Table | Source Column |
|---------------|--------------|---------------|
| InstrumentID | Trade.ProviderToInstrument | InstrumentID |
| MaxPositionUnits | Trade.ProviderToInstrument | MaxPositionUnits |

---

## 8. Sample Queries

### 8.1 Get max position units for instruments
```sql
SELECT InstrumentID, MaxPositionUnits
FROM Trade.InstrumentMaxPositionUnits WITH (NOLOCK)
WHERE InstrumentID IN (1, 2, 3)
ORDER BY InstrumentID;
```

### 8.2 Instruments with non-default cap
```sql
SELECT InstrumentID, MaxPositionUnits
FROM Trade.InstrumentMaxPositionUnits WITH (NOLOCK)
WHERE MaxPositionUnits IS NOT NULL AND MaxPositionUnits < 2147483647
ORDER BY MaxPositionUnits, InstrumentID;
```

### 8.3 Join with instrument metadata for display
```sql
SELECT impu.InstrumentID, imd.InstrumentDisplayName, imd.SymbolFull,
       impu.MaxPositionUnits
FROM Trade.InstrumentMaxPositionUnits impu WITH (NOLOCK)
JOIN Trade.InstrumentMetaData imd WITH (NOLOCK) ON impu.InstrumentID = imd.InstrumentID
WHERE imd.Tradable = 1
ORDER BY impu.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentMaxPositionUnits | Type: View | Source: etoro/etoro/Trade/Views/Trade.InstrumentMaxPositionUnits.sql*
