# Trade.ReopenOperationValidation

> Validates all positions in a pending reopen operation against 10 business rules, eliminates invalid positions with audit trail, assigns execution levels for dependency ordering, optionally validates customer balances, then builds and stores the AggregatedData XML summary for the operation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ReopenOperationID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ReopenOperationValidation is the gatekeeper step in the reopen operation workflow. It runs before approval (Trade.ReopenOperationSendApprovalRequest) to validate that all positions in Trade.PositionToReopen are eligible to be reopened. Invalid positions are removed from the live queue and archived to History.PositionToReopen with a specific failure reason, so only positions that pass all checks remain for execution. It also assigns LevelIDs for dependency-ordered execution and builds the AggregatedData XML summary that the approval email uses.

This procedure exists because reopening positions has strict preconditions: the position must still exist in history, the customer must still exist and have sufficient funds (optional), the mirror must still be active (for copy positions), and no duplicate reopens should occur. Without this validation step, Trade.PositionsReopen could attempt to reopen positions that would fail at the execution layer, producing a worse user experience and harder-to-audit failures.

Data flow: Called after Trade.ReopenOperationAdd creates the operation and child records are inserted to Trade.PositionToReopen. After validation, the remaining positions are approved via Trade.ReopenOperationSendApprovalRequest. Modifications: RD 6136 (2018, Mor) added mirror support; TRADEX-1731 (2021, Noam B.) added US user safety net; 16/11/2021 (Elad) changed PositionID to bigint.

---

## 2. Business Logic

### 2.1 Validation Rule Pipeline (10 Rules, Sequential DELETEs)

**What**: Each validation rule removes ineligible positions from Trade.PositionToReopen via DELETE...OUTPUT INTO History.PositionToReopen with a specific FailReason message. Positions surviving all rules proceed to execution.

**Columns/Parameters Involved**: `ClosedPositionID`, `CID`, `LevelID`, `ReopenOperationID`

**Rules applied in order**:
1. **CID Mismatch**: If the CID on the PositionToReopen row doesn't match the CID on History.Position or Trade.Position - abort entire operation with RAISERROR (hard stop).
2. **Negative Rates**: If ReopenOperation.RequestedLimitRate < 0 or RequestedStopRate <= 0 - abort entire operation with RAISERROR (hard stop).
3. **US User Safety Net** (TRADEX-1731): If Trade.IsUsUser(ptr.CID).IsUsUser = 1 - remove position, FailReason='Reopen is not supported for US users'.
4. **Already Open**: If ClosedPositionID already exists in Trade.PositionTbl with StatusID=1 - remove, FailReason='Position exists in Trade.Position'.
5. **Already Reopened**: If Trade.PositionTbl.ReopenForPositionID = ClosedPositionID with StatusID=1 - remove, FailReason='Reopen Position exists in Trade.Position'.
6. **TreeID Missing**: If the TreeID is not found in Trade.Position or Trade.PositionToReopen - remove, FailReason='TreeID not exists...'.
7. **Partial Close**: If OriginalPositionID != PositionID (position was partially closed) - remove, FailReason='The position was partially closed'.
8. **Redeem Close**: If ActionType=19 (position closed due to redeem) - remove, FailReason='The position was closed due to redeem'.
9. **Null Hedge Servers**: If RootHedgeServerID IS NULL OR HedgeServerID IS NULL - remove, FailReason='RootHedgeServerID or HedgeServerID is NULL'.
10. **Parent Missing** (copy positions): If OrigParentPositionID doesn't exist in PositionToReopen or Trade.Position (LevelID IS NULL only) - remove, FailReason='ParentPositionID does not exist...'.

### 2.2 Mirror Validation

**What**: Copy positions (LevelID IS NULL, MirrorID != 0) require their mirror to still be active.

**Columns/Parameters Involved**: `MirrorID`, `ReopenForMirrorID`, `IsActive`

