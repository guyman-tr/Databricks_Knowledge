# Hedge.SetInstrumentActivity

> Atomically replaces the entire inactive-instrument list for a hedge server: deletes all existing inactive entries for the server, then inserts the caller-supplied set in a single transaction.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @HedgeServerID (server whose blocklist is being replaced) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.SetInstrumentActivity` is the **bulk-replace** writer for the `Hedge.InactiveInstruments` blocklist. When the dealing system (or an operator console) decides that a specific set of instruments should be suppressed on a hedge server, it calls this procedure with the complete desired inactive list. The procedure wipes the existing list for that server and loads the new one atomically - there is no partial state: the server either has the old list or the new list, never a mix.

This procedure is used when the authoritative source (e.g., the dealing system) sends a snapshot of all currently inactive instruments for a server. By accepting a TVP (`Hedge.InstrumentTable`) the caller can pass any number of instruments in a single round-trip rather than issuing one call per instrument.

Data flows through this object as follows: the caller populates a `Hedge.InstrumentTable` TVP with the InstrumentIDs that should be inactive, then calls this procedure. Inside a transaction, all existing rows for the server are deleted and the TVP rows are inserted. The hedge server reads the updated list via `Hedge.HedgeServerInstrumentActivity` at next startup or config-reload. If any error occurs, the transaction is rolled back - preserving the previous list intact.

---

## 2. Business Logic

### 2.1 Atomic Bulk Replacement (DELETE + INSERT)

**What**: The inactive list is replaced in its entirety for the target server, not merged or incrementally updated.

**Columns/Parameters Involved**: `@HedgeServerID`, `@InactiveInstruments`

**Rules**:
- All existing rows in `Hedge.InactiveInstruments` for `@HedgeServerID` are deleted unconditionally.
- All rows from `@InactiveInstruments` TVP are inserted with the given `@HedgeServerID`.
- Both operations execute within a single `BEGIN TRAN / COMMIT` block - the table is never in a partial state.
- If an error occurs at any point, `ROLLBACK` restores the previous inactive list.
- Passing an empty TVP (`@InactiveInstruments` with zero rows) effectively clears the inactive list for the server - all instruments become active.

**Diagram**:
```
BEFORE:  InactiveInstruments[HedgeServerID=1] = { 100, 200, 300 }
CALL:    SetInstrumentActivity(@HedgeServerID=1, @InactiveInstruments={200, 400})
  BEGIN TRAN
    DELETE WHERE HedgeServerID=1  -> removes 100, 200, 300
    INSERT {1,200}, {1,400}        -> adds new set
  COMMIT
AFTER:   InactiveInstruments[HedgeServerID=1] = { 200, 400 }
```

### 2.2 Empty TVP = Clear All (Re-Activate All Instruments)

**What**: Passing an empty `@InactiveInstruments` TVP re-activates all instruments on the server.

**Columns/Parameters Involved**: `@InactiveInstruments`

**Rules**:
- The DELETE runs unconditionally (no existence check), so if zero rows are in the TVP, the INSERT adds nothing.
- Net result: the server's inactive list becomes empty and the hedge server treats all instruments as active.
- This is the mechanism to fully clear the blocklist in a single call.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | int | NO | - | CODE-BACKED | The hedge server whose inactive-instrument list is being replaced. All existing rows in `Hedge.InactiveInstruments` for this server are deleted before the new set is inserted. Corresponds to `Trade.HedgeServer.HedgeServerID`. |
| 2 | @InactiveInstruments | Hedge.InstrumentTable | NO | - | CODE-BACKED | Read-only TVP containing the complete set of instruments that should be inactive on `@HedgeServerID` after this call. Each row holds one `InstrumentID` (nullable int, implicit FK to `Trade.Instrument`). Pass an empty TVP to re-activate all instruments on the server. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @HedgeServerID | Trade.HedgeServer | Lookup | Identifies which server's blocklist is being updated; validated via FK on Hedge.InactiveInstruments |
| @InactiveInstruments | Hedge.InstrumentTable | TVP (UDT) | Passes the new inactive instrument list; rows reference Trade.Instrument implicitly |
| (target) | Hedge.InactiveInstruments | DELETER + WRITER | Deletes all rows for @HedgeServerID, then inserts new rows from the TVP |

### 5.2 Referenced By (other objects point to this)

No callers found within the SSDT repository. This procedure is called externally by the dealing system or operator tooling.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.SetInstrumentActivity (procedure)
+-- Hedge.InactiveInstruments (table) [DELETER + WRITER]
+-- Hedge.InstrumentTable (type) [@InactiveInstruments parameter]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.InactiveInstruments | Table | Target of DELETE (all rows for @HedgeServerID) and INSERT (new TVP rows) |
| Hedge.InstrumentTable | User Defined Type | Parameter type for @InactiveInstruments - defines the single-column TVP schema |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository. Called externally.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TRY/CATCH with ROLLBACK | Error handling | If any error occurs during DELETE or INSERT, the transaction is rolled back and the previous inactive list is preserved |
| Explicit transaction | Atomicity | BEGIN TRAN / COMMIT wraps DELETE + INSERT - the table is never in a partial state |

---

## 8. Sample Queries

### 8.1 Deactivate a specific set of instruments on server 1
```sql
DECLARE @Inactive [Hedge].[InstrumentTable];
INSERT INTO @Inactive (InstrumentID) VALUES (1016586), (1054039), (11543959);
EXEC [Hedge].[SetInstrumentActivity]
    @HedgeServerID = 1,
    @InactiveInstruments = @Inactive;
```

### 8.2 Clear the inactive list for server 1 (re-activate all instruments)
```sql
DECLARE @Empty [Hedge].[InstrumentTable]; -- no rows inserted
EXEC [Hedge].[SetInstrumentActivity]
    @HedgeServerID = 1,
    @InactiveInstruments = @Empty;
```

### 8.3 Verify current inactive instruments for a server after update
```sql
SELECT HedgeServerID, InstrumentID
FROM [Hedge].[InactiveInstruments] WITH (NOLOCK)
WHERE HedgeServerID = 1
ORDER BY InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.SetInstrumentActivity | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.SetInstrumentActivity.sql*
