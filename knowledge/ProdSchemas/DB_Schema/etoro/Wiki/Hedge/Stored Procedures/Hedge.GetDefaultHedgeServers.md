# Hedge.GetDefaultHedgeServers

> Returns two result sets for hedge server default routing: (1) per-instrument-type default server assignments from Hedge.InstrumentTypeConfiguration; (2) the system-wide fallback HedgeServerID from Maintenance.Feature FeatureID=102. Used by the hedge engine to establish default server routing when no specific assignment exists.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns all instrument type defaults and the system-wide feature flag |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure loads the hedge engine's default server routing configuration at two granularity levels:

1. **Per-instrument-type defaults** (first result set): `Hedge.InstrumentTypeConfiguration` maps each asset class (Forex, Stocks, Crypto, etc.) to a default HedgeServerID. When the hedge engine needs to assign a server for an instrument and no per-instrument configuration exists, it looks up the instrument's asset class and uses this type-level fallback.

2. **System-wide fallback** (second result set): `Maintenance.Feature FeatureID=102` (Description: "Default value for HedgeServerID for PositionOpen", Value=1) provides the ultimate fallback HedgeServerID for position open routing when no per-instrument or per-type assignment applies.

Together these two values form a three-level fallback hierarchy for hedge server assignment:
- Level 1: Per-instrument configuration (most specific)
- Level 2: Per-instrument-type default (`Hedge.InstrumentTypeConfiguration`)
- Level 3: System-wide default (Feature FeatureID=102, currently HedgeServerID=1)

**Current state**: `Hedge.InstrumentTypeConfiguration` has 0 rows, so only the system-wide Feature fallback (Level 3) is active. The type-based routing layer (Level 2) is designed but undeployed.

---

## 2. Business Logic

### 2.1 Instrument Type Default Routing (First Result Set)

**What**: Returns the per-asset-class default HedgeServerID mapping.

**Columns/Parameters Involved**: `InstrumentTypeID`, `DefaultHedgeServerID`

**Rules**:
- SELECT all rows from `Hedge.InstrumentTypeConfiguration` (no filter)
- No NOLOCK hint - default READ COMMITTED
- Currently returns 0 rows - table is empty in this environment
- `InstrumentTypeID` maps to `Dictionary.CurrencyType`: 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto
- When populated, hedge engine uses this to route: "all Stocks instruments default to HedgeServerID X"

### 2.2 System-Wide Fallback Default (Second Result Set)

**What**: Returns the `Value` from `Maintenance.Feature` where `FeatureID=102` - the ultimate fallback HedgeServerID.

**Columns/Parameters Involved**: `Maintenance.Feature.FeatureID`, `Value`

**Rules**:
- `SELECT Value FROM Maintenance.Feature WHERE FeatureID = 102`
- `FeatureID=102` = "Default value for HedgeServerID for PositionOpen" (current description)
- Current value: **1** (HedgeServerID=1 is the default when no type or per-instrument assignment applies)
- Returns a single-row, single-column result set: just `Value`
- The hedge engine uses this as the last-resort fallback for position open server routing

### 2.3 Two-Result-Set Pattern

**What**: The procedure always returns exactly two result sets in order.

**Rules**:
- First result set: InstrumentTypeID + DefaultHedgeServerID pairs (0 rows currently)
- Second result set: single Value row from Maintenance.Feature (always 1 row)
- Callers must consume both result sets in order

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | CODE-BACKED | No input parameters. Returns two result sets for hedge engine default server routing configuration. |

**Output Columns (First Result Set - InstrumentTypeConfiguration)**:

| Column | Source | Description |
|--------|--------|-------------|
| InstrumentTypeID | Hedge.InstrumentTypeConfiguration | Asset class identifier. FK to Dictionary.CurrencyType (1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto). Currently 0 rows. |
| DefaultHedgeServerID | Hedge.InstrumentTypeConfiguration | The hedge server to route all instruments of this type to by default. FK to Trade.HedgeServer. |

**Output Columns (Second Result Set - Maintenance.Feature FeatureID=102)**:

| Column | Source | Description |
|--------|--------|-------------|
| Value | Maintenance.Feature | The system-wide default HedgeServerID for PositionOpen routing. Current value: 1. This is the ultimate fallback when no per-instrument or per-type assignment exists. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source 1 | Hedge.InstrumentTypeConfiguration | Direct read | Per-instrument-type default server assignments; returns all rows (currently 0) |
| SELECT source 2 | Maintenance.Feature | Direct read (FeatureID=102) | System-wide fallback HedgeServerID for PositionOpen; currently Value=1 |

### 5.2 Referenced By (other objects point to this)

No SQL-level callers found. Called by the hedge engine on startup to load its default server routing configuration.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetDefaultHedgeServers (procedure)
├── Hedge.InstrumentTypeConfiguration (table) - SELECT InstrumentTypeID, DefaultHedgeServerID
└── Maintenance.Feature (table) - SELECT Value WHERE FeatureID=102
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.InstrumentTypeConfiguration | Table | SELECT InstrumentTypeID, DefaultHedgeServerID - all rows (currently empty) |
| Maintenance.Feature | Table | SELECT Value WHERE FeatureID=102 - system-wide default HedgeServerID fallback (currently Value=1) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row count messages |
| No NOLOCK | Isolation | Uses default READ COMMITTED on both source tables |
| Two result sets | Output | Always returns 2 result sets. Callers must consume both in order (type mappings first, feature flag second). |
| FeatureID=102 hardcoded | Design | The feature flag lookup is tightly coupled to FeatureID=102. If this row is removed from Maintenance.Feature, the second result set returns empty. |
| Empty first result set | Current State | Hedge.InstrumentTypeConfiguration has 0 rows - first result set is always empty until populated |

---

## 8. Sample Queries

### 8.1 View instrument type default server mapping

```sql
SELECT InstrumentTypeID, DefaultHedgeServerID
FROM Hedge.InstrumentTypeConfiguration WITH (NOLOCK)
ORDER BY InstrumentTypeID
```

### 8.2 Check the system-wide default HedgeServerID

```sql
SELECT FeatureID, Value, Description
FROM Maintenance.Feature WITH (NOLOCK)
WHERE FeatureID = 102
```

### 8.3 Cross-reference instrument types with their configured defaults

```sql
SELECT ct.CurrencyTypeID, ct.CurrencyTypeName,
       itc.DefaultHedgeServerID,
       hs.HedgeServerName
FROM Dictionary.CurrencyType ct WITH (NOLOCK)
LEFT JOIN Hedge.InstrumentTypeConfiguration itc WITH (NOLOCK)
       ON ct.CurrencyTypeID = itc.InstrumentTypeID
LEFT JOIN Trade.HedgeServer hs WITH (NOLOCK)
       ON itc.DefaultHedgeServerID = hs.HedgeServerID
ORDER BY ct.CurrencyTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetDefaultHedgeServers | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetDefaultHedgeServers.sql*
