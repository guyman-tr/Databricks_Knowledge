# History.OrdersExit

> Unified view of all closed copy-trading exit orders - combines the historical archive (History.OrdersExitTbl) with currently-closed live orders (Trade.OrdersExitTbl WHERE StatusID=2) to provide a single query interface for the complete set of completed copy-trading position exit orders.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | OrderID (int) |
| **Partition** | N/A |
| **Indexes** | N/A (view - base table indexes used) |

---

## 1. Business Meaning

History.OrdersExit is the complete closed-order interface for copy-trading exit orders. In the eToro Copy Trading system, when a copier's copy position needs to be closed - due to mirror deregistration, stop-loss trigger, parent position closing, or manual close - an exit order is created in `Trade.OrdersExitTbl`. When that exit order completes, it is asynchronously archived to `History.OrdersExitTbl` via `Trade.AsyncOrdersChangeLog` (procedure `Trade.ExitOrderPostActions`, OperationTypeID=2) using the DELETE...OUTPUT INTO pattern.

This UNION ALL view bridges the two pools of closed exit orders: the permanently archived rows in `History.OrdersExitTbl` and the recently-closed rows still in `Trade.OrdersExitTbl` with `StatusID=2` (closed but not yet moved to History). Unlike `History.OrdersEntry`, both source tables use identical column names - no aliasing is required in the UNION ALL.

The view is the exit-side companion to `History.OrdersEntry`. Together they provide the full order lifecycle for copy-trading positions: entry orders track how positions were opened (the copy-open phase); exit orders track how positions were closed (the copy-close phase). The exit table has 4,208 archived rows with 615 distinct copiers and 1,716 distinct positions, averaging ~2.4 exit orders per position (reflecting partial closes and multiple close events).

Two procedures reference this view: `Trade.ChekAsyncFailedSteps` (validates async processing health) and `Trade.OrdersExitChangeLogAdd` (change log writer for exit order audit trail).

---

## 2. Business Logic

### 2.1 UNION ALL: Archived + Currently-Closed Exit Orders

**What**: Combines two pools of closed exit orders that differ only in archival status.

**Columns/Parameters Involved**: All 13 columns

**Rules**:
- Branch 1: `History.OrdersExitTbl` - all rows (permanently archived closed orders). No column renaming needed.
- Branch 2: `Trade.OrdersExitTbl WHERE StatusID=2` - recently-closed orders not yet archived. All 13 column names are identical between the two tables (unlike the entry orders view which requires aliasing).
- UNION ALL is used (not UNION) because the same OrderID cannot exist in both tables simultaneously - the DELETE...OUTPUT INTO pattern is atomic.
- StatusID=2 in Trade.OrdersExitTbl means the exit order is closed; StatusID=1 is open/active.

**Diagram**:
```
History.OrdersExitTbl (archived, permanently closed exit orders)
  SELECT OrderID, CID, PositionID, OpenOccurred, CloseOccurred, ...13 columns
  |
UNION ALL
  |
Trade.OrdersExitTbl WHERE StatusID=2 (recently closed, pending archival)
  SELECT OrderID, CID, PositionID, OpenOccurred, CloseOccurred, ...13 columns
  |
  v
History.OrdersExit (view - all closed exit orders, unified 13-column schema)
```

### 2.2 CloseActionType - Exit Order Outcome Classification

**What**: Records why/how the copy-trading exit order completed.

**Columns/Parameters Involved**: `CloseActionType`, `MirrorCloseActionType`

**Rules** (from History.OrdersExitTbl distribution):

| CloseActionType | Count | Pct | Meaning |
|----------------|-------|-----|---------|
| 4 | 2,436 | 58% | Parent position closed - exit propagated from popular investor closing their position |
| 1 | 1,334 | 32% | Normal close - standard copier-initiated or system-initiated close |
| 0 | 194 | 5% | Default/no specific close reason |
| 3 | 176 | 4% | Mirror-stop or market close (batch close without mirror deregistration) |
| 2 | 65 | 1.5% | Alternate close variant |
| 6 | 3 | 0.07% | Special close type |

`MirrorCloseActionType` records the state of the mirror relationship at the time of this exit order. 0 = mirror was still active when the position was exited (most common - position closed while copying relationship persists). Non-zero = exit was triggered by mirror deregistration.

### 2.3 Position Identification and Partial Close Context

**What**: The PositionID identifies the copier's specific position being closed; partial close fields track fractional exits.

**Columns/Parameters Involved**: `PositionID`, `UnitsToDeduct`, `CloseByUnitsID`, `RedeemID`, `RedeemReasonID`

