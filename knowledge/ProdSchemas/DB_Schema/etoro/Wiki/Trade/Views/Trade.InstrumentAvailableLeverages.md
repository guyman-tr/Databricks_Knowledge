# Trade.InstrumentAvailableLeverages

> One-row-per-instrument view of min/max/default leverage IDs derived from Trade.ProviderInstrumentToLeverage via Dictionary.Leverage.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InstrumentAvailableLeverages exposes the aggregated leverage range per instrument: the minimum leverage ID, maximum leverage ID, and default leverage ID that users can select when opening positions. It is derived from Trade.ProviderInstrumentToLeverage by aggregating across all providers and mapping numeric leverage values to Dictionary.Leverage IDs. This view enables validation (e.g., max leverage per asset class in Monitor.AlertForTradingConfigurationManager) and operational config display without joining multiple tables each time.

Without this view, callers would need to aggregate ProviderInstrumentToLeverage grouped by InstrumentID, join to Dictionary.Leverage for min/max values, and separately resolve the default. The view encapsulates that logic and provides a simple one-row-per-instrument interface.

---

## 2. Business Logic

### 2.1 Leverage Range per Instrument

**What**: For each instrument, compute the minimum and maximum available leverage values across all providers, and resolve the default leverage when the user does not specify one.

**Columns/Parameters Involved**: `InstrumentID`, `MinLeverageID`, `MaxLeverageID`, `DefaultLeverageID`

**Rules**:
- Base data: Trade.ProviderInstrumentToLeverage joined to Dictionary.Leverage on LeverageID.
- Min/Max: GROUP BY InstrumentID, MIN(DL.Value), MAX(DL.Value). The Value column in Dictionary.Leverage holds the numeric leverage (1, 2, 5, 10, 20, 30, 50, 100, 200, 400).
- Default: Subquery filters TPL.IsDefault = 1 and returns the corresponding LeverageID.
- Resolve IDs: JOIN back to Dictionary.Leverage to map MinLeverage Value -> MinLeverageID, MaxLeverage Value -> MaxLeverageID.
- DefaultLeverageID may be NULL when no row has IsDefault=1 for that instrument (LEFT JOIN on default subquery).

**Diagram**:
```
ProviderInstrumentToLeverage (InstrumentID, LeverageID, IsDefault)
    |
    v
Dictionary.Leverage (LeverageID, Value)
    |
    v
Aggregate: MIN(Value), MAX(Value) per InstrumentID
JOIN for DefaultLeverageID where IsDefault=1
    |
    v
InstrumentAvailableLeverages (InstrumentID, MinLeverageID, MaxLeverageID, DefaultLeverageID)
```

---

## 3. Data Overview

| InstrumentID | MinLeverageID | MaxLeverageID | DefaultLeverageID | Meaning |
|--------------|---------------|---------------|-------------------|---------|
| 1589 | 1 | 11 | 1 | Min=1x, Max=20x (LeverageID 11), Default=1x |
| 2917 | 1 | 11 | 1 | Same leverage tier pattern |
| 5834 | 1 | 11 | 1 | Same pattern |
| 10079 | 1 | 11 | 1 | Same pattern |
| 14324 | 1 | 11 | 1 | Same pattern |

**Selection criteria for the 5 rows:** TOP 5 from live query. All samples show MinLeverageID=1 (1x), MaxLeverageID=11 (20x per Dictionary.Leverage), DefaultLeverageID=1. NULL patterns: DefaultLeverageID can be NULL when no default is set.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. Identifies the tradeable instrument. From ProviderInstrumentToLeverage GROUP BY. |
| 2 | MinLeverageID | int | NO | - | CODE-BACKED | FK to Dictionary.Leverage. Lowest leverage tier available for this instrument across all providers. Resolved from MIN(DL.Value) -> Dictionary.Leverage.LeverageID. |
| 3 | MaxLeverageID | int | NO | - | CODE-BACKED | FK to Dictionary.Leverage. Highest leverage tier available. Resolved from MAX(DL.Value). |
| 4 | DefaultLeverageID | int | YES | - | CODE-BACKED | FK to Dictionary.Leverage. Leverage offered when user does not specify. From ProviderInstrumentToLeverage where IsDefault=1. NULL when no default row exists. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit FK | Via ProviderInstrumentToLeverage.InstrumentID |
| MinLeverageID | Dictionary.Leverage | FK | Min leverage tier |
| MaxLeverageID | Dictionary.Leverage | FK | Max leverage tier |
| DefaultLeverageID | Dictionary.Leverage | FK | Default leverage tier |

### 5.2 Base Tables (FROM/JOIN)

| Table | Alias | Join Condition |
|-------|-------|----------------|
| Trade.ProviderInstrumentToLeverage | TPL | Base source for InstrumentID, LeverageID, IsDefault |
| Dictionary.Leverage | DL, MINL, MAXL | TPL.LeverageID = DL.LeverageID; MINL.Value = MinLeverage; MAXL.Value = MaxLeverage |

