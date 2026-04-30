# Trade.MirrorReopen

> Restores a previously closed copy-trade mirror by re-creating it via Trade.RegisterMirror (with @IsReopenMirror=1), linking the new mirror to the closed one via ReopenForMirrorID, sending a Service Broker notification to the position service, and recording the reopen outcome in History.MirrorToReopen.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ClosedMirrorID + @CID + @ReopenOperationID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.MirrorReopen is the single-mirror executor in the mirror reopen workflow. When a copier's mirror was previously closed (unregistered) and they (or an admin process) want to restore it, this procedure validates the reopen is legal, reconstructs the mirror with the same settings as the original (drawn from History.Mirror), and links the new mirror back to the old one.

The procedure is called row-by-row from Trade.MirrorsReopen, which drives a cursor over Trade.MirrorToReopen (the pending reopen queue) filtered by ReopenTypeID=2. Each call either succeeds (Result=1 in History.MirrorToReopen) or fails gracefully (Result=0 with FailReason), and in both cases the row is removed from Trade.MirrorToReopen.

The MSL (Mirror Stop Loss) handling is special: if the mirror's Amount has been reduced below the original absolute MSL, the @AllowUpdateMirrorSL flag determines whether to silently recalculate the MSL to the percentage-of-Amount equivalent, or to reject the reopen entirely.

---

## 2. Business Logic

### 2.1 Pre-Validation (Mirror State Checks)

**What**: Ensures the closed mirror is in a valid state for reopening before reading its data.

**Columns/Parameters Involved**: `Trade.Mirror.MirrorID`, `Trade.Mirror.ReopenForMirrorID`, `History.Mirror.MirrorOperationID`

**Rules**:
- IF EXISTS Trade.Mirror WHERE MirrorID=@ClosedMirrorID AND CID=@CID: RAISERROR("Mirror exists in Trade.Mirror") - the mirror is still active, cannot reopen
- IF EXISTS Trade.Mirror WHERE ReopenForMirrorID=@ClosedMirrorID AND CID=@CID: RAISERROR("Reopen Mirror exists in Trade.Mirror") - already been reopened
- IF NOT EXISTS History.Mirror WHERE MirrorID=@ClosedMirrorID AND CID=@CID AND MirrorOperationID=2: RAISERROR("Mirror not exists in History.Mirror with MirrorOperation = UnRegister Mirror") - not properly closed (MirrorOperationID=2 is UnRegister/Close)

### 2.2 Closed Mirror Data Load

**What**: Reads the original mirror settings from History.Mirror to reconstruct the mirror.

**Columns/Parameters Involved**: `History.Mirror` (MirrorOperationID=2 row)

**Rules**:
- SELECT from History.Mirror WHERE MirrorID=@ClosedMirrorID AND CID=@CID AND MirrorOperationID=2
- Loads: @ParentCID, @ParentUserName, @Amount (investment), @OldMirrorSL, @MirrorSLPercentage, @MirrorTypeID, @IsOpenOpen, @RealizedEquity, @PauseCopy, @InitialInvestment, @DepositSummary, @WithdrawalSummary, @NetProfit, @UseCopyDividend, @GuruTPV, @MirrorCalculationType (ISNULL -> 0)
- If the same leader is currently being copied by the same copier: EXISTS Trade.Mirror WHERE CID=@CID AND ParentCID=@ParentCID -> RAISERROR("Mirror exists in Trade.Mirror")

### 2.3 MSL Consistency and Balance Check

**What**: Ensures the stored Amount is still above the MSL threshold, and the copier has sufficient balance.

**Columns/Parameters Involved**: `@Amount`, `@OldMirrorSL`, `@MirrorSLPercentage`, `@AllowUpdateMirrorSL`, `Customer.CustomerMoney.Credit`

**Rules**:
- SELECT @UserCredit = Credit FROM Customer.CustomerMoney WHERE CID=@CID
- IF @Amount <= @OldMirrorSL (investment has shrunk to or below the stop level):
  - IF @AllowUpdateMirrorSL=0: RAISERROR("The Amount is lower then MSL Amount") - strict mode
  - IF @AllowUpdateMirrorSL=1: @MirrorSL = ROUND((@Amount * @MirrorSLPercentage)/100, 2) - recalculate MSL from percentage
- IF @Amount > @OldMirrorSL: @MirrorSL = @OldMirrorSL (preserve original absolute MSL)
- IF @ValidateUserBalance=1 AND @UserCredit < @Amount: RAISERROR("Insufficient Funds")

### 2.4 Mirror Re-Creation

**What**: Creates the new mirror via Trade.RegisterMirror with @IsReopenMirror=1 to skip MSL consistency check.

**Columns/Parameters Involved**: `Trade.RegisterMirror`, `@MirrorID OUTPUT`, `@Occurred OUTPUT`

