# Trade.PayForFeeProcess

> Partitioned overnight/weekend fee processor - iterates Trade.FeeNightProcess records for a partition, applies each fee via SetBalanceClameFee, updates EndOfWeekFee, queues balance notifications to FeeQueueInMem, and marks the partition complete.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Partition (partition slice of FeeNightProcess to process) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Each night (and over weekends), eToro charges overnight/weekend fees to positions holding CFDs and leveraged instruments. `Trade.FeeNightProcess` is the pre-populated queue of fees to be charged. This procedure processes one partition slice of that queue, enabling parallel execution across multiple partitions.

The procedure handles two fee types distinguished by the `Fee` column:
- **Fee=1** -> Overnight fee (non-weekend): charges daily for holding leveraged positions overnight
- **Fee!=1** -> Weekend fee: charged for the multi-day weekend hold

For each position, it:
1. Updates `EndOfWeekFee` on the position record (live or archived)
2. Calls `Customer.SetBalanceClameFee` to deduct the fee from the customer's balance
3. Queues a notification to `dbo.FeeQueueInMem` (in-memory table for near-real-time user notifications) when the customer or mirror changes

Individual position failures are isolated: a failed position is recorded in `Trade.FeeNightProcess` with StatusID=-1 and the loop continues. After the loop, all failed positions are archived to `History.FeeNightProcessFail` and an error is raised.

---

## 2. Business Logic

### 2.1 Partition-Based Queue Loading

**What**: Loads only the positions for the specified partition with StatusID=0 (pending).

**Columns/Parameters Involved**: `Trade.FeeNightProcess.PartitionCol`, `Trade.FeeNightProcess.StatusID`

**Rules**:
- SELECT from Trade.FeeNightProcess WHERE PartitionCol=@Partition AND StatusID=0
- Loaded into temp table #PositionsToChargeWithFee with ROW_NUMBER() for ordered iteration
- Indexes created on temp table: CIX(ID), IX_PositionID, TmpIndex(CID, MirrorID)
- `OPTION (RECOMPILE)` on the initial SELECT for optimal execution plan

### 2.2 Fee Type Determination

**What**: Determines whether each position is being charged a weekend fee or overnight fee.

**Columns/Parameters Involved**: `Trade.FeeNightProcess.Fee`, `@IsWeekendFee`

**Rules**:
- @IsWeekendFee = CASE WHEN Fee=1 THEN 0 ELSE 1 END
  - Fee=1 -> @IsWeekendFee=0 -> Overnight fee
  - Fee!=1 -> @IsWeekendFee=1 -> Weekend fee
- Controls which timestamp column is updated on PositionTbl:
  - @IsWeekendFee=0: SET LastOverNightClameDate = GETUTCDATE()
  - @IsWeekendFee=1: SET LastEOWClameDate = GETUTCDATE()
- Controls FeeQueueInMem CreditTypeID:
  - @IsWeekendFee=1: CreditTypeID=14 (weekend fee), ReasonID=1
  - @IsWeekendFee=0: CreditTypeID=-14 (overnight fee), ReasonID=2

**Diagram**:
```
Fee=1  -> Overnight -> @IsWeekendFee=0 -> LastOverNightClameDate, CreditTypeID=-14, ReasonID=2
Fee!=1 -> Weekend   -> @IsWeekendFee=1 -> LastEOWClameDate,       CreditTypeID=14,  ReasonID=1
```

### 2.3 EndOfWeekFee Update with Closed-Position Fallback

**What**: Accumulates the fee in the position record, falling back to History table if already closed.

**Columns/Parameters Involved**: `Trade.PositionTbl.EndOfWeekFee`, `History.Position_Active.EndOfWeekFee`, `PartitionCol`

**Rules**:
- UPDATE Trade.PositionTbl SET EndOfWeekFee += @FeeInDollars, LastOverNightClameDate/LastEOWClameDate = GETUTCDATE()
  WHERE PositionID=@PositionID AND PartitionCol=@PositionID%50
- IF @@ROWCOUNT=0: UPDATE History.Position_Active SET EndOfWeekFee += @FeeInDollars WHERE PositionID=@PositionID
- Note: no check of StatusID on the History fallback - applies to any archived position

### 2.4 FeeQueueInMem Notifications (CID/Mirror Change Boundary)

**What**: Sends a batched fee notification when the processing crosses a CID or MirrorID boundary.

**Columns/Parameters Involved**: `dbo.FeeQueueInMem`, `@OldCID`, `@OldMirrorID`, `@SumOfFee`

**Rules**:
- Notification is emitted when (@CID <> @OldCID) OR (ISNULL(@MirrorID,0) <> ISNULL(@OldMirrorID,0))
- Uses the PREVIOUS customer's accumulated @SumOfFee (0-@SumOfFee negated)
- CreditTypeID=14 (weekend) or -14 (overnight)
- CASE WHEN @OldIsFromMirror=1 THEN @OldMirrorID ELSE 0 END for MirrorID field
- After loop: inserts final row for the last customer (@CID with current @SumOfFee)

### 2.5 Per-Position Error Isolation

**What**: Failed positions are skipped and marked, not allowed to abort the entire batch.

**Columns/Parameters Involved**: `Trade.FeeNightProcess.StatusID`, `Trade.FeeNightProcess.ErrorMessage`, `History.FeeNightProcessFail`

