# History.OrdersEntry

> Unified view of all closed copy-trading entry orders - combines the historical archive (History.OrdersEntryTbl) with currently-closed live orders (Trade.OrdersEntryTbl WHERE StatusID=2) to provide a single query interface for the complete set of completed open-open entry orders.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | OrderID (int) |
| **Partition** | N/A |
| **Indexes** | N/A (view - base table indexes used) |

---

## 1. Business Meaning

History.OrdersEntry is the complete closed-order interface for copy-trading "open-open" entry orders. In the eToro Copy Trading system, when a copier follows a popular investor, the platform creates entry orders in `Trade.OrdersEntryTbl` to mirror the popular investor's open positions. When an entry order is completed (filled, cancelled, or converted), it is asynchronously moved to `History.OrdersEntryTbl` via `Trade.AsyncOrdersChangeLog` using the DELETE...OUTPUT INTO pattern.

This UNION ALL view bridges the two pools of closed entry orders: the permanently archived rows in `History.OrdersEntryTbl` and the recently-closed rows still sitting in `Trade.OrdersEntryTbl` with `StatusID=2` (closed but not yet archived). Querying this view returns the complete picture of all closed entry orders regardless of which table they currently reside in.

**Column name normalization**: The two source tables use different names for the same logical columns. `Trade.OrdersEntryTbl.Occurred` maps to `OpenOccurred` in the view (using the History table's naming convention); `Trade.OrdersEntryTbl.CloseOccurred` maps to `ClosedOccurred`. The view exposes the History naming convention in both branches.

The table rows reflect exclusively copy-trading behavior: all 3,762 archived rows have MirrorID and ParentPositionID set. The live data shows these are short-lived (~60-minute) daily interval copy position refresh orders for instruments like EURUSD (InstrumentID=5) at Leverage=30.

Three procedures reference this view: `dbo.SSRS_CS_History_OrdersEntry` (SSRS copy-order reporting), `dbo.SSRS_PRE_MARKET_ORDER` (pre-market order reporting), and `Trade.OrdersEntryChangeLogAdd` (change log writer).

---

## 2. Business Logic

### 2.1 UNION ALL: Archived + Currently-Closed Entry Orders

**What**: Combines two pools of closed entry orders that differ only in archival status.

**Columns/Parameters Involved**: All 19 columns, `OpenOccurred`, `ClosedOccurred`

**Rules**:
- Branch 1: `History.OrdersEntryTbl` - all rows (permanently archived closed orders). Uses native column names `OpenOccurred` and `ClosedOccurred`.
- Branch 2: `Trade.OrdersEntryTbl WHERE StatusID=2` - recently-closed orders not yet asynchronously archived. Column name mapping: `Trade.Occurred` is aliased as `OpenOccurred`; `Trade.CloseOccurred` is aliased as `ClosedOccurred`.
- No deduplication - UNION ALL is used because the same OrderID cannot appear in both tables (DELETE...OUTPUT INTO atomically moves from Trade to History).
- The WHERE StatusID=2 filter limits the Trade branch to closed orders only (1=open, 2=closed).

**Diagram**:
```
History.OrdersEntryTbl (archived, permanently closed)
  SELECT OrderID, CID, ..., OpenOccurred, ClosedOccurred, ...
  |
UNION ALL
  |
Trade.OrdersEntryTbl WHERE StatusID=2 (recently closed, pending archival)
  SELECT OrderID, CID, ..., Occurred AS OpenOccurred, CloseOccurred AS ClosedOccurred, ...
  |
  v
History.OrdersEntry (view - all closed entry orders, unified 19-column schema)
```

### 2.2 Column Name Mapping (Trade vs History Naming)

**What**: Two columns have different names in `Trade.OrdersEntryTbl` vs `History.OrdersEntryTbl`.

**Columns/Parameters Involved**: `OpenOccurred`, `ClosedOccurred`

**Rules**:
- `Trade.OrdersEntryTbl.Occurred` -> view column `OpenOccurred` (when the entry order was opened)
- `Trade.OrdersEntryTbl.CloseOccurred` -> view column `ClosedOccurred` (when the entry order was closed)
- The History table uses the descriptive `OpenOccurred`/`ClosedOccurred` names; the Trade table uses `Occurred`/`CloseOccurred`
- The DELETE...OUTPUT INTO archival procedure explicitly handles this mapping: `OUTPUT DELETED.Occurred INTO History.OrdersEntryTbl (...OpenOccurred...)`

### 2.3 CloseActionType - Entry Order Outcome Classification

**What**: Indicates why/how the copy-trading entry order was closed.

**Columns/Parameters Involved**: `CloseActionType`

**Rules** (from History.OrdersEntryTbl distribution):

| CloseActionType | Count | Pct | Meaning |
|----------------|-------|-----|---------|
| 1 | 2,274 | 60% | Normal close - entry order fulfilled (dominant) |
| 0 | 1,090 | 29% | Default state or completed without specific reason |
| 2 | 379 | 10% | Alternative close - order cancelled or converted |
| 4 | 19 | 1% | Exit order created for parent position - also triggers INSERT into Trade.SynchOrdersEntry |

---

## 3. Data Overview

| OrderID | CID | InstrumentID | MirrorID | ParentPositionID | Amount | CloseActionType | OpenOccurred | ClosedOccurred |
|---------|-----|-------------|---------|-----------------|--------|----------------|-------------|---------------|
| 3802 | 6770872 | 5 (EURUSD) | 1839451 | 2150639050 | $4.94 | 1 | 2024-05-17 00:01 | 2024-05-17 01:00 | Normal close. ~59min lifetime. Leverage=30, IsBuy=true, OrderTypeID=13. |
| 3801 | 14952789 | 5 (EURUSD) | 1839448 | 2150639038 | $3.53 | 0 | 2024-05-16 23:01 | 2024-05-17 00:01 | Default close. 60min open window - daily rollover cycle. |
| 3800 | 6770875 | 5 (EURUSD) | 1839273 | 2150639038 | $3.52 | 1 | 2024-05-16 00:01 | 2024-05-16 01:00 | Normal close. Same 60min pattern. Different MirrorID, same ParentPositionID as 3801 - multiple copiers on the same parent position. |

The consistent ~60-minute open windows across all rows reflect daily interval-based copy position refresh events. All observed entries are EURUSD at Leverage=30, suggesting this dataset captures a specific copy group's activity rather than the full diversity of instruments.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | int | NO | - | CODE-BACKED | Copy-trading entry order ID. Matches Trade.OrdersEntryTbl.OrderID. Preserved via DELETE...OUTPUT INTO archival. PK in both source tables. |
| 2 | CID | int | YES | - | CODE-BACKED | Copier customer ID. Nullable in the History table (legacy schema). Always populated in current data. NC index on History.OrdersEntryTbl for copier-based lookups. |
| 3 | InstrumentID | int | YES | - | CODE-BACKED | The instrument being copied - the parent popular investor's position instrument. All observed data shows InstrumentID=5 (EURUSD). References Trade.Instrument. |
| 4 | Leverage | int | YES | - | CODE-BACKED | Leverage applied to this entry order. All observed rows have Leverage=30 (30x EURUSD standard). |
| 5 | Amount | money | YES | - | CODE-BACKED | The copier's proportional dollar share for this entry order. $3.52-$4.94 in observed data (small proportional shares of the parent position). |
| 6 | IsBuy | bit | YES | - | CODE-BACKED | Direction: 1=Buy (long), 0=Sell. All current rows are IsBuy=true, matching the parent's long EURUSD position. |
| 7 | StopLosPercentage | money | YES | - | CODE-BACKED | Stop-loss as a percentage of the copy amount. 0 for all observed rows (no percentage-based SL configured). |
| 8 | TakeProfitPercentage | money | YES | - | CODE-BACKED | Take-profit as a percentage of the copy amount. 0 for all observed rows. |
| 9 | OpenOccurred | datetime | NO | - | CODE-BACKED | When the entry order was opened. In History.OrdersEntryTbl this is the native column name. In Trade.OrdersEntryTbl this is aliased from `Occurred`. Represents the start of the copy position interval. |
| 10 | CloseActionType | int | NO | - | CODE-BACKED | How/why the entry order was closed. Values: 0=default, 1=normal close (60%), 2=alternate close, 4=exit order created for parent (triggers Trade.SynchOrdersEntry insert). |
| 11 | ClosedOccurred | datetime | NO | getutcdate() | CODE-BACKED | When the entry order was closed. In History.OrdersEntryTbl this is the native column name. In Trade.OrdersEntryTbl aliased from `CloseOccurred`. DEFAULT = getutcdate() as safety net in both source tables. |
| 12 | ParentPositionID | bigint | YES | - | CODE-BACKED | The popular investor's position ID being copied. Always populated in current data. bigint since Nov 2021 (position IDs exceeded int range). Links to Trade.PositionTbl in the REAL environment. |
| 13 | MirrorID | int | YES | - | CODE-BACKED | The copy relationship ID. Always populated in current data. Links to Trade.Mirror (copier-popular-investor pairing). |
| 14 | InitialMirrorAmountInCents | money | YES | - | CODE-BACKED | Total allocated copy amount at time of this entry order, in cents (e.g., 35000 = $350.00). Used as the basis for calculating the proportional copy Amount for this order. |
| 15 | IsTslEnabled | tinyint | NO | 0 | CODE-BACKED | Whether trailing stop-loss was enabled for this entry order. DEFAULT=0. All current rows have IsTslEnabled=0. |
| 16 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Amount expressed in fractional instrument units. 0 for all observed rows in current data. |
| 17 | OrderTypeID | int | YES | 13 | CODE-BACKED | Type of the entry order. DEFAULT=13 (used for all 3,762 archived rows). OrderTypeID=13 represents the copy-trading "open-open" entry order type. |
| 18 | OpenOpenOperationTypeID | int | YES | - | CODE-BACKED | Type of the open-open operation that created this entry. All current rows have OpenOpenOperationTypeID=1. Classifies the trigger for the copy position opening cycle. |
| 19 | IsDiscounted | bit | YES | - | CODE-BACKED | Whether a discounted spread was applied to this entry order. false=no discount for all observed rows. Added in FB 53719 (Free Stocks feature). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (archived rows) | History.OrdersEntryTbl | View (UNION branch 1) | Historical archive of permanently closed copy-trading entry orders |
| (live closed rows) | Trade.OrdersEntryTbl | View (UNION branch 2, WHERE StatusID=2) | Recently closed entry orders pending async archival |
| ParentPositionID | Trade.PositionTbl | Implicit FK | Popular investor's position being mirrored |
| MirrorID | Trade.Mirror | Implicit FK | Copy relationship (copier to popular investor) |
| CID | Customer.Customer | Implicit FK | Copier customer |
| InstrumentID | Trade.Instrument | Implicit FK | Instrument of the copied position |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.SSRS_CS_History_OrdersEntry | OrderID | Read (SSRS report) | Copy-trading entry order history report |
| dbo.SSRS_PRE_MARKET_ORDER | OrderID | Read (SSRS report) | Pre-market order reporting |
| Trade.OrdersEntryChangeLogAdd | OrderID | Read (change log) | Adds change log entries referencing this view's data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.OrdersEntry (view)
|- History.OrdersEntryTbl (table - leaf, archived closed orders)
|    - Written by: Trade.AsyncOrdersChangeLog (DELETE...OUTPUT INTO, OperationTypeID=2)
|    - Triggered by: Trade.OrderEntryClose -> Trade.InsertAsyncRecord
|
+- Trade.OrdersEntryTbl (table - cross-schema, live table with StatusID=2 closed rows)
     - Written by: Trade order entry flow
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.OrdersEntryTbl | Table | UNION ALL branch 1 - all 19 columns, all archived rows |
| Trade.OrdersEntryTbl | Table | UNION ALL branch 2 - all 19 columns (with 2 column aliases), WHERE StatusID=2 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.SSRS_CS_History_OrdersEntry | Stored Procedure | SSRS report consumer |
| dbo.SSRS_PRE_MARKET_ORDER | Stored Procedure | SSRS report consumer |
| Trade.OrdersEntryChangeLogAdd | Stored Procedure | Change log writer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. Queries benefit from:
- `History.OrdersEntryTbl`: CLUSTERED PK on OrderID, NC on CID
- `Trade.OrdersEntryTbl`: Primary indexes serve the WHERE StatusID=2 filter

### 7.2 Constraints

N/A for View.

---

## 8. Sample Queries

### 8.1 Get all closed entry orders for a specific copier (full history)
```sql
SELECT
    oe.OrderID,
    oe.MirrorID,
    oe.ParentPositionID,
    oe.InstrumentID,
    oe.Amount,
    oe.IsBuy,
    oe.Leverage,
    oe.CloseActionType,
    oe.OpenOccurred,
    oe.ClosedOccurred,
    DATEDIFF(MINUTE, oe.OpenOccurred, oe.ClosedOccurred) AS LifetimeMinutes
FROM History.OrdersEntry oe WITH (NOLOCK)
WHERE oe.CID = 6770872
ORDER BY oe.ClosedOccurred DESC;
```

### 8.2 Entry orders for a specific copy mirror relationship
```sql
SELECT
    oe.OrderID,
    oe.ParentPositionID,
    oe.Amount,
    oe.InitialMirrorAmountInCents / 100.0 AS MirrorAmountDollars,
    oe.CloseActionType,
    oe.OpenOccurred,
    oe.ClosedOccurred
FROM History.OrdersEntry oe WITH (NOLOCK)
WHERE oe.MirrorID = 1839451
ORDER BY oe.OpenOccurred DESC;
```

### 8.3 Count and volume of closed copy entry orders by close action type
```sql
SELECT
    oe.CloseActionType,
    COUNT(*) AS OrderCount,
    SUM(oe.Amount) AS TotalAmount,
    AVG(DATEDIFF(MINUTE, oe.OpenOccurred, oe.ClosedOccurred)) AS AvgLifetimeMinutes
FROM History.OrdersEntry oe WITH (NOLOCK)
GROUP BY oe.CloseActionType
ORDER BY OrderCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for History.OrdersEntry. Business context inherited from History.OrdersEntryTbl documentation.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 2, 5, 7, 8)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 consumers | App Code: 0 repos | Corrections: 0 applied*
*Object: History.OrdersEntry | Type: View | Source: etoro/etoro/History/Views/History.OrdersEntry.sql*
