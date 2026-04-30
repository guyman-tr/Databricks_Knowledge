# Trade.PostOpenPositionActions

> Post-open change log writer that parses the new position's data from an XML parameter bag, checks the IsReal environment flag, and inserts a ChangeTypeID=0 (open) entry into History.PositionChangeLog.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Params XML: Root/PositionID/@Value |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.PostOpenPositionActions is the post-execution coordinator called after Trade.PositionOpen (or the SSB open consumer) completes a position open. Its primary role is to write the opening entry into History.PositionChangeLog (ChangeTypeID=0 = position open), creating the first record in the position's audit trail.

This SP is the open-side counterpart to PostClosePositionActions and follows the same XML @Params / @PartsToDo / @ID calling convention used across the entire post-action family.

Key characteristics:
- Reads Maintenance.Feature FeatureID=22 to determine @IsReal (live vs. demo environment)
- @RetVal bit-flag: the TRY/CATCH increments @RetVal by 2 on failure (not by 1 as in PostEditStopLossPosition), enabling the caller to distinguish error sources across multiple steps if the SP is expanded
- No MirrorRealizedEquity/AccountRealizedEquity manipulation: these are passed through to the change log as-is from the XML

The change log open record sets PreviousAmount = NewAmount = @Amount (no prior state) and AmountChanged = 0, establishing the baseline for all subsequent change log entries in the position's lifecycle.

---

## 2. Business Logic

### 2.1 XML Parameter Extraction

**What**: Parses all position fields from the @Params XML bag after startup.

**Rules**:
- @StartDate = GETUTCDATE() set at entry (captured for logging; not written anywhere currently)
- @CID and @PositionID read first (outside TRY)
- All remaining fields read via @Params.value('(Root/{Field}/@Value)[1]', '{type}')
- Fields: CID (INT), PositionID (BIGINT), CloseOnEndOfWeek (BIT), Amount (MONEY), LimitRate (dtPrice), StopRate (dtPrice), Occurred (DATETIME), ParentPositionID (BIGINT), LastOpPriceRate (dtPrice), LastOpPriceRateID (BIGINT), LastOpConversionRate (dtPrice), LastOpConversionRateID (BIGINT), MirrorID (INT), MirrorRealizedEquity (MONEY), AccountRealizedEquity (MONEY), TreeID (BIGINT), SessionID (BIGINT), IsTslEnabled (TINYINT), ClientRequestGuid (UNIQUEIDENTIFIER), UnitsBaseValueCents (INT), IsSettled (BIT), AmountInUnitsDecimal (DECIMAL(16,6)), ClientViewRateID (BIGINT), ClientViewRate (DECIMAL(16,6)), ClientRateForCalcID (BIGINT), ClientRateForCalc (DECIMAL(16,6)), SettlementTypeID (TINYINT)

### 2.2 IsReal Environment Check

**What**: Reads the environment flag to distinguish live from demo.

**Rules**:
- SELECT Value FROM Maintenance.Feature WITH (NOLOCK) WHERE FeatureID=22
- @IsReal cast to INT
- FeatureID=22 = IsReal: 1 = production/live environment, 0 = demo
- @IsReal is declared and populated but NOT passed to PositionChangeLog_Insert in the current implementation (vestigial read, retained for future use)

### 2.3 Client Version Lookup

**Rules**:
- SELECT ClientVersion FROM Customer.Login (NOLOCK) WHERE CID=@CID
- Performed inside the TRY block (after XML parsing, before PositionChangeLog_Insert call)

### 2.4 Change Log Insert (ChangeTypeID=0)

**What**: Calls History.PositionChangeLog_Insert to record the position open.

**Rules**:
- ChangeTypeID = 0 (position open - hardcoded)
- @PreviousCloseOnEndOfWeek = @CloseOnEndOfWeek (opening state, no prior state to compare)
- @CloseOnEndOfWeek = @CloseOnEndOfWeek
- @PreviousEndOfWeekFee = 0 (no prior fee)
- @EndOfWeekFee = 0
- @PreviousAmount = @Amount (opening amount is both previous and new)
- @AmountChanged = 0 (no change at open)
- @PreviousLimitRate = @LimitRate (opening limit rate - no previous state)
- @LimitRate = @LimitRate
- @PreviousStopRate = @StopRate (opening stop rate - no previous state)
- @StopRate = @StopRate
- @NewAmount = @Amount
- @OrigParentPositionID = @ParentPositionID (same at open - no history of reparenting yet)
- @PrevTreeID = @TreeID, @TreeID = @TreeID (tree unchanged at open)
- @PreviousUnitsBaseValueCents = @UnitsBaseValueCents (same value - no prior state)
- @UnitsBaseValueCents = @UnitsBaseValueCents
- If PositionChangeLog_Insert returns non-zero: RAISERROR with @ErrOut

