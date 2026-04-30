# Trade.PostPositionOpenForSdrtCharge

> SDRT (Stamp Duty Reserve Tax) batch charge processor that applies per-position SDRT fees via Customer.SetBalanceClameFee, notifies customers via dbo.FeeQueueInMem at CID/mirror boundaries, deduplicates already-charged positions, and archives successful charges to History.PostPositionOpenForSdrt.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Trade.PostPositionOpenForSdrt.PositionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.PostPositionOpenForSdrtCharge is a scheduled job SP that processes pending Stamp Duty Reserve Tax (SDRT) charges for newly opened positions. SDRT is a UK tax on equity share transactions; when UK customers open stock positions, an SDRT fee is assessed at the time of opening and must be charged to their account.

The SP processes pending queue records from Trade.PostPositionOpenForSdrt in batches, applying each fee via Customer.SetBalanceClameFee. It batches FeeQueueInMem notifications by CID+MirrorID group (rather than per-position) to minimize notification traffic: one fee notification is sent per customer/mirror change-of-boundary rather than per position.

Key behaviors:
1. **Deduplication**: Before charging, positions already in History.PostPositionOpenForSdrt (within the last month) are removed from the batch - prevents double-charging positions that were already processed
2. **Row-by-row WHILE loop**: Each position is charged individually within its own transaction. This allows partial batch success (failed positions get StatusID decremented; successful positions continue)
3. **Boundary-triggered notification**: dbo.FeeQueueInMem inserts happen when CID or MirrorID changes between consecutive positions (sorted by CID, MirrorID, PositionID), accumulating SumOfFee across the group
4. **Two-phase commit**: Main WHILE loop commits per-position; post-loop block moves all StatusID=1 (success) rows to History.PostPositionOpenForSdrt in a separate transaction

---

## 2. Business Logic

### 2.1 Batch Load and Deduplication

**What**: Loads pending SDRT charges and removes any already-processed positions.

**Rules**:
- SELECT TOP(@BatchSize) * FROM Trade.PostPositionOpenForSdrt WHERE StatusID=@StatusID ORDER BY CID, MirrorID, PositionID
- @RowsToExecute = @@ROWCOUNT (OUTPUT parameter - caller knows if work was done)
- If @RowsToExecute=0: RETURN immediately (no work)
- CREATE CLUSTERED INDEX IX_PositionID on #PositionsToChargeWithSdrt(PositionID)
- Deduplication: DELETE rows from #temp WHERE PositionID exists in History.PostPositionOpenForSdrt AND OccurredAsDate > DATEADD(MONTH,-1, GETUTCDATE())
- Deleted PositionIDs collected in @PositionIDsToDelete table variable
- DELETE Trade.PostPositionOpenForSdrt WHERE PositionID IN @PositionIDsToDelete (clean from live queue too)
- dbo.FeeQueueInMem cleanup: DELETE WHERE Status=1 (clears processed notifications before starting)

### 2.2 Initial Row Selection (Pre-Loop)

**What**: Seeds loop variables from the first row of the batch.

**Rules**:
- SELECT TOP 1 with ORDER BY CID, MirrorID, PositionID
- Initializes: @PositionID, @ParentPositionID, @CID, @OldCID (=@CID), @MirrorID, @OldMirrorID (=@MirrorID), @FeeInDollars, @InstrumentID
- @OldIsFromMirror = CASE WHEN ISNULL(@MirrorID,0) > 0 THEN 1 ELSE 0 END
- @MirrorIsActive, @OldMirrorIsActive from first row

### 2.3 Per-Position WHILE Loop

**What**: Processes each position in the batch sequentially.

