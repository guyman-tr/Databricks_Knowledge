# Hedge.HedgeServerInstrumentActivity

> Returns the list of suppressed (inactive) instrument IDs for a specific hedge server, used at startup or on config reload to determine which instruments to skip during hedging.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: InstrumentID column (list of inactive instrument IDs) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.HedgeServerInstrumentActivity` retrieves the hedge server's instrument suppression (blocklist) for a given server. The hedge server calls this procedure at startup or on configuration reload to learn which instruments to skip when processing hedging exposure.

The result is a simple single-column result set of InstrumentIDs that are currently inactive on the requested server. Any InstrumentID returned here will not be hedged on that server - the hedge server suppresses exposure processing for these instruments. Instruments not in the result set are considered active and hedged normally. This is a presence-means-inactive model: the table stores only exceptions, not the full instrument list.

The procedure operates with READ UNCOMMITTED isolation (`SET TRAN ISOLATION LEVEL READ UNCOMMITTED`), which is appropriate for a configuration read where near-real-time staleness is acceptable and locking the configuration table during hedge server startup would be undesirable.

---

## 2. Business Logic

### 2.1 Blocklist Read

**What**: Returns all instruments currently suppressed on the given hedge server.

**Columns/Parameters Involved**: `@HedgeServerID`, `InstrumentID`

**Rules**:
- Filters `Hedge.InactiveInstruments` by `HedgeServerID = @HedgeServerID`.
- Returns only the `InstrumentID` column - callers need only the IDs, not metadata.
- READ UNCOMMITTED isolation ensures the startup read is non-blocking.
- An empty result set means all instruments are active on that server (no suppressions configured).
- A non-empty result set means hedging is disabled for those instruments on this server.

**Diagram**:
```
Hedge Server startup/reload
  |
  EXEC Hedge.HedgeServerInstrumentActivity(@HedgeServerID)
  |
  SELECT InstrumentID FROM Hedge.InactiveInstruments WHERE HedgeServerID = @HedgeServerID
  |
  Result: [InstrumentID1, InstrumentID2, ...]  (or empty if no suppressions)
  |
  Hedge Server: skip exposure processing for returned InstrumentIDs
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | INT | NO | - | CODE-BACKED | The hedge server whose inactive instrument list is requested. Maps to Trade.HedgeServer(HedgeServerID). No default - callers must supply a specific server ID. |

**Output columns (result set):**

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | InstrumentID | int | An instrument that is currently suppressed (inactive) on the requested hedge server. The hedge server will skip exposure hedging for this instrument. Implicit FK to Trade.Instrument. See Hedge.InactiveInstruments for the full blocklist. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @HedgeServerID | Hedge.InactiveInstruments | READ | Reads the inactive instrument blocklist for the specified server |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.HedgeServerInstrumentActivity (procedure)
+-- Hedge.InactiveInstruments (table) [READ - inactive instruments by server]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.InactiveInstruments | Table | Reads InstrumentIDs for the given HedgeServerID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET TRAN ISOLATION LEVEL READ UNCOMMITTED | Isolation level | Non-blocking startup read - acceptable for configuration data where slight staleness is tolerable |

---

## 8. Sample Queries

### 8.1 Get inactive instruments for a specific hedge server
```sql
EXEC [Hedge].[HedgeServerInstrumentActivity] @HedgeServerID = 1
```

### 8.2 Verify inactive instruments directly from the source table
```sql
SELECT InstrumentID
FROM [Hedge].[InactiveInstruments] WITH (NOLOCK)
WHERE HedgeServerID = 1
ORDER BY InstrumentID
```

### 8.3 Count inactive instruments per server
```sql
SELECT HedgeServerID, COUNT(1) AS InactiveCount
FROM [Hedge].[InactiveInstruments] WITH (NOLOCK)
GROUP BY HedgeServerID
ORDER BY HedgeServerID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.HedgeServerInstrumentActivity | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.HedgeServerInstrumentActivity.sql*