**Rules**:
- `PositionID` = the copier's own position ID (bigint, matching Trade.PositionTbl / History.Position_Active)
- The NC index on (CID, PositionID) in History.OrdersExitTbl enables efficient per-copier-position lookups
- One PositionID can have multiple exit orders: 1,716 distinct PositionIDs / 4,208 rows = ~2.4 exit orders per position on average
- `UnitsToDeduct` + `CloseByUnitsID`: set for partial-close-by-units operations; NULL = full position close (all current observed rows)
- `RedeemID` + `RedeemReasonID`: set when the close was triggered by a redemption event; NULL for all current observed rows

---

## 3. Data Overview

| OrderID | CID | PositionID | MirrorID | CloseActionType | MirrorCloseActionType | OpenActionType | OpenOccurred | CloseOccurred |
|---------|-----|-----------|---------|----------------|----------------------|---------------|-------------|---------------|
| 4286 | 6620821 | 2150658010 | 1839529 | 3 | 0 | 1 | 2024-05-17 23:11 | 2024-05-19 08:31 | CloseType=3 (mirror-stop/batch-close). Mirror still active (MirrorCloseActionType=0). ~33h exit order. |
| 4285 | 14866502 | 2150657978 | 1839519 | 3 | 0 | 1 | 2024-05-17 23:11 | 2024-05-19 08:41 | Same batch close event. OpenOccurred identical to 4286 - these were opened together. ~34h duration. |
| 4284 | 14866507 | 2150657997 | 1839523 | 3 | 0 | 1 | 2024-05-17 23:11 | 2024-05-19 08:28 | Same batch. Identical OpenOccurred across all three rows confirms a batch-initiated exit. CloseOccurred varies slightly (processing order). |

The identical OpenOccurred (2024-05-17 23:11) for all three most recent rows is a tell that these exit orders were opened in a single batch operation - likely a scheduled close event or market closure triggering simultaneous exit orders across multiple copiers. The CloseOccurred timestamps (~10 minutes apart) reflect sequential processing by Trade.AsyncOrdersChangeLog.

Note: RedeemID, RedeemReasonID, UnitsToDeduct, and CloseByUnitsID are NULL for all observed rows, confirming full-close non-redemption exits in current data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | int | NO | - | CODE-BACKED | Exit order ID. Matches Trade.OrdersExitTbl.OrderID. Preserved via DELETE...OUTPUT INTO. PK in both source tables. |
| 2 | CID | int | NO | - | CODE-BACKED | Copier customer ID. NOT NULL (unlike the entry table where CID is nullable). All 4,208 rows have CID. NC index on (CID, PositionID) in History.OrdersExitTbl. |
| 3 | PositionID | bigint | NO | - | CODE-BACKED | The copier's position being closed. bigint (changed from int in Nov 2021 when position IDs exceeded int range). 1,716 distinct positions in the archived data. NC index key for per-copier-position lookups. |
| 4 | OpenOccurred | datetime | NO | - | CODE-BACKED | When the exit order was opened (the start of the exit process - when the close was initiated). Identical across batch-close events for positions closed in the same operation. |
| 5 | CloseOccurred | datetime | NO | getutcdate() | CODE-BACKED | When the exit order was completed. Set to GETUTCDATE() by Trade.AsyncOrdersChangeLog. DEFAULT = getutcdate() as safety net. Sequential for batch-processed exits. |
| 6 | CloseActionType | int | YES | - | CODE-BACKED | Why/how the exit order completed. Values: 0=default, 1=normal close (32%), 2=alternate, 3=mirror-stop/market-close (4%), 4=parent-position-closed (dominant, 58%), 6=special. |
| 7 | MirrorID | int | YES | - | CODE-BACKED | The copy relationship ID. Always populated in current data (all 4,208 rows). Links to Trade.Mirror. |
| 8 | MirrorCloseActionType | int | YES | - | CODE-BACKED | How the mirror relationship was closed at exit time. 0 = mirror still active (most common). Non-zero = exit was triggered by mirror deregistration with a specific reason. |
| 9 | OpenActionType | int | NO | 0 | CODE-BACKED | Type of action that opened this exit order. DEFAULT=0 in schema. Most current rows have OpenActionType=1. Classifies the trigger for initiating the exit order process. |
| 10 | RedeemID | int | YES | - | CODE-BACKED | Links this exit order to a redemption operation if close was triggered by a redeem event. NULL for all observed rows (no redemption-triggered exits in current data). |
| 11 | RedeemReasonID | int | YES | - | CODE-BACKED | Reason for the redemption if RedeemID is set. NULL when RedeemID is NULL. |
| 12 | UnitsToDeduct | decimal(16,6) | YES | - | CODE-BACKED | For partial-close-by-units: the number of units being closed in this exit order. NULL = full position close. NULL for all current observed rows. |
| 13 | CloseByUnitsID | bigint | YES | - | CODE-BACKED | The identifier of the close-by-units operation that initiated this partial close. NULL when UnitsToDeduct is NULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (archived rows) | History.OrdersExitTbl | View (UNION branch 1) | Historical archive of permanently closed copy-trading exit orders |
| (live closed rows) | Trade.OrdersExitTbl | View (UNION branch 2, WHERE StatusID=2) | Recently closed exit orders pending async archival |
| PositionID | Trade.PositionTbl / History.Position_Active | Implicit FK | The copier's position being closed (bigint) |
| MirrorID | Trade.Mirror | Implicit FK | Copy relationship that generated this exit order |
| CID | Customer.Customer | Implicit FK | Copier customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ChekAsyncFailedSteps | OrderID | Read (health check) | Validates that async exit order processing completed correctly |
| Trade.OrdersExitChangeLogAdd | OrderID | Read (change log) | Adds audit trail entries referencing this view |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.OrdersExit (view)
|- History.OrdersExitTbl (table - leaf, archived closed exit orders)
|    - Written by: Trade.AsyncOrdersChangeLog (ExitOrderPostActions, OperationTypeID=2)
|    - DELETE Trade.OrdersExitTbl OUTPUT INTO History.OrdersExitTbl
|
+- Trade.OrdersExitTbl (table - cross-schema, live table with StatusID=2 closed rows)
     - Written by: Trade exit order close flow
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.OrdersExitTbl | Table | UNION ALL branch 1 - all 13 columns, all archived rows |
| Trade.OrdersExitTbl | Table | UNION ALL branch 2 - all 13 columns (same names, no aliasing), WHERE StatusID=2 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ChekAsyncFailedSteps | Stored Procedure | Health check for async processing |
| Trade.OrdersExitChangeLogAdd | Stored Procedure | Change log writer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. Queries benefit from:
- `History.OrdersExitTbl`: CLUSTERED PK on OrderID (FILLFACTOR=85, PAGE compression), NC (CID, PositionID) for copier-position lookups
- `Trade.OrdersExitTbl`: Primary indexes serve the WHERE StatusID=2 filter and PositionID lookups

