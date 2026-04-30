# Hedge.GetAllInstrumentActivity

> Returns all (HedgeServerID, InstrumentID) pairs in the hedge instrument blocklist - instruments currently suppressed from hedging activity on each server.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns full blocklist from Hedge.InactiveInstruments |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Despite its name ("GetAll**Instrument**Activity"), this procedure returns the **inactive** instruments - those currently suppressed from hedging. Each row returned identifies a (HedgeServerID, InstrumentID) pair that is on the hedge blocklist. The hedge server uses this list to skip exposure processing for those instruments.

The procedure reads from `Hedge.InactiveInstruments`, which is the hedge server's instrument suppression list. An instrument is suppressed when the Dealing Room explicitly disables hedging for it - due to market disruption, operational reasons, or testing.

The procedure runs with `SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED` (equivalent to `WITH (NOLOCK)`), appropriate for configuration data reads on a potentially high-frequency call path.

---

## 2. Business Logic

### 2.1 Blocklist-Based Activity Model

**What**: The procedure returns all instruments that are INACTIVE (suppressed). Instruments NOT in this result are active and should be hedged normally.

**Rules**:
- A (HedgeServerID, InstrumentID) pair present in the result = hedging is SUPPRESSED for that combination
- Absence from the result = instrument is ACTIVE and hedging proceeds normally
- Currently 6 rows total: 3 instruments on server 1, 1 on server 8, 2 on server 1100 (per InactiveInstruments doc)
- The name "GetAllInstrumentActivity" is misleading - it specifically returns the inactive/suppressed list

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | CODE-BACKED | No input parameters. Returns all rows from `Hedge.InactiveInstruments` without filtering. The hedge engine uses this list to build its in-memory suppression set at startup or on refresh. |

**Output Columns**:

| Column | Source | Description |
|--------|--------|-------------|
| HedgeServerID | Hedge.InactiveInstruments | The hedge server for which hedging is suppressed |
| InstrumentID | Hedge.InactiveInstruments | The instrument that is blocked from hedging on this server |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Hedge.InactiveInstruments | Direct read | Returns the complete hedge blocklist (HedgeServerID, InstrumentID pairs) |

### 5.2 Referenced By (other objects point to this)

No SQL-level callers found. Called by the hedge engine to load its instrument suppression list.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetAllInstrumentActivity (procedure)
└── Hedge.InactiveInstruments (table) - SELECT source
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.InactiveInstruments | Table | SELECT HedgeServerID, InstrumentID - all rows (no filter) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| READ UNCOMMITTED | Isolation | SET TRAN ISOLATION LEVEL READ UNCOMMITTED - dirty reads allowed |
| Naming note | Documentation | Name "GetAllInstrumentActivity" is misleading - the procedure returns InactiveInstruments (the blocklist), not all instrument activity status |

---

## 8. Sample Queries

### 8.1 View current instrument suppression list

```sql
SELECT HedgeServerID, InstrumentID
FROM Hedge.InactiveInstruments WITH (NOLOCK)
ORDER BY HedgeServerID, InstrumentID
```

### 8.2 Check if a specific instrument is suppressed on any server

```sql
SELECT HedgeServerID, InstrumentID
FROM Hedge.InactiveInstruments WITH (NOLOCK)
WHERE InstrumentID = 1
```

### 8.3 Count suppressed instruments per server

```sql
SELECT HedgeServerID, COUNT(*) AS SuppressedInstruments
FROM Hedge.InactiveInstruments WITH (NOLOCK)
GROUP BY HedgeServerID
ORDER BY HedgeServerID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetAllInstrumentActivity | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetAllInstrumentActivity.sql*
