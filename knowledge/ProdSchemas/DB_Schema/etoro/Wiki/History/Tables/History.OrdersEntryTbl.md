# History.OrdersEntryTbl

> Archive of closed copy-trading "open-open" entry orders. When a CopyTrader entry order in Trade.OrdersEntryTbl is closed, it is atomically moved here via DELETE...OUTPUT INTO by Trade.AsyncOrdersChangeLog (OperationTypeID=2). Every row represents a completed entry order from the Copy Trading open-open flow, linking the copier (CID, MirrorID) to the parent position being copied (ParentPositionID).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | OrderID (int, PK - matches Trade.OrdersEntryTbl.OrderID) |
| **Partition** | No - CLUSTERED on [PRIMARY], NC index on [MAIN] |
| **Indexes** | 2 (CLUSTERED PK on OrderID, NC on CID) |

---

## 1. Business Meaning

This table is the historical archive for the Copy Trading "open-open" entry order system. When a copier (CID, MirrorID) follows a popular investor, the system creates entry orders in `Trade.OrdersEntryTbl` representing the copier's intent to mirror the parent's open positions. When such an entry order completes (is filled, cancelled, or converted to a position), `Trade.AsyncOrdersChangeLog` deletes it from `Trade.OrdersEntryTbl` and archives it here via `DELETE ... OUTPUT INTO History.OrdersEntryTbl`.

The table has 3,762 rows (2023-01-04 to 2024-05-17 in the current environment - not actively written since May 2024). All 3,762 rows have MirrorID and ParentPositionID set, confirming this is exclusively a copy-trading entry order archive. OrderTypeID=13 for all rows (the DEFAULT).

**Companion tables**: `History.OrdersExitTbl` archives the exit (close-side) orders. Together with `History.OrdersEntryTbl`, they form the complete lifecycle record for copy-trading entry orders. The view `History.OrdersEntry` joins this table with other context for reporting.

---

## 2. Business Logic

### 2.1 Delete-Output-Into Archive Pattern

**What**: Copy-trading entry orders are archived using the DELETE...OUTPUT INTO pattern - a single atomic statement that removes from Trade and writes to History simultaneously.

**Columns/Parameters Involved**: `OrderID`, `ClosedOccurred`, `CloseActionType`

**Rules**:
```sql
-- Trade.AsyncOrdersChangeLog (OperationTypeID=2 / close):
DELETE Trade.OrdersEntryTbl
OUTPUT DELETED.OrderID, DELETED.CID, DELETED.InstrumentID, DELETED.Leverage, DELETED.Amount, DELETED.IsBuy,
       DELETED.StopLosPercentage, DELETED.TakeProfitPercentage, DELETED.Occurred, DELETED.CloseActionType, DELETED.CloseOccurred,
       DELETED.ParentPositionID, DELETED.MirrorID, DELETED.InitialMirrorAmountInCents, DELETED.IsTslEnabled, DELETED.AmountInUnitsDecimal,
       DELETED.OrderTypeID, DELETED.OpenOpenOperationTypeID, DELETED.IsDiscounted
INTO History.OrdersEntryTbl (OrderID, CID, InstrumentID, Leverage, Amount, IsBuy,
       StopLosPercentage, TakeProfitPercentage, OpenOccurred, CloseActionType, ClosedOccurred,
       ParentPositionID, MirrorID, InitialMirrorAmountInCents, IsTslEnabled, AmountInUnitsDecimal,
       OrderTypeID, OpenOpenOperationTypeID, IsDiscounted)
WHERE OrderID = @OrderID
```
- **Column name mapping**: Trade.OrdersEntryTbl.`Occurred` -> History.OrdersEntryTbl.`OpenOccurred`; Trade.OrdersEntryTbl.`CloseOccurred` -> History.OrdersEntryTbl.`ClosedOccurred`
- Before archival, Trade.OrderEntryClose updates Trade.OrdersEntryTbl with `StatusID=2, CloseOccurred=GETUTCDATE(), CloseActionType=@ActionTypeID` to mark it closed
- The async mechanism: Trade.OrderEntryClose enqueues via `Trade.InsertAsyncRecord`, then `Trade.AsyncOrdersChangeLog` processes it asynchronously

### 2.2 CloseActionType - Entry Order Outcome

**What**: Records why the entry order was closed/completed.

**Columns/Parameters Involved**: `CloseActionType`

**Rules** (observed values):

| CloseActionType | Count | Meaning |
|----------------|-------|---------|
| 0 | 1,090 | Initial/default state or order completed without a specific close reason |
| 1 | 2,274 | Normal close - entry order fulfilled (dominant: 60%) |
| 2 | 379 | Alternative close type - order cancelled or converted |
| 4 | 19 | Exit order created for parent position - triggers insertion into Trade.SynchOrdersEntry for synchronization |