### 2.5 Error Handling and Return Value

**Rules**:
- TRY/CATCH wraps the entire operation (ClientVersion read + PositionChangeLog_Insert call)
- On CATCH: @RetVal = @RetVal + 2 (increments by 2, not 1; distinguishes this step from other potential steps)
- RETURN @RetVal: 0 = success; 2 = change log insert failure

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Params | XML | NO | - | CODE-BACKED | XML bag with all opening position data. Full field list: CID, PositionID, CloseOnEndOfWeek, Amount, LimitRate, StopRate, Occurred, ParentPositionID, LastOpPriceRate, LastOpPriceRateID, LastOpConversionRate, LastOpConversionRateID, MirrorID, MirrorRealizedEquity, AccountRealizedEquity, TreeID, SessionID, IsTslEnabled, ClientRequestGuid, UnitsBaseValueCents, IsSettled, AmountInUnitsDecimal, ClientViewRateID, ClientViewRate, ClientRateForCalcID, ClientRateForCalc, SettlementTypeID. |
| 2 | @PartsToDo | INT | NO | - | CODE-BACKED | Bit flag for sub-task selection. Current implementation runs a single task. Architectural consistency with PostClosePositionActions / PostEditStopLossPosition. |
| 3 | @ID | INT | NO | - | CODE-BACKED | Operation identifier for logging/tracking. Not actively used in current implementation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | Maintenance.Feature | DML read | FeatureID=22: IsReal environment flag |
| SELECT | Customer.Login | DML read | ClientVersion lookup for change log metadata |
| EXEC | History.PositionChangeLog_Insert | Procedure call | Writes ChangeTypeID=0 (position open) change log entry |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called after Trade.PositionOpen completes (via SSB consumer or synchronous post-open processing).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PostOpenPositionActions (procedure)
+-- Maintenance.Feature (table) - IsReal flag (FeatureID=22)
+-- Customer.Login (table) - ClientVersion lookup
+-- History.PositionChangeLog_Insert (procedure) - change log write
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | SELECT Value (NOLOCK) WHERE FeatureID=22 - IsReal environment flag |
| Customer.Login | Table | SELECT ClientVersion (NOLOCK) for audit metadata |
| History.PositionChangeLog_Insert | Stored Procedure | Records ChangeTypeID=0 (position open) in History.PositionChangeLog |

### 6.2 Objects That Depend On This

No dependents found in SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- ChangeTypeID=0 is hardcoded - this SP is solely for the opening change log entry
- @RetVal incremented by 2 on failure (not 1) - architectural pattern for multi-step expansion readiness
- @IsReal is read but NOT passed to PositionChangeLog_Insert: declared for potential future conditional logic
- @StartDate is captured but not used: retained from an older monitoring pattern
- Change log headers span 2013-2021; SettlementTypeID parameter added in 2018 (FB 53286)

---

## 8. Sample Queries

### 8.1 Typical invocation after position open

```sql
DECLARE @params XML = '<Root>
    <CID Value="12345"/>
    <PositionID Value="987654321"/>
    <Amount Value="1000"/>
    <LimitRate Value="1.2500"/>
    <StopRate Value="1.1500"/>
    <Occurred Value="2026-03-17T10:00:00"/>
    <ParentPositionID Value="0"/>
    <MirrorID Value="0"/>
    <TreeID Value="987654321"/>
    <IsSettled Value="0"/>
    ...
</Root>';
EXEC Trade.PostOpenPositionActions @Params=@params, @PartsToDo=0, @ID=1;
-- Returns 0 on success, 2 on failure
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos searched / 0 files | Corrections: 0 applied*
*Object: Trade.PostOpenPositionActions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PostOpenPositionActions.sql*
