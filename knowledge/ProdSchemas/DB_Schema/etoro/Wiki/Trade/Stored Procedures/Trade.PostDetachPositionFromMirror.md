# Trade.PostDetachPositionFromMirror

> Batch processor that finalizes mirror detach operations: archives the mirror record to History.Mirror, writes position change log entries (including settlement-change correction entries), and removes processed rows from Trade.PostDetachOperation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Trade.PostDetachOperation.ID (batch primary key) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.PostDetachPositionFromMirror is the batch execution engine for the mirror-detach post-processing pipeline. When a position is detached from its mirror (e.g., due to mirror closure, stop-copy, or partial rebalance), the detach event is first staged in Trade.PostDetachOperation. This SP then consumes that queue in batches, performing the durable writes that complete the detach.

The SP performs three atomic actions per batch within a single transaction:
1. Archives the mirror's final state to History.Mirror
2. Writes position change log entries to History.PositionChangeLog_Active_BIGINT - including a second "settlement correction" entry (ChangeTypeID=13) for any position whose IsSettled flag changed during the detach
3. Deletes the processed rows from Trade.PostDetachOperation

On error, the transaction rolls back and the status of each processed row is decremented (StatusID = StatusID - 1), enabling callers to retry failed batches by querying a lower StatusID.

The comment in the code notes that History.PositionChangeLog_Active_BIGINT is used here specifically for Tradonomi (US broker integration), which uses BIGINT position IDs rather than INT.

---

## 2. Business Logic

### 2.1 Batch Load

**What**: Loads the next batch of pending detach operations into a temp table.

**Rules**:
- SELECT TOP(@BatchSize) * FROM Trade.PostDetachOperation WHERE StatusID=@StatusID
- StatusID=0 = pending (normal execution path)
- StatusID=-1, -2, etc. = retry states (decremented on each failure)
- If @StatusID=0: creates CIX on ID, NIX on (PCL_IsSettled, PCL_PreviousIsSettled), IX_PositionID on PCL_PositionID for query performance
- All subsequent work is done against #base (the loaded snapshot)

### 2.2 History.Mirror Archive

**What**: Inserts the mirror's final state into History.Mirror using H_M_ prefixed columns from #base.

**Rules**:
- All columns sourced directly from #base H_M_ columns
- ISNULL(H_M_MIMOOperationTypeID, 0): defaults NULL to 0
- ISNULL(H_M_MirrorTypeID, 1): defaults NULL to 1 (standard mirror type)
- No filter on PCL_PositionID - every row in #base generates a History.Mirror record regardless of position data

### 2.3 Position Change Log Insert (Primary Entry)

**What**: Inserts position change log for all detached positions with change type from the source data.

**Rules**:
- WHERE PCL_PositionID IS NOT NULL (rows without position link are skipped)
- ChangeTypeID = PCL_ChangeTypeID (from the staged record - typically detach-specific type)
- ParentPositionID hardcoded to 0 (detached position has no longer a parent)
- MirrorID hardcoded to 0 (no longer part of a mirror)
- AmountChanged hardcoded to 0 (detach does not change amount)
- PreviousAmount = NewAmount = PCL_PositionAmount (amount unchanged)
- LastOpPriceRate, LastOpPriceRateID = NULL
- PreviousLimitRate = LimitRate = PCL_LimitRate (no change to rates during detach)
- PreviousStopRate = StopRate = PCL_StopRate (no change to rates during detach)

### 2.4 Position Change Log Insert (Settlement Correction Entry, ChangeTypeID=13)

**What**: Inserts a second change log entry specifically for positions whose IsSettled flag changed during the detach.

**Rules**:
- WHERE PCL_IsSettled != PCL_PreviousIsSettled AND PCL_PositionID IS NOT NULL
- ChangeTypeID = 13 (settlement state correction for detach)
- Key inversion: IsSettled = PCL_PreviousIsSettled, PreviousIsSettled = PCL_IsSettled (values are SWAPPED relative to the primary entry)
- TreeID = PCL_PositionID (uses PositionID as TreeID, distinct from normal usage)
- LastOpConversionRate, LastOpConversionRateID = NULL for this entry
- IsTslEnabled, PreviousAmountInUnits, AmountInUnits, MirrorRealizedEquity = NULL for this entry
- This entry captures the "rollback" of the settlement state that occurred when the position was part of the mirror closing

