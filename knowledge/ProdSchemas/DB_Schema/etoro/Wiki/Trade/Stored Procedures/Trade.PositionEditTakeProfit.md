# Trade.PositionEditTakeProfit

> Edits or removes the Take Profit level for a position's tree, validating that the position exists and is not a user-modified mirror position.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID (partition key: @PositionID%50 on Trade.Position) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.PositionEditTakeProfit is the core SP for changing or removing a position's Take Profit (TP) level. When a user sets a TP on a trade, it creates a limit rate at which the position will auto-close in profit. This SP validates the request and propagates the new TP level to the entire position tree via Trade.UpdateTree.

Two pre-conditions are enforced: (1) the position must exist as an open position, and (2) if the position is a mirror copy (ParentPositionID > 0 and MirrorID > 0), it cannot be modified by the user directly (@IsInitiatedByUser check) - mirror positions follow their parent's TP. The @IsNoTakeProfit flag supports the "remove TP" scenario where the user clears the take profit level entirely.

The SP signature contains several parameters that are declared but not used in the current implementation (@NetProfit, @LastOpPriceRate, @LastOpPriceRateID, @LastOpConversionRate, @LastOpConversionRateID, @XMLResult). These reflect an older, more complex version of the SP that was simplified over time (evidenced by the commented-out @PositionInfo table variable and related SELECT).

---

## 2. Business Logic

### 2.1 Position Existence and Context Read

**What**: Reads ParentPositionID, TreeID, and MirrorID from Trade.Position for the given PositionID.

**Columns/Parameters Involved**: Trade.Position.ParentPositionID, TreeID, MirrorID, @PositionID

**Rules**:
- SELECT with NOLOCK, partition-aware: WHERE PositionID=@PositionID AND @PositionID%50=PartitionCol
- If @ParentPositionID IS NULL -> position not found: RAISERROR(60115, 16, 1, 'edit', @PositionID); RETURN 60115
- Error 60115 = position not found at edit attempt

### 2.2 Mirror Position Protection

**What**: Prevents user-initiated TP modification on positions that are copies within a copy-trading mirror.

**Columns/Parameters Involved**: @ParentPositionID, @MirrorID, @IsInitiatedByUser

**Rules**:
- IF @ParentPositionID > 0 AND @MirrorID > 0 AND @IsInitiatedByUser <> 0 -> RAISERROR(60084, 16, 1); RETURN 60084
- Error 60084 = "Mirrored positions can't be modified" (FB: 20707, Jan 2014)
- System-initiated edits (@IsInitiatedByUser=0) bypass this check and can modify mirror positions

### 2.3 Take Profit Tree Update

**What**: Propagates the new TP level through the position tree via Trade.UpdateTree.

**Columns/Parameters Involved**: Trade.UpdateTree @TreeID, @LimitRate OUTPUT, @IsNoTakeProfit

**Rules**:
- EXEC Trade.UpdateTree @TreeID=@TreeID, @StopRate=NULL, @LimitRate=@LimitRate OUTPUT, @CloseOnEndOfWeek=NULL, @FromEditProd=1, @Credit=0, @SessionID=@SessionID, @ClientRequestGuid=@ClientRequestGuid, @IsNoTakeProfit=@IsNoTakeProfit
- @LimitRate is an OUTPUT parameter: Trade.UpdateTree may adjust the value (e.g., rounding) and returns the applied limit rate
- @StopRate=NULL: SL is not changed by this call
- @IsNoTakeProfit: when BIT=1, removes the TP level; when 0 or NULL, sets it to @LimitRate
- @FromEditProd=1: production edit path flag
- @Credit=0: no credit adjustment
- @SessionID and @ClientRequestGuid: audit/idempotency

### 2.4 Transaction and Error Handling

**Rules**:
- BEGIN TRY / BEGIN TRANSACTION around UpdateTree; COMMIT on success
- CATCH: builds @ErrOut with proc name + ERROR_NUMBER + ERROR_LINE + ERROR_MESSAGE; ROLLBACK if @@TRANCOUNT=1, COMMIT if >1
- RAISERROR(60000, 16, 1, @ErrOut, @ErrNum) wraps the error with context
- Returns 0 on success; 60000 on error

### 2.5 Unused Parameters (Vestigial Signature)