### 5.3 Referenced By (other objects point to this)

| Source Object | Role | Description |
|---------------|------|-------------|
| Monitor.AlertForTradingConfigurationManager | READER | Validates max leverage per InstrumentTypeID vs asset-class limits |
| Monitor.AlertForTradingConfigurationManager_DataDog | READER | Same validation, returns count of violations |
| Trade.InstrumentAvailableLeveragesConfigTable | UDT | Table-valued type shaped like view output; used by UpdateInstrumentsAvailableLeverages |
| Trade.UpdateInstrumentsAvailableLeverages | MODIFIER | Updates ProviderInstrumentToLeverage using config shaped like this view |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InstrumentAvailableLeverages (view)
    |
    +-- Trade.ProviderInstrumentToLeverage (table)
    |
    +-- Dictionary.Leverage (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderInstrumentToLeverage | Table | FROM/JOIN for leverage tiers per instrument |
| Dictionary.Leverage | Table | Resolve LeverageID from Value; min/max/default IDs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Monitor.AlertForTradingConfigurationManager | Procedure | FROM - max leverage validation |
| Monitor.AlertForTradingConfigurationManager_DataDog | Procedure | FROM - count of config violations |
| Trade.InstrumentAvailableLeveragesConfigTable | UDT | Same column shape for config input |
| Trade.UpdateInstrumentsAvailableLeverages | Procedure | Consumes config table, modifies ProviderInstrumentToLeverage |

---

## 7. Technical Details

### 7.1 DDL Summary

- **Base tables**: Trade.ProviderInstrumentToLeverage, Dictionary.Leverage
- **Logic**: Subquery t1 = GROUP BY InstrumentID, MIN(DL.Value), MAX(DL.Value). Subquery t2 = default LeverageID where IsDefault=1. LEFT JOIN t2 on InstrumentID. JOIN Dictionary.Leverage MINL on MinLeverage = MINL.Value, JOIN MAXL on MaxLeverage = MAXL.Value.
- **Output**: InstrumentID, MinLeverageID, MaxLeverageID, DefaultLeverageID

### 7.2 Column Sources

| Output Column | Source Table | Source Column / Expression |
|---------------|--------------|----------------------------|
| InstrumentID | t1 | InstrumentID |
| MinLeverageID | MINL | LeverageID (where MINL.Value = t1.MinLeverage) |
| MaxLeverageID | MAXL | LeverageID (where MAXL.Value = t1.MaxLeverage) |
| DefaultLeverageID | t2 | LeverageID (from IsDefault=1 subquery; NULL if no default) |

---

## 8. Sample Queries

### 8.1 Get leverage range for an instrument
```sql
SELECT avail.InstrumentID, dl_min.Value AS MinLeverage, dl_max.Value AS MaxLeverage,
       avail.DefaultLeverageID, dl_def.Value AS DefaultLeverageValue
FROM Trade.InstrumentAvailableLeverages avail WITH (NOLOCK)
JOIN Dictionary.Leverage dl_min WITH (NOLOCK) ON avail.MinLeverageID = dl_min.LeverageID
JOIN Dictionary.Leverage dl_max WITH (NOLOCK) ON avail.MaxLeverageID = dl_max.LeverageID
LEFT JOIN Dictionary.Leverage dl_def WITH (NOLOCK) ON avail.DefaultLeverageID = dl_def.LeverageID
WHERE avail.InstrumentID = 1;
```

### 8.2 Instruments with no default leverage
```sql
SELECT avail.InstrumentID, avail.MinLeverageID, avail.MaxLeverageID
FROM Trade.InstrumentAvailableLeverages avail WITH (NOLOCK)
WHERE avail.DefaultLeverageID IS NULL
ORDER BY avail.InstrumentID;
```

### 8.3 Join with InstrumentMetaData for validation
```sql
SELECT avail.InstrumentID, meta.InstrumentDisplayName, meta.InstrumentTypeID,
       avail.MinLeverageID, avail.MaxLeverageID, avail.DefaultLeverageID,
       dl.Value AS MaxLeverageValue
FROM Trade.InstrumentAvailableLeverages avail WITH (NOLOCK)
JOIN Trade.InstrumentMetaData meta WITH (NOLOCK) ON avail.InstrumentID = meta.InstrumentID
JOIN Dictionary.Leverage dl WITH (NOLOCK) ON avail.MaxLeverageID = dl.LeverageID
WHERE meta.Tradable = 1
ORDER BY avail.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| DWH Process Data Sources | Confluence | May reference instrument/leverage data flows |
| DWH user guide - Dim_Instrument | Confluence | May reference instrument dimensions |

*Note: No direct Confluence pages found for "InstrumentAvailableLeverages". Above are text-search hits that may mention instrument or leverage in related context.*

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentAvailableLeverages | Type: View | Source: etoro/etoro/Trade/Views/Trade.InstrumentAvailableLeverages.sql*