CloseActionType=4 is specially handled in Trade.OrderEntryClose: when ActionTypeID=4, an additional INSERT into `Trade.SynchOrdersEntry` records the synchronization event.

### 2.3 Copy-Trading Context (MirrorID + ParentPositionID)

**What**: Every row in this table has both MirrorID and ParentPositionID - these are the core copy-trading identifiers.

**Columns/Parameters Involved**: `MirrorID`, `ParentPositionID`, `InitialMirrorAmountInCents`

**Rules**:
- `MirrorID` = the CopyTrader relationship ID (links to Trade.Mirror)
- `ParentPositionID` = the popular investor's position being copied (links to Trade.PositionTbl in the REAL environment)
- `InitialMirrorAmountInCents` = the total allocated copy amount at the time of this entry order (e.g., 35000 = $350.00). Used to calculate the proportional share of the parent position for this copier
- All 3,762 rows have both MirrorID and ParentPositionID populated - confirming this table exclusively serves the open-open copy flow

---

## 3. Data Overview

| OrderID | CID | InstrumentID | MirrorID | ParentPositionID | Amount | CloseActionType | OpenOccurred | ClosedOccurred |
|---------|-----|-------------|---------|-----------------|--------|----------------|-------------|---------------|
| 3802 | 6770872 | 5 (EURUSD) | 1839451 | 2150639050 | $4.94 | 1 | 2024-05-17 00:01 | 2024-05-17 01:00 | Normal close, ~59min lifetime |
| 3801 | 14952789 | 5 (EURUSD) | 1839448 | 2150639038 | $3.53 | 0 | 2024-05-16 23:01 | 2024-05-17 00:01 | 60min open window - daily rollover |
| 3800 | 6770875 | 5 (EURUSD) | 1839273 | 2150639038 | $3.52 | 1 | 2024-05-16 00:01 | 2024-05-16 01:00 | Same pattern: 60min, Leverage=30 |

