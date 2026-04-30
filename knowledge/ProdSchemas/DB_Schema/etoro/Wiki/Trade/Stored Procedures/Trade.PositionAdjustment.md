# Trade.PositionAdjustment

> Adjusts an existing position by closing it with a neutral P&L and immediately reopening it with a new amount/units, re-wiring child positions in the CopyTrader tree and auditing the close/open pair.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @positionsToClose + @opsRequestId (the position being adjusted and the ops request) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Position adjustments are operations where a position must be re-stated with a different amount or unit count - typically triggered by operations teams for corporate action adjustments, instrument migrations, or corrections. The adjustment is atomic: the old position is closed at cost (zero net profit) and a new position is opened with the adjusted parameters in the same transaction.

This procedure handles exactly ONE position at a time (enforced by COUNT guard). The close uses ActionType=20 (adjustment close) and the open uses ActionType=7. The caller provides execution rate and timing parameters to ensure the new position reflects the correct market context.

A critical secondary function is **CopyTrader tree re-wiring**: when the closed position was a tree root or had child positions, those children must be re-pointed to the new position ID. Direct children get their `ParentPositionID` updated; for direct (non-mirror) positions, ALL tree descendants get their `TreeID` updated. All re-wiring changes are logged to `History.PositionChangeLog_Active_BIGINT` with ChangeTypeID=15 (adjustment).

The procedure returns THREE result sets for the calling service:
1. The closed position data (for hedge server notifications)
2. The newly opened position data (from Trade.Position)
3. Customer CID, GCID, CountryID (for downstream processing)

---

## 2. Business Logic

### 2.1 Single-Position Guard

**What**: Enforces that only one position can be adjusted at a time.

**Columns/Parameters Involved**: `@positionsToClose COUNT`

**Rules**:
- IF (SELECT COUNT(PositionID) FROM @positionsToClose) > 1: RAISERROR('Can handle only one position each time'), RETURN(-1)
- Design constraint: adjustment is fundamentally a single-position operation; batch close/open atomicity across multiple positions is not supported

### 2.2 Pending Close Guard

**What**: Blocks adjustment if the position already has a pending close in progress.

**Columns/Parameters Involved**: `Trade.CloseExecutionPlan.PositionID`

**Rules**:
- IF EXISTS (SELECT 1 FROM @positionsToClose A WHERE EXISTS (SELECT 1 FROM Trade.CloseExecutionPlan B WHERE A.PositionID=B.PositionID)): RAISERROR('Cannot handle pending close position'), RETURN(-1)
- Prevents race condition: adjusting a position that's already being closed via normal execution path

### 2.3 Close-Then-Open Pattern (Atomic Adjustment)

**What**: Closes the old position at zero profit and opens a new one with adjusted parameters.

**Columns/Parameters Involved**: `@positionCloseActionType=20`, `@positionOpenActionType=7`, `@netProfit=0`

**Rules**:
- EXEC Trade.PositionClose: @ActionType=20, @NetProfit=0, @EndForexRate=InitForexRate (close at cost)
- @Amount = ROUND(@initForexRate * @amountInUnits * 100.0, 0) -- calculated in cents from the new unit count
- EXEC Trade.PositionOpen: @OpenActionType=7, @Amount=@Amount (recalculated), @AmountInUnitsDecimal=@amountInUnits
- New @PositionID is OUTPUT from Trade.PositionOpen
- Both within single BEGIN TRAN / COMMIT

### 2.4 CopyTrader Tree Re-wiring

**What**: Updates child positions to point to the new position ID when the adjusted position was a parent.

**Columns/Parameters Involved**: `Trade.PositionTbl.ParentPositionID`, `Trade.PositionTbl.TreeID`, `History.PositionChangeLog_Active_BIGINT.ChangeTypeID`

**Rules**:
- **Direct children** (always): SELECT children with ParentPositionID=OLD PositionID -> UPDATE ParentPositionID=NEW @positionId
  - Log each change to History.PositionChangeLog_Active_BIGINT with ChangeTypeID=15
- **Tree descendants** (IF @MirrorID=0 only - not for mirror positions): SELECT ALL positions with TreeID=OLD TreeID -> UPDATE TreeID=NEW @positionId
  - Log each change to History.PositionChangeLog_Active_BIGINT with ChangeTypeID=15
  - Mirror positions do NOT get TreeID re-wired (their tree structure is managed by the mirror system)

