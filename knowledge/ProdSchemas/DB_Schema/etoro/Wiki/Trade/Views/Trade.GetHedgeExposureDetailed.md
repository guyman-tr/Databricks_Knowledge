# Trade.GetHedgeExposureDetailed

> Detailed hedge exposure view with buy/sell breakdown and profit comparisons per instrument per hedge server, filtered to positions participating in hedge computation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID + HedgeServerID (composite) |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.GetHedgeExposureDetailed extends the basic hedge exposure view with a **granular buy/sell lot breakdown** and **profit difference tracking** between positions and hedges. While GetHedgeExposure only shows the net difference, this view separates buy-side and sell-side lots, and compares position profit against hedge profit to assess hedging effectiveness.

This view filters positions by IsComputeForHedge = 1, ensuring only hedge-eligible positions contribute. It does NOT filter by PlayerLevelID (unlike GetHedgeExposure), so all customer types are included. The ProviderID is hardcoded to 1, suggesting this was designed for a single-provider environment.

Note: The NetProfit calculations are currently hardcoded to 1 (commented-out Internal.GetNetProfit and GetNetProfitHedge calls), making the profit columns (HedgeProfit, PosProfit, NetProfitDifference) return placeholder values. The lot-based columns (Opened, OpenedBuy, OpenedSell, Hedged, Difference) are fully functional.

---

## 2. Business Logic

### 2.1 Buy/Sell Exposure Breakdown

**What**: Separates open position lots into buy-side and sell-side for directional risk analysis.

**Columns/Parameters Involved**: `Opened`, `OpenedBuy`, `OpenedSell`, `Hedged`, `Difference`

**Rules**:
- OpenedBuy = SUM(IsBuy ? LotCountDecimal : 0) from positions WHERE IsComputeForHedge = 1
- OpenedSell = SUM(IsBuy ? 0 : LotCountDecimal) from positions
- Opened = OpenedBuy - OpenedSell (net exposure in lots)
- Hedged = SUM(IsBuy ? +1 : -1 * LotCountDecimal) from Trade.Hedge
- Difference = Opened - Hedged

### 2.2 Profit Comparison (Placeholder)

**What**: Intended to compare position PnL against hedge PnL to measure hedging cost.

**Columns/Parameters Involved**: `NetProfitDifference`, `HedgeProfit`, `PosProfit`

**Rules**:
- Currently hardcoded: PosProfit = 1, HedgeProfit = 1, NetProfitDifference = 0
- Original intent: HedgeProfit - PosProfit shows whether hedging is profitable

---

## 3. Data Overview

N/A - aggregation view. See Trade.GetExposuresForAllHedgeServers for similar data patterns.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | int | NO | 1 | CODE-BACKED | Hardcoded to 1. Single-provider view design. |
| 2 | InstrumentID | int | YES | - | CODE-BACKED | Financial instrument. From Trade.GetInstrument (RIGHT JOIN). |
| 3 | Name | nvarchar | YES | - | CODE-BACKED | Instrument name. From Trade.GetInstrument. Human-readable label. |
| 4 | HedgeServerID | int | YES | - | CODE-BACKED | Hedge server. Coalesced from positions or hedges. |
| 5 | Opened | decimal | YES | 0 | CODE-BACKED | Net open position lots. OpenedBuy - OpenedSell. From positions WHERE IsComputeForHedge = 1. |
| 6 | OpenedBuy | decimal | YES | 0 | CODE-BACKED | Total buy-side lot count from hedge-eligible open positions. |
| 7 | OpenedSell | decimal | YES | 0 | CODE-BACKED | Total sell-side lot count from hedge-eligible open positions. |
| 8 | Hedged | decimal | YES | 0 | CODE-BACKED | Net hedge lot count. From Trade.Hedge. |
| 9 | Difference | decimal | YES | 0 | CODE-BACKED | Computed: Opened - Hedged. Unhedged exposure in lots. |
| 10 | NetProfitDifference | decimal | YES | 0 | CODE-BACKED | Computed: HedgeProfit - PosProfit. Currently returns 0 (both hardcoded to 1). |
| 11 | HedgeProfit | decimal | YES | 0 | CODE-BACKED | Hedge PnL. Currently hardcoded to 1 (GetNetProfitHedge commented out). |
| 12 | PosProfit | decimal | YES | 0 | CODE-BACKED | Position PnL. Currently hardcoded to 1 (GetNetProfit commented out). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (positions) | Trade.Position | Subquery | Hedge-eligible open positions (IsComputeForHedge=1) |
| (hedges) | Trade.Hedge | Subquery | Active hedge lot aggregation |
| InstrumentID | Trade.GetInstrument | RIGHT JOIN | Instrument name and completeness |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetHedgeExposureDetailed (view)
+-- Trade.Position (view)
|     +-- Trade.PositionTbl (table)
|     +-- Trade.PositionTreeInfo (table)
+-- Trade.Hedge (table)
+-- Trade.GetInstrument (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | Position lot aggregation (IsComputeForHedge=1) |
| Trade.Hedge | Table | Hedge lot aggregation |
| Trade.GetInstrument | View | RIGHT JOIN for instrument names and completeness |

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

### 8.1 Instruments with buy/sell breakdown

```sql
SELECT Name, HedgeServerID, OpenedBuy, OpenedSell, Opened, Hedged, Difference
FROM   Trade.GetHedgeExposureDetailed WITH (NOLOCK)
WHERE  Opened <> 0 OR Hedged <> 0
ORDER BY ABS(Difference) DESC;
```

### 8.2 Most exposed instruments

```sql
SELECT TOP 10 Name, InstrumentID, HedgeServerID, Difference
FROM   Trade.GetHedgeExposureDetailed WITH (NOLOCK)
ORDER BY ABS(Difference) DESC;
```

### 8.3 Directional skew analysis

```sql
SELECT Name, HedgeServerID, OpenedBuy, OpenedSell,
       OpenedBuy - OpenedSell AS NetDirection
FROM   Trade.GetHedgeExposureDetailed WITH (NOLOCK)
WHERE  OpenedBuy > 0 OR OpenedSell > 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetHedgeExposureDetailed | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetHedgeExposureDetailed.sql*
