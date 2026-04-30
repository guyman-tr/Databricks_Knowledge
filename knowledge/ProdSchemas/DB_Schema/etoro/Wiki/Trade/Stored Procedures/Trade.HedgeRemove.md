# Trade.HedgeRemove

> Forcibly removes a hedge (pending request and/or live hedge) by logging it to History.HedgeFail and deleting it from Trade.HedgeRequest and Trade.Hedge. Clears HedgeID on linked Trade.Position records. Used for failure scenarios and hedge reconciliation cleanup.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Input: @HedgeID, @FailTypeID, @FailReason, @FailReasonID; Logs: History.HedgeFail; Deletes: Trade.HedgeRequest, Trade.Hedge; Updates: Trade.Position |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.HedgeRemove is the **forced hedge removal procedure** used when a hedge must be abandoned/cleaned up outside the normal open/close lifecycle. This covers failure scenarios: network errors, provider rejections, reconciliation mismatches, or administrative cleanup.

The procedure handles two separate hedge states in sequence:
1. **Pending requests** (Trade.HedgeRequest): If any HedgeRequest row exists for @HedgeID, log it to History.HedgeFail and delete it.
2. **Live hedges** (Trade.Hedge): If a live hedge row exists for @HedgeID, log it to History.HedgeFail, clear HedgeID from any linked Trade.Position records, and delete the hedge row.

Both paths join with `Hedge.HedgeServerToLiquidityAccount` to populate the LiquidityAccountID in the fail log.

The `@FailTypeID` and `@FailReason` parameters allow callers to categorize the failure reason. The `@FailReasonID` parameter was added later (see comment "add Severity column") to provide a coded reason for analytics.

**Used by**: Trade.HedgeRemoveAll (removes all hedges), Trade.HedgeRemoveDiff (removes orphaned hedges without positions), Trade.HedgeRemoveFully (removes hedges with positions). These cursor wrappers call this procedure for each hedge ID.

---

## 2. Business Logic

### 2.1 Remove Pending Requests (HedgeRequest Path)

**What**: Archive any pending HedgeRequest rows for @HedgeID to HedgeFail, then delete them.

**Rules**:
- INSERT History.HedgeFail: SELECT from Trade.HedgeRequest HR JOIN Hedge.HedgeServerToLiquidityAccount HSTLA ON HR.HedgeServerID=HSTLA.HedgeServerID WHERE HR.HedgeID=@HedgeID
- RequestOpenOccurred = CASE WHEN RequestType=1 THEN Occurred ELSE NULL END
- RequestCloseOccurred = CASE WHEN RequestType=2 THEN Occurred ELSE NULL END
- TradeID and AccountID: NULL (not stored in HedgeRequest)
- OpenOccurred: NULL (not yet opened)
- FailReason=@FailReason, FailReasonID=@FailReasonID
- IF @@ROWCOUNT > 0: DELETE FROM Trade.HedgeRequest WHERE HedgeID=@HedgeID

### 2.2 Remove Live Hedge (Hedge Path)

**What**: Archive any live Trade.Hedge row for @HedgeID to HedgeFail, clear Position linkage, delete hedge.

**Rules**:
- INSERT History.HedgeFail: SELECT from Trade.Hedge HR JOIN Hedge.HedgeServerToLiquidityAccount HSTLA ON HR.HedgeServerID=HSTLA.HedgeServerID WHERE HR.HedgeID=@HedgeID
- EndForexRate, RequestedEndForexRate, EndDateTime: NULL (hedge was not closed normally)
- TradeID, AccountID, OrderID, OpenOccurred (=Occurred): from Trade.Hedge
- RequestOpenOccurred=RequestOccurred (from Trade.Hedge), RequestCloseOccurred=NULL
- FailReason=@FailReason, FailReasonID=@FailReasonID
- IF @@ROWCOUNT > 0:
  - UPDATE Trade.Position SET HedgeID=NULL WHERE HedgeID=@HedgeID (unlink positions from this hedge)
  - DELETE FROM Trade.Hedge WHERE HedgeID=@HedgeID

**Diagram**:
```
Trade.HedgeRemove(@HedgeID, @FailTypeID, @FailReason, @FailReasonID)
    |
    BEGIN TRANSACTION / BEGIN TRY
    |
    +-- (1) REQUEST PATH:
    |       INSERT History.HedgeFail
    |         SELECT from Trade.HedgeRequest
    |         JOIN Hedge.HedgeServerToLiquidityAccount
    |         WHERE HedgeID=@HedgeID
    |       IF @@ROWCOUNT > 0:
    |           DELETE Trade.HedgeRequest WHERE HedgeID=@HedgeID
    |
    +-- (2) LIVE HEDGE PATH:
    |       INSERT History.HedgeFail
    |         SELECT from Trade.Hedge
    |         JOIN Hedge.HedgeServerToLiquidityAccount
    |         WHERE HedgeID=@HedgeID
    |       IF @@ROWCOUNT > 0:
    |           UPDATE Trade.Position SET HedgeID=NULL WHERE HedgeID=@HedgeID
    |           DELETE Trade.Hedge WHERE HedgeID=@HedgeID
    |
    +-- COMMIT / RETURN 0
    |
    BEGIN CATCH:
    +-- ROLLBACK (if outermost) or COMMIT (nested)
    +-- EXEC Internal.CallRaiseError; RETURN error
```

