# Trade.PositionChange

> UNION ALL view combining position edit history from PositionChangeOld and History.PositionChangeLog for open positions—tracks previous/current values for hedge, amount, SL, TP, overnight fee, and weekend close.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionChangeID |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.PositionChange is a **unified position edit history view** that combines two data sources: the legacy Trade.PositionChangeOld table and the modern History.PositionChangeLog. Both branches are restricted to positions that are still open (via INNER JOIN to Trade.Position), so the view returns only edit-history records for active positions.

The system evolved from a single table (PositionChangeOld) to a partitioned history store (PositionChangeLog). Older edits remain in PositionChangeOld; newer edits are written to History.PositionChangeLog. Trade.PositionChange provides a single query surface for all edit history of open positions, regardless of when the edit occurred. The History branch nullifies PreviousHedgeID, HedgeID, OrderID, and TradeRange because those columns are not tracked in PositionChangeLog.

This view supports audit trails, recovery workflows, and analytics that need the full edit history of a position while it remains open. Once a position is closed and removed from Trade.Position, its PositionChangeLog records remain in History but no longer appear in Trade.PositionChange.

---

## 2. Business Logic

### 2.1 UNION ALL of Legacy and History Sources

**What**: Merges PositionChangeOld and History.PositionChangeLog into one schema, filtered to open positions only.

**Columns/Parameters Involved**: `PositionChangeID`, `PositionID`, `PreviousHedgeID`, `HedgeID`, `OrderID`, `Amount`, `AmountChanged`, `TradeRange`

**Rules**:
- Branch 1 (PositionChangeOld): All columns from TPCO; joins Trade.Position on PositionID.
- Branch 2 (PositionChangeLog): PreviousHedgeID, HedgeID, OrderID = NULL; TradeRange = NULL; Amount sourced from HPCL.AmountChanged (aliased as Amount).
- Both branches require INNER JOIN to Trade.Position so only open positions are returned.

### 2.2 Open-Position Filter

**What**: Restricts results to positions still in Trade.Position (open only).

**Columns/Parameters Involved**: `PositionID`

**Rules**:
- INNER JOIN Trade.Position TPOS ON TPCO.PositionID = TPOS.PositionID (branch 1)
- INNER JOIN Trade.Position TPOS ON HPCL.PositionID = TPOS.PositionID (branch 2)
- Closed positions drop out of Trade.Position, so their change log rows no longer appear in this view.

---

## 3. Data Overview

Each row represents one edit event for an open position. Columns track previous vs. current values for CloseOnEndOfWeek, EndOfWeekFee, Amount, LimitRate, StopRate, hedge IDs, and last-op price/conversion rates. Occurred indicates when the edit occurred.

---

## 4. Elements

| # | Column Name | Data Type | Source | Confidence | Description |
|---|-------------|-----------|--------|------------|-------------|
| 1 | PositionChangeID | int/bigint | TPCO / HPCL | CODE-BACKED | Unique change record ID. |
| 2 | PositionID | bigint | TPCO / HPCL | CODE-BACKED | Position that was edited. FK to Trade.Position. |
| 3 | PreviousHedgeID | bigint | TPCO | CODE-BACKED | Hedge ID before edit; NULL from History branch. |
| 4 | HedgeID | bigint | TPCO | CODE-BACKED | Hedge ID after edit; NULL from History branch. |
| 5 | OrderID | int | TPCO | CODE-BACKED | Order ID associated with edit; NULL from History branch. |
| 6 | PreviousCloseOnEndOfWeek | bit | TPCO / HPCL | CODE-BACKED | Weekend-close flag before edit. |
| 7 | CloseOnEndOfWeek | bit | TPCO / HPCL | CODE-BACKED | Weekend-close flag after edit. |
| 8 | PreviousEndOfWeekFee | money | TPCO / HPCL | CODE-BACKED | End-of-week fee before edit. |
| 9 | EndOfWeekFee | money | TPCO / HPCL | CODE-BACKED | End-of-week fee after edit. |
| 10 | PreviousAmount | money | TPCO / HPCL | CODE-BACKED | Position amount before edit. |
| 11 | Amount | money | TPCO.Amount / HPCL.AmountChanged | CODE-BACKED | Position amount after edit. History branch uses AmountChanged. |
| 12 | PreviousLimitRate | float | TPCO / HPCL | CODE-BACKED | Take-profit rate before edit. |
| 13 | LimitRate | float | TPCO / HPCL | CODE-BACKED | Take-profit rate after edit. |
| 14 | PreviousStopRate | float | TPCO / HPCL | CODE-BACKED | Stop-loss rate before edit. |
| 15 | StopRate | float | TPCO / HPCL | CODE-BACKED | Stop-loss rate after edit. |
| 16 | Occurred | datetime | TPCO / HPCL | CODE-BACKED | When the edit occurred. |
| 17 | TradeRange | float | TPCO | CODE-BACKED | Market range tolerance; NULL from History branch. |
| 18 | ParentPositionID | bigint | TPCO / HPCL | CODE-BACKED | Parent position in hierarchy. |
| 19 | OrigParentPositionID | bigint | TPCO / HPCL | CODE-BACKED | Original parent before splits/merges. |
| 20 | LastOpPriceRate | decimal(16,8) | TPCO / HPCL | CODE-BACKED | Last operation price rate. |
| 21 | LastOpPriceRateID | bigint | TPCO / HPCL | CODE-BACKED | Last op price rate snapshot ID. |
| 22 | LastOpConversionRate | decimal(16,8) | TPCO / HPCL | CODE-BACKED | Last operation conversion rate. |
| 23 | LastOpConversionRateID | bigint | TPCO / HPCL | CODE-BACKED | Last op conversion rate snapshot ID. |
| 24 | MirrorID | int | TPCO / HPCL | CODE-BACKED | Copy-trade mirror ID. 0=manual. |

---

## 5. Relationships

### 5.1 References To

| Object | Relationship |
|--------|--------------|
| Trade.PositionChangeOld | FROM (branch 1) |
| History.PositionChangeLog | FROM (branch 2) |
| Trade.Position | INNER JOIN on PositionID (both branches) |

### 5.2 Referenced By

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionChange (view)
+-- Trade.PositionChangeOld (table) [not documented]
+-- History.PositionChangeLog (view/table) [x-schema]
+-- Trade.Position (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionChangeOld | Table | Legacy edit history (branch 1) |
| History.PositionChangeLog | Table/View | Modern edit history (branch 2) |
| Trade.Position | View | Open-position filter |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Edit history for a specific open position

```sql
SELECT PositionChangeID, PositionID, PreviousStopRate, StopRate, PreviousLimitRate, LimitRate, Occurred
FROM   Trade.PositionChange WITH (NOLOCK)
WHERE  PositionID = 2152077450
ORDER BY Occurred DESC;
```

### 8.2 Recent SL/TP edits across open positions

```sql
SELECT PositionID, PreviousStopRate, StopRate, PreviousLimitRate, LimitRate, Occurred
FROM   Trade.PositionChange WITH (NOLOCK)
WHERE  (PreviousStopRate <> StopRate OR PreviousLimitRate <> LimitRate)
  AND Occurred > DATEADD(hour, -24, GETUTCDATE());
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Quality: 8.0/10*
*Object: Trade.PositionChange | Type: View | Source: etoro/etoro/Trade/Views/Trade.PositionChange.sql*