**Diagram**:
```
@MirrorID=0 (direct position):
  Direct children: ParentPositionID -> @positionId [logged]
  All tree descendants: TreeID -> @positionId [logged]

@MirrorID>0 (mirror position):
  Direct children: ParentPositionID -> @positionId [logged]
  (no TreeID re-wire)
```

### 2.5 Adjustment Audit Record

**What**: Records the close/open pair in the audit table for traceability.

**Columns/Parameters Involved**: `Trade.PositionAdjustmentAudit.ClosedPositionID`, `Trade.PositionAdjustmentAudit.OpenedPositionID`

**Rules**:
- INSERT INTO Trade.PositionAdjustmentAudit (ClosedPositionID, OpenedPositionID)
- SELECT PositionID (old), @positionId (new) FROM #positionsToClose WHERE StatusId=1
- Enables bidirectional lookup: find the new position from old, or the old from new

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @positionsToClose | Trade.PositionIDsTbl READONLY | NO | - | CODE-BACKED | TVP containing the position ID to adjust. MUST contain exactly one row - COUNT>1 raises an error. Joined to Trade.Position to load position details into #positionsToClose temp table. |
| 2 | @cid | INT | NO | - | CODE-BACKED | Customer ID owning the position. Used in Trade.PositionOpen call and in the Customer.CustomerMoney lookup for @PositionRatio calculation. |
| 3 | @instrumentId | INT | NO | - | CODE-BACKED | Instrument for the new position. Passed to Trade.PositionOpen. Also used to resolve @StopRate from Trade.ProviderToInstrument.Precision. |
| 4 | @initForexRate | dtPrice | NO | - | CODE-BACKED | The new open rate for the adjusted position. Used to calculate @Amount (rate * amountInUnits * 100). Also used as @EndForexRate for the close (close at cost = zero P&L). |
| 5 | @amountInUnits | DECIMAL(16,6) | NO | - | CODE-BACKED | The new unit count for the adjusted position. Used to calculate @Amount = ROUND(@initForexRate * @amountInUnits * 100.0, 0) in cents. |
| 6 | @hedgeServerId | INT | NO | - | CODE-BACKED | Hedge server ID. Passed to Trade.PositionClose and Trade.PositionOpen. Also OUTPUT from PositionClose (may be updated by hedge routing). |
| 7 | @requestOccurred | DATETIME | NO | - | CODE-BACKED | Timestamp of the original ops request. Used as @RequestCloseOccurred in PositionClose and @RequestOccurred in PositionOpen. |
| 8 | @executionOccurred | DATETIME | NO | - | CODE-BACKED | Timestamp of execution. Used as @EndDateTime in PositionClose and @InitDateTime in PositionOpen. |
| 9 | @opsRequestId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | The ops team request ID for this adjustment. Used as @ClientRequestGuid in both PositionClose and PositionOpen. Returned as RequestGuid in result sets. |
| 10 | @LastOpConversionRate | dtPrice | YES | 1 | CODE-BACKED | Conversion rate for the last operation. Passed to Trade.PositionClose and Trade.PositionOpen. Defaults to 1 if not provided. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @positionsToClose | Trade.CloseExecutionPlan | READ | Pending close guard: blocks adjustment if position has in-flight close |
| @positionsToClose | Trade.Position | READ | Loads position details (CID, InstrumentID, MirrorID, TreeID, etc.) into temp table |
| @instrumentId | Trade.ProviderToInstrument | READ | Resolves Precision for @StopRate calculation |
| @cid | Customer.CustomerMoney | READ | Reads RealizedEquity for @PositionRatio calculation |
| Internal | Trade.PositionClose | EXEC (CALL) | Closes old position with ActionType=20, NetProfit=0 |
| Internal | Trade.PositionOpen | EXEC (CALL) | Opens new adjusted position with ActionType=7, new Amount/AmountInUnits |
| Internal | Trade.PositionTbl | UPDATE (WRITE) | Re-wires ParentPositionID (direct children) and TreeID (all tree descendants, non-mirror only) |
| Internal | History.PositionChangeLog_Active_BIGINT | INSERT (WRITE) | Logs tree re-wiring changes with ChangeTypeID=15 |
| Internal | Trade.PositionAdjustmentAudit | INSERT (WRITE) | Records closed/opened position ID pair for audit |
| @cid | Customer.Customer | READ | Returns CID/GCID/CountryID in result set 3 |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionAdjustment (procedure)
+-- Trade.PositionClose (procedure) [EXEC - close old position, ActionType=20, NetProfit=0]
+-- Trade.PositionOpen (procedure) [EXEC - open new position, ActionType=7, new amount]
+-- Trade.CloseExecutionPlan (table) [READ - pending close guard]
+-- Trade.Position (view) [READ - load position details]
+-- Trade.PositionTbl (table) [UPDATE - tree re-wiring: ParentPositionID, TreeID]
+-- Trade.ProviderToInstrument (table) [READ - Precision for StopRate]
+-- Customer.CustomerMoney (table) [READ - RealizedEquity for PositionRatio]
+-- History.PositionChangeLog_Active_BIGINT (table) [INSERT - tree change audit, ChangeTypeID=15]
+-- Trade.PositionAdjustmentAudit (table) [INSERT - adjustment close/open pair audit]
+-- Customer.Customer (table) [READ - CID/GCID/CountryID result set]
+-- Trade.PositionIDsTbl (UDT) [TVP input type]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionClose | Stored Procedure | Closes the original position with ActionType=20 (adjustment), NetProfit=0 |
| Trade.PositionOpen | Stored Procedure | Opens the adjusted position with the new amount/units, returns new @PositionID |
| Trade.CloseExecutionPlan | Table | Pending close check - blocks adjustment if position is mid-close |
| Trade.Position | View | Source for position details loaded into temp table |
| Trade.PositionTbl | Table | Updated for CopyTrader tree re-wiring (ParentPositionID, TreeID) |
| Trade.ProviderToInstrument | Table | Precision lookup for @StopRate calculation |
| Customer.CustomerMoney | Table | RealizedEquity for @PositionRatio calculation |
| History.PositionChangeLog_Active_BIGINT | Table | Receives ChangeTypeID=15 records for tree re-wiring events |
| Trade.PositionAdjustmentAudit | Table | Records the (ClosedPositionID, OpenedPositionID) pair |
| Customer.Customer | Table | Returns CID, GCID, CountryID in the third result set |
| Trade.PositionIDsTbl | User-Defined Table Type | TVP type for @positionsToClose input |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| COUNT(@positionsToClose) > 1 | Business guard | Single-position-only restriction - adjustment is not supported for multiple positions simultaneously |
| CloseExecutionPlan check | Race condition guard | Cannot adjust a position that is mid-close in the execution pipeline |
| @netProfit=0 | Design | Adjustment close is at-cost: zero net profit ensures no customer P&L impact from the close leg |
| @Amount = ROUND(rate * units * 100, 0) | Calculation | New amount in cents derived from new rate and unit count |
| @@TRANCOUNT checks in CATCH | Design | @@TRANCOUNT=1 -> ROLLBACK; >1 -> COMMIT (nested transaction handling) |
| ChangeTypeID=15 | Constant | Adjustment change type in PositionChangeLog_Active_BIGINT |
| @positionCloseActionType=20 | Constant | ActionType 20 = adjustment close |
| @positionOpenActionType=7 | Constant | ActionType 7 = adjustment open (re-open) |
| Three result sets | Interface | Close data + open data + customer data - all required for calling service's downstream actions |

---

## 8. Sample Queries

### 8.1 Check the adjustment audit for a position
```sql
SELECT
    ClosedPositionID,
    OpenedPositionID
FROM Trade.PositionAdjustmentAudit WITH (NOLOCK)
WHERE ClosedPositionID = 123456789
   OR OpenedPositionID = 123456789;
```

### 8.2 Find tree re-wiring log entries for an adjustment
```sql
SELECT TOP 20
    PositionID,
    ChangeTypeID,
    Occurred,
    OrigParentPositionID,
    ParentPositionID,
    PrevTreeID,
    TreeID
FROM History.PositionChangeLog_Active_BIGINT WITH (NOLOCK)
WHERE ChangeTypeID = 15
  AND Occurred >= DATEADD(HOUR, -1, GETUTCDATE())
ORDER BY Occurred DESC;
```

### 8.3 Check for pending close conflicts before adjustment
```sql
-- Check if a position is in CloseExecutionPlan (would block adjustment)
SELECT PositionID, StatusID
FROM Trade.CloseExecutionPlan WITH (NOLOCK)
WHERE PositionID = 123456789;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (1,5,8,9B,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (PositionClose, PositionOpen) | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PositionAdjustment | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PositionAdjustment.sql*
