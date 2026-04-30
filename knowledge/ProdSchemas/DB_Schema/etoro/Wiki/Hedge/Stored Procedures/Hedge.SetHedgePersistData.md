# Hedge.SetHedgePersistData

> Bulk upsert for the hedge server persistence cache: updates existing Hedge.PositionsHedgeTbl rows and inserts missing ones from a Hedge.PositionsHedgePersistTable TVP. Called periodically by the hedge server to checkpoint its current position state for crash recovery. Returns @PersistID (scope_identity from caller's prior scope) as an OUTPUT parameter.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Writes to Hedge.PositionsHedgeTbl via TVP upsert; @PersistID BIGINT OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.SetHedgePersistData` is the write path for `Hedge.PositionsHedgeTbl` - the hedge server's local persistence store for its current view of aggregate customer positions. The hedge server calls this procedure periodically to checkpoint its in-memory position state to the database, enabling recovery after restarts without re-querying the full trading history.

Each call passes a `Hedge.PositionsHedgePersistTable` TVP containing the current aggregate position state for all (InstrumentID, HedgeServerID, IsBuy) combinations. The procedure performs a **two-step upsert**:
1. **UPDATE**: matches TVP rows to existing PositionsHedgeTbl rows on the composite key (InstrumentID, HedgeServerID, IsBuy) and updates all mutable fields.
2. **INSERT**: for TVP rows where no matching PositionsHedgeTbl row exists (NOT EXISTS check), inserts new rows.

No DELETE is performed - rows are removed separately via `Hedge.ClearHedgeExposuresPersistData` (TRUNCATE for full refresh) or `Hedge.DeleteZeroRowPositionsHedgePersistData` (cleanup of zero-amount rows).

**IsBuy as a persistence dimension**: unlike `Hedge.Netting` which stores a single netted position per instrument+account, this table stores SEPARATE rows for long (IsBuy=1) and short (IsBuy=0) positions, enabling gross exposure tracking in both directions independently.

**@PersistID OUTPUT quirk**: The procedure calls `SET @PersistID = SCOPE_IDENTITY()` BEFORE any INSERT. Since PositionsHedgeTbl has no IDENTITY column (its PK is a composite key), `SCOPE_IDENTITY()` returns NULL or the identity from a prior operation in the caller's scope. This OUTPUT parameter is a correlation/tracking mechanism for the caller, not a newly-generated IDENTITY.

---

## 2. Business Logic

### 2.1 Two-Step TVP Upsert

**What**: All TVP rows are processed in two passes - update existing, insert new.

**Columns/Parameters Involved**: `@HedgeToUpdate TVP`, all PositionsHedgeTbl columns

**Rules**:
- **Pass 1 (UPDATE)**: `UPDATE Hedge.PositionsHedgeTbl ... FROM ... JOIN @HedgeToUpdate RTU ON (PH.InstrumentID=RTU.InstrumentID AND PH.HedgeServerID=RTU.HedgeServerID AND PH.IsBuy=RTU.IsBuy)`. Updates InstrumentID, HedgeServerID, IsBuy, AmountInUnitsDecimal, UnitMargin, InitForexRate, Redeemed, LastDataID, LastUpdated.
- **Pass 2 (INSERT)**: `INSERT ... SELECT ... FROM @HedgeToUpdate WHERE NOT EXISTS (SELECT 1 FROM PositionsHedgeTbl WHERE same PK)`. Inserts only rows without an existing PK match.
- No explicit transaction wraps the two passes - they execute sequentially without atomicity guarantee. In practice this is safe because the NOT EXISTS check prevents duplicate inserts.

**Diagram**:
```
Hedge Server (periodic persistence checkpoint)
  |
  | Builds @HedgeToUpdate PositionsHedgePersistTable TVP
  |   (all active instrument/server/direction combinations)
  |
  | EXEC Hedge.SetHedgePersistData(@HedgeToUpdate, @PersistID OUTPUT)
  |
  | Step 1: SET @PersistID = SCOPE_IDENTITY()  <- captures prior scope identity
  |
  | Step 2: UPDATE PositionsHedgeTbl
  |   JOIN @HedgeToUpdate ON (InstrumentID, HedgeServerID, IsBuy)
  |   SET AmountInUnitsDecimal, UnitMargin, InitForexRate, etc.
  |
  | Step 3: INSERT INTO PositionsHedgeTbl
  |   SELECT ... FROM @HedgeToUpdate WHERE NOT EXISTS (matching PK)
  |
  | Step 4: SELECT @PersistID  <- returns the scope identity value
  v
Hedge.PositionsHedgeTbl: updated + new rows
  |
  +-> On hedge server restart: reads PositionsHedgeTbl to restore in-memory state
  +-> LastDataID/LastUpdated watermarks used to resume event processing
```

### 2.2 Checkpoint Recovery Pattern

**What**: The persisted data contains watermarks (LastDataID, LastUpdated) that allow the hedge server to resume event processing from where it left off.

**Columns/Parameters Involved**: `LastDataID`, `LastUpdated`, `AmountInUnitsDecimal`, `InitForexRate`

**Rules**:
- On restart, the hedge server reads `Hedge.PositionsHedgeTbl` to restore its in-memory position book.
- `LastDataID`: the highest event/data ID already processed. On recovery, the server replays only events with ID > LastDataID.
- `LastUpdated`: timestamp of the last position update - used as a secondary watermark.
- `InitForexRate`: weighted average opening rate - used to compute unrealized P&L on recovery.
- `Redeemed`: partially closed portion - combined with AmountInUnitsDecimal to determine if the position can be cleaned up.

### 2.3 @PersistID OUTPUT

**What**: The OUTPUT parameter returns a scope identity value as a correlation mechanism.

**Rules**:
- `SET @PersistID = SCOPE_IDENTITY()` is called BEFORE the UPDATE/INSERT.
- Since PositionsHedgeTbl has no IDENTITY column, SCOPE_IDENTITY() returns the identity value from the caller's prior scope (or NULL if no identity has been generated in this scope).
- The final `SELECT @PersistID` returns this value to the caller.
- The caller uses this as a correlation/tracking ID, not as a newly-generated row ID for this upsert.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeToUpdate | Hedge.PositionsHedgePersistTable (TVP) | NO | - | CODE-BACKED | READONLY TVP containing the current aggregate position state snapshot. Each row represents one (InstrumentID, HedgeServerID, IsBuy) combination. Rows are matched against PositionsHedgeTbl on this composite key. |
| 2 | @PersistID | BIGINT OUTPUT | NO | - | CODE-BACKED | OUTPUT parameter. Set to SCOPE_IDENTITY() BEFORE the INSERT (not after), so it captures the prior scope's identity value, not a newly generated one. PositionsHedgeTbl has no IDENTITY column. Returned as SELECT @PersistID at end of procedure. |

**TVP columns (Hedge.PositionsHedgePersistTable) - all mapped to PositionsHedgeTbl:**

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | InstrumentID | INT | Instrument for this position. Part of composite upsert key. |
| 2 | HedgeServerID | INT | Hedge server for this position. Part of composite upsert key. |
| 3 | IsBuy | BIT | Direction: 1=long, 0=short. Part of composite upsert key. Long and short stored as separate rows. |
| 4 | AmountInUnitsDecimal | DECIMAL | Total units currently held in this direction. Core exposure metric. |
| 5 | UnitMargin | DECIMAL | Margin cost per unit. Used in margin/equity calculations. |
| 6 | InitForexRate | dbo.dtPrice | Weighted average opening rate for unrealized P&L computation on recovery. |
| 7 | Redeemed | DECIMAL | Units already redeemed/closed. Together with AmountInUnitsDecimal determines if position can be deleted. |
| 8 | LastDataID | BIGINT | Highest event ID processed. Recovery watermark - resume processing from LastDataID+1. |
| 9 | LastUpdated | DATETIME | Timestamp of last position update. Secondary recovery watermark. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Hedge.PositionsHedgeTbl | WRITER (UPDATE + INSERT) | Bulk upsert: update existing positions, insert new ones |

### 5.2 Referenced By (other objects point to this)

Not found in SQL repo. No explicit role permission in UsersPermissions files. Called from hedge server application as part of periodic persistence checkpoint.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.SetHedgePersistData (procedure)
|-- Hedge.PositionsHedgePersistTable (UDT TVP type) [@HedgeToUpdate parameter type]
+-- Hedge.PositionsHedgeTbl (table) [UPDATE + INSERT target]
    +-- Dictionary.HedgeOrderState (implicit - see table doc)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.PositionsHedgePersistTable | User Defined Type (TVP) | @HedgeToUpdate parameter type |
| Hedge.PositionsHedgeTbl | Table | UPDATE + INSERT target for position persistence |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo. | - | Called from hedge server application for periodic position state checkpointing. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No TRY/CATCH | Error propagation | Exceptions propagate directly to the caller (hedge server application handles failures). |
| No explicit TRANSACTION | Non-atomic upsert | UPDATE and INSERT are separate statements without a BEGIN TRAN wrapper. Race conditions between the NOT EXISTS check and INSERT are theoretically possible, though unlikely for a single-writer hedge server process. |
| SCOPE_IDENTITY() before INSERT | @PersistID quirk | @PersistID captures prior scope identity, not the upsert result. PositionsHedgeTbl has no IDENTITY column. |
| WITH (NOLOCK) on source table in UPDATE | Read isolation | PositionsHedgeTbl is read with NOLOCK for the UPDATE join, preventing lock contention. The UPDATE still acquires write locks on matched rows. |

---

## 8. Sample Queries

### 8.1 Checkpoint position state from hedge server
```sql
DECLARE @Positions Hedge.PositionsHedgePersistTable
INSERT INTO @Positions VALUES (1, 1, 1, 224924151.0000, 0.0001, 159.3200, 0, 998916, GETUTCDATE())
INSERT INTO @Positions VALUES (1, 1, 0, 50000.0000, 0.0001, 159.3000, 0, 998917, GETUTCDATE())

DECLARE @PersistID BIGINT
EXEC [Hedge].[SetHedgePersistData]
    @HedgeToUpdate = @Positions,
    @PersistID     = @PersistID OUTPUT

SELECT @PersistID AS PersistID
```

### 8.2 Verify upserted positions
```sql
SELECT InstrumentID, HedgeServerID, IsBuy,
       AmountInUnitsDecimal, UnitMargin, InitForexRate,
       Redeemed, LastDataID, LastUpdated
FROM [Hedge].[PositionsHedgeTbl] WITH (NOLOCK)
WHERE HedgeServerID = 1
ORDER BY InstrumentID, IsBuy
```

### 8.3 Check which positions can be cleaned up (Redeemed=0 AND AmountInUnitsDecimal=0)
```sql
SELECT InstrumentID, HedgeServerID, IsBuy, LastUpdated
FROM [Hedge].[PositionsHedgeTbl] WITH (NOLOCK)
WHERE AmountInUnitsDecimal = 0
  AND Redeemed = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL repo | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.SetHedgePersistData | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.SetHedgePersistData.sql*
