# Trade.PostClosePositionActions

> Post-close orchestrator that archives a closed position to History.Position_Active, writes position change log entries, handles partial-close splits, and optionally sends contract-roll notifications and demo refills.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Params XML: Root/PositionID/@Value |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.PostClosePositionActions is the post-execution coordinator called after Trade.PositionClose completes. Once a position has been marked StatusID=2 (closed) in Trade.PositionTbl, this SP is invoked (typically via SSB consumer or synchronous call) to perform all secondary actions that must happen after the close but are not part of the atomic close transaction.

It uses a bit-flag parameter (@PartsToDo) to control which sub-tasks run. @PartsToDo=0 runs ALL tasks. Individual tasks can be re-run independently if they failed (by passing specific bit flags). This allows the calling service to retry individual failed steps without re-running the entire post-close flow.

**Key operations**:
1. **Part 0 (archive)**: INSERT closed position into History.Position_Active; DELETE from Trade.PositionTbl
2. **Part 4 (demo refill)**: Commented-out block; was used to auto-refill demo accounts to $2000 - now disabled
3. **Part 4096 (contract roll message)**: ActionType=7 -> send notification via Customer.SendMessage if customer is offline
4. **Part 8192 (change log)**: Write close/partial-close event to History.PositionChangeLog_Insert (ChangeTypeID=6 for full, 11 for partial)
5. **Part 16384 (detached mirror)**: Update NetProfit in History.Mirror or Trade.Mirror for detached mirror positions
6. **Part 32768 (partial close change log)**: Write the remaining open position's change log entry (ChangeTypeID=12)

---

## 2. Business Logic

### 2.1 XML Parameters Pattern

**What**: All position data is passed via @Params XML using XPath pattern Root/{FieldName}/@Value.

**Rules**:
- All values extracted via @Params.value('(Root/{Field}/@Value)[1]', '{type}')
- Fields: PositionID, MirrorRealizedEquity, AccountRealizedEquity, SessionID, ClosedExitOrderID, IsMirrorActive, ClientRequestGuid, IsPartial, PartialClosePositionID, PartialClosedPositionAmount, OpenPositionAmount, ClientVersion, PositionStopLoss, PartialClosedEndOfWeekFee, OriginalEndOfWeekFee, PreviousAmountInUnits, AmountInUnits, PreviousUnitsBaseValueInCents, UnitsBaseValueInCents, ClientViewRateID, ClientViewRate, ClientRateForCalcID, ClientRateForCalc, SkewValue, RedeemID, RedeemReasonID, RedeemStatus, Amount, ExecutedWithoutSettings, PreviousLotCountDecimal, LotCountDecimal, SnapshotTimestamp, PriceType

### 2.2 Archive to History.Position_Active (@PartsToDo & 0)

**What**: Copies closed position data from Trade.PositionTbl (joined to PositionTreeInfo and HedgeServer) into History.Position_Active, then deletes from Trade.PositionTbl.

**Rules**:
- Only runs for full close (@IsPartial=0)
- Source: TPOS (Trade.PositionTbl) INNER JOIN TPTI (Trade.PositionTreeInfo) LEFT JOIN THS (Trade.HedgeServer) WHERE StatusID=2 AND PartitionCol=@PositionID%50 AND abs(TreeID%50)=TPTI.PartitionCol
- Two INSERT attempts: first with UnitsBaseValueCents; if @@ROWCOUNT=0, second without (compatibility fallback)
- If second attempt also fails: RAISERROR 'PostClose procedure did not find the position that should be closed'
- DELETE Trade.PositionTbl WHERE PositionID=@PositionID AND PartitionCol=@PositionID%50
- StopRate sourced from ISNULL(@PositionStopLoss, TPTI.StopRate) - caller can override
- EndHedgeQuery = COALESCE(CASE WHEN THS.IsDummy=1 THEN 0 ELSE -1 END, -1)

### 2.3 Post-Archive Data Read

**What**: Reads position attributes from History.PositionSlim for subsequent sub-tasks.

**Rules**:
- SELECT Commission, NetProfit, LotCountDecimal, ProviderID, InstrumentID, CID, etc. FROM History.PositionSlim
- WHERE PositionID = IIF(@IsPartial=1, @PartialClosePositionID, @PositionID)
- Also reads: Maintenance.Feature FeatureID=22 (@IsReal), Customer.Customer (credit, currencyID, IsComputeForHedge)

### 2.4 Contract Roll Notification (@PartsToDo & 4096)

**Rules**:
- Only fires when @ActionType=7 (contract roll)
- IF NOT EXISTS Customer.Login WHERE CID=@CID (customer offline)
- IF message template 22 is active in Maintenance.MessageTemplate
- EXECUTE Customer.SendMessage with CID list, template 22, PositionID

### 2.5 Change Log Insert (@PartsToDo & 8192)

**Rules**:
- Full close: ChangeTypeID=6, @AmountToUse=@Amount, @PositionIDToClose=@PositionID
- Partial close: ChangeTypeID=11, @AmountToUse=@PartialClosedPositionAmount, @PositionIDToClose=@PartialClosePositionID
- Calls History.PositionChangeLog_Insert with all position metadata

### 2.6 Detached Mirror NetProfit (@PartsToDo & 16384)

**Rules**:
- Fires when @MirrorID>0 AND @OrigParentPositionID<>@ParentPositionID (detached position)
- UPDATE History.Mirror SET NetProfit=NetProfit+@NetProfit WHERE MirrorID=@MirrorID AND MirrorOperationID=2
- If @@ROWCOUNT=0 (mirror still open): UPDATE Trade.Mirror SET NetProfit=NetProfit+@NetProfit