**Rules**:
- CATCH: ROLLBACK, @FailedPosition++, DELETE from #PositionsToChargeWithFee, UPDATE Trade.FeeNightProcess SET StatusID=-1, ErrorMessage=@ErrorMessage
- Loop continues to next position
- Post-loop: IF @FailedPosition > 0: RAISERROR (severity 10, informational warning)
- IF EXISTS (SELECT FROM FeeNightProcess WHERE StatusID=-1 AND PartitionCol=@Partition):
  - INSERT failed records INTO History.FeeNightProcessFail
  - RAISERROR (severity 16, error)
- Final: UPDATE Trade.FeeNightProcessJobsLogs SET LastExecuteSuccessfully=GETUTCDATE() WHERE Mod=@Partition

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Partition | INT | NO | - | CODE-BACKED | The partition slice of Trade.FeeNightProcess to process. Filtered by PartitionCol=@Partition. Enables parallel execution: multiple instances can process different partitions simultaneously. Also used to update Trade.FeeNightProcessJobsLogs.Mod=@Partition on completion. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Partition | Trade.FeeNightProcess | READ + UPDATE | Source queue: reads StatusID=0 records; marks StatusID=1 (done) or StatusID=-1 (failed) per position |
| @PositionID | Trade.PositionTbl | UPDATE (WRITE) | Increments EndOfWeekFee; updates LastOverNightClameDate or LastEOWClameDate per fee type |
| @PositionID | History.Position_Active | UPDATE (WRITE) | Fallback EndOfWeekFee update for positions closed before fee processing |
| @CID/@MirrorID | Customer.SetBalanceClameFee | EXEC (CALL) | Charges the fee from the customer's balance per position |
| @OldCID | dbo.FeeQueueInMem | INSERT (WRITE) | In-memory notification queue: batched by CID/MirrorID boundary for near-real-time user notifications |
| On error | History.FeeNightProcessFail | INSERT (WRITE) | Archives failed fee records for investigation |
| @Partition | Trade.FeeNightProcessJobsLogs | UPDATE (WRITE) | Updates LastExecuteSuccessfully timestamp on completion |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PayForFeeProcess (procedure)
+-- Trade.FeeNightProcess (table) [READ + UPDATE - fee queue source and status tracking]
+-- Trade.PositionTbl (table) [UPDATE - EndOfWeekFee + date stamps]
+-- History.Position_Active (table) [UPDATE - fallback for closed positions]
+-- Customer.SetBalanceClameFee (procedure) [EXEC - balance deduction per position]
+-- dbo.FeeQueueInMem (table) [INSERT - real-time notification queue]
+-- History.FeeNightProcessFail (table) [INSERT - fail archive]
+-- Trade.FeeNightProcessJobsLogs (table) [UPDATE - completion timestamp]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.FeeNightProcess | Table | Fee queue: reads pending (StatusID=0) records for partition; updates to 1 (done) or -1 (failed) |
| Trade.PositionTbl | Table | Updated with EndOfWeekFee delta + last-charge timestamps per fee type |
| History.Position_Active | Table | Fallback update for positions that closed between fee calculation and processing |
| Customer.SetBalanceClameFee | Stored Procedure | Deducts fee from customer balance, returns @IsFromMirror |
| dbo.FeeQueueInMem | Table | In-memory table: receives batched fee notifications by customer/mirror boundary |
| History.FeeNightProcessFail | Table | Archives positions that failed processing for investigation |
| Trade.FeeNightProcessJobsLogs | Table | Updated on success: LastExecuteSuccessfully for the partition's Mod entry |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Per-position transaction (BEGIN TRAN/COMMIT) | Design | Each position is its own transaction - failure of one does not affect others |
| OPTION (RECOMPILE) | Performance | Forces fresh execution plan for the FeeNightProcess partition scan |
| Temp table indexes (CIX, IX_PositionID, TmpIndex) | Performance | Three indexes on #PositionsToChargeWithFee for efficient loop iteration |
| Fee=1 -> overnight, Fee!=1 -> weekend | Business rule | Fee column value 1 = non-weekend (overnight) fee; any other value = weekend fee |
| Severity 10 vs 16 | Error handling | @FailedPosition>0 raises severity 10 (warning, execution continues); StatusID=-1 records raise severity 16 (error) |
| dbo.FeeQueueInMem vs Service Broker | Design note | Comment in code: "we use table instead of service broker" - fee notifications use in-memory table for lower latency |

---

## 8. Sample Queries

### 8.1 Check pending fees in a partition
```sql
SELECT TOP 20
    PositionID,
    CID,
    MirrorID,
    FeeInDollars,
    Fee,
    StatusID,
    PartitionCol
FROM Trade.FeeNightProcess WITH (NOLOCK)
WHERE PartitionCol = 5
  AND StatusID = 0
ORDER BY CID, MirrorID;
```

### 8.2 Check failed fees for a partition
```sql
SELECT TOP 10
    PositionID,
    CID,
    FeeInDollars,
    ErrorMessage,
    StatusID
FROM Trade.FeeNightProcess WITH (NOLOCK)
WHERE PartitionCol = 5
  AND StatusID = -1;
```

### 8.3 Check partition job completion log
```sql
SELECT
    Mod,
    LastExecuteSuccessfully
FROM Trade.FeeNightProcessJobsLogs WITH (NOLOCK)
ORDER BY Mod;
```

### 8.4 Check fail archive after a failed run
```sql
SELECT TOP 10
    PositionID,
    CID,
    FeeInDollars,
    ErrorMessage,
    StatusID
FROM History.FeeNightProcessFail WITH (NOLOCK)
ORDER BY PositionID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (1,5,8,9B,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (SetBalanceClameFee) | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PayForFeeProcess | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PayForFeeProcess.sql*
