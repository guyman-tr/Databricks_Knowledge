# Trade.PostEditStopLossPosition

> Post-SL-edit change log writer that parses position data from an XML parameter bag and inserts a ChangeTypeID=1 entry into History.PositionChangeLog recording the stop loss rate change.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Params XML: Root/PositionID/@Value |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.PostEditStopLossPosition is the post-execution change log writer called after Trade.PositionEditStopLoss updates a position's stop loss rate. It records the SL edit as a permanent audit entry in History.PositionChangeLog (ChangeTypeID=1 = stop loss edit).

Like PostClosePositionActions and PostOpenPositionActions, all position data is received via a single XML @Params bag parsed with XPath. This pattern allows the caller to pass the complete position snapshot at the time of the SL edit without requiring individual parameters for each field.

The SP uses @PartsToDo (bit-flag) and @ID (operation ID) parameters consistent with the post-action family, though the current implementation runs only a single task (the change log insert) and the bit-flag structure is vestigial or reserved for future expansion.

@NewAmount is computed as ISNULL(@PreviousAmount, 0) + ISNULL(@Credit, 0): the amount after applying the SL credit adjustment. Credit is the delta (positive = increase, negative = decrease) applied when the stop loss margin is adjusted.

---

## 2. Business Logic

### 2.1 XML Parameter Extraction

**What**: Parses all position fields from the @Params XML bag.

**Rules**:
- Pattern: @Params.value('(Root/{Field}/@Value)[1]', '{type}')
- @CID read first (top of SP, outside TRY) - used for Customer.Login lookup
- Fields: CID, PositionID (BIGINT), CloseOnEndOfWeek, EndOfWeekFee, Amount (=PreviousAmount), Credit (=AmountChanged), LimitRate, PreviousStopRate, StopRate, Occurred, ParentPositionID (BIGINT), OrigParentPositionID (BIGINT), LastOpPriceRate, LastOpPriceRateID (BIGINT), LastOpConversionRate, LastOpConversionRateID (BIGINT), MirrorID

### 2.2 Client Version Lookup

**What**: Reads the customer's current ClientVersion from Customer.Login.

**Rules**:
- SELECT ClientVersion FROM Customer.Login (NOLOCK) WHERE CID=@CID
- NOLOCK hint: reads potentially dirty/stale client version (acceptable for audit metadata)
- ClientVersion passed to PositionChangeLog_Insert for client identification

### 2.3 NewAmount Computation

**What**: Derives the post-edit position amount.

**Rules**:
- @NewAmount = ISNULL(@PreviousAmount, 0) + ISNULL(@Credit, 0)
- @PreviousAmount from XML field "Amount"
- @Credit from XML field "Credit" (the stop loss margin delta in dollars)
- ISNULL guards protect against NULL XML fields

### 2.4 Change Log Insert (ChangeTypeID=1)

**What**: Calls History.PositionChangeLog_Insert to record the SL edit.

**Rules**:
- ChangeTypeID = 1 (stop loss edit - hardcoded)
- @PreviousCloseOnEndOfWeek = @CloseOnEndOfWeek (same value - unchanged by SL edit)
- @CloseOnEndOfWeek = @CloseOnEndOfWeek
- @PreviousEndOfWeekFee = @EndOfWeekFee (same value - unchanged)
- @EndOfWeekFee = @EndOfWeekFee
- @PreviousAmount = @PreviousAmount (amount before credit applied)
- @AmountChanged = @Credit (the SL margin delta)
- @PreviousLimitRate = @LimitRate (limit rate unchanged - same value used twice)
- @LimitRate = @LimitRate
- @PreviousStopRate = @PreviousStopRate (the rate before the edit)
- @StopRate = @StopRate (the new rate after the edit)
- @NewAmount = @NewAmount (= PreviousAmount + Credit)
- If History.PositionChangeLog_Insert returns non-zero: RAISERROR with @ErrOut message

### 2.5 Error Handling and Return Value

**Rules**:
- TRY/CATCH wraps the entire change log operation
- On CATCH: @RetVal = @RetVal + 1 (increments; starts at 0)
- RETURN @RetVal: 0 = success, non-zero = failure
- Caller can check return value to detect failure without exception propagation

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Params | XML | NO | - | CODE-BACKED | XML bag with all SL edit data. Fields: CID, PositionID, CloseOnEndOfWeek, EndOfWeekFee, Amount (PreviousAmount), Credit (delta), LimitRate, PreviousStopRate, StopRate, Occurred, ParentPositionID, OrigParentPositionID, LastOpPriceRate, LastOpPriceRateID, LastOpConversionRate, LastOpConversionRateID, MirrorID. |
| 2 | @PartsToDo | INT | NO | - | CODE-BACKED | Bit flag for sub-task selection. Current implementation runs a single task; this parameter is consistent with the post-action SP family (PostClosePositionActions, PostOpenPositionActions) for architectural uniformity. |
| 3 | @ID | INT | NO | - | CODE-BACKED | Operation ID for tracking/logging. Not actively used in current implementation. Consistent with post-action SP family. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | Customer.Login | DML read | ClientVersion lookup for change log metadata |
| EXEC | History.PositionChangeLog_Insert | Procedure call | Writes ChangeTypeID=1 (SL edit) change log entry |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called after Trade.PositionEditStopLoss completes (via SSB consumer or synchronous call).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PostEditStopLossPosition (procedure)
+-- Customer.Login (table) - ClientVersion lookup
+-- History.PositionChangeLog_Insert (procedure) - change log write
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Login | Table | SELECT ClientVersion (NOLOCK) for change log audit field |
| History.PositionChangeLog_Insert | Stored Procedure | Records ChangeTypeID=1 (SL edit) in History.PositionChangeLog |

### 6.2 Objects That Depend On This

No dependents found in SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- ChangeTypeID=1 is hardcoded - this SP is solely for SL edits
- @NewAmount = ISNULL(@PreviousAmount,0) + ISNULL(@Credit,0): Credit is the SL margin delta (dollars), NOT cents
- History.PositionChangeLog_Insert non-zero return triggers RAISERROR; the TRY/CATCH then catches it and sets @RetVal=1
- Change log headers: created 10-04-2013, last modified 17/11/2021 (BIGINT PositionID migration)

---

## 8. Sample Queries

### 8.1 Typical invocation after SL edit

```sql
DECLARE @params XML = '<Root>
    <CID Value="12345"/>
    <PositionID Value="987654321"/>
    <Amount Value="1000"/>
    <Credit Value="50"/>
    <PreviousStopRate Value="1.1200"/>
    <StopRate Value="1.1100"/>
    <Occurred Value="2026-03-17T10:00:00"/>
    <MirrorID Value="0"/>
    ...
</Root>';
EXEC Trade.PostEditStopLossPosition @Params=@params, @PartsToDo=0, @ID=1;
-- Returns 0 on success, 1 on failure
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos searched / 0 files | Corrections: 0 applied*
*Object: Trade.PostEditStopLossPosition | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PostEditStopLossPosition.sql*
