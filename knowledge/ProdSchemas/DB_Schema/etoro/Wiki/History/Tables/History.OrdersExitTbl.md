# History.OrdersExitTbl

> Archive of closed copy-trading exit orders. When a CopyTrader exit order in Trade.OrdersExitTbl is closed, it is atomically moved here via DELETE...OUTPUT INTO by Trade.AsyncOrdersChangeLog (ExitOrderPostActions, OperationTypeID=2). Each row represents a completed exit order from the Copy Trading system, linking the copier (CID, MirrorID) to the specific position being closed (PositionID).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | OrderID (int, PK) |
| **Partition** | No - CLUSTERED on [PRIMARY], NC index on [HISTORY] |
| **Indexes** | 2 (CLUSTERED PK on OrderID, NC on CID+PositionID) |

---

## 1. Business Meaning

This table is the historical archive for copy-trading exit orders. Where `History.OrdersEntryTbl` captures entry (open-side) orders for copy positions, `History.OrdersExitTbl` captures exit (close-side) orders. When a copy position needs to be closed - due to mirror deregistration, stop-loss trigger, parent position closing, or manual close - an exit order is created in `Trade.OrdersExitTbl` and when completed, archived here via DELETE...OUTPUT INTO.

The table has 4,208 rows (2023-01-05 to 2024-05-19). All 4,208 rows have MirrorID set, confirming this is exclusively a copy-trading exit order archive. 615 distinct copier CIDs and 1,716 distinct positions are represented.

**Companion table**: `History.OrdersEntryTbl` archives the entry orders. Together they form the complete order lifecycle for copy-trading positions. The view `History.OrdersExit` joins this table with additional context for reporting.

---

## 2. Business Logic

### 2.1 Delete-Output-Into Archive Pattern

**What**: Exit orders are archived using the same DELETE...OUTPUT INTO pattern as entry orders, handled by Trade.AsyncOrdersChangeLog.

**Columns/Parameters Involved**: `OrderID`, `CloseOccurred`, `CloseActionType`

**Rules**:
```sql
-- Trade.AsyncOrdersChangeLog (ProcedureName='Trade.ExitOrderPostActions', OperationTypeID=2):
DELETE Trade.OrdersExitTbl
OUTPUT DELETED.OrderID, DELETED.PositionID, DELETED.OpenOccurred, DELETED.CloseOccurred, DELETED.CloseActionType,
       DELETED.CID, DELETED.MirrorID, DELETED.MirrorCloseActionType, DELETED.OpenActionType,
       DELETED.RedeemID, DELETED.RedeemReasonID, DELETED.UnitsToDeduct, DELETED.CloseByUnitsID
INTO History.OrdersExitTbl (OrderID, PositionID, OpenOccurred, CloseOccurred, CloseActionType,
       CID, MirrorID, MirrorCloseActionType, OpenActionType,
       RedeemID, RedeemReasonID, UnitsToDeduct, CloseByUnitsID)
WHERE OrderID = @OrderID
```
- `CloseOccurred` is set to GETUTCDATE() on Trade.OrdersExitTbl before archival (DEFAULT = getutcdate() as safety net)
- The async mechanism: the exit order close triggers `Trade.InsertAsyncRecord`, and `Trade.AsyncOrdersChangeLog` processes it asynchronously

### 2.2 CloseActionType - Exit Order Outcome

**What**: Records why the exit order completed.

**Columns/Parameters Involved**: `CloseActionType`, `MirrorCloseActionType`

**Rules** (observed distribution):

| CloseActionType | Count | Pct | Meaning |
|----------------|-------|-----|---------|
| 4 | 2,436 | 58% | Exit order triggered by a parent-close event (position close propagated from popular investor) |
| 1 | 1,334 | 32% | Normal close |
| 0 | 194 | 5% | Default/no specific close reason |
| 3 | 176 | 4% | Alternate close (seen in most recent rows: position cancelled after mirror deregistration) |
| 2 | 65 | 1.5% | Alternate close variant |
| 6 | 3 | 0.07% | Special close type |

`MirrorCloseActionType` records how the mirror relationship itself was closed at the time of this exit order. 0 for most rows (mirror still active when position exited), non-zero when the exit was triggered by mirror deregistration.

