# Trade.PositionEditIsTSLEnabled

> Enables or disables Trailing Stop Loss (TSL) for a position's tree, flushing pending TSL async records when disabling, and returning the updated manual-SL version.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID (partition key: @PositionID%50 on Trade.Position) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.PositionEditIsTSLEnabled is called when a user toggles the Trailing Stop Loss (TSL) feature on or off for a position. TSL automatically adjusts the stop-loss level as the position moves in the user's favour, locking in profits. Because a position belongs to a tree (positions can be mirrored or grouped), the TSL state is managed at the tree level via Trade.UpdateTree.

When disabling TSL (@IsEnabled=0): the SP first attempts to flush any pending TSL adjustment records from the async table for the tree (Trade.FlushTSLForSpecificTree). This ensures any queued TSL moves are applied before the feature is turned off, preventing orphaned TSL adjustments from being processed after the user has disabled the feature. The flush is done in its own nested try/catch - if it fails, the disable still proceeds.

When enabling TSL (@IsEnabled=1): the SP skips the flush and directly calls Trade.UpdateTree to enable TSL with the provided threshold (@NextThresHold).

After the tree update, the SP reads back the updated SLManualVer and SLManualVerTimestamp from Trade.PositionTreeInfo for the caller - these version counters are used for optimistic concurrency when multiple SL edits could collide.

---

## 2. Business Logic

### 2.1 Tree ID Resolution

**What**: Resolves the TreeID for the given PositionID using partition-aware query.

**Columns/Parameters Involved**: Trade.Position.TreeID, Trade.Position.PositionPartitionCol, @PositionID

**Rules**:
- SELECT TreeID FROM Trade.Position WHERE PositionID=@PositionID AND PositionPartitionCol=@PositionID%50
- Uses partition elimination on Trade.Position
- @TreeID is required for all subsequent calls

### 2.2 Flush Pending TSL Records (Disable Only)

**What**: When disabling TSL, flushes any pending async TSL adjustment records for the tree before proceeding.

**Columns/Parameters Involved**: @IsEnabled=0, Trade.FlushTSLForSpecificTree(@PositionID)

**Rules**:
- Only executes when @IsEnabled=0 (disabling)
- Calls Trade.FlushTSLForSpecificTree with @PositionID as argument
- Wrapped in inner TRY/CATCH with empty CATCH: failure to flush does NOT prevent the TSL disable
- Design rationale: "I still need to disable the TSL" even if flush fails

### 2.3 Tree TSL State Update

**What**: Updates the TSL state in the position tree via Trade.UpdateTree.

**Columns/Parameters Involved**: Trade.UpdateTree @TreeID, @IsTslEnabled, @SessionID, @IsManualOperation=1, @NextThresHold, @FromEditProd=1, @ClientRequestGuid

**Rules**:
- @IsTslEnabled = @IsEnabled (0=disabled, 1=enabled)
- @IsManualOperation=1: marks this as a user-initiated change (not system-generated)
- @FromEditProd=1: flag indicating this came from the production edit path
- @NextThresHold: when enabling TSL, the initial trailing threshold level; NULL when disabling
- @ClientRequestGuid: deduplication key for idempotency (added FB:51172, 2018-05-01)
- @SessionID: the user's session identifier for audit/change-log purposes

### 2.4 Return SL Version Counters (OUTPUT)

**What**: Reads back the updated SL manual version and timestamp for the caller.

**Columns/Parameters Involved**: Trade.PositionTreeInfo.SLManualVer, SLManualVerTimestamp, @TreeID