### 2.3 Known Quirk - Missing @FailReasonID in Cursor Callers

The cursor wrappers (HedgeRemoveAll, HedgeRemoveDiff, HedgeRemoveFully) call HedgeRemove with only 3 arguments, omitting @FailReasonID. Since @FailReasonID has no default value in the current signature, these calls would fail at runtime. This indicates the cursor SPs were not updated when @FailReasonID was added to HedgeRemove.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeID | INTEGER | NO | - | CODE-BACKED | The hedge to remove. Will attempt to remove both any HedgeRequest rows AND any Trade.Hedge row with this ID. |
| 2 | @FailTypeID | INTEGER | NO | - | CODE-BACKED | Failure type code stored in History.HedgeFail.FailTypeID. Categorizes the reason for removal (e.g., 1=open fail, 2=close fail, 3=open not found). Caller defines the code. |
| 3 | @FailReason | VARCHAR(MAX) | NO | - | CODE-BACKED | Human-readable description of why the hedge is being removed. Stored in History.HedgeFail.FailReason. |
| 4 | @FailReasonID | INT | NO | - | CODE-BACKED | Coded failure reason for analytics (added later - see "add Severity column" comment). Stored in History.HedgeFail.FailReasonID. Note: cursor caller SPs (HedgeRemoveAll, HedgeRemoveDiff, HedgeRemoveFully) do not pass this parameter - likely a defect. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @HedgeID | Trade.HedgeRequest | SELECT (log) + DELETE | Archive and remove pending requests |
| @HedgeID | Trade.Hedge | SELECT (log) + DELETE | Archive and remove live hedge |
| HedgeServerID | Hedge.HedgeServerToLiquidityAccount | JOIN | Resolve LiquidityAccountID for fail log |
| @HedgeID | Trade.Position | UPDATE HedgeID=NULL | Unlink positions from removed hedge |
| FailTypeID, FailReasonID | History.HedgeFail | INSERT (two paths) | Failure audit log |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.HedgeRemoveAll | EXEC cursor | Called procedure | Calls for every hedge in Hedge + HedgeRequest |
| Trade.HedgeRemoveDiff | EXEC cursor | Called procedure | Calls for hedges without linked positions |
| Trade.HedgeRemoveFully | EXEC cursor | Called procedure | Calls for hedges with linked positions |
| Hedge Server (external) | - | Called by external system | Hedge server calls to clean up failed hedges |
| PROD_BIadmins | GRANT EXECUTE | Permission | BI analytics team has execute rights |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.HedgeRemove (procedure)
+-- Trade.HedgeRequest (table) [SELECT + DELETE]
+-- Trade.Hedge (table) [SELECT + DELETE]
+-- Hedge.HedgeServerToLiquidityAccount (x-schema table) [JOIN for LiquidityAccountID]
+-- Trade.Position (view/table) [UPDATE HedgeID=NULL]
+-- History.HedgeFail (x-schema table) [INSERT x2]
+-- Internal.CallRaiseError (procedure) [x-schema, CATCH error handler]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeRequest | Table | SELECT and DELETE pending requests |
| Trade.Hedge | Table | SELECT and DELETE live hedge |
| Hedge.HedgeServerToLiquidityAccount | Table | JOIN to resolve LiquidityAccountID |
| Trade.Position | View/Table | UPDATE HedgeID=NULL on linked positions |
| History.HedgeFail | Table | INSERT failure log (two separate INSERTs) |
| Internal.CallRaiseError | Procedure | CATCH handler error propagation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeRemoveAll | Procedure | Calls for all hedges |
| Trade.HedgeRemoveDiff | Procedure | Calls for orphaned hedges (no positions) |
| Trade.HedgeRemoveFully | Procedure | Calls for linked hedges (with positions) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

TRY/CATCH with nested transaction handling. Error propagation via Internal.CallRaiseError (not direct RAISERROR). The procedure runs both INSERT paths unconditionally - it does not short-circuit. If the hedge has neither HedgeRequest nor Hedge rows, both INSERTs will return 0 rows and nothing is deleted (silent no-op).

---

## 8. Sample Queries

### 8.1 Remove a failed hedge

```sql
EXEC Trade.HedgeRemove
    @HedgeID = 12345,
    @FailTypeID = 3,
    @FailReason = 'Hedge rejected by provider - instrument halted',
    @FailReasonID = 18;
```

### 8.2 Verify cleanup

```sql
-- Check HedgeRequest cleaned up
SELECT * FROM Trade.HedgeRequest WITH (NOLOCK) WHERE HedgeID = 12345;

-- Check Trade.Hedge cleaned up
SELECT * FROM Trade.Hedge WITH (NOLOCK) WHERE HedgeID = 12345;

-- Check Position unlinked
SELECT PositionID, HedgeID FROM Trade.PositionTbl WITH (NOLOCK) WHERE HedgeID = 12345;
-- Should return 0 rows

-- Check HedgeFail log
SELECT HedgeID, FailTypeID, FailReasonID, FailReason, InstrumentID
FROM History.HedgeFail WITH (NOLOCK)
WHERE HedgeID = 12345
ORDER BY RequestCloseOccurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/4 (1, 11 - Phase 8: callers found, Phase 10: skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed (callers) | App Code: 0 repos (skipped) | Corrections: 0 applied*
*Object: Trade.HedgeRemove | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.HedgeRemove.sql*
