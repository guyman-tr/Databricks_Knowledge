# Trade.GetHedgeExposureWithActiveParent

> Simplified hedge exposure (Opened/Hedged/Difference) per instrument per hedge server, excluding demo customers and orphaned child positions whose parents no longer exist.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID + HedgeServerID (composite) |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.GetHedgeExposureWithActiveParent combines the two exposure filters from its sibling views: (1) excludes demo customers (PlayerLevelID <> 4 from GetHedgeExposure) and (2) excludes orphaned child positions (active parent check from GetHedgeExposureDetailedWithActiveParent). It returns only the simplified 5-column format (InstrumentID, HedgeServerID, Difference, Opened, Hedged) without the buy/sell breakdown.

This is the most conservative exposure view - it excludes both demo positions AND orphaned positions, providing the cleanest signal for hedge execution decisions. Use this when you need accurate net exposure without noise from test accounts or stale copy-trade positions.

---

## 2. Business Logic

### 2.1 Combined Exclusion Filters

**What**: Dual-filter exposure: no demo customers, no orphaned positions.

**Columns/Parameters Involved**: `PlayerLevelID`, `ParentPositionID`

**Rules**:
- Excludes positions where Customer.Customer.PlayerLevelID = 4 (demo/test)
- Excludes child positions (ParentPositionID > 0) where parent no longer exists in Trade.Position
- Opened = SUM(IsBuy ? +1 : -1 * LotCountDecimal) from filtered positions
- Hedged = SUM(IsBuy ? +1 : -1 * LotCountDecimal) from Trade.Hedge
- Difference = Opened - Hedged

---

## 3. Data Overview

N/A - aggregation view. Results should be the most conservative (lowest lot counts) among the hedge exposure family.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | YES | - | CODE-BACKED | Financial instrument. From Trade.GetInstrument (RIGHT JOIN). |
| 2 | HedgeServerID | int | YES | - | CODE-BACKED | Hedge server. Coalesced from positions or hedges. |
| 3 | Difference | decimal | YES | 0 | CODE-BACKED | Computed: Opened - Hedged. Net unhedged exposure in lots (cleanest signal). |
| 4 | Opened | decimal | YES | 0 | CODE-BACKED | Net open position lots. Excludes demo customers AND orphaned positions. |
| 5 | Hedged | decimal | YES | 0 | CODE-BACKED | Net hedge lots. From Trade.Hedge. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (positions) | Trade.Position | Subquery + self-join | Filtered positions with active parent and real customer checks |
| CID | Customer.Customer | JOIN | Demo customer exclusion (PlayerLevelID <> 4) |
| (hedges) | Trade.Hedge | Subquery | Active hedge aggregation |
| InstrumentID | Trade.GetInstrument | RIGHT JOIN | Instrument completeness |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetHedgeExposureWithActiveParent (view)
+-- Trade.Position (view) [self-join for parent check]
|     +-- Trade.PositionTbl (table)
|     +-- Trade.PositionTreeInfo (table)
+-- Customer.Customer (x-schema table)
+-- Trade.Hedge (table)
+-- Trade.GetInstrument (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | Position lot aggregation with self-join for parent check |
| Customer.Customer | Table | Demo customer exclusion |
| Trade.Hedge | Table | Hedge lot aggregation |
| Trade.GetInstrument | View | RIGHT JOIN for completeness |

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

### 8.1 All instruments with exposure

```sql
SELECT InstrumentID, HedgeServerID, Opened, Hedged, Difference
FROM   Trade.GetHedgeExposureWithActiveParent WITH (NOLOCK)
WHERE  Opened <> 0 OR Hedged <> 0;
```

### 8.2 Most underhedged instruments

```sql
SELECT TOP 10 InstrumentID, HedgeServerID, Difference
FROM   Trade.GetHedgeExposureWithActiveParent WITH (NOLOCK)
WHERE  Difference > 0
ORDER BY Difference DESC;
```

### 8.3 Compare all exposure views

```sql
SELECT e.InstrumentID, e.HedgeServerID,
       e.Opened AS Opened_All,
       a.Opened AS Opened_ActiveParent
FROM   Trade.GetHedgeExposure e WITH (NOLOCK)
       INNER JOIN Trade.GetHedgeExposureWithActiveParent a WITH (NOLOCK)
         ON e.InstrumentID = a.InstrumentID AND e.HedgeServerID = a.HedgeServerID
WHERE  e.Opened <> a.Opened;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetHedgeExposureWithActiveParent | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetHedgeExposureWithActiveParent.sql*
