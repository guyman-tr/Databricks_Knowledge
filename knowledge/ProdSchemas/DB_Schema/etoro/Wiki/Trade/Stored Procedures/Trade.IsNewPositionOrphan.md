# Trade.IsNewPositionOrphan

> DEMO ENVIRONMENT ONLY: Scans for "orphan" copied positions (positions in demo that reference a parent position no longer open in the real environment), then closes them using Trade.ManualPositionClose_Crisis. Maintains a watermark in Maintenance.Feature (FeatureID=104) to track incremental progress.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OperationID - audit identifier passed to ManualPositionClose_Crisis |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.IsNewPositionOrphan is a demo-environment cleanup job procedure that detects and closes "orphan" positions. In eToro's CopyTrader, when a leader closes a position in the real environment, the corresponding copied position in the demo environment should also close. An "orphan" is a demo position with a ParentPositionID that no longer exists in RealOpenPositions - its parent was closed in real but the demo copy was not properly closed.

Despite its name suggesting a read-only predicate, this procedure is an active cleanup operation that:
1. Detects orphan positions (copied demo positions whose parents are not in RealOpenPositions)
2. Calculates the correct closing rates from the parent's historical real data
3. Calls Trade.ManualPositionClose_Crisis to forcibly close each orphan
4. Logs closures to History.OrphanPositionsCloseByJob
5. Updates a watermark (Maintenance.Feature FeatureID=104) for incremental processing

The procedure is guarded against accidental execution in the real environment: if Maintenance.Feature FeatureID=22 = 1, it raises an error and stops. The FeatureID=104 watermark allows the procedure to process positions incrementally across multiple runs rather than re-scanning all positions every time.

Data flow: Scheduled cleanup job -> Trade.IsNewPositionOrphan -> orphan positions detected -> Trade.ManualPositionClose_Crisis -> History.OrphanPositionsCloseByJob audit log -> FeatureID=104 watermark updated.

History (DDL comments): Created 2017 (Adi, FB 49314); modified Nov 2017 (Adi) to fix Bid/Ask computation bugs; updated 2021 (Elad) to change PositionID to BIGINT.

---

## 2. Business Logic

### 2.1 Real Environment Guard

**What**: Blocks execution if running in real (production) environment.

**Rules**:
- IF EXISTS (SELECT * FROM Maintenance.Feature WHERE FeatureID = 22 AND CAST(Value AS INT) = 1):
- RAISERROR('This procedure can not be activated in Real environment. It should run only on demo environment', 16, 1).
- FeatureID=22 is the "is real environment" feature flag.

### 2.2 Watermark Initialization (First Run)

**What**: On first execution, initializes the watermark to the current maximum position ID.

**Rules**:
- SELECT @LastPositionChecked = CAST(Value AS BIGINT) FROM Maintenance.Feature WHERE FeatureID = 104.
- IF @LastPositionChecked IS NULL:
  - SELECT @LastPositionChecked = MAX(PositionID) FROM Trade.Position WHERE ParentPositionID > 0.
  - UPDATE Maintenance.Feature SET Value = @LastPositionChecked WHERE FeatureID = 104.
  - RETURN (nothing to process on first run - watermark is set to current state).
- FeatureID=104 stores the last PositionID that was processed.

### 2.3 Orphan Detection

**What**: Identifies new copied positions (since last run) that no longer have their parent in RealOpenPositions.

**Columns/Parameters Involved**: `Trade.PositionTbl.ParentPositionID`, `Trade.PositionTbl.StatusID`, `RealOpenPositions.PositionID`

**Rules**:
- @LastPosition = MAX(PositionID) FROM Trade.PositionTbl WHERE StatusID = 1 (current max open position).
- INSERT INTO #PositionsToClose: positions WHERE ParentPositionID > 0 AND PositionID > @LastPositionChecked AND PositionID <= @LastPosition AND StatusID = 1.
- Early exit if #PositionsToClose is empty (no new copied positions to check).
- DELETE from #PositionsToClose WHERE ParentPositionID found in RealOpenPositions (these are NOT orphans - parent still open).
- If nothing remains: update watermark = @LastPositionChecked, RETURN (all parents still open, no orphans).

### 2.4 Orphan Closure (Cursor Loop)

**What**: Iterates over orphan positions, computes closing rates from parent's real history, and calls ManualPositionClose_Crisis.

**Columns/Parameters Involved**: `RealHistoryPosition.EndForexRate`, `RealHistoryPosition.FullCommissionOnClose`, `RealHistoryPosition.AmountInUnitsDecimal`, `RealHistoryPosition.LastOpConversionRate`

**Rules**:
- CURSOR iterates over #PositionsToClose ordered by (PositionID, ParentPositionID).
- Rate optimization: only re-fetch @Bid/@Ask from RealHistoryPosition when @ParentPositionID changes (batches same-parent positions).
- Rate formula:
  - @Bid = ROUND(IIF(IsBuy=1, EndForexRate, EndForexRate - FullCommissionOnClose / (AmountInUnitsDecimal * LastOpConversionRate)), 2)
  - @Ask = ROUND(IIF(IsBuy=0, EndForexRate, EndForexRate + FullCommissionOnClose / (AmountInUnitsDecimal * LastOpConversionRate)), 2)
  - Bid: for buy positions, EndForexRate is already the bid; for sell positions, subtract commission per unit to get bid.
  - Ask: for sell positions, EndForexRate is the ask; for buy positions, add commission per unit to get ask.
- IF @Bid IS NOT NULL AND @Ask IS NOT NULL:
  - EXEC Trade.ManualPositionClose_Crisis @PositionID=..., @BidSpread=@Bid, @AskSpread=@Ask, @OperationID=@OperationID.
  - INSERT INTO History.OrphanPositionsCloseByJob (PositionID) for audit trail.
