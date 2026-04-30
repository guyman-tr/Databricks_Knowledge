# Hedge.GetInstrumentsIsTradeable

> Returns the tradability flag for all instruments from Trade.GetInstrumentMetaData view. No parameters; full view read of 2 columns (InstrumentID, IsTradable). The hedge engine uses this to skip execution for non-tradeable instruments.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | None - no parameters, returns all instruments |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Hedge.GetInstrumentsIsTradeable returns the per-instrument tradability flag (`IsTradable`) for all instruments. The hedge engine calls this at startup (or on refresh) to know which instruments are currently tradeable so it can skip hedge order processing for non-tradeable instruments (e.g., instruments that have been suspended, delisted, or temporarily halted).

The procedure reads from `Trade.GetInstrumentMetaData` - a view that provides consumer-friendly aliases for Trade.InstrumentMetaData columns (`Tradable` -> `IsTradable`, `InstrumentVisible` -> `IsVisible`, etc.). The view exposes the full metadata row but this procedure only needs InstrumentID and IsTradable.

Cross-schema read (Trade schema view consumed by Hedge schema procedure) - a common pattern in the eToro architecture where the Hedge schema contains service-layer procedures while the Trade schema owns the core instrument entities.

---

## 2. Business Logic

### 2.1 IsTradable Flag Semantics

**What**: IsTradable controls whether the instrument is available for trade execution.

**Columns/Parameters Involved**: `IsTradable`

**Rules**:
- IsTradable = 1: instrument is live and available for hedge order processing.
- IsTradable = 0: instrument is non-tradeable (suspended, delisted, expired contract, or pending activation).
- The hedge engine uses this flag to skip exposure calculation and order dispatch for non-tradeable instruments.
- The underlying column in Trade.InstrumentMetaData is `Tradable` (bit); the view aliases it as `IsTradable`.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Output Columns** (2 of ~15 Trade.GetInstrumentMetaData columns):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | eToro instrument identifier. All instruments from Trade.GetInstrumentMetaData are returned. |
| 2 | IsTradable | bit | NO | - | CODE-BACKED | 1 = instrument is live and tradeable by the hedge engine. 0 = instrument is suspended, delisted, or non-active. Aliased from Trade.InstrumentMetaData.Tradable by the GetInstrumentMetaData view. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| 2-column read | Trade.GetInstrumentMetaData | Cross-schema Lookup (View) | InstrumentID + IsTradable. All instruments. No WHERE filter. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge engine (external) | Result set | Caller | Loads tradability flags at startup to skip non-tradeable instruments. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetInstrumentsIsTradeable (procedure)
└── Trade.GetInstrumentMetaData (view) [cross-schema]
    └── Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrumentMetaData | View | Cross-schema: 2 columns selected (InstrumentID, IsTradable). All rows. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge engine (external) | Application | Startup load of tradability flags for execution filtering. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

No NOLOCK (reading from a view, isolation depends on underlying table settings). No temp tables. No parameters. Simple cross-schema view read of 2 columns.

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC Hedge.GetInstrumentsIsTradeable;
```

### 8.2 Count tradeable vs non-tradeable instruments

```sql
SELECT IsTradable, COUNT(*) AS InstrumentCount
FROM   Trade.GetInstrumentMetaData
GROUP BY IsTradable;
```

### 8.3 Find recently non-tradeable instruments

```sql
SELECT InstrumentID, IsTradable
FROM   Trade.GetInstrumentMetaData
WHERE  IsTradable = 0
ORDER BY InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HedgeServer Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11710727812) | Confluence (DROD) | Instrument tradability filtering in hedge execution pipeline. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,9B,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos searched / 0 files matched | Corrections: 0 applied*
*Object: Hedge.GetInstrumentsIsTradeable | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetInstrumentsIsTradeable.sql*
