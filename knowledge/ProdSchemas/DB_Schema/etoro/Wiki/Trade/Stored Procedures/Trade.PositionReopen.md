# Trade.PositionReopen

> Reopens a previously closed position by refunding the P&L, taxes, and fees to the user, then opening a new position with the same parameters (and optionally adjusted SL/TP rates).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ClosedPositionID (the position being reopened), @ReopenOperationID (reopen batch key) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.PositionReopen is the single-position execution engine for the "reopen position" feature. When a position has been incorrectly closed (e.g., due to a false stop-loss trigger, broker error, or corporate action adjustment), trading operations or an automated job can initiate a reopen operation. This SP:

1. **Refunds** the closed position's P&L (and optionally taxes/fees) to the user's balance via Customer.SetBalanceCompensation
2. **Reopens** a new position via Trade.PositionOpen with the same instrument, direction, leverage, and amounts as the closed one, with @OpenActionType=2 (Reopen)
3. **Links** the new position to the old one via ReopenForPositionID, and updates child positions' tree linkage
4. **Notifies** downstream services via SSB (Service Broker) and the SBR queue table

The SP handles two position types:
- **Manual positions** (MirrorID=0, @IsManual=1): validates the current market rate is within SL/TP boundaries, optionally adjusts the position amount for SL delta compensation, and checks user balance
- **Mirror positions** (MirrorID>0, @IsManual=0): validates the mirror is still active, calls Trade.ChangeMirrorAmountForMoe to adjust mirror balance, finds the parent position in the mirror tree

On failure, the SP archives the failure record to both History.PositionToReopen (Result=0) and History.PositionFailWrite (FailTypeID=3) before re-throwing the exception.