- Inner TRY/CATCH: skip error 60004 (already closed), re-THROW all other errors.

### 2.5 Watermark Update

**What**: At successful completion, advance the watermark to @LastPosition.

**Rules**:
- UPDATE Maintenance.Feature SET Value = @LastPosition WHERE FeatureID = 104.
- On next run, processing starts from @LastPosition + 1.

**Diagram**:
```
@OperationID
    |
    v
Maintenance.Feature FeatureID=22 = 1? -> RAISERROR (real env block)
    |
    v
FeatureID=104 (watermark) = NULL? -> Initialize + RETURN (first run)
    |
    v
Find new copied positions (@LastPositionChecked to MAX(open PositionID))
    -> #PositionsToClose (ParentPositionID > 0, StatusID=1)
    |
    +-- Empty? -> RETURN (no new copies to check)
    |
    v
DELETE from #PositionsToClose WHERE parent in RealOpenPositions
    |
    +-- Empty? -> Update watermark=@LastPositionChecked, RETURN (no orphans)
    |
    v
CURSOR over #PositionsToClose:
    For each orphan:
        Get Bid/Ask from RealHistoryPosition (if new parent)
        IF Bid+Ask not null:
            EXEC Trade.ManualPositionClose_Crisis
            INSERT History.OrphanPositionsCloseByJob
        SKIP error 60004 (already closed)
    |
    v
Update FeatureID=104 = @LastPosition
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OperationID | int | NO | - | CODE-BACKED | Audit/operation identifier passed through to Trade.ManualPositionClose_Crisis for each orphan closure. Allows attribution of closures to a specific job run. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT/UPDATE | Maintenance.Feature | Reader + Modifier | FeatureID=22: real env guard. FeatureID=104: watermark for incremental processing. |
| SELECT | Trade.Position | Reader | First-run MAX(PositionID) initialization |
| SELECT/INSERT | Trade.PositionTbl | Reader | New copied position discovery (ParentPositionID > 0, between watermarks) |
| DELETE filter | RealOpenPositions | Reader | Synonym/view for live open positions; excludes non-orphan positions |
| SELECT | RealHistoryPosition | Reader | Synonym/view for real position history; provides EndForexRate and commission data for closing rate computation |
| EXEC | Trade.ManualPositionClose_Crisis | Callee | Forcibly closes each orphan position at computed Bid/Ask rates |
| INSERT | History.OrphanPositionsCloseByJob | Writer | Audit log: records each PositionID closed as orphan by this job |

### 5.2 Referenced By (other objects point to this)

Not discovered in SQL codebase. Invoked by a scheduled cleanup job in the demo environment.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.IsNewPositionOrphan (procedure)
├── Maintenance.Feature (table) - env guard (FeatureID=22) + watermark (FeatureID=104)
├── Trade.Position (table) - first-run MAX(PositionID)
├── Trade.PositionTbl (table) - new position discovery
├── RealOpenPositions (synonym/view) - live open position check
├── RealHistoryPosition (synonym/view) - parent position historical close rates
├── Trade.ManualPositionClose_Crisis (procedure) - orphan position closer
└── History.OrphanPositionsCloseByJob (table) - audit log
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | FeatureID=22: is-real-env guard. FeatureID=104: read/write watermark for incremental orphan scanning. |
| Trade.Position | Table | First-run: MAX(PositionID WHERE ParentPositionID>0) for watermark initialization |
| Trade.PositionTbl | Table | New copied position discovery between watermarks (StatusID=1, ParentPositionID>0) |
| RealOpenPositions | Synonym/View | Non-orphan filter: positions whose parent is still open are excluded |
| RealHistoryPosition | Synonym/View | Provides EndForexRate, FullCommissionOnClose, AmountInUnitsDecimal, LastOpConversionRate, IsBuy for rate computation |
| Trade.ManualPositionClose_Crisis | Stored Procedure | Called to force-close each orphan position |
| History.OrphanPositionsCloseByJob | Table | Audit table; one INSERT per closed orphan |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Demo environment cleanup job | External (Scheduler) | Calls periodically to detect and close orphan copied positions |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Demo-only guard | Critical | FeatureID=22=1 triggers RAISERROR; procedure must not run on production |
| CURSOR-based iteration | Legacy | Uses explicit CURSOR for per-orphan processing; appropriate for low-volume orphan cases |
| Error 60004 skip | Design | 60004 = already closed; orphans already closed by another process are silently skipped |
| @Bid/@Ask null guard | Safety | If RealHistoryPosition has no record for @ParentPositionID, rates are NULL and close is skipped |
| Incremental watermark | Performance | FeatureID=104 ensures each run only processes new positions since last run |
| RealOpenPositions/RealHistoryPosition | Cross-DB | Likely synonyms pointing to the real (production) database from the demo database |

---

## 8. Sample Queries

### 8.1 Execute the orphan cleanup job (demo env only)

```sql
-- Only run in DEMO environment (FeatureID=22 != 1)
EXEC Trade.IsNewPositionOrphan @OperationID = 999;
```

### 8.2 Check current watermark

```sql
SELECT FeatureID, Value
FROM Maintenance.Feature WITH (NOLOCK)
WHERE FeatureID IN (22, 104);
-- FeatureID 22: is-real-env flag. FeatureID 104: last processed PositionID
```

### 8.3 View recently closed orphan positions

```sql
SELECT PositionID, ClosedDate
FROM History.OrphanPositionsCloseByJob WITH (NOLOCK)
ORDER BY ClosedDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.0/10 (Elements: 8/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.IsNewPositionOrphan | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.IsNewPositionOrphan.sql*
