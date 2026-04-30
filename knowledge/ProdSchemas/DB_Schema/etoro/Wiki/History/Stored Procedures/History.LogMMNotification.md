# History.LogMMNotification

> Sole writer for Money Management failure events - inserts a single audit row into History.MMLog when the MM subsystem encounters a failure synchronizing a copy-trade position, enabling recovery processes to skip known-failed positions.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID + @FailTypeID - the position and type of MM failure |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.LogMMNotification` is the sole writer for `History.MMLog`, eToro's Money Management (MM) failure log for the copy-trading (Mirror Trading) system. When the MM subsystem attempts to synchronize a child position to its parent (e.g., opening a copied position to the right size, editing stop-loss, closing at end of week) and the operation fails, this procedure is called to record the failure permanently.

The logged failures serve a critical role: recovery suppression. Multiple recovery views (`Trade.ClosePositionsGetRecoveryItemsDemo`, `Trade.GetRealEditOWMMRecovery`, `Trade.GetRealEditSLMMRecovery`) query MMLog to find positions with known MM failures (FailTypeID=8 or 9) and exclude them from re-processing. Without this log, recovery processes would repeatedly retry the same broken positions, creating noise and consuming resources.

The procedure was modified on 17/11/2021 by Bonnie to change `@PositionID` from INT to BIGINT - a schema evolution to support the position ID range growth in the trading system.

---

## 2. Business Logic

### 2.1 MM Failure Event Recording

**What**: The MM subsystem passes the failed position's ID, the failure type, optional context, and optional mirror/parent references to record a durable failure event.

**Columns/Parameters Involved**: `@PositionID`, `@FailTypeID`, `@Details`, `@OrderID`, `@MirrorID`, `@ParentPositionID`

**Rules**:
- @PositionID = 0: the failure is not tied to a specific opened child position (e.g., FailTypeID=12 "Max position amount in units" where the child was never successfully opened). In this case @ParentPositionID identifies the parent.
- @PositionID > 0: the failure is tied to a specific existing position (e.g., FailTypeID=8 "MM object disconnected from parent" or FailTypeID=9 "MM Max StopLoss")
- Occurred = GETUTCDATE() at INSERT time (server-generated; not a parameter)
- @OrderID defaults to 0 (supplied as 0 when no order context exists)
- @MirrorID populated when the failure relates to a copy-trading mirror (Smart Portfolio); NULL for non-mirror positions
- Multiple rows can exist for the same PositionID with the same or different FailTypeIDs (failures can accumulate per position)

### 2.2 FailTypeID Enum - Recovery Suppression Significance

**What**: The FailTypeID determines which recovery processes will skip this position. Two values (8 and 9) are specifically handled by recovery views; others are logged for audit purposes.

**Columns/Parameters Involved**: `@FailTypeID`

**Rules**:
- FailTypeID=8 "MM object disconnected from its parent": excludes position from close recovery (Trade.ClosePositionsGetRecoveryItemsDemo, Trade.GetRecoveryItemsDemo)
- FailTypeID=9 "MM Max StopLoss": excludes position from OW edit recovery (Trade.GetRealEditOWMMRecovery) and SL edit recovery (Trade.GetRealEditSLMMRecovery / _Org); marks position as MaxSLReached=1 in Trade.GetRecoveryItemsDemo
- FailTypeID=12 "Max position amount in units": observed in staging data (8 rows from October 2023)
- All other FailTypeIDs (1-7, 10-11, 13-17): logged for audit purposes; not specifically filtered by known recovery views
- Full enum in Dictionary.FailType (17 values): 1=Request To Open, 2=Request To Close, 3=Open, 4=Close, 5=Edit, 6=External Error, 7=Internal Error, 8=MM disconnected from parent, 9=MM Max StopLoss, 10=Min Position Amount, 11=Mirror edit SL insufficient funds, 12=Max position amount in units, 13=Max Take Profit reached, 14=PositionRedeemCancelFail, 15=PositionRedeemPendingFail, 16=PositionRedeemCloseFail, 17=Detach

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | The child position that the MM failure affected. Maps to History.MMLog.PositionID (BIGINT since 2021-11-17 change). 0 if the child position was never opened (failure occurred before the position existed); in that case @ParentPositionID identifies the parent. >0 if a specific position failed. |
| 2 | @FailTypeID | INT | NO | - | CODE-BACKED | Type of MM failure. Dictionary.FailType enum: 8=MM object disconnected from parent (recovery exclusion for close), 9=MM Max StopLoss (recovery exclusion for OW/SL edits, MaxSLReached flag), 12=Max position amount in units. See History.MMLog Section 1 for full 17-value enum. |
| 3 | @Details | VARCHAR(250) | YES | NULL | CODE-BACKED | Optional free-text context describing the specific failure (e.g., error message or state description). Truncated to 250 characters. NULL when not provided by the caller. |
| 4 | @OrderID | INT | YES | 0 | CODE-BACKED | The order ID associated with the failed MM operation. Defaults to 0 when no order context is applicable. Identifies the specific trade request that failed within the MM execution path. |
| 5 | @MirrorID | INT | YES | NULL | CODE-BACKED | The copy-trading mirror relationship associated with this MM failure. NULL for non-mirror (direct position) failures. Populated when the MM subsystem was processing a copied position within a Smart Portfolio / CopyTrader relationship. |
| 6 | @ParentPositionID | BIGINT | YES | NULL | CODE-BACKED | The parent position that this failed child position was being synchronized to. Relevant when @PositionID=0 (the child was never created). Identifies the source position in the copy hierarchy for post-failure investigation. BIGINT since 2021-11-17 change. |

**Return values**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Return code 0 | INT | - | - | CODE-BACKED | Returned by RETURN(0) after successful INSERT. |
| 2 | Return code -1 | INT | - | - | CODE-BACKED | Returned by RETURN(-1) in CATCH block after error. Indicates the failure could not be logged (the log itself failed). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | History.MMLog | Writes (INSERT) | Sole writer - inserts one row per MM failure event |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MM engine / copy-trading application | - | Caller | Called by the Money Management subsystem when a position synchronization operation fails; no callers found in SSDT repository |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.LogMMNotification (procedure)
+-- History.MMLog (table - MM failure event log)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.MMLog | Table | INSERT target - one row per MM failure event |

### 6.2 Objects That Depend On This

No callers found in the etoro SSDT repository. Called by the Money Management / copy-trading application code.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Implementation notes**:
- SET NOCOUNT ON applied - suppresses row count messages
- BEGIN TRY / BEGIN CATCH: on error, builds @Msg with ERROR_PROCEDURE() + ERROR_LINE() + ERROR_NUMBER() + ERROR_MESSAGE(), then RAISERROR(@Msg,16,1) + RETURN(-1)
- RETURN(0) on success (explicit return code)
- Occurred is server-generated (GETUTCDATE()) - the caller does not supply a timestamp
- Change history: 17/11/2021 (Bonnie) - changed @PositionID from INT to BIGINT; same change applied to @ParentPositionID

---

## 8. Sample Queries

### 8.1 Log an MM failure for a position disconnected from its parent

```sql
EXEC History.LogMMNotification
    @PositionID       = 2152662906,
    @FailTypeID       = 8,
    @Details          = 'Parent position not found in Trade.Position',
    @MirrorID         = 1234567,
    @ParentPositionID = 2100000001
-- Returns 0 on success, -1 on error
```

### 8.2 Check if a position has MM failures that would suppress recovery

```sql
SELECT
    ml.ID,
    ml.PositionID,
    ml.FailTypeID,
    ft.Name AS FailTypeName,
    ml.Occurred,
    ml.Details,
    ml.MirrorID,
    ml.OrderID
FROM History.MMLog ml WITH (NOLOCK)
JOIN Dictionary.FailType ft WITH (NOLOCK) ON ml.FailTypeID = ft.FailTypeID
WHERE ml.PositionID = @PositionID
ORDER BY ml.Occurred DESC
```

### 8.3 Find all positions excluded from SL edit recovery (FailTypeID=9)

```sql
SELECT
    ml.PositionID,
    ml.MirrorID,
    ml.Occurred,
    ml.Details
FROM History.MMLog ml WITH (NOLOCK)
WHERE ml.FailTypeID = 9
ORDER BY ml.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9B, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 1 repo / 0 files | Corrections: 0 applied*
*Object: History.LogMMNotification | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.LogMMNotification.sql*