**Rules**:
- WHILE EXISTS (SELECT * FROM #PositionsToChargeWithSdrt)
- Each iteration: BEGIN TRAN / END TRY / BEGIN CATCH / COMMIT or ROLLBACK

**Per-position transaction**:
1. EXEC Customer.SetBalanceClameFee @PositionID, @CID, @MirrorID, @FeeInDollars, @ParentPositionID, @Description='SDRT Charge', @IsFromMirror OUTPUT
2. Boundary check: IF (@CID <> @OldCID) OR (ISNULL(@MirrorID,0) <> ISNULL(@OldMirrorID,0)):
   - Insert dbo.FeeQueueInMem for @OldCID with accumulated @SumOfFee (negated: 0 - @SumOfFee)
   - Reset Olds: @OldCID=@CID, @OldMirrorID=@MirrorID, @SumOfFee=@FeeInDollars, @OldIsFromMirror=@IsFromMirror, @OldMirrorIsActive=@MirrorIsActive
   - CreditTypeID=14, ReasonID=2, MirrorID=(MirrorID when @OldIsFromMirror=1 else 0), InstrumentID=0, isFundParam=0, Status=0
3. No boundary change: @SumOfFee += @FeeInDollars (accumulate within group)
4. UPDATE Trade.PostPositionOpenForSdrt SET StatusID=1 WHERE PositionID=@PositionID AND StatusID=@StatusID
5. If @@ROWCOUNT=1: COMMIT; else ROLLBACK (guards against concurrent status changes)
6. CATCH: ROLLBACK + UPDATE StatusID = StatusID - 1 (decrement for retry)
7. DELETE current row from #temp
8. SELECT TOP 1 next row (ORDER BY CID, MirrorID, PositionID)

### 2.4 Final Boundary Notification

**What**: Inserts the last group's fee notification after the loop exits.

**Rules**:
- INSERT dbo.FeeQueueInMem for @CID (last group) with @SumOfFee
- Uses @IsFromMirror (not @OldIsFromMirror) for the last row
- CreditTypeID=14, ReasonID=2, MirrorID=(MirrorID when @IsFromMirror=1 else 0), InstrumentID=0, isFundParam=0, Status=0
- DiffAmountInDollars = 0 - @SumOfFee (negated - fee is a debit)

### 2.5 History Archive (Post-Loop)

**What**: Moves all successfully charged rows to History.PostPositionOpenForSdrt.

**Rules**:
- SELECT * INTO #PostPositionOpenSdrtChargeSuccess FROM Trade.PostPositionOpenForSdrt WHERE StatusID=1
- INSERT INTO History.PostPositionOpenForSdrt: PositionID, ParentPositionID, CID, MirrorID, InstrumentID, OpenActionType, FeeInDollars, MirrorIsActive, Leverage, IsBuy
- DELETE FROM Trade.PostPositionOpenForSdrt WHERE PositionID IN (success set)
- Wrapped in BEGIN TRAN / COMMIT; CATCH prints error and ROLLBACKs (non-fatal - rows remain in queue with StatusID=1 for next run)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BatchSize | INT | NO | - | CODE-BACKED | Maximum number of Trade.PostPositionOpenForSdrt rows to process per execution. Controls transaction duration and memory. |
| 2 | @StatusID | INT | NO | - | CODE-BACKED | Status filter: 0=pending (normal execution), -1/-2=retry states (decremented on failure). StatusID=1=success (moved to history). |
| 3 | @RowsToExecute | INT | NO | - | CODE-BACKED | OUTPUT. @@ROWCOUNT of the initial SELECT - number of rows in the loaded batch (before deduplication removal). Allows callers to determine if there is more work to do. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT / DELETE | Trade.PostPositionOpenForSdrt | DML read+write | Source queue; StatusID update; cleanup of success rows |
| DELETE (dedup) | History.PostPositionOpenForSdrt | DML read | Deduplication: positions charged in the last month are excluded |
| DELETE / SELECT | dbo.FeeQueueInMem | DML read+write | Clears old notifications; inserts fee notifications at CID/mirror boundaries |
| EXEC | Customer.SetBalanceClameFee | Procedure call | Applies SDRT fee to customer balance |
| INSERT | History.PostPositionOpenForSdrt | DML write | Archives successfully charged positions |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by SQL Agent job on schedule (comment: "This procedure will be executed by Job").

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PostPositionOpenForSdrtCharge (procedure)
+-- Trade.PostPositionOpenForSdrt (table) - source queue
+-- History.PostPositionOpenForSdrt (table) - deduplication check + archive target
+-- dbo.FeeQueueInMem (table) - customer fee notification queue
+-- Customer.SetBalanceClameFee (procedure) - balance charge execution
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PostPositionOpenForSdrt | Table | SELECT pending; UPDATE StatusID; DELETE after archive |
| History.PostPositionOpenForSdrt | Table | Deduplication check (last month); INSERT archive on success |
| dbo.FeeQueueInMem | Table | DELETE Status=1 on init; INSERT fee notifications at CID/mirror boundaries |
| Customer.SetBalanceClameFee | Stored Procedure | Applies SDRT charge to customer's balance; returns @IsFromMirror |

### 6.2 Objects That Depend On This

No dependents found in SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- Row-by-row WHILE loop is intentional (not a set-based operation) to allow per-position error isolation
- dbo.FeeQueueInMem notifications are batched by CID+MirrorID: one INSERT per customer/mirror group, not per position (reduces notification noise)
- DiffAmountInDollars stored as NEGATIVE (0 - @SumOfFee) because fees are debits from the customer's perspective
- The @IsFromMirror OUTPUT from Customer.SetBalanceClameFee determines whether to reference the MirrorID in FeeQueueInMem
- Failure decrement: StatusID = StatusID - 1 (preserves the full failure chain for monitoring)
- The DEBUG PRINT statements (visible in code) indicate this SP was actively debugged in production; they have performance implications
- History archive failure (ERROR 2 block) is non-fatal: rows remain at StatusID=1 and will be picked up again on next run

---

## 8. Sample Queries

### 8.1 Process a batch of 50 pending SDRT charges

```sql
DECLARE @RowsToExecute INT;
EXEC Trade.PostPositionOpenForSdrtCharge @BatchSize=50, @StatusID=0, @RowsToExecute=@RowsToExecute OUTPUT;
SELECT @RowsToExecute AS RowsInBatch;
```

### 8.2 Check pending SDRT queue status

```sql
SELECT StatusID, COUNT(*) AS RecordCount, SUM(FeeInDollars) AS TotalFeeUSD
FROM Trade.PostPositionOpenForSdrt WITH (NOLOCK)
GROUP BY StatusID
ORDER BY StatusID;
```

### 8.3 Check recently archived SDRT charges

```sql
SELECT TOP 100 PositionID, CID, MirrorID, FeeInDollars, IsBuy
FROM History.PostPositionOpenForSdrt WITH (NOLOCK)
WHERE OccurredAsDate > DATEADD(DAY, -7, GETUTCDATE())
ORDER BY OccurredAsDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos searched / 0 files | Corrections: 0 applied*
*Object: Trade.PostPositionOpenForSdrtCharge | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PostPositionOpenForSdrtCharge.sql*
