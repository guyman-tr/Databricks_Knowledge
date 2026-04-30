# Trade.GetHedgeExposureDetailedWithActiveParent

> Detailed hedge exposure with buy/sell breakdown, identical to GetHedgeExposureDetailed but additionally filtering out orphaned child positions whose parents no longer exist.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID + HedgeServerID (composite) |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.GetHedgeExposureDetailedWithActiveParent is a variant of Trade.GetHedgeExposureDetailed that adds an **active parent validation filter**. In addition to the IsComputeForHedge=1 filter, it requires that child positions (ParentPositionID > 0) still have their parent position open. If a parent was closed but the child somehow remains, the child is excluded from exposure calculations because it represents a stale/orphaned position that should not influence hedging decisions.

This view exists to provide a more accurate exposure picture for the hedge management system. Orphaned positions skew lot counts and can cause incorrect hedge sizing. By filtering them out, the hedge execution engine gets a cleaner signal.

The implementation mirrors GetHedgeExposureDetailed exactly but adds: LEFT JOIN Trade.Position TP2 ON TP.ParentPositionID = TP2.PositionID with filter: (TP.ParentPositionID = 0 OR TP2.PositionID IS NOT NULL).

---

## 2. Business Logic

### 2.1 Active Parent Validation

**What**: Excludes orphaned child positions from exposure calculation.

**Columns/Parameters Involved**: `ParentPositionID` (from Trade.Position self-join)

**Rules**:
- Position passes if ParentPositionID = 0 (no parent, standalone position)
- OR if the parent position still exists in Trade.Position (TP2.PositionID IS NOT NULL)
- Orphaned positions (ParentPositionID > 0 but parent no longer in Trade.Position) are excluded
- Same buy/sell breakdown and profit columns as GetHedgeExposureDetailed

---

## 3. Data Overview

N/A - aggregation view. Results similar to GetHedgeExposureDetailed but may show slightly different lot counts where orphaned positions existed.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | int | NO | 1 | CODE-BACKED | Hardcoded to 1. Single-provider design. |
| 2 | InstrumentID | int | YES | - | CODE-BACKED | Financial instrument. From Trade.GetInstrument (RIGHT JOIN). |
| 3 | Name | nvarchar | YES | - | CODE-BACKED | Instrument name. From Trade.GetInstrument. |
| 4 | HedgeServerID | int | YES | - | CODE-BACKED | Hedge server. Coalesced from positions or hedges. |
| 5 | Opened | decimal | YES | 0 | CODE-BACKED | Net open position lots (buy - sell). Excludes orphans and non-hedge-eligible. |
| 6 | OpenedBuy | decimal | YES | 0 | CODE-BACKED | Buy-side lot count from hedge-eligible positions with active parents. |
| 7 | OpenedSell | decimal | YES | 0 | CODE-BACKED | Sell-side lot count from hedge-eligible positions with active parents. |
| 8 | Hedged | decimal | YES | 0 | CODE-BACKED | Net hedge lot count. From Trade.Hedge. |
| 9 | Difference | decimal | YES | 0 | CODE-BACKED | Computed: Opened - Hedged. Unhedged exposure in lots (orphan-clean). |
| 10 | NetProfitDifference | decimal | YES | 0 | CODE-BACKED | Computed: HedgeProfit - PosProfit. Currently returns 0 (placeholder). |
| 11 | HedgeProfit | decimal | YES | 0 | CODE-BACKED | Hedge PnL. Currently hardcoded to 1. |
| 12 | PosProfit | decimal | YES | 0 | CODE-BACKED | Position PnL. Currently hardcoded to 1. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (positions) | Trade.Position | Subquery + self-join | Hedge-eligible positions with active parent check |
| (hedges) | Trade.Hedge | Subquery | Active hedge lot aggregation |
| InstrumentID | Trade.GetInstrument | RIGHT JOIN | Instrument names and completeness |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetHedgeExposureDetailedWithActiveParent (view)
+-- Trade.Position (view) [self-join for parent check]
|     +-- Trade.PositionTbl (table)
|     +-- Trade.PositionTreeInfo (table)
+-- Trade.Hedge (table)
+-- Trade.GetInstrument (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | Position lot aggregation with self-join for parent validation |
| Trade.Hedge | Table | Hedge lot aggregation |
| Trade.GetInstrument | View | RIGHT JOIN for instrument names |

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

### 8.1 Compare with standard detailed view

```sql
SELECT d.InstrumentID, d.HedgeServerID,
       d.Opened AS OpenedStandard,
       ap.Opened AS OpenedActiveParent,
       d.Opened - ap.Opened AS OrphanedLots
FROM   Trade.GetHedgeExposureDetailed d WITH (NOLOCK)
       INNER JOIN Trade.GetHedgeExposureDetailedWithActiveParent ap WITH (NOLOCK)
         ON d.InstrumentID = ap.InstrumentID AND d.HedgeServerID = ap.HedgeServerID
WHERE  d.Opened <> ap.Opened;
```

### 8.2 Top exposed instruments (orphan-clean)

```sql
SELECT TOP 10 Name, HedgeServerID, Difference
FROM   Trade.GetHedgeExposureDetailedWithActiveParent WITH (NOLOCK)
ORDER BY ABS(Difference) DESC;
```

### 8.3 Buy/sell breakdown

```sql
SELECT Name, HedgeServerID, OpenedBuy, OpenedSell, Hedged, Difference
FROM   Trade.GetHedgeExposureDetailedWithActiveParent WITH (NOLOCK)
WHERE  OpenedBuy > 0 OR OpenedSell > 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetHedgeExposureDetailedWithActiveParent | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetHedgeExposureDetailedWithActiveParent.sql*