### 2.3 Position Identification (PositionID vs InstrumentID)

**What**: Unlike `History.OrdersEntryTbl` which identifies the instrument being copied, the exit table identifies the specific copier position being closed.

**Columns/Parameters Involved**: `PositionID`, `CID`, `MirrorID`

**Rules**:
- `PositionID` = the copier's own position ID (bigint, matches Trade.PositionTbl/History.Position_Active)
- The NC index on (CID, PositionID) enables efficient lookup of all exit orders for a specific copier position
- One PositionID may have multiple exit orders (e.g., partial closes via UnitsToDeduct)
- 1,716 distinct PositionIDs across 615 copiers, averaging ~2.4 exit orders per position

### 2.4 Redeem and Partial Close Context

**What**: Exit orders can be triggered by redemption events or partial close (by units) operations.

**Columns/Parameters Involved**: `RedeemID`, `RedeemReasonID`, `UnitsToDeduct`, `CloseByUnitsID`

**Rules**:
- `RedeemID` + `RedeemReasonID`: set when the position close is linked to a redemption operation (NULL for most rows in current data)
- `UnitsToDeduct` + `CloseByUnitsID`: set for partial close-by-units operations where only a portion of the position is exited. NULL means a full close.
- All observed recent rows have NULL for all four columns (full closes, not redemption/partial)

---

## 3. Data Overview

| OrderID | CID | PositionID | MirrorID | CloseActionType | OpenActionType | OpenOccurred | CloseOccurred |
|---------|-----|-----------|---------|----------------|---------------|-------------|---------------|
| 4285 | 14866502 | 2150657978 | 1839519 | 3 | 1 | 2024-05-17 23:11 | 2024-05-19 08:41 | ~33h exit order - mirror stop |
| 4286 | 6620821 | 2150658010 | 1839529 | 3 | 1 | 2024-05-17 23:11 | 2024-05-19 08:31 | Same batch, CloseType=3 |
| 4284 | 14866507 | 2150657997 | 1839523 | 3 | 1 | 2024-05-17 23:11 | 2024-05-19 08:28 | MirrorCloseActionType=0 (mirror not closed) |

Most recent rows cluster around CloseActionType=3 with MirrorCloseActionType=0, suggesting a batch close of copy positions without mirror deregistration (e.g., stop-loss trigger or market close).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | int | NO | - | CODE-BACKED | Exit order ID, matching Trade.OrdersExitTbl.OrderID. Preserved via DELETE...OUTPUT INTO. PK. |
| 2 | CID | int | NO | - | CODE-BACKED | Copier customer ID. NOT NULL (unlike History.OrdersEntryTbl.CID which is nullable). All 4,208 rows have CID. |
| 3 | PositionID | bigint | NO | - | CODE-BACKED | The copier's position being closed. bigint (changed from int in Nov 2021 for large position IDs). NC index (CID, PositionID) enables efficient lookup. 1,716 distinct positions in current data. |
| 4 | OpenOccurred | datetime | NO | - | CODE-BACKED | When the exit order was created/opened (the start of the exit process). |
| 5 | CloseOccurred | datetime | NO | getutcdate() | CODE-BACKED | When the exit order was completed. Set to GETUTCDATE() at close time; DEFAULT = getutcdate() as safety net. |
| 6 | CloseActionType | int | YES | - | CODE-BACKED | How/why the exit order completed. Values: 0=default, 1=normal, 2=alternate, 3=mirror-stop or market-close, 4=parent-position-closed (dominant at 58%), 6=special. |
| 7 | MirrorID | int | YES | - | CODE-BACKED | The copy relationship ID. Always populated in current data (all 4,208 rows). Links to Trade.Mirror. |
| 8 | MirrorCloseActionType | int | YES | - | CODE-BACKED | How the mirror relationship was closed at the time of this exit order. 0 = mirror still active when position was exited. Non-zero = exit triggered by mirror deregistration with a specific reason code. |
| 9 | OpenActionType | int | NO | 0 | CODE-BACKED | Type of the action that opened this exit order. DEFAULT=0. Most current rows have OpenActionType=1. Classifies the trigger for initiating the exit order. |
| 10 | RedeemID | int | YES | - | CODE-BACKED | Links this exit order to a redemption operation if the close was triggered by a redeem event. NULL for all current rows (no redemption-triggered closes in this dataset). |
| 11 | RedeemReasonID | int | YES | - | CODE-BACKED | The reason for the redemption if RedeemID is set. NULL when RedeemID is NULL. |
| 12 | UnitsToDeduct | decimal(16,6) | YES | - | CODE-BACKED | For partial-close-by-units operations: the number of units being closed in this exit order. NULL = full position close. NULL for all current rows. |
| 13 | CloseByUnitsID | bigint | YES | - | CODE-BACKED | The identifier of the close-by-units operation that initiated this partial close. NULL when UnitsToDeduct is NULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Target Object | Target Element | Relationship Type | Description |
|--------------|----------------|-------------------|-------------|
| Trade.Mirror | MirrorID | Implicit FK (no constraint) | The copy relationship that generated this exit order. |
| Trade.PositionTbl / History.Position_Active | PositionID | Implicit FK (no constraint) | The copier's position being closed. bigint FK. |
| Customer.Customer | CID | Implicit FK (no constraint) | The copier customer. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.AsyncOrdersChangeLog | OrderID | Writer (archive-on-delete) | Deletes from Trade.OrdersExitTbl and outputs into this table (ExitOrderPostActions, OperationTypeID=2) |
| History.OrdersExit | OrderID | View join | Reporting view joining exit order context |
| dbo.SSRS_ORDERS_BY_CID | CID | Read | SSRS report queries by copier |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.OrdersExitTbl (table)
- Written by: Trade.AsyncOrdersChangeLog
  - DELETE Trade.OrdersExitTbl OUTPUT INTO History.OrdersExitTbl (ExitOrderPostActions, OperationTypeID=2)
  - Triggered asynchronously by the exit order close flow
