# Trade.GetHedgeExposure

> Calculates per-instrument net hedge exposure (difference between open position lots and hedge lots) across all hedge servers, excluding demo/level-4 customers.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID + HedgeServerID (composite) |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.GetHedgeExposure provides a **simplified exposure summary** showing the difference between aggregated open position lots and aggregated hedge lots for each instrument and hedge server combination. Unlike GetExposuresForAllHedgeServers (which includes pending requests), this view focuses strictly on the realized position-vs-hedge gap.

This view filters out demo/test customers (PlayerLevelID <> 4 via Customer.Customer join), ensuring only real customer positions contribute to the exposure calculation. This is important because demo accounts create synthetic positions that should not influence real hedge execution decisions.

The view uses FULL OUTER JOIN semantics to capture instruments that have positions but no hedges (underhedged) and instruments that have hedges but no positions (overhedged), with a RIGHT OUTER JOIN to Trade.GetInstrument to ensure all tradeable instruments appear even if they have neither positions nor hedges.

---

## 2. Business Logic

### 2.1 Position-vs-Hedge Difference

**What**: The core metric showing how much unhedged exposure exists per instrument.

**Columns/Parameters Involved**: `Difference`, `Opened`, `Hedged`

**Rules**:
- Opened = SUM(IsBuy ? +1 : -1 * LotCountDecimal) from Trade.Position WHERE PlayerLevelID <> 4
- Hedged = SUM(IsBuy ? +1 : -1 * LotCountDecimal) from Trade.Hedge
- Difference = Opened - Hedged (positive = underhedged long, negative = underhedged short)
- Grouped by ProviderID, InstrumentID, HedgeServerID for positions; by ProviderID, InstrumentID, HedgeServerID for hedges

---

## 3. Data Overview

N/A - aggregation view producing calculated results. See Trade.GetExposuresForAllHedgeServers for similar data with more columns.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | YES | - | CODE-BACKED | Financial instrument. From Trade.GetInstrument (RIGHT JOIN ensures all instruments appear). |
| 2 | HedgeServerID | int | YES | - | CODE-BACKED | Hedge server. Coalesced from positions or hedges. |
| 3 | Difference | decimal | YES | 0 | CODE-BACKED | Computed: Opened - Hedged. Net unhedged exposure in lots. Positive = underhedged long, negative = underhedged short. |
| 4 | Opened | decimal | YES | 0 | CODE-BACKED | Net open position lots (buy - sell). Excludes demo customers (PlayerLevelID <> 4). |
| 5 | Hedged | decimal | YES | 0 | CODE-BACKED | Net hedge lots (buy - sell). From Trade.Hedge. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (positions) | Trade.Position | Subquery | Open position aggregation |
| CID | Customer.Customer | JOIN | Filters out demo customers (PlayerLevelID <> 4) |
| (hedges) | Trade.Hedge | Subquery | Hedge aggregation |
| InstrumentID | Trade.GetInstrument | RIGHT JOIN | Ensures all instruments appear |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetHedgeExposure (view)
+-- Trade.Position (view)
|     +-- Trade.PositionTbl (table)
|     +-- Trade.PositionTreeInfo (table)
+-- Customer.Customer (x-schema table)
+-- Trade.Hedge (table)
+-- Trade.GetInstrument (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | Open position lot aggregation |
| Customer.Customer | Table | Demo customer exclusion (PlayerLevelID <> 4) |
| Trade.Hedge | Table | Hedge lot aggregation |
| Trade.GetInstrument | View | RIGHT JOIN for complete instrument list |

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

### 8.1 Instruments with significant unhedged exposure

```sql
SELECT InstrumentID, HedgeServerID, Opened, Hedged, Difference
FROM   Trade.GetHedgeExposure WITH (NOLOCK)
WHERE  ABS(Difference) > 1
ORDER BY ABS(Difference) DESC;
```

### 8.2 Overhedged instruments

```sql
SELECT InstrumentID, HedgeServerID, Opened, Hedged, Difference
FROM   Trade.GetHedgeExposure WITH (NOLOCK)
WHERE  Difference < 0;
```

### 8.3 All instruments with exposure

```sql
SELECT InstrumentID, HedgeServerID, Opened, Hedged, Difference
FROM   Trade.GetHedgeExposure WITH (NOLOCK)
WHERE  Opened <> 0 OR Hedged <> 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetHedgeExposure | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetHedgeExposure.sql*
