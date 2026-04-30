# Hedge.UpdateRedeemedPositions

> Atomically replaces the redeemed-position record for a given (InstrumentID, HedgeServerID) pair via DELETE+INSERT in a single transaction, returning the new IDENTITY PersistID as a version token to the caller.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID + @HedgeServerID (composite replace key); @PersistID OUTPUT (new version ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.UpdateRedeemedPositions` is the **sole write path** for `Hedge.RedeemedPositions` - the per-instrument, per-server snapshot of how much hedge position has been redeemed (unwound) as eToro customers close their positions. When the hedge server processes a batch of position closures, it calls this procedure to record the current cumulative redeemed amount.

This procedure uses a DELETE+INSERT pattern (not UPDATE) specifically because `Hedge.RedeemedPositions` has a PersistID IDENTITY column that must increment with every "version" of the record. An UPDATE would not advance the IDENTITY, making version tracking impossible. By deleting the old row and inserting a new one, each write produces a fresh PersistID that the caller can use to correlate data across services and detect whether a record has been superseded.

Data flows as follows: the hedge server computes the cumulative redeemed units for a specific (InstrumentID, HedgeServerID) pair, then calls this procedure with the amount and a batch identifier. Inside a transaction, the existing row is deleted and a new row is inserted. The new IDENTITY value (PersistID) is captured with `SCOPE_IDENTITY()` and returned via the OUTPUT parameter. On any error, the procedure rolls back (with special handling for nested transactions) and re-throws the error to the caller.

---

## 2. Business Logic

### 2.1 Atomic Replace Pattern (DELETE + INSERT = New PersistID)

**What**: The existing record for (InstrumentID, HedgeServerID) is always deleted before inserting the new one - no UPSERT or UPDATE path exists.

**Columns/Parameters Involved**: `@InstrumentID`, `@HedgeServerID`, `@Units`, `@PersistID`, `@LastDataID`, `@LastUpdated`

**Rules**:
- DELETE: removes any existing row for the (HedgeServerID, InstrumentID) pair. If no row exists, the DELETE is a no-op.
- INSERT: inserts the new record with updated AmountInUnits (@Units), LastDataID (@LastDataID), LastUpdated (@LastUpdated).
- `@PersistID = SCOPE_IDENTITY()` - captures the IDENTITY value of the newly inserted row and returns it to the caller.
- The PersistID monotonically increases with each replace - it is a generation/version counter, not a business key.
- Both steps are within BEGIN TRAN / COMMIT - either both succeed or neither does.

**Diagram**:
```
CALL: UpdateRedeemedPositions(@InstrumentID=1, @HedgeServerID=3, @Units=2500000.12, @PersistID OUT, ...)
  BEGIN TRAN
    DELETE FROM RedeemedPositions WHERE HedgeServerID=3 AND InstrumentID=1   -> 0 or 1 row removed
    INSERT (InstrumentID=1, HedgeServerID=3, AmountInUnits=2500000.12, ...)  -> new row, PersistID=98765
    SET @PersistID = SCOPE_IDENTITY() -> 98765
  COMMIT
RETURNS: @PersistID = 98765
```

### 2.2 Nested Transaction Error Handling

**What**: The CATCH block handles two scenarios: standalone call vs being called from within an outer transaction.

**Columns/Parameters Involved**: `@@TRANCOUNT`

**Rules**:
- `IF @@TRANCOUNT = 1`: this is the outermost transaction - ROLLBACK the full transaction. The hedge data is not persisted.
- `IF @@TRANCOUNT > 1`: this SP was called from within an outer transaction - COMMIT the inner savepoint (release the inner tran count), then THROW to let the outer transaction decide whether to roll back.
- THROW re-propagates the original error in both cases - callers always receive the error signal.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | int | NO | - | CODE-BACKED | The financial instrument whose redeemed position is being updated. Part of the composite replace key (InstrumentID, HedgeServerID). Implicit FK to Trade.Instrument. |
| 2 | @HedgeServerID | int | NO | - | CODE-BACKED | The hedge server that owns this redeemed position record. Part of the composite replace key. FK to Trade.HedgeServer (validated via Hedge.RedeemedPositions table constraints). |
| 3 | @Units | decimal(18,8) | NO | - | CODE-BACKED | The cumulative redeemed position amount in instrument-native units (shares, lots, etc.) as of this update. Replaces the previous AmountInUnits value entirely. High precision (8 decimal places) supports small-denomination instruments. |
| 4 | @PersistID | bigint | NO | - | CODE-BACKED | OUTPUT parameter. Returns the IDENTITY value of the newly inserted row in Hedge.RedeemedPositions. Used by callers as a version token - callers can detect if their data has been superseded by comparing stored PersistID values. Increases monotonically with each call. |
| 5 | @LastDataID | varchar(100) | NO | - | CODE-BACKED | String-based batch/correlation identifier for the data cycle that produced this redeemed amount. Unlike the integer LastDataID in PositionsHedgeTbl, this is varchar(100) to accommodate richer batch IDs (e.g., string timestamps, UUIDs). |
| 6 | @LastUpdated | datetime | NO | - | CODE-BACKED | Timestamp of this redeemed position snapshot. Set by the caller to the hedge server's current cycle time. NOT the database insert time - the caller controls this value for data correlation and replay sequencing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.Instrument | Implicit | Identifies the instrument whose hedge position is being redeemed |
| @HedgeServerID | Trade.HedgeServer | Lookup | Identifies which hedge server's redeemed position is being recorded |
| (DELETE + INSERT target) | Hedge.RedeemedPositions | DELETER + WRITER | Replaces the existing row (or creates first row) for the (InstrumentID, HedgeServerID) pair |

### 5.2 Referenced By (other objects point to this)

No callers found within the SSDT repository. Called externally by the hedge server process during redemption processing.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.UpdateRedeemedPositions (procedure)
+-- Hedge.RedeemedPositions (table) [DELETER + WRITER]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.RedeemedPositions | Table | Target of DELETE (remove old record) and INSERT (write new record); SCOPE_IDENTITY() captures the new PersistID |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository. Called externally.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TRY/CATCH with nested tran handling | Error handling | Handles both standalone (ROLLBACK when @@TRANCOUNT=1) and nested (COMMIT inner + THROW when @@TRANCOUNT>1) scenarios |
| THROW | Error propagation | Re-throws the original error to caller in all error paths; caller receives full error detail |
| DELETE+INSERT (not UPDATE) | Design | Ensures PersistID (IDENTITY) increments on every write cycle, enabling reliable version tracking |

---

## 8. Sample Queries

### 8.1 Record a redeemed position update and capture the version ID
```sql
DECLARE @NewPersistID BIGINT;

EXEC [Hedge].[UpdateRedeemedPositions]
    @InstrumentID = 1,
    @HedgeServerID = 3,
    @Units         = 2500000.12345678,
    @PersistID     = @NewPersistID OUTPUT,
    @LastDataID    = 'batch-2026-03-19-08:00',
    @LastUpdated   = '2026-03-19 08:00:00';

SELECT @NewPersistID AS NewPersistID; -- Use to correlate with other systems
```

### 8.2 Read current redeemed positions for a server
```sql
SELECT InstrumentID, HedgeServerID, AmountInUnits, LastDataID, PersistID, LastUpdated
FROM   [Hedge].[RedeemedPositions] WITH (NOLOCK)
WHERE  HedgeServerID = 3
ORDER BY InstrumentID;
```

### 8.3 Detect if a previously stored PersistID is still current
```sql
DECLARE @StoredPersistID BIGINT = 98765;
SELECT CASE WHEN PersistID = @StoredPersistID THEN 'Current' ELSE 'Superseded' END AS Status
FROM   [Hedge].[RedeemedPositions] WITH (NOLOCK)
WHERE  InstrumentID = 1 AND HedgeServerID = 3;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.UpdateRedeemedPositions | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.UpdateRedeemedPositions.sql*