**Rules**:
- @AmountInCents = @Amount * 100
- EXEC Trade.RegisterMirror @CID, @ParentCID, @AmountInCents, @MirrorID OUTPUT, @MirrorTypeID, @IsOpenOpen, @GuruTPV, @MirrorSL, @MirrorSLPercentage, @ParentUserName, @SessionID=-1, @Occurred OUTPUT, @ClientRequestGuid=NULL, @ValidateUserBalance, @IsReopenMirror=1, @InitialInvestment, @DepositSummary, @WithdrawalSummary, @NetProfit, @MirrorCalculationType
- @SessionID=-1 (system-initiated, not user session)
- @IsReopenMirror=1 bypasses the MSL round-check in Trade.RegisterMirror

### 2.5 Link New Mirror to Closed Mirror

**What**: Creates the bidirectional traceability link between the reopened mirror and its predecessor.

**Columns/Parameters Involved**: `Trade.Mirror.ReopenForMirrorID`

**Rules**:
- UPDATE Trade.Mirror SET ReopenForMirrorID=@ClosedMirrorID WHERE MirrorID=@MirrorID
- This allows querying the lineage: "which old mirror does this new mirror replace?"

### 2.6 Service Broker Notification

**What**: Notifies the position service of the reopen event so it can copy the leader's open positions if @IsOpenOpen=1.

**Columns/Parameters Involved**: `svcInitiator -> svcPosition`, `ctrAnyXMLData`, `mtAnyXMLData`

**Rules**:
- Builds XML with OperationTypeId=5 (Reopen Mirror) and TradingData from Trade.Mirror WHERE MirrorID=@MirrorID
- TradingData includes: CID, MirrorID, ParentCID, ParentUserName, Amount, MirrorSL, MirrorSLPercentage, CopyOpenPositions (IsOpenOpen), InitDateTime (Occurred), MirrorCalculationType
- BEGIN DIALOG CONVERSATION @Handle FROM svcInitiator TO svcPosition ON CONTRACT ctrAnyXMLData
- SEND ON CONVERSATION @Handle MESSAGE TYPE mtAnyXMLData (@XMLResult)
- END CONVERSATION @Handle (one-way fire-and-forget)

### 2.7 Outcome Recording and Queue Cleanup

**What**: Records the reopen result (success or failure) and removes the row from the pending queue.

**Columns/Parameters Involved**: `History.MirrorToReopen`, `Trade.MirrorToReopen`

**Rules**:
- On success: INSERT INTO History.MirrorToReopen (ReopenOperationID, CID, ClosedMirrorID, ReopenMirrorID=@MirrorID, RequestReopenOccurred, Result=1, NewMirrorSL=IIF(@OldMirrorSL<>@MirrorSL, @MirrorSL, NULL))
- On failure (CATCH): INSERT INTO History.MirrorToReopen (..., ReopenMirrorID=@MirrorID, Result=0, FailReason='Trade.ReopenMirror Failed: ' + @ErrorMessage)
- DELETE FROM Trade.MirrorToReopen WHERE ClosedMirrorID=@ClosedMirrorID AND ReopenOperationID=@ReopenOperationID (both success and failure paths)

### 2.8 Transaction and Error Handling

**What**: Outer TRY/CATCH with explicit transaction inside the TRY.