**Rules**:
- If the position's MirrorID is not found in Trade.Mirror OR Trade.Mirror.IsActive=0 - remove with FailReason='Mirror is not active or has already been closed'.
- Joins on hp.MirrorID = tm.MirrorID OR hp.MirrorID = tm.ReopenForMirrorID to support previously-reopened mirror cases.

### 2.3 LevelID Assignment (Dependency-Ordered Execution)

**What**: Assigns LevelIDs to surviving positions so Trade.PositionsReopen can execute them in parent-before-child order.

**Columns/Parameters Involved**: `LevelID`, `OrigParentPositionID`

**Rules**:
- Level 1: Manual positions (MirrorID=0) - set directly.
- Level N+1: Iterative WHILE loop that assigns LevelID=N+1 to positions whose parent (OrigParentPositionID) has LevelID=N.
- Three UPDATE paths per iteration: (a) parent in PositionToReopen, (b) parent in Trade.Position, (c) parent found via previous reopen result.
- Loop continues until no more LevelID IS NULL positions remain.

### 2.4 Optional Balance Validation (Cursor)

**What**: When ValidateUserBalance=1, iterates positions via cursor and checks each customer has sufficient funds.

**Columns/Parameters Involved**: `ValidateUserBalance`, `UserCredit`, `NetProfit`, `Amount`

**Rules**:
- Manual positions (MirrorID=0): checks Customer.CustomerMoney.Credit - NetProfit >= Amount. Failure: FailReason='Insufficient Funds'.
- Copy positions (MirrorID>0): checks Trade.Mirror.Amount - NetProfit >= Amount. Also verifies parent position exists. Failure: FailReason='Insufficient Funds'.
- Positions failing balance check: inserted to History.PositionToReopen (Result=0) and deleted from Trade.PositionToReopen.

### 2.5 AggregatedData XML Build

**What**: Builds a summary XML of surviving positions grouped by InstrumentID and HedgeServerID, stores it on Trade.ReopenOperation, and returns it as a result set.

**Columns/Parameters Involved**: `AggregatedData`

**Rules**:
- SELECT InstrumentID, HedgeServerID, SUM(AmountInUnitsDecimal) AS Units, SUM(Amount) AS Amount, COUNT(*) AS NumberOfPositions grouped by InstrumentID, HedgeServerID where LevelID IS NOT NULL.
- Built with FOR XML RAW('AggregatedData') ... ROOT('AggregatedDataList').
- Stored in Trade.ReopenOperation.AggregatedData for use by Trade.ReopenOperationSendApprovalRequest (which converts the XML to HTML table rows).
- Also returned as a SELECT result set.