```

### 6.1 Objects This Depends On

No FK constraints. Implicit dependencies: Trade.Mirror (MirrorID), Trade.PositionTbl (PositionID).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.OrdersExit | View | JOIN-based reporting view |
| dbo.SSRS_ORDERS_BY_CID | SP | SSRS report |
| dbo.SSRS_ORDERS_AMOUNT | SP | SSRS report |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HOrdersExit | CLUSTERED | OrderID ASC | - | - | Active (FILLFACTOR=85, PAGE compression, PRIMARY filegroup) |
| His_NonClusteredIndex_CID_PID | NONCLUSTERED | CID ASC, PositionID ASC | - | - | Active (PAGE compression, HISTORY filegroup) |

### 7.2 Constraints

| Name | Type | Definition |
|------|------|------------|
| PK_HOrdersExit | PRIMARY KEY | OrderID ASC - clustered |
| DF_TradeExitOrders_DateExecuted | DEFAULT | CloseOccurred = getutcdate() |
| DF_HistoryOrderExist_OpenActionType | DEFAULT | OpenActionType = 0 |

---

## 8. Sample Queries

### 8.1 Exit order history for a copier's position

```sql
SELECT
    h.OrderID,
    h.MirrorID,
    h.CloseActionType,
    h.MirrorCloseActionType,
    h.OpenActionType,
    h.OpenOccurred,
    h.CloseOccurred,
    DATEDIFF(MINUTE, h.OpenOccurred, h.CloseOccurred) AS ExitDurationMinutes,
    h.UnitsToDeduct,
    h.RedeemID
FROM History.OrdersExitTbl h WITH (NOLOCK)
WHERE h.CID = @CID
  AND h.PositionID = @PositionID
ORDER BY h.CloseOccurred DESC;
```

### 8.2 Exit orders for a mirror relationship

```sql
SELECT
    h.OrderID,
    h.PositionID,
    h.CloseActionType,
    h.MirrorCloseActionType,
    h.OpenOccurred,
    h.CloseOccurred
FROM History.OrdersExitTbl h WITH (NOLOCK)
WHERE h.MirrorID = @MirrorID
ORDER BY h.CloseOccurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific table.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.7/10 (Elements: 8.7/10, Logic: 8.8/10, Relationships: 8.5/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Trade.AsyncOrdersChangeLog) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.OrdersExitTbl | Type: Table | Source: etoro/etoro/History/Tables/History.OrdersExitTbl.sql*