**Rules**:
- SET XACT_ABORT ON
- TRY opens at procedure start; BEGIN TRANSACTION is deferred until after validations pass
- CATCH: IF @@TRANCOUNT=1 ROLLBACK, IF @@TRANCOUNT>1 COMMIT
- If @ErrorMessage was not set by a specific validation (custom RAISERROR), it defaults to ERROR_MESSAGE() from the caught error
- History.MirrorToReopen and DELETE from Trade.MirrorToReopen run in CATCH too (always record outcome)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ReopenOperationID | INT | NO | - | CODE-BACKED | The batch reopen operation this request belongs to. Links to Trade.ReopenOperation.ReopenOperationID. Used to find the Trade.MirrorToReopen row to process and delete. |
| 2 | @CID | INT | NO | - | CODE-BACKED | Copier's customer ID. Used for all validation queries and passed to Trade.RegisterMirror. |
| 3 | @ClosedMirrorID | INT | NO | - | CODE-BACKED | The MirrorID of the mirror to be reopened. Must exist in History.Mirror with MirrorOperationID=2 (UnRegister/Close). |
| 4 | @ValidateUserBalance | TINYINT | NO | - | CODE-BACKED | 1=check copier has sufficient balance; 0=bypass balance check. Passed directly to Trade.RegisterMirror. |
| 5 | @AllowUpdateMirrorSL | BIT | NO | - | CODE-BACKED | 1=recalculate MSL if Amount <= OldMirrorSL (MSL = Amount * MirrorSLPercentage / 100); 0=reject reopen if Amount <= OldMirrorSL. Controls MSL adjustment on reopen. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ClosedMirrorID, @CID | Trade.Mirror | Read | Validates mirror is not still active; checks for existing reopen; checks copier not already copying same leader |
| @ClosedMirrorID, @CID | History.Mirror | Read | Validates mirror was properly closed (MirrorOperationID=2); reads all original mirror settings for reconstruction |
| @CID | Customer.CustomerMoney | Read | Balance check before reopen |
| @CID, @MirrorID | Trade.RegisterMirror | EXEC | Re-creates the mirror with @IsReopenMirror=1 |
| @MirrorID | Trade.Mirror | Write | UPDATE ReopenForMirrorID=@ClosedMirrorID after RegisterMirror |
| svcInitiator -> svcPosition | Service Broker | Async Notify | OperationTypeId=5 Reopen Mirror notification to position service |
| @ReopenOperationID, @ClosedMirrorID | Trade.MirrorToReopen | Read + Delete | Reads request details; deletes processed row from queue |
| @ReopenOperationID | History.MirrorToReopen | Write | Records success (Result=1) or failure (Result=0) outcome |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.MirrorsReopen | Cursor loop | EXEC | Bulk reopen driver: iterates Trade.MirrorToReopen for ReopenOperationID where ReopenTypeID=2, calls this per row |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.MirrorReopen (procedure)
|- Trade.Mirror (table) - validation reads + ReopenForMirrorID update
|- History.Mirror (table) - closed mirror data source (MirrorOperationID=2)
|- Customer.CustomerMoney (table) - balance check
|- Trade.RegisterMirror (procedure)
|   |- Trade.Mirror, Trade.PostDetachOperation, Customer.SetBalance, ...
|- Trade.MirrorToReopen (table) - pending queue read + delete
|- History.MirrorToReopen (table) - outcome record write
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Validation reads; UPDATE ReopenForMirrorID |
| History.Mirror | Table | Original mirror settings (MirrorOperationID=2 row) |
| Customer.CustomerMoney | Table | Balance check (Credit column) |
| Trade.RegisterMirror | Procedure | Creates the new mirror row with @IsReopenMirror=1 |
| Trade.MirrorToReopen | Table | Queue source; DELETE after processing |
| History.MirrorToReopen | Table | Outcome audit record (success + failure) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.MirrorsReopen | Procedure | Batch executor: iterates Trade.MirrorToReopen and calls this per CID/ClosedMirrorID combination |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- SET XACT_ABORT ON; BEGIN TRANSACTION deferred until after all validations pass (pre-validation errors do not require rollback)
- @SessionID hardcoded to -1 (system-initiated reopen, not tied to a real user session)
- @ClientRequestGuid hardcoded to NULL (no deduplication on reopen path)
- Both success and failure CATCH paths: INSERT History.MirrorToReopen + DELETE Trade.MirrorToReopen (outcome always recorded, queue always drained)
- History.MirrorToReopen.NewMirrorSL is non-NULL only when MSL was adjusted (OldMirrorSL <> computed MirrorSL), providing audit trail of MSL changes on reopen
- Service Broker conversation is fire-and-forget (END CONVERSATION immediately after SEND)
- MirrorOperationID=2 is the closed/unregistered state required for reopening
- ReopenTypeID=2 in Trade.ReopenOperation filters which batch reopen operations this procedure handles (other types may exist)

---

## 8. Sample Queries

### 8.1 Check reopen history for a mirror

```sql
SELECT htr.ReopenOperationID, htr.CID, htr.ClosedMirrorID, htr.ReopenMirrorID,
       htr.RequestReopenOccurred, htr.Result, htr.FailReason, htr.NewMirrorSL
FROM History.MirrorToReopen WITH (NOLOCK) htr
WHERE htr.CID = <CID>
ORDER BY htr.RequestReopenOccurred DESC;
```

### 8.2 Find mirrors linked to a closed predecessor

```sql
SELECT MirrorID, CID, ParentCID, Amount, Occurred, ReopenForMirrorID
FROM Trade.Mirror WITH (NOLOCK)
WHERE ReopenForMirrorID = <ClosedMirrorID>;
```

### 8.3 Check pending reopen queue

```sql
SELECT mtr.ReopenOperationID, mtr.CID, mtr.ClosedMirrorID,
       mtr.ValidateUserBalance, mtr.AllowUpdateMirrorSL, mtr.RequestOccurred,
       ro.ReopenTypeID, ro.IsExecuted
FROM Trade.MirrorToReopen mtr WITH (NOLOCK)
JOIN Trade.ReopenOperation ro WITH (NOLOCK) ON mtr.ReopenOperationID = ro.ReopenOperationID
WHERE ro.ReopenTypeID = 2 AND ro.IsExecuted = 0
ORDER BY mtr.ClosedMirrorID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 SP caller (Trade.MirrorsReopen) | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Trade.MirrorReopen | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.MirrorReopen.sql*
