# Trade.GetTraderDisplayableInstrumentDataForAPI

> Returns InstrumentIDs for all enabled, trader-displayable instruments from the primary provider (ProviderID=1), ordered by InstrumentID. No parameters.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (no parameters) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the list of instruments that are visible to traders in the eToro platform UI. It filters `Trade.ProviderToInstrument` to the primary provider (ProviderID=1, Tradonomi) and returns only those instruments that are:
1. **Enabled** (`Enabled=1`): actively tradeable through the provider
2. **Displayable** (`DisplayOrder > 0`): explicitly marked for display in the trader-facing UI

`DisplayOrder > 0` is the key filter. A DisplayOrder of 0 or negative means the instrument is configured in the system but should not be shown to traders - it may be internal-only, deprecated, or not yet launched. Only instruments with DisplayOrder > 0 are eligible for the trader-facing API response.

The procedure is named "ForAPI" because it is called by the trading API to populate the list of available instruments in the trader's instrument browser/search. The result is a simple list of InstrumentIDs; the API layer enriches these with additional instrument metadata from Trade.InstrumentMetaData or other sources.

Note: `VisibleInternallyOnly=1` instruments (from ProviderToInstrument) would have Enabled=1 but are typically filtered by DisplayOrder or other logic in the UI layer.

---

## 2. Business Logic

### 2.1 Enabled + Displayable Instrument Filter

**What**: Returns all instruments tradeable through the primary provider that are marked for display to traders.

**Columns/Parameters Involved**: `ProviderID`, `Enabled`, `DisplayOrder`

**Rules**:
- `ProviderID = 1`: Tradonomi - the primary execution provider for eToro
- `Enabled = 1`: instrument is actively available for trading (not suspended, not decommissioned)
- `DisplayOrder > 0`: instrument is in the trader-displayable set; instruments with DisplayOrder=0 are hidden from the UI
- `ORDER BY InstrumentID`: deterministic, stable ordering for the API response
- No additional filters (no InstrumentTypeID, no exchange, no asset class) -> complete displayable instrument set

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Output Columns**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | INT | NO | - | CODE-BACKED | Unique instrument identifier for a displayable, enabled instrument on the primary provider. FK to Trade.Instrument. The API consumer uses this list to determine which instruments to show in the trader's instrument browser. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.ProviderToInstrument | Reader | SELECT InstrumentID WHERE ProviderID=1 AND DisplayOrder>0 AND Enabled=1; NOLOCK |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trading API service | (none) | Application call | Loads the set of trader-displayable instruments at startup or on cache refresh |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetTraderDisplayableInstrumentDataForAPI (procedure)
+-- Trade.ProviderToInstrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | SELECT InstrumentID WHERE ProviderID=1 AND DisplayOrder>0 AND Enabled=1; NOLOCK; ORDER BY InstrumentID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trading API / instrument browser service | External application | Loads displayable instrument list for the trader UI |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK | Isolation hint | READ UNCOMMITTED; acceptable for instrument configuration reads |
| ProviderID = 1 | Business filter | Hardcoded to primary provider (Tradonomi); assumes single primary provider for display purposes |
| DisplayOrder > 0 | Business filter | Key displayability gate; excludes hidden/internal instruments |
| Enabled = 1 | Business filter | Excludes disabled/suspended instruments |
| ORDER BY InstrumentID | Sort | Deterministic ordering for stable API responses |

---

## 8. Sample Queries

### 8.1 Get all trader-displayable instruments

```sql
EXEC Trade.GetTraderDisplayableInstrumentDataForAPI;
```

### 8.2 Count of displayable instruments

```sql
SELECT COUNT(*) AS DisplayableInstruments
FROM Trade.ProviderToInstrument WITH (NOLOCK)
WHERE ProviderID = 1 AND DisplayOrder > 0 AND Enabled = 1;
```

### 8.3 Check if a specific instrument is displayable

```sql
SELECT CASE WHEN EXISTS (
    SELECT 1 FROM Trade.ProviderToInstrument WITH (NOLOCK)
    WHERE ProviderID = 1 AND InstrumentID = 1 AND DisplayOrder > 0 AND Enabled = 1
) THEN 'Displayable' ELSE 'Hidden or Disabled' END AS Status;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetTraderDisplayableInstrumentDataForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetTraderDisplayableInstrumentDataForAPI.sql*