### 7.2 Constraints

N/A for View.

---

## 8. Sample Queries

### 8.1 Get all closed exit orders for a specific copier position (full history)
```sql
SELECT
    oe.OrderID,
    oe.MirrorID,
    oe.CloseActionType,
    oe.MirrorCloseActionType,
    oe.OpenActionType,
    oe.OpenOccurred,
    oe.CloseOccurred,
    DATEDIFF(MINUTE, oe.OpenOccurred, oe.CloseOccurred) AS ExitDurationMinutes,
    oe.UnitsToDeduct,
    oe.RedeemID
FROM History.OrdersExit oe WITH (NOLOCK)
WHERE oe.CID = 6620821
  AND oe.PositionID = 2150658010
ORDER BY oe.CloseOccurred DESC;
```

### 8.2 Find all exits for a mirror relationship with their close reasons
```sql
SELECT
    oe.OrderID,
    oe.PositionID,
    oe.CloseActionType,
    oe.MirrorCloseActionType,
    oe.OpenOccurred,
    oe.CloseOccurred
FROM History.OrdersExit oe WITH (NOLOCK)
WHERE oe.MirrorID = 1839529
ORDER BY oe.CloseOccurred DESC;
```

### 8.3 Batch close events - positions closed in the same operation
```sql
SELECT
    oe.OpenOccurred,
    COUNT(*) AS ExitOrderCount,
    COUNT(DISTINCT oe.PositionID) AS DistinctPositions,
    COUNT(DISTINCT oe.CID) AS DistinctCopiers,
    oe.CloseActionType
FROM History.OrdersExit oe WITH (NOLOCK)
WHERE oe.OpenOccurred >= DATEADD(DAY, -30, GETUTCDATE())
GROUP BY oe.OpenOccurred, oe.CloseActionType
HAVING COUNT(*) > 5  -- batch events only
ORDER BY ExitOrderCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for History.OrdersExit. Business context inherited from History.OrdersExitTbl documentation.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.1/10 (Elements: 9.1/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 2, 5, 7, 8)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 consumers | App Code: 0 repos | Corrections: 0 applied*
*Object: History.OrdersExit | Type: View | Source: etoro/etoro/History/Views/History.OrdersExit.sql*