**Rules**:
- SELECT SLManualVer, SLManualVerTimestamp FROM Trade.PositionTreeInfo WHERE TreeID=@TreeID
- @SLManualVer OUTPUT: incremented version counter; caller uses for optimistic concurrency check
- @SLManualVerTimestamp OUTPUT: datetime of the version; used to detect concurrent SL edits
- These are read AFTER Trade.UpdateTree completes so they reflect the new state

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IsEnabled | TINYINT | NO | - | CODE-BACKED | TSL state to set: 1=enable TSL, 0=disable TSL. Controls whether flush is performed and the value passed to UpdateTree. |
| 2 | @PositionID | BIGINT | NO | - | CODE-BACKED | Position to edit. Used for partition-aware TreeID lookup (PositionPartitionCol=@PositionID%50) and as input to FlushTSLForSpecificTree. |
| 3 | @SessionID | BIGINT | NO | - | CODE-BACKED | User session identifier. Passed to Trade.UpdateTree for audit/change-log attribution. |
| 4 | @NextThresHold | dtPrice | YES | NULL | CODE-BACKED | Initial TSL trailing threshold when enabling TSL. NULL when disabling. Passed to Trade.UpdateTree. |
| 5 | @SLManualVer | INT | NO | - | CODE-BACKED | OUTPUT. Updated SL manual version counter from Trade.PositionTreeInfo after the tree update. Used by caller for optimistic concurrency. |
| 6 | @SLManualVerTimestamp | DATETIME | YES | NULL | CODE-BACKED | OUTPUT. Timestamp of the SL manual version. Read from Trade.PositionTreeInfo after update. |
| 7 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Deduplication key for idempotency. Passed to Trade.UpdateTree. Added in FB:51172 (2018-05-01). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT TreeID | Trade.Position | DML read | Partition-aware TreeID lookup for @PositionID |
| EXEC (conditional) | Trade.FlushTSLForSpecificTree | Procedure call | Flushes pending TSL async records when disabling TSL |
| EXEC | Trade.UpdateTree | Procedure call | Updates TSL enabled state and threshold in position tree |
| SELECT SLManualVer | Trade.PositionTreeInfo | DML read | Reads updated SL version counters after tree update |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No callers found in SSDT repo or application repos. Called by trading frontend or order-management services when user toggles TSL.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionEditIsTSLEnabled (procedure)
+-- Trade.Position (view/table) - TreeID read with partition elimination
+-- Trade.FlushTSLForSpecificTree (procedure) - flush pending TSL records (disable path)
+-- Trade.UpdateTree (procedure) - TSL state update in tree
+-- Trade.PositionTreeInfo (table) - read updated SL version counters
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View/Table | SELECT TreeID WHERE PositionID=@PositionID AND PositionPartitionCol=@PositionID%50 |
| Trade.FlushTSLForSpecificTree | Stored Procedure | EXEC on disable path to flush pending async TSL records |
| Trade.UpdateTree | Stored Procedure | EXEC to update IsTslEnabled, NextThresHold, SessionID in position tree |
| Trade.PositionTreeInfo | Table | SELECT SLManualVer, SLManualVerTimestamp WHERE TreeID=@TreeID |

### 6.2 Objects That Depend On This

No dependents found in SSDT repo. Called by trading frontend or SL/TSL management services.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- Flush failure (FlushTSLForSpecificTree) is silently swallowed by inner TRY/CATCH - the disable proceeds regardless
- No explicit transaction block; UpdateTree likely manages its own transaction
- Outer CATCH re-throws without modification (THROW with no args)
- No partition elimination on PositionTbl - uses Trade.Position view for tree lookup

---

## 8. Sample Queries

### 8.1 Enable TSL with a threshold

```sql
DECLARE @SLManualVer INT;
DECLARE @SLManualVerTimestamp DATETIME;

EXEC Trade.PositionEditIsTSLEnabled
    @IsEnabled             = 1,
    @PositionID            = 123456789,
    @SessionID             = 999,
    @NextThresHold         = 1.0850,
    @SLManualVer           = @SLManualVer OUTPUT,
    @SLManualVerTimestamp  = @SLManualVerTimestamp OUTPUT,
    @ClientRequestGuid     = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890';

SELECT @SLManualVer AS NewVersion, @SLManualVerTimestamp AS VersionTimestamp;
```

### 8.2 Disable TSL (flush pending records first)

```sql
DECLARE @SLManualVer INT;

EXEC Trade.PositionEditIsTSLEnabled
    @IsEnabled   = 0,
    @PositionID  = 123456789,
    @SessionID   = 999,
    @SLManualVer = @SLManualVer OUTPUT;

SELECT @SLManualVer AS NewVersion;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: Trade.PositionEditIsTSLEnabled | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PositionEditIsTSLEnabled.sql*
