# Hedge.SetSingleInstrumentActivity

> Idempotently adds a single instrument to a hedge server's inactive-instrument blocklist, then returns the server's full current inactive list; no-op if the instrument is already inactive.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @HedgeServerID + @InactiveInstrument (composite key to check/insert) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.SetSingleInstrumentActivity` is the **single-instrument additive writer** for `Hedge.InactiveInstruments`. While its companion `Hedge.SetInstrumentActivity` replaces the entire inactive list for a server, this procedure adds one instrument to the blocklist at a time and confirms the operation by returning the updated list.

This procedure is used for **real-time deactivation** of individual instruments - when a Dealing Room operator or an automated process decides that a specific instrument should stop being hedged on a specific server without affecting the other inactive instruments. The IF NOT EXISTS guard makes the call safe to repeat: calling it twice with the same parameters has the same effect as calling it once.

Data flows as follows: the caller provides a HedgeServerID and a single InstrumentID. Inside a transaction, the procedure checks whether that pair already exists in `Hedge.InactiveInstruments`. If it does not, it inserts the pair. Regardless of whether the insert happened, it then returns all currently inactive instruments for that server. On any error, the transaction rolls back - leaving the previous state intact.

---

## 2. Business Logic

### 2.1 Idempotent Add (IF NOT EXISTS Guard)

**What**: The insert only fires if the (HedgeServerID, InstrumentID) pair is not already present, making the procedure safe to call multiple times.

**Columns/Parameters Involved**: `@HedgeServerID`, `@InactiveInstrument`

**Rules**:
- `IF NOT EXISTS (SELECT TOP 1 1 FROM Hedge.InactiveInstruments WHERE HedgeServerID = @HedgeServerID AND InstrumentID = @InactiveInstrument)` - the composite PK of InactiveInstruments already prevents duplicates, but the IF NOT EXISTS provides an application-level guard that avoids a primary key violation error.
- If the instrument is ALREADY inactive: no INSERT happens; the procedure returns the existing list silently.
- If the instrument is NOT inactive: INSERT adds the pair; the procedure returns the updated list.
- The SELECT (return of full list) runs in both branches - the caller always gets the current state.

**Diagram**:
```
CALL: SetSingleInstrumentActivity(@HedgeServerID=1, @InactiveInstrument=999)
  BEGIN TRAN
    IF NOT EXISTS (HedgeServerID=1, InstrumentID=999 in InactiveInstruments)
      -> INSERT {HedgeServerID=1, InstrumentID=999}   [if new]
      -> (skip)                                         [if already exists]
    SELECT InstrumentID FROM InactiveInstruments WHERE HedgeServerID=1
  COMMIT
RETURNS: full inactive list for server 1 (including 999 if newly added)
```

### 2.2 Returns Current Inactive List (Confirm + Read in One Call)

**What**: The procedure's SELECT returns the full updated inactive list, letting the caller confirm the deactivation took effect without a separate query.

**Columns/Parameters Involved**: `InstrumentID` (returned result set)

**Rules**:
- The SELECT runs with WITH (NOLOCK) for read performance.
- The SELECT is inside the same transaction as the INSERT - the caller sees the committed state.
- There is no explicit output parameter; the inactive list is returned as a result set.
- Contrast with `Hedge.SetInstrumentActivity` which returns nothing - this procedure is designed for real-time interactive use where the caller wants immediate confirmation.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | int | NO | - | CODE-BACKED | The hedge server on which the instrument should be deactivated. Determines the scope of both the insert check and the returned list. Corresponds to `Trade.HedgeServer.HedgeServerID`. |
| 2 | @InactiveInstrument | int | NO | - | CODE-BACKED | The single instrument to add to the inactive (blocklist) set for `@HedgeServerID`. If this (HedgeServerID, InstrumentID) pair already exists in `Hedge.InactiveInstruments`, the call is a no-op. Implicit FK to `Trade.Instrument`. |

**Result set returned**:

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | InstrumentID | int | All currently inactive InstrumentIDs for @HedgeServerID after this call completes. Includes @InactiveInstrument if it was newly inserted. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @HedgeServerID | Trade.HedgeServer | Lookup | Identifies which server's blocklist is being updated |
| @InactiveInstrument | Trade.Instrument | Implicit | Instrument being deactivated on the server |
| (target) | Hedge.InactiveInstruments | WRITER + READER | Conditionally inserts one row; always reads all rows for the server |

### 5.2 Referenced By (other objects point to this)

No callers found within the SSDT repository. Called externally by operator tooling or automated processes.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.SetSingleInstrumentActivity (procedure)
+-- Hedge.InactiveInstruments (table) [conditional INSERT + SELECT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.InactiveInstruments | Table | Checked via IF NOT EXISTS, inserted into if new, and queried for the return result set |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository. Called externally.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| IF NOT EXISTS guard | Application-level idempotency | Prevents PK violation; calling twice with same args is a no-op instead of an error |
| TRY/CATCH with ROLLBACK | Error handling | INSERT and SELECT execute within a transaction; any error rolls back and preserves the previous list |
| No re-activation path | Design limitation | There is no "remove single instrument from inactive list" procedure; full re-activation requires `Hedge.SetInstrumentActivity` with an empty or filtered TVP |

---

## 8. Sample Queries

### 8.1 Deactivate instrument 1016586 on server 1 (real-time call)
```sql
EXEC [Hedge].[SetSingleInstrumentActivity]
    @HedgeServerID     = 1,
    @InactiveInstrument = 1016586;
-- Returns: full inactive list for server 1
```

### 8.2 Check idempotency: call again with same args (should be no-op)
```sql
EXEC [Hedge].[SetSingleInstrumentActivity]
    @HedgeServerID     = 1,
    @InactiveInstrument = 1016586;
-- Returns same list - no new row inserted
```

### 8.3 Verify current inactive instruments for a server directly
```sql
SELECT HedgeServerID, InstrumentID
FROM   [Hedge].[InactiveInstruments] WITH (NOLOCK)
WHERE  HedgeServerID = 1
ORDER BY InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.SetSingleInstrumentActivity | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.SetSingleInstrumentActivity.sql*