### 2.5 Queue Cleanup and Error Recovery

**What**: Deletes processed rows from Trade.PostDetachOperation on success; decrements StatusID on failure.

**Rules**:
- DELETE Trade.PostDetachOperation WHERE ID IN (SELECT ID FROM #base) via INNER JOIN
- On CATCH: ROLLBACK, then UPDATE Trade.PostDetachOperation SET StatusID = StatusID - 1 for all rows in #base
- Failure decrement allows caller to retry with the new (decremented) StatusID value
- RAISERROR re-propagates the original error message to the caller after rollback

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BatchSize | INT | NO | - | CODE-BACKED | Number of rows to process from Trade.PostDetachOperation per invocation. Controls memory footprint and transaction duration. |
| 2 | @StatusID | INT | NO | - | CODE-BACKED | Filter for which pending records to process. 0=pending/normal path. Negative values represent retry states (decremented on failure). StatusID=1 = success (already processed). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT INTO #base | Trade.PostDetachOperation | DML read | Source queue of pending detach operations |
| INSERT | History.Mirror | DML write | Archives mirror final state (H_M_ columns) |
| INSERT UNION ALL | History.PositionChangeLog_Active_BIGINT | DML write | Primary + settlement-correction change log entries |
| DELETE | Trade.PostDetachOperation | DML write | Removes processed rows from queue |
| UPDATE (CATCH) | Trade.PostDetachOperation | DML write | Decrements StatusID on failure for retry |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by SQL Agent job or orchestration service processing the detach queue.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PostDetachPositionFromMirror (procedure)
+-- Trade.PostDetachOperation (table) - source queue (read + delete)
+-- History.Mirror (table) - mirror archive target
+-- History.PositionChangeLog_Active_BIGINT (table) - change log write (Tradonomi)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PostDetachOperation | Table | SELECT TOP batch; DELETE processed rows; UPDATE StatusID on failure |
| History.Mirror | Table | INSERT mirror archive record per batch row |
| History.PositionChangeLog_Active_BIGINT | Table | INSERT position change log (primary + ChangeTypeID=13 correction rows) |

### 6.2 Objects That Depend On This

No dependents found in SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- All three writes (History.Mirror INSERT, PositionChangeLog INSERT, PostDetachOperation DELETE) are atomic within a single BEGIN TRAN / COMMIT block
- CATCH block ROLLBACK ensures queue rows remain intact on failure (only StatusID is decremented, outside any transaction, so it always applies)
- The ChangeTypeID=13 settlement correction entry intentionally SWAPS IsSettled and PreviousIsSettled to record the pre-detach state
- The comment `-- tradonomi should be [History.PositionChangeLog_Active] table` indicates this BIGINT variant is used for the US brokerage (Tradonomi) integration path, which requires 64-bit position IDs
- Indexes are only created on #base when @StatusID=0 (the normal path); retry calls (negative StatusID) skip index creation

---

## 8. Sample Queries

### 8.1 Process the next batch of pending detach operations

```sql
EXEC Trade.PostDetachPositionFromMirror @BatchSize = 100, @StatusID = 0;
```

### 8.2 Retry failed operations (StatusID decremented to -1)

```sql
EXEC Trade.PostDetachPositionFromMirror @BatchSize = 100, @StatusID = -1;
```

### 8.3 Check pending detach queue depth

```sql
SELECT StatusID, COUNT(*) AS RecordCount
FROM Trade.PostDetachOperation WITH (NOLOCK)
GROUP BY StatusID
ORDER BY StatusID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos searched / 0 files | Corrections: 0 applied*
*Object: Trade.PostDetachPositionFromMirror | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PostDetachPositionFromMirror.sql*