### 2.7 Partial Close Remaining Position Change Log (@PartsToDo & 32768)

**Rules**:
- Only runs when @IsPartial=1
- @PreviousAmount = @OpenPositionAmount + @PartialClosedPositionAmount
- @AmountChanged = 0 - @PartialClosedPositionAmount (reduction)
- Calls History.PositionChangeLog_Insert with ChangeTypeID=12 (partial close - open side), @NewAmount=@OpenPositionAmount

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Params | XML | NO | - | CODE-BACKED | XML bag containing all position parameters. Parsed via XPath. Full list: PositionID, MirrorEquity, AccountEquity, SessionID, IsPartial, PartialClosePositionID, amounts, rates, IDs. |
| 2 | @PartsToDo | INT | NO | - | CODE-BACKED | Bit flag controlling which sub-tasks run: 0=all, 4=demo refill (disabled), 4096=contract roll message, 8192=change log, 16384=detached mirror, 32768=partial change log. |
| 3 | @ID | INT | NO | - | CODE-BACKED | Operation identifier. Used for log tracking (StepsLog). Not actively used in current implementation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT / DELETE | History.Position_Active | DML write | Archives closed position; source: PositionTbl |
| DELETE | Trade.PositionTbl | DML write | Removes closed position after archiving |
| JOIN | Trade.PositionTreeInfo | DML read | LimitRate, StopRate, IsDiscounted, IsTslEnabled, CloseOnEndOfWeek |
| LEFT JOIN | Trade.HedgeServer | DML read | IsDummy flag for EndHedgeQuery |
| SELECT | History.PositionSlim | DML read | Position attributes for sub-tasks |
| SELECT | Maintenance.Feature | DML read | FeatureID=22 IsReal flag |
| SELECT | Customer.Customer | DML read | Credit, CurrencyID, IsComputeForHedge |
| SELECT | Billing.Redeem | DML read | Max RedeemID for position |
| SELECT | Customer.Login | DML read | ClientVersion |
| EXEC | Customer.SendMessage | Procedure call | Contract-roll notification |
| EXEC | History.PositionChangeLog_Insert | Procedure call | Close/partial change log |
| UPDATE | History.Mirror / Trade.Mirror | DML write | NetProfit update for detached mirror |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by SSB consumer or position execution service after Trade.PositionClose completes.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PostClosePositionActions (procedure)
+-- Trade.PositionTbl (table) - archive source + DELETE
+-- History.Position_Active (table) - archive target
+-- Trade.PositionTreeInfo (table) - tree data
+-- Trade.HedgeServer (table) - IsDummy flag
+-- History.PositionSlim (table/view) - post-archive reads
+-- Maintenance.Feature (table) - IsReal flag
+-- Customer.Customer (table) - credit/currency
+-- Billing.Redeem (table) - RedeemID
+-- Customer.Login (table) - ClientVersion
+-- Customer.SendMessage (procedure) - contract-roll notification
+-- History.PositionChangeLog_Insert (procedure) - change log
+-- History.Mirror (table) - detached mirror NetProfit
+-- Trade.Mirror (table) - detached mirror NetProfit fallback
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | SELECT closed position data (StatusID=2); DELETE after archive |
| History.Position_Active | Table | INSERT archive target for closed positions |
| Trade.PositionTreeInfo | Table | LimitRate, StopRate, CloseOnEndOfWeek, IsTslEnabled, IsDiscounted, IsNoStopLoss, IsNoTakeProfit |
| Trade.HedgeServer | Table | IsDummy flag for EndHedgeQuery computation |
| History.PositionSlim | Table/View | Commission, NetProfit, ActionType, rates after archive |
| Maintenance.Feature | Table | FeatureID=22: IsReal environment flag |
| Customer.Customer | Table | Credit, CurrencyID, PlayerLevelID (IsComputeForHedge) |
| Billing.Redeem | Table | MAX(RedeemID) for position |
| Customer.Login | Table | ClientVersion for change log |
| Customer.SendMessage | Stored Procedure | Contract-roll offline notification |
| History.PositionChangeLog_Insert | Stored Procedure | Close/partial change log writer |
| History.Mirror | Table | NetProfit update for detached mirror (closed mirror) |
| Trade.Mirror | Table | NetProfit fallback update for detached mirror (open mirror) |

### 6.2 Objects That Depend On This

No dependents found in SSDT repo. Called by SSB consumer service.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- Demo refill block is entirely commented out
- @PartsToDo bit flags: 4=demo, 4096=rolling, 8192=changelog, 16384=detach, 32768=partial
- Each part is wrapped in separate TRY/CATCH; failure increments @RetVal by the part's flag value
- Initial transaction (for archive) is committed at end of initial TRY block; subsequent parts run outside transaction

---

## 8. Sample Queries

### 8.1 Called by execution service after close

```sql
-- Typically invoked programmatically by SSB consumer; XML structure:
DECLARE @params XML = '<Root>
    <PositionID Value="123456789"/>
    <IsPartial Value="0"/>
    <SessionID Value="999"/>
    <IsMirrorActive Value="0"/>
    ...
</Root>';
EXEC Trade.PostClosePositionActions @Params=@params, @PartsToDo=0, @ID=1;
```

### 8.2 Re-run only the change log step

```sql
EXEC Trade.PostClosePositionActions @Params=@params, @PartsToDo=8192, @ID=1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: Trade.PostClosePositionActions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PostClosePositionActions.sql*