All observed rows have OrderTypeID=13, OpenOpenOperationTypeID=1, InstrumentID=5 (EURUSD), Leverage=30. The consistent ~60-minute open windows suggest these are daily interval-based copy position refreshes.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | int | NO | - | CODE-BACKED | Copy-trading entry order ID, matching Trade.OrdersEntryTbl.OrderID. Preserved from the live table via DELETE...OUTPUT INTO. PK of this table. |
| 2 | CID | int | YES | - | CODE-BACKED | Copier customer ID. Always populated in current data (all 3,762 rows have CID). Indexed via IX_HOrdersEntry_CID for efficient copier-based lookups. |
| 3 | InstrumentID | int | YES | - | CODE-BACKED | The instrument being copied. In current data, all rows have InstrumentID=5 (EURUSD). Represents the parent position's instrument. |
| 4 | Leverage | int | YES | - | CODE-BACKED | Leverage applied to this entry order. All current rows have Leverage=30 (30x, consistent with EURUSD standard leverage). |
| 5 | Amount | money | YES | - | CODE-BACKED | The copier's proportional dollar amount for this entry order (the copier's share of the parent position size). $3.52-$4.94 in observed data, reflecting small proportional shares. |
| 6 | IsBuy | bit | YES | - | CODE-BACKED | Direction: 1=Buy (long), 0=Sell. All current rows are IsBuy=true (matching the parent's long position). |
| 7 | StopLosPercentage | money | YES | - | CODE-BACKED | Stop-loss as a percentage of the copy amount. 0 for all observed rows (no percentage-based SL configured). |
| 8 | TakeProfitPercentage | money | YES | - | CODE-BACKED | Take-profit as a percentage of the copy amount. 0 for all observed rows. |
| 9 | OpenOccurred | datetime | NO | - | CODE-BACKED | When the entry order was opened. Copied from Trade.OrdersEntryTbl.Occurred (column renamed in history). For observed rows, this is at the start of each 60-minute interval. |
| 10 | CloseActionType | int | NO | - | CODE-BACKED | How the entry order was closed. Values: 0=default/no reason, 1=normal close (dominant), 2=alternate close, 4=exit order created for parent (triggers SynchOrdersEntry). |
| 11 | ClosedOccurred | datetime | NO | getutcdate() | CODE-BACKED | When the entry order was closed. Set by Trade.OrderEntryClose via `CloseOccurred=GETUTCDATE()` before archival. DEFAULT = getutcdate() (safety net). |
| 12 | ParentPositionID | bigint | YES | - | CODE-BACKED | The popular investor's position ID being copied. Always populated in current data. Bigint since positionIDs exceed int range (changed in Nov 2021 per SP comment). |
| 13 | MirrorID | int | YES | - | CODE-BACKED | The copy relationship ID. Always populated in current data. Links to Trade.Mirror which holds the copier-popular-investor pairing. |
| 14 | InitialMirrorAmountInCents | money | YES | - | CODE-BACKED | The total allocated copy amount for this mirror relationship, in cents (e.g., 35000 = $350). Used as the basis for calculating the proportional copy amount for this entry order. |
| 15 | IsTslEnabled | tinyint | NO | 0 | CODE-BACKED | Whether trailing stop-loss was enabled. DEFAULT=0. All current rows have IsTslEnabled=0. |
| 16 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Amount expressed in fractional units. 0 for all observed rows in current data. |
| 17 | OrderTypeID | int | YES | 13 | CODE-BACKED | Type of the entry order. DEFAULT=13 (used for all 3,762 rows). OrderTypeID=13 represents the copy-trading "open-open" entry order type. |
| 18 | OpenOpenOperationTypeID | int | YES | - | CODE-BACKED | Type of the open-open operation that created this entry. All current rows have OpenOpenOperationTypeID=1. Classifies the trigger for the copy position opening. |
| 19 | IsDiscounted | bit | YES | - | CODE-BACKED | Whether a discounted spread was applied. false=no discount for all observed rows. Added in FB 53719 (Free Stocks). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Target Object | Target Element | Relationship Type | Description |
|--------------|----------------|-------------------|-------------|
| Trade.Mirror | MirrorID | Implicit FK (no constraint) | The copy relationship that generated this entry order. |
| Trade.PositionTbl | ParentPositionID | Implicit FK (no constraint) | The parent popular investor position being mirrored. Bigint FK to the REAL environment position. |
| Customer.Customer | CID | Implicit FK (no constraint) | The copier customer. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.AsyncOrdersChangeLog | OrderID | Writer (archive-on-delete) | Deletes from Trade.OrdersEntryTbl and outputs into this table (OperationTypeID=2) |
| History.OrdersEntry | OrderID | View join | Joins this table with context for reporting |
| dbo.SSRS_ORDERS_BY_CID | CID | Read | SSRS report queries by copier |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.OrdersEntryTbl (table)
- Written by: Trade.AsyncOrdersChangeLog
  - DELETE Trade.OrdersEntryTbl OUTPUT INTO History.OrdersEntryTbl (OperationTypeID=2)
  - Triggered asynchronously by Trade.OrderEntryClose -> Trade.InsertAsyncRecord
```

### 6.1 Objects This Depends On

No FK constraints. Implicit dependencies: Trade.Mirror (MirrorID), Trade.PositionTbl (ParentPositionID).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.OrdersEntry | View | JOIN-based reporting view |
| dbo.SSRS_ORDERS_BY_CID | SP | SSRS report |
| dbo.SSRS_ORDERS_AMOUNT | SP | SSRS report |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HOrdersEntry | CLUSTERED | OrderID ASC | - | - | Active (PAGE compression, PRIMARY filegroup) |
| IX_HOrdersEntry_CID | NONCLUSTERED | CID ASC | - | - | Active (FILLFACTOR=90, PAGE compression, MAIN filegroup) |

### 7.2 Constraints

| Name | Type | Definition |
|------|------|------------|
| PK_HOrdersEntry | PRIMARY KEY | OrderID ASC - clustered |
| DF_TradeOrdersEntry_ClosedOccurred | DEFAULT | ClosedOccurred = getutcdate() |
| DF_HistoryOrdersEntry_IsTslEnabled | DEFAULT | IsTslEnabled = 0 |
| DF_HistoryOrdersEntry_OrderTypeID | DEFAULT | OrderTypeID = 13 |

---

## 8. Sample Queries

### 8.1 Entry order history for a copier

```sql
SELECT
    h.OrderID,
    h.MirrorID,
    h.ParentPositionID,
    h.InstrumentID,
    h.Amount,
    h.IsBuy,
    h.Leverage,
    h.CloseActionType,
    h.OpenOccurred,
    h.ClosedOccurred,
    DATEDIFF(MINUTE, h.OpenOccurred, h.ClosedOccurred) AS LifetimeMinutes
FROM History.OrdersEntryTbl h WITH (NOLOCK)
WHERE h.CID = @CID
ORDER BY h.ClosedOccurred DESC;
```

### 8.2 Entry orders for a specific mirror relationship

```sql
SELECT
    h.OrderID,
    h.ParentPositionID,
    h.Amount,
    h.InitialMirrorAmountInCents / 100.0 AS MirrorAmountDollars,
    h.CloseActionType,
    h.OpenOccurred,
    h.ClosedOccurred
FROM History.OrdersEntryTbl h WITH (NOLOCK)
WHERE h.MirrorID = @MirrorID
ORDER BY h.OpenOccurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific table.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 8.8/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (Trade.AsyncOrdersChangeLog, Trade.OrderEntryClose) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.OrdersEntryTbl | Type: Table | Source: etoro/etoro/History/Tables/History.OrdersEntryTbl.sql*