This SP processes one position at a time and is called by Trade.PositionsReopen (#25 in this batch) which orchestrates multi-position reopen batches.

---

## 2. Business Logic

### 2.1 Pre-Flight Validations

**What**: Three existence checks before any work begins.

**Rules**:
- Position must NOT currently be open: IF EXISTS (PositionTbl WHERE StatusID=1 AND PositionID=@ClosedPositionID AND CID=@CID) -> error 'Position exists in Trade.Position'
- Reopen must not already exist: IF EXISTS (PositionTbl WHERE StatusID=1 AND ReopenForPositionID=@ClosedPositionID AND CID=@CID) -> error 'Reopen Position exists in Trade.Position'
- Must exist in history: IF NOT EXISTS (History.PositionSlim WHERE PositionID=@ClosedPositionID AND CID=@CID) -> error 'Position not exists in History.PositionSlim'

### 2.2 Closed Position Data Extraction

**What**: Reads all parameters needed to reopen the position from History.PositionSlim.

**Columns/Parameters Involved**: History.PositionSlim, Trade.FnGetCurrentClosingRate

**Rules**:
- Full read of 35+ columns from History.PositionSlim WHERE PositionID=@ClosedPositionID AND CID=@CID
- CROSS APPLY Trade.FnGetCurrentClosingRate(IsBuy, IsSettled, InstrumentID, EstimatedMarkupRatio): gets @CurrentClosingRate
- @IsManual = CASE WHEN MirrorID=0 THEN 1 ELSE 0 END
- @MoneyToReturnInCents = (0 - NetProfit) * 100 (refund = negative of the P&L, amounts in cents)
- @LimitRate = ISNULL(@RequestedLimitRate, LimitRate) (use caller's rate if provided)
- @StopRate = ISNULL(@RequestedStopRate, StopRate) (use caller's rate if provided)
- @CloseTotalTaxes and @CloseTotalFees multiplied by 100 (cents)
- @OpenActionType = 2 (Reopen Position action type constant)

### 2.3 IsNoStopLoss / IsNoTakeProfit Logic

**What**: Determines whether to preserve or override the SL/TP "no stop loss" / "no take profit" flags.

**Rules**:
- IsNoStopLoss: if @IsNoStopLoss is NOT NULL and @RequestedStopRate is provided -> check if StopRate = one pip (Trade.GetOnePip) -> 1 (no SL); else 0
- IsNoTakeProfit: if @IsNoTakeProfit is NOT NULL and @RequestedLimitRate IS NULL -> preserve; if @RequestedLimitRate provided -> set to 0

### 2.4 Manual Position Validations and Amount Adjustment

**What**: For manual positions (non-mirror), validates market rate is within trade boundaries and optionally adjusts amount for SL delta.

**Columns/Parameters Involved**: @IsManual=1, Trade.FnCalculatePnLWrapper, Trade.ProviderToInstrument.MaxStopLossPercentage

**Rules**:
- Market rate check: CurrentClosingRate must be above @StopRate (for buy) or below @StopRate (for sell) and below @LimitRate (if set)
- If @RequestedStopRate is provided: calculate @TotalPnLInCents via Trade.FnCalculatePnLWrapper at the new SL rate; compute @CreditChangeInCents from margin and non-margin components; adjust @AmountInCents
- @CompensateOnStopLossDelta=1: additional credit refund when SL move increases non-margin portion
- Balance check: IF @ValidateUserBalance=1 AND @UserCreditInCents + @TotalAmountToReturn < @AmountInCents -> 'Insufficient Funds'

### 2.5 Mirror Position Validations

**What**: For mirror positions, validates active mirror and finds parent position.

**Rules**:
- SELECT @ParentCID, @MirrorID FROM Trade.Mirror WHERE CID=@CID AND IsActive=1 AND (MirrorID=@MirrorID OR ReopenForMirrorID=@MirrorID)
- Mirror must be active: @ParentCID must be NOT NULL
- Mirror balance check: @ExpectedMirrorAmountInCents = Mirror.Amount*100 + @TotalAmountToReturn; if @ValidateUserBalance=1 and insufficient -> 'Insufficient Funds'
- Find @ParentPositionID from Trade.PositionTbl WHERE CID=@ParentCID AND (ReopenForPositionID=@OrigParentPositionID OR PositionID=@OrigParentPositionID) AND StatusID=1

### 2.6 Transaction: Compensation and Position Open

**What**: Within a transaction - refund P&L, adjust mirror balance, open new position, link records, send notifications.

**Rules**:
- EXEC Customer.SetBalanceCompensation: @Payment=@MoneyToReturnInCents, @CompensationReasonID=56, @Description='Compensation caused by Reopen Position'
- Optionally: Customer.SetBalanceCompensation for taxes (@CloseTotalTaxes) and fees (@CloseTotalFees)
- If mirror: Trade.ChangeMirrorAmountForMoe with @DeltaAmountInCents=@TotalAmountToReturn
- EXEC Trade.PositionOpen: opens new position with @OpenActionType=2 (Reopen), @ReopenForPositionID linked
- UPDATE Trade.PositionTbl SET ReopenForPositionID=@ClosedPositionID WHERE PositionID=@NewPositionID
- UPDATE children: SET TreeID=@TreeID, ParentPositionID=@PositionID WHERE ParentPositionID=@ClosedPositionID AND StatusID=1
- If manual: UPDATE all positions in old tree: SET TreeID=@PositionID WHERE TreeID=@ClosedPositionID
- SSB SEND: TradingDbPositionNotification XML with OperationTypeId=2 (Reopen)
- If fees/taxes != 0: Trade.InsertEventsIntoSbrQueueTable EventTypeID=3 (CostTypeID=3=Fee or 4=Tax, OperationTypeID=25=Reopen)
- Archive to History.PositionToReopen (Result=1), DELETE from Trade.PositionToReopen

### 2.7 Error Handling

**Rules**:
- CATCH: ROLLBACK if @@TRANCOUNT=1, COMMIT if >1
- Archive to History.PositionToReopen (Result=0, FailReason='Trade.ReopenPosition Failed: {msg}')
- DELETE from Trade.PositionToReopen
- INSERT to History.PositionFailWrite (FailTypeID=3) with all position parameters
- THROW to re-raise

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ReopenOperationID | INT | NO | - | CODE-BACKED | Reopen batch operation ID. References Trade.PositionToReopen.ReopenOperationID. Used to archive success/failure to History.PositionToReopen. |
| 2 | @ClosedPositionID | BIGINT | NO | - | CODE-BACKED | The previously closed position to reopen. Must exist in History.PositionSlim; must NOT be open in PositionTbl. |
| 3 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Must match the CID of the closed position in History.PositionSlim. |
| 4 | @ValidateUserBalance | TINYINT | YES | 0 | CODE-BACKED | 1=check that user/mirror has sufficient balance before opening; 0=skip balance check. |
| 5 | @RequestedStopRate | dtPrice | YES | NULL | CODE-BACKED | Override stop loss rate for the reopened position. NULL=use original SL from History.PositionSlim. |
| 6 | @RequestedLimitRate | dtPrice | YES | NULL | CODE-BACKED | Override take profit rate for the reopened position. NULL=use original TP from History.PositionSlim. |
| 7 | @CompensateOnStopLossDelta | TINYINT | YES | 0 | CODE-BACKED | 1=add SL delta credit to the refund amount when a new stop loss is provided; 0=no additional compensation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| EXISTS check | Trade.PositionTbl | DML read | Validates position not already open or already reopened |
| EXISTS check | History.PositionSlim | DML read | Validates closed position exists |
| SELECT | History.PositionSlim | DML read | Full closed position data extraction |
| CROSS APPLY | Trade.FnGetCurrentClosingRate | Function call | Current closing rate for market boundary check |
| SELECT | Customer.CustomerMoney | DML read | User credit for balance validation (manual) |
| SELECT | Trade.ProviderToInstrument | DML read | MaxStopLossPercentage/Leverage1MaintenanceMargin for SL delta |
| SELECT | Trade.FnCalculatePnLWrapper | Function call | PnL at new SL rate for amount adjustment |
| SELECT | Trade.GetOnePip | Function call | One-pip threshold for IsNoStopLoss determination |
| SELECT | Trade.Mirror | DML read | Mirror active/balance validation; ParentCID lookup |
| SELECT | Trade.PositionTbl | DML read | ParentPositionID lookup for mirror |
| SELECT | BackOffice.Customer | DML read | ManagerID for compensation calls |
| EXEC | Customer.SetBalanceCompensation | Procedure call | Refund P&L, taxes, fees to user |
| EXEC | Trade.ChangeMirrorAmountForMoe | Procedure call | Adjust mirror balance (mirror path) |
| EXEC | Trade.PositionOpen | Procedure call | Open new position (core reopen operation) |
| UPDATE | Trade.PositionTbl | DML write | Set ReopenForPositionID; re-tree child positions |
| SSB SEND | Service Broker (svcPosition) | SSB | Position open notification to SSB queue |
| EXEC | Trade.InsertEventsIntoSbrQueueTable | Procedure call | Fee/tax refund events to SBR queue |
| INSERT/DELETE | History.PositionToReopen / Trade.PositionToReopen | DML write | Archive success/failure result; consume queue record |
| INSERT | History.PositionFailWrite | DML write | Failure record (FailTypeID=3) on error |

### 5.2 Referenced By (other objects point to this)

| Caller | How Used |
|--------|----------|
| Trade.PositionsReopen | Calls this SP for each individual position in a reopen batch (ReopenOperationID scope) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionReopen (procedure)
+-- Trade.PositionTbl (table) - existence/duplication checks; child tree updates
+-- History.PositionSlim (table/view) - closed position data source
+-- Trade.FnGetCurrentClosingRate (function) - current closing rate
+-- Customer.CustomerMoney (table) - user credit balance
+-- Trade.ProviderToInstrument (table) - max SL percentage
+-- Trade.FnCalculatePnLWrapper (function) - PnL calculation for SL delta
+-- Trade.GetOnePip (function) - one-pip threshold
+-- Trade.Mirror (table) - mirror validation and balance
+-- BackOffice.Customer (table) - ManagerID
+-- Customer.SetBalanceCompensation (procedure) - P&L/tax/fee refund
+-- Trade.ChangeMirrorAmountForMoe (procedure) - mirror balance update
+-- Trade.PositionOpen (procedure) - new position creation
+-- Trade.InsertEventsIntoSbrQueueTable (procedure) - SBR event queue
+-- History.PositionToReopen (table) - reopen audit log
+-- Trade.PositionToReopen (table) - reopen request queue
+-- History.PositionFailWrite (table) - failure log
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Validation; child tree re-linking; ReopenForPositionID update |
| History.PositionSlim | Table/View | Full closed position data extraction |
| Trade.FnGetCurrentClosingRate | Function | Current rate for trade boundary check |
| Customer.CustomerMoney | Table | User credit balance check |
| Trade.ProviderToInstrument | Table | MaxStopLossPercentage for SL delta calculation |
| Trade.FnCalculatePnLWrapper | Function | PnL at new SL rate |
| Trade.GetOnePip | Function | One-pip value for IsNoStopLoss detection |
| Trade.Mirror | Table | Mirror active status; ParentCID; mirror balance |
| BackOffice.Customer | Table | ManagerID for compensation attribution |
| Customer.SetBalanceCompensation | Stored Procedure | Refund closed P&L, taxes, fees |
| Trade.ChangeMirrorAmountForMoe | Stored Procedure | Mirror balance delta adjustment |
| Trade.PositionOpen | Stored Procedure | Opens new position with original parameters |
| Trade.InsertEventsIntoSbrQueueTable | Stored Procedure | Fee/tax refund events (SBR queue) |
| History.PositionToReopen | Table | INSERT success/failure audit record |
| Trade.PositionToReopen | Table | DELETE consumed reopen request |
| History.PositionFailWrite | Table | INSERT failure record on error |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionsReopen | Stored Procedure | Calls this SP for each position in a reopen batch |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- No partition elimination on Trade.PositionTbl in validation EXISTS checks (uses full-table scans)
- @MoneyToReturnInCents = (0 - NetProfit) * 100: cents conversion AND sign inversion (NetProfit is from P&L perspective, refund is inverse)
- CompensationReasonID=56 hardcoded for all reopen compensations
- OperationTypeID=25 in SBR events = "Reopen"; CalculationTypeID=7 = "Refund"
- SSB SEND: uses svcInitiator -> svcPosition contract pattern (same as Trade.PositionClose)

---

## 8. Sample Queries

### 8.1 Check reopen queue for pending operations

```sql
SELECT ReopenOperationID, CID, ClosedPositionID, LevelID, RequestOccurred
FROM Trade.PositionToReopen WITH (NOLOCK)
ORDER BY RequestOccurred DESC;
```

### 8.2 Check reopen history results

```sql
SELECT ReopenOperationID, CID, ClosedPositionID, ReopenPositionID, Result, FailReason, RequestReopenOccurred
FROM History.PositionToReopen WITH (NOLOCK)
WHERE RequestReopenOccurred >= DATEADD(day, -1, GETDATE())
ORDER BY RequestReopenOccurred DESC;
```

### 8.3 Reopen a single position (called by Trade.PositionsReopen)

```sql
EXEC Trade.PositionReopen
    @ReopenOperationID          = 12345,
    @ClosedPositionID           = 987654321,
    @CID                        = 11111111,
    @ValidateUserBalance        = 1,
    @RequestedStopRate          = NULL,
    @RequestedLimitRate         = NULL,
    @CompensateOnStopLossDelta  = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 caller found (Trade.PositionsReopen) | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: Trade.PositionReopen | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PositionReopen.sql*
