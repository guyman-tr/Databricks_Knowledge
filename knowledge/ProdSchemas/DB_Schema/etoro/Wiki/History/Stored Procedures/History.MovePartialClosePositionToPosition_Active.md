# History.MovePartialClosePositionToPosition_Active

> Partition-aware batch mover that transfers completed partial-close position records from History.PositionClosePartial into History.Position_Active within a specified partition range, deleting the source rows after successful INSERT.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartPartitionID / @EndPartitionID - partition range to process; @Batch - row limit per call |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.MovePartialClosePositionToPosition_Active` is a batch migration utility for the partial-close position pipeline. When a position is partially closed (a fraction of the position is closed while the remainder stays open), the partial-close event is first written to `History.PositionClosePartial` as a staging area. This procedure moves those staged records into `History.Position_Active` - the primary store for active (and recently closed) positions - and deletes the source rows after a successful INSERT.

The procedure is partition-aware: both `History.PositionClosePartial` and `History.Position_Active` are partitioned on `PartitionCol` (computed as `PositionID % 50`, yielding partition values 0-49). The `@StartPartitionID` and `@EndPartitionID` parameters allow the caller to target specific partition ranges, enabling parallel execution across different partition buckets and controlled load on the system.

The `History.MovePartialClosePositionToPosition_ActiveType` TVP (Table-Valued Parameter UDT) is used as an intermediate store to capture the newly-inserted PositionIDs and their partition columns from the OUTPUT clause, which are then used to precisely match and delete the corresponding source rows.

---

## 2. Business Logic

### 2.1 INSERT-then-DELETE with TVP Output Capture

**What**: The procedure atomically transfers records by first INSERTing into the destination (capturing inserted IDs), then DELETEing from the source using those same IDs.

**Columns/Parameters Involved**: `@Batch`, `@StartPartitionID`, `@EndPartitionID`, `@MovePositionID` (TVP), `@rowcount`

**Rules**:
- SELECT TOP (@Batch) from History.PositionClosePartial WHERE PartitionCol BETWEEN @StartPartitionID AND @EndPartitionID
- OUTPUT clause: `output inserted.PositionID, inserted.PositionID%50 INTO @MovePositionID(PositionID, PartitionCol)` - captures the newly inserted position IDs and their computed partition values
- DELETE from History.PositionClosePartial WHERE PositionID in @MovePositionID AND PartitionCol in @MovePositionID AND PartitionCol BETWEEN @StartPartitionID AND @EndPartitionID
- @rowcount = @@ROWCOUNT after DELETE - returns the number of rows deleted (should equal rows inserted)
- All within BEGIN TRAN / COMMIT for atomicity
- CATCH: SELECT ERROR_MESSAGE() + ROLLBACK (no re-raise - error is returned as a result set, not thrown)

**Diagram**:
```
History.PositionClosePartial
  WHERE PartitionCol BETWEEN @StartPartitionID AND @EndPartitionID
        |
        v
INSERT TOP(@Batch) INTO History.Position_Active
  OUTPUT inserted.PositionID, PositionID%50 INTO @MovePositionID
        |
        v
DELETE History.PositionClosePartial
  WHERE PositionID IN @MovePositionID AND PartitionCol IN @MovePositionID
  AND PartitionCol BETWEEN @StartPartitionID AND @EndPartitionID
        |
        v