**Rules**:
- @NetProfit MONEY = 0 (in cents per comment): declared but never used in current implementation
- @XMLResult XML OUTPUT: declared but never populated or returned
- @LastOpPriceRate, @LastOpPriceRateID, @LastOpConversionRate, @LastOpConversionRateID: declared but unused
- Commented-out @PositionInfo table variable: prior version populated this from SELECT before UpdateTree; now simplified to direct call

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | Position to edit. Partition key: @PositionID%50 on Trade.Position. |
| 2 | @LimitRate | dtPrice | NO | - | CODE-BACKED | New Take Profit rate. Passed as INPUT/OUTPUT to Trade.UpdateTree; the applied (potentially adjusted) rate is returned. Ignored if @IsNoTakeProfit=1. |
| 3 | @NetProfit | MONEY | YES | 0 | CODE-BACKED | Declared but unused in current implementation. Comment notes 'in cents'. Present for API compatibility. |
| 4 | @XMLResult | XML | YES | NULL | CODE-BACKED | OUTPUT. Declared but never populated. Vestigial from prior version. |
| 5 | @LastOpPriceRate | dtPrice | YES | NULL | CODE-BACKED | Declared but unused. Last operation price rate. Present for API compatibility. |
| 6 | @LastOpPriceRateID | BIGINT | YES | NULL | CODE-BACKED | Declared but unused. Last operation price rate ID. Present for API compatibility. |
| 7 | @LastOpConversionRate | dtPrice | YES | NULL | CODE-BACKED | Declared but unused. Last operation conversion rate. Present for API compatibility. |
| 8 | @LastOpConversionRateID | BIGINT | YES | NULL | CODE-BACKED | Declared but unused. Last operation conversion rate ID. Present for API compatibility. |
| 9 | @IsInitiatedByUser | INT | YES | 1 | CODE-BACKED | 1=user-initiated (default), 0=system-initiated. System-initiated edits bypass the mirror protection check. |
| 10 | @ErrOut | NVARCHAR(4000) | YES | '' | CODE-BACKED | OUTPUT. Populated on error with SP name, ERROR_NUMBER, ERROR_LINE, ERROR_MESSAGE for caller inspection. |
| 11 | @SessionID | BIGINT | YES | NULL | CODE-BACKED | User session ID. Passed to Trade.UpdateTree for audit/change-log. |
| 12 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Idempotency key. Passed to Trade.UpdateTree. Added FB:51172 (2018-05-01). |
| 13 | @IsNoTakeProfit | BIT | YES | NULL | CODE-BACKED | When 1, removes/disables the Take Profit level. When NULL or 0, sets it to @LimitRate. Passed to Trade.UpdateTree. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT (NOLOCK) | Trade.Position | DML read | Reads ParentPositionID, TreeID, MirrorID with partition elimination |
| EXEC | Trade.UpdateTree | Procedure call | Propagates LimitRate / IsNoTakeProfit change through position tree |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No callers found in SSDT repo or application repos. Called by trading frontend or TP management services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionEditTakeProfit (procedure)
+-- Trade.Position (view/table) - existence check and context read
+-- Trade.UpdateTree (procedure) - TP propagation to tree
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View/Table | SELECT ParentPositionID, TreeID, MirrorID WHERE PositionID=@PositionID AND @PositionID%50=PartitionCol |
| Trade.UpdateTree | Stored Procedure | EXEC to set LimitRate (or clear TP with IsNoTakeProfit) on position tree |

### 6.2 Objects That Depend On This

No dependents found in SSDT repo. Called by trading frontend or TP management services.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- Error 60115: position not found (ParentPositionID=NULL after partition-aware read)
- Error 60084: mirrored position cannot be user-modified
- Error 60000: generic catch-all with context in @ErrOut
- Nested transaction support: @@TRANCOUNT>1 causes COMMIT not ROLLBACK

---

## 8. Sample Queries

### 8.1 Set a take profit level

```sql
DECLARE @LimitRate dtPrice = 1.1200;
DECLARE @ErrOut NVARCHAR(4000) = '';
EXEC Trade.PositionEditTakeProfit
    @PositionID         = 123456789,
    @LimitRate          = @LimitRate OUTPUT,
    @IsInitiatedByUser  = 1,
    @SessionID          = 999,
    @ClientRequestGuid  = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890',
    @ErrOut             = @ErrOut OUTPUT;
SELECT @LimitRate AS AppliedLimitRate, @ErrOut AS ErrOut;
```

### 8.2 Remove the take profit

```sql
DECLARE @LimitRate dtPrice = NULL;
DECLARE @ErrOut NVARCHAR(4000) = '';
EXEC Trade.PositionEditTakeProfit
    @PositionID        = 123456789,
    @LimitRate         = @LimitRate OUTPUT,
    @IsNoTakeProfit    = 1,
    @IsInitiatedByUser = 1,
    @SessionID         = 999,
    @ErrOut            = @ErrOut OUTPUT;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: Trade.PositionEditTakeProfit | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PositionEditTakeProfit.sql*
