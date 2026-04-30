# Hedge.InactiveInstruments

> Hedge server instrument blocklist: each row suppresses hedging activity for one instrument on one hedge server; the hedge server skips exposure processing for any (HedgeServerID, InstrumentID) pair present here.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | (HedgeServerID, InstrumentID) composite CLUSTERED PK |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED PK on HedgeServerID + InstrumentID) |

---

## 1. Business Meaning

Hedge.InactiveInstruments is the hedge server's **instrument suppression list** (blocklist). Any (HedgeServerID, InstrumentID) pair present in this table tells the hedge server to skip hedging for that instrument on that server. Absence from the table means the instrument is active and should be hedged normally.

This allows the Dealing Room to disable hedging for specific instruments on specific servers without changing the broader instrument configuration. Use cases include:
- Temporarily suspending hedging for an instrument during market disruption
- Disabling instruments that are no longer traded but whose configurations still exist
- Suppressing hedging on specific servers for testing or operational reasons

**Live data (6 rows)**:
- HedgeServerID=1: InstrumentIDs 1016586, 1054039, 11543959 (3 instruments inactive on primary server)
- HedgeServerID=8: InstrumentID 1 (EUR/USD or instrument 1 inactive on server 8)
- HedgeServerID=1100: InstrumentIDs 1 and 2 inactive

**Write patterns**:
- `Hedge.SetInstrumentActivity`: Bulk replacement - DELETE all inactive instruments for a server, then INSERT the new set. Used to replace the entire inactive list for a server at once.
- `Hedge.SetSingleInstrumentActivity`: Add a single instrument to the inactive list (idempotent - no-op if already present). Returns the updated full list.

**Read patterns**:
- `Hedge.HedgeServerInstrumentActivity`: Called by the hedge server at startup or on config reload - returns all inactive InstrumentIDs for a specific server.
- `Hedge.GetAllInstrumentActivity`: Admin/monitoring query - returns all rows across all servers.

The table resides on the DICTIONARY filegroup (not MAIN), reflecting its role as configuration/dictionary data rather than transactional log data.

---

## 2. Business Logic

### 2.1 Blocklist Semantics (Presence = Inactive)

**What**: The table stores exceptions only - instruments that should NOT be hedged. The default (absent from table) is active.

**Columns/Parameters Involved**: `HedgeServerID`, `InstrumentID`

**Rules**:
- If (HedgeServerID=1, InstrumentID=100) is NOT in this table: instrument 100 is active on server 1 - hedge normally.
- If (HedgeServerID=1, InstrumentID=100) IS in this table: instrument 100 is inactive on server 1 - skip hedging.
- This is a per-server override: the same InstrumentID can be active on one server and inactive on another.
- The HedgeServer reads this list at startup (Hedge.HedgeServerInstrumentActivity) and suppresses exposure processing for listed instruments.

### 2.2 Bulk vs Single Write Operations

**What**: Two write procedures support different operational needs.

**Columns/Parameters Involved**: `HedgeServerID`, `InstrumentID`

**Rules**:
- `SetInstrumentActivity(@HedgeServerID, @InactiveInstruments TVP)`: **Full replacement** - deletes ALL inactive instruments for the server, then inserts the new TVP set in one transaction. Used when the dealing system sends a complete "current inactive list" snapshot.
- `SetSingleInstrumentActivity(@HedgeServerID, @InactiveInstrument int)`: **Additive** - inserts the instrument if not already present (IF NOT EXISTS guard). Returns the full current inactive list after the insert. Used for real-time deactivation of a single instrument.
- There is no corresponding "RemoveSingleInstrumentActivity" procedure - re-activating a single instrument requires either the bulk SetInstrumentActivity or a direct DELETE.

---

## 3. Data Overview

6 rows | DICTIONARY filegroup | 3 distinct servers

| HedgeServerID | InstrumentID |
|---|---|
| 1 | 1016586 |
| 1 | 1054039 |
| 1 | 11543959 |
| 8 | 1 |
| 1100 | 1 |
| 1100 | 2 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeServerID | int | NO | - | CODE-BACKED | FK to Trade.HedgeServer(HedgeServerID). The hedge server on which this instrument is suppressed. Part of composite PK. A server can have many inactive instruments. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | The instrument suppressed on this hedge server. Implicit reference to Trade.Instrument (no DDL FK). Part of composite PK. The hedge server will skip exposure processing for this InstrumentID when it reads this list. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID | Trade.HedgeServer | FK (WITH CHECK) | FK_HedgeInactiveInstrument_HedgeServer |
| InstrumentID | Trade.Instrument | Implicit (no DDL FK) | Instrument being suppressed |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.SetInstrumentActivity | @HedgeServerID | Writer (bulk replace) | Replaces entire inactive list for a server |
| Hedge.SetSingleInstrumentActivity | @HedgeServerID, @InactiveInstrument | Writer (add single) | Adds one instrument to the inactive list |
| Hedge.HedgeServerInstrumentActivity | @HedgeServerID | Reader | Hedge server reads inactive list at startup |
| Hedge.GetAllInstrumentActivity | - | Reader | Admin/monitoring view of all inactive instruments |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.InactiveInstruments (table)
  - FK: Trade.HedgeServer (HedgeServerID)
  - Implicit: Trade.Instrument (InstrumentID)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeServer | Table | FK target for HedgeServerID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.SetInstrumentActivity | Procedure | Bulk replaces the inactive list for a server |
| Hedge.SetSingleInstrumentActivity | Procedure | Adds a single instrument to the inactive list |
| Hedge.HedgeServerInstrumentActivity | Procedure | Reads inactive list by server (startup/reload) |
| Hedge.GetAllInstrumentActivity | Procedure | Admin read of all inactive instruments |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HedgeInactiveInstruments | CLUSTERED PK | HedgeServerID ASC, InstrumentID ASC | - | - | Active (FILLFACTOR=100, DICTIONARY filegroup) |

Note: FILLFACTOR=100 is appropriate for this configuration table - data is small and infrequently written.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HedgeInactiveInstruments | PRIMARY KEY (CLUSTERED) | (HedgeServerID, InstrumentID) - unique per server+instrument pair |
| FK_HedgeInactiveInstrument_HedgeServer | FOREIGN KEY (WITH CHECK) | HedgeServerID -> Trade.HedgeServer |

---

## 8. Sample Queries

### 8.1 All inactive instruments across all servers
```sql
SELECT HedgeServerID, InstrumentID
FROM Hedge.InactiveInstruments WITH (NOLOCK)
ORDER BY HedgeServerID, InstrumentID;
```

### 8.2 Active instruments for a server (instruments NOT in the blocklist)
```sql
-- All instruments that ARE configured for server 1 but NOT inactive
SELECT i.InstrumentID
FROM Trade.Instrument i WITH (NOLOCK)
WHERE NOT EXISTS (
    SELECT 1 FROM Hedge.InactiveInstruments ii WITH (NOLOCK)
    WHERE ii.HedgeServerID = 1 AND ii.InstrumentID = i.InstrumentID
);
```

### 8.3 Servers with the most inactive instruments
```sql
SELECT HedgeServerID, COUNT(1) AS InactiveCount
FROM Hedge.InactiveInstruments WITH (NOLOCK)
GROUP BY HedgeServerID
ORDER BY InactiveCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for Hedge.InactiveInstruments.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,3,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.InactiveInstruments | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.InactiveInstruments.sql*