@rowcount = @@ROWCOUNT (DELETE count)
COMMIT
```

### 2.2 Partition Range Processing

**What**: Processing is bounded to a specific partition range to allow parallel execution across different partition buckets without contention.

**Columns/Parameters Involved**: `@StartPartitionID`, `@EndPartitionID`, `PartitionCol`

**Rules**:
- PartitionCol values: 0-49 (comment: "0 -> 49")
- A single call can process one partition (e.g., @StartPartitionID=0, @EndPartitionID=0) or a range (e.g., @StartPartitionID=0, @EndPartitionID=24)
- Multiple callers can run simultaneously targeting non-overlapping partition ranges
- @Batch limits the number of rows per call to prevent large transactions; caller repeats until @rowcount=0 to drain the source

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Batch | INT | YES | 1000 | CODE-BACKED | Maximum number of rows to process per call (SELECT TOP @Batch). Default 1000 prevents large transactions. Caller repeats the procedure call until @rowcount returns 0 to fully drain the partition range. |
| 2 | @StartPartitionID | BIGINT | NO | - | CODE-BACKED | Start of the partition range to process (inclusive). PartitionCol values are 0-49 (PositionID % 50). Allows targeting a subset of partitions. Used in WHERE PartitionCol BETWEEN @StartPartitionID AND @EndPartitionID on both the INSERT source and DELETE target. |
| 3 | @EndPartitionID | BIGINT | NO | - | CODE-BACKED | End of the partition range to process (inclusive). Combined with @StartPartitionID to define the partition slice. For single-partition processing: @StartPartitionID = @EndPartitionID. For full range: 0 to 49. |
| 4 | @rowcount | INT | NO (OUTPUT) | - | CODE-BACKED | OUTPUT: Number of rows deleted from History.PositionClosePartial in this call (= @@ROWCOUNT after DELETE). When @rowcount = 0, there are no more rows to process in the specified partition range. Caller uses this as the loop termination condition. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | History.PositionClosePartial | Reads + Deletes | SELECT TOP @Batch source; DELETE rows successfully moved (matched via @MovePositionID TVP) |
| (body) | History.Position_Active | Writes (INSERT) | Destination - receives the partial-close position records |
| (body) | History.MovePartialClosePositionToPosition_ActiveType | Type (TVP) | User-defined table type used as intermediate storage to capture OUTPUT from INSERT and drive the DELETE |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Partial-close position pipeline application | - | Caller | Called repeatedly per partition range until @rowcount=0; no callers found in SSDT repository |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.MovePartialClosePositionToPosition_Active (procedure)
+-- History.PositionClosePartial (table - source staging table for partial closes)
+-- History.Position_Active (table - destination for moved records)
+-- History.MovePartialClosePositionToPosition_ActiveType (UDT - TVP for OUTPUT capture)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionClosePartial | Table | SELECT source (TOP @Batch, partition-filtered) + DELETE target |
| History.Position_Active | Table | INSERT destination for moved position records |
| History.MovePartialClosePositionToPosition_ActiveType | User Defined Type | TVP declared as @MovePositionID; holds (PositionID, PartitionCol) from INSERT OUTPUT clause |

### 6.2 Objects That Depend On This

No callers found in the etoro SSDT repository. Called by the partial-close position migration pipeline.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Implementation notes**:
- Column list: 99 explicit columns transferred (the full set from both tables); no SELECT * - all column names are listed explicitly in both INSERT and SELECT
- TVP type: `History.MovePartialClosePositionToPosition_ActiveType` holds (PositionID BIGINT, PartitionCol BIGINT) - matches the OUTPUT clause
- CATCH block: `SELECT ERROR_MESSAGE()` returns the error as a result set row, then ROLLBACK. The error is NOT re-raised (no THROW or RAISERROR). The caller must check @rowcount or handle the error result set.
- The @rowcount output will be 0 (not set) if an error occurs (ROLLBACK runs before @@ROWCOUNT is captured)
- No NOLOCK on source read - ensures consistent batch reads within the transaction

---

## 8. Sample Queries

### 8.1 Process one partition range batch (partition 0 only)

```sql
DECLARE @rowcount INT

EXEC History.MovePartialClosePositionToPosition_Active
    @Batch            = 1000,
    @StartPartitionID = 0,
    @EndPartitionID   = 0,
    @rowcount         = @rowcount OUTPUT

SELECT @rowcount AS RowsMoved
```

### 8.2 Drain all rows in a partition range by looping until empty

```sql
DECLARE @rowcount INT = 1

WHILE @rowcount > 0
BEGIN
    EXEC History.MovePartialClosePositionToPosition_Active
        @Batch            = 1000,
        @StartPartitionID = 0,
        @EndPartitionID   = 24,
        @rowcount         = @rowcount OUTPUT
END
```

### 8.3 Check pending records in PositionClosePartial by partition

```sql
SELECT
    PartitionCol,
    COUNT(*) AS PendingRows
FROM History.PositionClosePartial WITH (NOLOCK)
GROUP BY PartitionCol
ORDER BY PartitionCol
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9B, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 1 repo / 0 files | Corrections: 0 applied*
*Object: History.MovePartialClosePositionToPosition_Active | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.MovePartialClosePositionToPosition_Active.sql*