**Diagram**:
```
Trade.ReopenOperationValidation(@ReopenOperationID)
    |
    v
Load #CurrentHistoryPositions (PositionToReopen + History.Position)
    |
    v
[10 Validation Rules: DELETE invalid positions -> History.PositionToReopen with FailReason]
    |
    v
[Assign LevelIDs for parent-before-child execution ordering]
    |
    v
[Optional: Balance check cursor (if ValidateUserBalance=1)]
    |
    v
Build AggregatedData XML -> UPDATE Trade.ReopenOperation
    |
    v
SELECT AggregatedData (for caller)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ReopenOperationID | INT | NO | - | CODE-BACKED | The reopen operation ID to validate. All child records in Trade.PositionToReopen with this ID are processed. The operation's ValidateUserBalance flag is read to determine if balance checks run. AggregatedData is written back to Trade.ReopenOperation for this ID. |

**Output (result set):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | AggregatedData | XML | YES | - | CODE-BACKED | The AggregatedData XML summary of surviving valid positions grouped by InstrumentID and HedgeServerID (Units, Amount, NumberOfPositions). Same value stored in Trade.ReopenOperation.AggregatedData and returned as a result set for the caller. NULL if no positions survived validation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ReopenOperationID | Trade.ReopenOperation | Reader + Modifier | Reads ValidateUserBalance and RequestedStopRate/LimitRate; writes AggregatedData. |
| @ReopenOperationID | Trade.PositionToReopen | Modifier (DELETE + UPDATE) | Removes invalid positions; assigns LevelID to valid ones. |
| ClosedPositionID | History.Position | Reader (JOIN) | Validates position history exists and reads StopRate, ActionType, HedgeServerIDs. |
| ClosedPositionID | History.Position_Active | Reader (OUTER APPLY) | Fallback for resolved parent position IDs. |
| ClosedPositionID | Trade.PositionTbl | Reader (JOIN) | Checks if position already open (StatusID=1). |
| CID | Trade.IsUsUser | Function (CROSS APPLY) | US user safety net check. |
| MirrorID | Trade.Mirror | Reader (JOIN) | Validates copy position mirrors are still active. |
| CID | Customer.CustomerMoney | Reader (cursor) | Balance check for manual positions when ValidateUserBalance=1. |
| MirrorID | Trade.Mirror | Reader (cursor) | Balance check for copy positions when ValidateUserBalance=1. |
| (procedure) | History.PositionToReopen | Writer (INSERT via OUTPUT) | Archives eliminated positions with failure reasons. |
| (procedure) | Trade.Position | Reader (JOIN) | Used in level assignment loops. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by back-office workflow tools between ReopenOperationAdd and ReopenOperationSendApprovalRequest.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ReopenOperationValidation (procedure)
├── Trade.ReopenOperation (table)
├── Trade.PositionToReopen (table)
├── History.Position (table)
├── History.Position_Active (table)
├── History.PositionToReopen (table)
├── Trade.PositionTbl (table)
├── Trade.Position (table)
├── Trade.Mirror (table)
├── Trade.IsUsUser (function)
├── Customer.CustomerMoney (table)
└── Trade.PositionToReopen (self-join for level assignment)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ReopenOperation | Table | Read ValidateUserBalance, RequestedStopRate/LimitRate; write AggregatedData XML. |
| Trade.PositionToReopen | Table | Main validation target - positions are deleted (invalid) or updated (LevelID assignment). |
| History.Position | Table | Join to validate position history, read CID, ActionType, TreeID, HedgeServerIDs. |
| History.Position_Active | Table | OUTER APPLY for re-opened parent position resolution. |
| History.PositionToReopen | Table | INSERT via OUTPUT - archives eliminated positions with FailReason. |
| Trade.PositionTbl | Table | Check for existing open positions (StatusID=1) or already-reopened positions. |
| Trade.Position | Table | Used in LevelID assignment loop for parent-open positions. |
| Trade.Mirror | Table | Validates mirror IsActive for copy positions; reads Amount for balance check. |
| Trade.IsUsUser | Function | CROSS APPLY to check US user status for safety net rule. |
| Customer.CustomerMoney | Table | Reads Credit for manual position balance validation. |

### 6.2 Objects That Depend On This

No dependents found. Called directly by back-office workflow tools.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Uses a CURSOR for balance validation (ValidateUserBalance=1 path) - cursor is LOCAL scope.

---

## 8. Sample Queries

### 8.1 Run validation for a pending reopen operation

```sql
EXEC Trade.ReopenOperationValidation @ReopenOperationID = 42;
-- Returns AggregatedData XML of surviving valid positions
```

### 8.2 Check positions that failed validation

```sql
SELECT ReopenOperationID, CID, ClosedPositionID, Result, FailReason, RequestReopenOccurred
FROM History.PositionToReopen WITH (NOLOCK)
WHERE ReopenOperationID = 42 AND Result = 0
ORDER BY RequestReopenOccurred;
```

### 8.3 View surviving valid positions after validation

```sql
SELECT ptr.ReopenOperationID, ptr.CID, ptr.ClosedPositionID, ptr.LevelID, ptr.OrigParentPositionID
FROM Trade.PositionToReopen ptr WITH (NOLOCK)
WHERE ptr.ReopenOperationID = 42
ORDER BY ptr.LevelID, ptr.CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ReopenOperationValidation | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ReopenOperationValidation.sql*
