# Trade.PositionTreeInfo

> Copy-trade tree hierarchy table storing stop-loss, take-profit, trailing stop, and weekend-close settings shared by all positions in a copy-trade tree. One row per TreeID; linked from Trade.PositionTbl via TreeID.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | TreeID (BIGINT), PartitionCol (computed) - composite PK |
| **Partition** | Yes - PS_PositionTreeInfo_BIGINT on PartitionCol = abs(TreeID) % 50 |
| **Indexes** | 2 (PK clustered, IX_RowVersionTree_New NC) |

---

## 1. Business Meaning

Trade.PositionTreeInfo stores the shared risk-management settings (stop-loss, take-profit, trailing stop, weekend close) for a copy-trade tree. Each row corresponds to a TreeID - the root position's PositionID - and applies to every position in that tree (the root and all its copy-trade children). When a leader opens a position with SL/TP, those levels are stored here; when copiers open positions, they share the same TreeID and thus inherit these settings from this table.

This table exists because copy-trade trees can have many positions (hundreds or thousands of copiers) but only one set of SL/TP/TSL levels. Storing these in PositionTbl would duplicate data and make updates expensive when the leader edits stop-loss. By centralizing in PositionTreeInfo, a single UPDATE (e.g., via Trade.PositionEditStopLoss or Trade.UpdateTree) propagates to all positions that JOIN on TreeID.

Data flows: `Trade.PositionOpen` INSERTs a new row when opening a root position (TreeID = PositionID) if one does not exist. For copy-trade children, TreeID points to the root's PositionID - the row already exists. `Trade.PositionEditStopLoss`, `Trade.UpdateTree`, `Trade.PositionEditIsTSLEnabled` UPDATE this table. `Trade.DemoUpdateTreeOnDetachment` and `Trade.DetachFromParentPosition` INSERT new rows when a copier detaches (new TreeID for the detached subtree). `Trade.DeleteClosedTrees` removes orphaned trees. All position views (GetPositionData, GetOpenPositionData, BslView) JOIN here to resolve StopRate, LimitRate, IsTslEnabled for display and close logic.

---

## 2. Business Logic

### 2.1 TreeID and Partitioning

**What**: TreeID equals the root position's PositionID. PartitionCol enables efficient partitioning.

**Columns/Parameters Involved**: `TreeID`, `PartitionCol`

**Rules**:
- TreeID: Root position has TreeID = PositionID. Children share the root's TreeID. Demo: negative TreeID (IsReal = -1).
- PartitionCol: Computed as abs(TreeID) % 50. Joins must use `TPOS.TreeID = TPTI.TreeID AND abs(TPOS.TreeID)%50 = TPTI.PartitionCol` for partition elimination.
- One row per TreeID. Many positions (root + children) share the same row.

### 2.2 Stop-Loss and Take-Profit

**What**: StopRate and LimitRate define automatic close levels. IsNoStopLoss and IsNoTakeProfit override.

**Columns/Parameters Involved**: `StopRate`, `LimitRate`, `IsNoStopLoss`, `IsNoTakeProfit`, `SLManualVer`, `SLManualVerTimestamp`

**Rules**:
- StopRate: Price at which position closes to limit loss. For buy: when market falls to StopRate. For sell: when market rises to StopRate.
- LimitRate: Take-profit price. For buy: when market rises to LimitRate. For sell: when market falls to LimitRate.
- IsNoStopLoss = 1: Position has no stop-loss (e.g., certain instruments like Bitcoin). IsNoTakeProfit = 1: No take-profit.
- SLManualVer: Version counter for manual SL edits. SLManualVerTimestamp: When last manually edited. Used for conflict detection.

### 2.3 Trailing Stop-Loss and Next Threshold

**What**: IsTslEnabled enables trailing stop. NextThresHold stores the trailing level.

**Columns/Parameters Involved**: `IsTslEnabled`, `NextThresHold`

**Rules**:
- IsTslEnabled: 1 = trailing stop active (stop follows favorable price), 0 = fixed stop. Default 0 (DF_TradePositionTreeInfo_IsTslEnabled).
- NextThresHold: For TSL, the current trailing stop level. Updated as price moves favorably. PositionOpen receives @InitSLNextThresHold and inserts it.

### 2.4 Weekend and Discount

**What**: CloseOnEndOfWeek and IsDiscounted control weekend behavior and fee tier.

**Columns/Parameters Involved**: `CloseOnEndOfWeek`, `IsDiscounted`

**Rules**:
- CloseOnEndOfWeek: 1 = position closes before weekend (avoid overnight fees), 0 = stays open. ClaimEndOfWeekFee and weekend logic use this.
- IsDiscounted: 1 = discounted spread/fee tier applies for this tree, 0 = standard. From Mirror or customer at open.

---

## 3. Data Overview

| TreeID | StopRate | LimitRate | CloseOnEndOfWeek | IsTslEnabled | IsDiscounted | IsNoStopLoss | IsNoTakeProfit | Meaning |
|---|---|---|---|---|---|---|---|---|
| -2150231000 | 2.353 | 26.038 | 0 | 0 | 0 | NULL | NULL | Demo tree (negative). Fixed SL/TP. Stays open over weekend. |
| -2150220550 | 17.176 | 205.777 | 0 | 0 | 1 | NULL | NULL | Demo tree with discounted fee. |
| 0 | 0.0001 | 36.2843 | 0 | 0 | 0 | 1 | 0 | System/placeholder. IsNoStopLoss=1, no take-profit. |
| 119771000 | 5608.94 | 5388.98 | 0 | 0 | 0 | NULL | NULL | Real tree. Stop below limit (sell position). |
| 119771450 | 1.6574 | 1.7574 | 0 | 0 | 0 | NULL | NULL | Real tree. Stop below limit (sell). |

**Selection criteria**: Mix of demo (negative TreeID), placeholder (0), and real trees. Table holds ~4.4M rows (one per unique TreeID). Each row is shared by 1 to thousands of positions.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TreeID | bigint | NO | - | CODE-BACKED | Primary key. Equals root position's PositionID. Links to Trade.PositionTbl.TreeID. Children share root's TreeID. Demo: negative. |
| 2 | StopRate | dbo.dtPrice | NO | - | CODE-BACKED | Stop-loss trigger price. Position closes when market hits this rate. Updated by PositionEditStopLoss, UpdateTree. |
| 3 | LimitRate | dbo.dtPrice | NO | - | CODE-BACKED | Take-profit trigger price. Position closes when market hits this rate. |
| 4 | CloseOnEndOfWeek | bit | NO | - | CODE-BACKED | 1 = close before weekend, 0 = stay open. ClaimEndOfWeekFee and weekend logic use this. |
| 5 | IsTslEnabled | tinyint | NO | 0 | CODE-BACKED | 1 = trailing stop-loss active, 0 = fixed. DF_TradePositionTreeInfo_IsTslEnabled. PositionEditIsTSLEnabled updates. |
| 6 | SLManualVer | smallint | NO | 1 | CODE-BACKED | Version counter for manual SL edits. Incremented on edit. DF_TradePositionTreeInfo_SLManualVer. |
| 7 | SLManualVerTimestamp | datetime | YES | - | CODE-BACKED | When stop-loss was last manually edited. PositionEditStopLoss, PositionEditIsTSLEnabled set this. |
| 8 | NextThresHold | dbo.dtPrice | YES | - | CODE-BACKED | For TSL: current trailing stop level. Updated as price moves. PositionOpen inserts @InitSLNextThresHold. |
| 9 | IsDiscounted | bit | NO | 0 | CODE-BACKED | 1 = discounted spread/fee for this tree, 0 = standard. DF_PositionTreeInfo_IsDiscounted. |
| 10 | PartitionCol | computed | NO | abs(TreeID)%50 | CODE-BACKED | Partition key. PERSISTED. PS_PositionTreeInfo_BIGINT. Joins use abs(TPOS.TreeID)%50 = TPTI.PartitionCol. |
| 11 | RowVersionTree | timestamp | NO | - | CODE-BACKED | Row version for change tracking. Index IX_RowVersionTree_New for incremental sync. |
| 12 | IsNoStopLoss | bit | YES | - | CODE-BACKED | 1 = no stop-loss (e.g., Bitcoin). NULL = standard SL applies. Set from order at open. |
| 13 | IsNoTakeProfit | bit | YES | - | CODE-BACKED | 1 = no take-profit. NULL = standard TP applies. Set from order at open. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This table has no outgoing references. TreeID is a logical link to Trade.PositionTbl.TreeID - positions reference this table, not the reverse.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionTbl | TreeID | Implicit | Positions JOIN on TreeID to get SL/TP/TSL. One PositionTreeInfo row per TreeID. |
| Trade.PositionOpen | INSERT | Writer | Creates row for root (TreeID=PositionID) if not exists. Duplicate-key catch for demo. |
| Trade.PositionEditStopLoss | UPDATE | Modifier | Updates StopRate, SLManualVer, SLManualVerTimestamp. |
| Trade.UpdateTree | UPDATE | Modifier | Updates StopRate, LimitRate, NextThresHold on corporate actions. |
| Trade.PositionEditIsTSLEnabled | UPDATE | Modifier | Updates IsTslEnabled, SLManualVerTimestamp. |
| Trade.DemoUpdateTreeOnDetachment | INSERT | Writer | New row for detached subtree. |
| Trade.DetachFromParentPosition | INSERT | Writer | New row for detached positions. |
| Trade.DetachPositionsFromMirror | INSERT | Writer | New row with StopRate, LimitRate, CloseOnEndOfWeek, etc. |
| Trade.GetPositionData | INNER JOIN | Reader | Resolves StopRate, LimitRate, IsTslEnabled for position view. |
| Trade.GetOpenPositionData | INNER JOIN | Reader | Same. |
| Trade.Position | INNER JOIN | Reader | Legacy view. |
| Trade.PositionClose | INNER JOIN | Reader | Reads StopRate, LimitRate for close logic. |
| Trade.GetPositionsForFeeProcess | JOIN | Reader | Fee and EOW logic. |
| Trade.ClaimEndOfWeekFee | JOIN | Reader | CloseOnEndOfWeek for weekend fee. |
| Trade.DeleteClosedTrees | FROM | Deleter | Removes orphaned trees. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionTreeInfo (table)
```

Tables are leaf nodes. No code-level dependencies.

### 6.1 Objects This Depends On

No explicit FK targets. TreeID conceptually links to Trade.PositionTbl.TreeID.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | TreeID column; positions JOIN to this table |
| Trade.PositionOpen | Procedure | INSERT |
| Trade.PositionEditStopLoss | Procedure | UPDATE |
| Trade.UpdateTree | Procedure | UPDATE |
| Trade.PositionEditIsTSLEnabled | Procedure | UPDATE |
| Trade.DemoUpdateTreeOnDetachment | Procedure | INSERT |
| Trade.DetachFromParentPosition | Procedure | INSERT |
| Trade.DetachPositionsFromMirror | Procedure | INSERT |
| Trade.GetPositionData | View | INNER JOIN |
| Trade.GetOpenPositionData | View | INNER JOIN |
| Trade.Position | View | INNER JOIN |
| Trade.PositionClose | Procedure | INNER JOIN |
| Trade.GetPositionsForFeeProcess | Procedure | JOIN |
| Trade.ClaimEndOfWeekFee | Procedure | JOIN |
| Trade.DeleteClosedTrees | Procedure | FROM/DELETE |
| 30+ other procedures/views | - | Reader/Writer |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TradePositionTreeInfo | CLUSTERED | TreeID, PartitionCol | - | - | Active |
| IX_RowVersionTree_New | NC | RowVersionTree | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TradePositionTreeInfo | PK | TreeID, PartitionCol. Clustered on partition. |
| DF_TradePositionTreeInfo_IsTslEnabled | DEFAULT | IsTslEnabled = 0 |
| DF_TradePositionTreeInfo_SLManualVer | DEFAULT | SLManualVer = 1 |
| DF_PositionTreeInfo_IsDiscounted | DEFAULT | IsDiscounted = 0 |

---

## 8. Sample Queries

### 8.1 Get tree settings with position count per tree
```sql
SELECT pti.TreeID, pti.StopRate, pti.LimitRate, pti.IsTslEnabled, pti.CloseOnEndOfWeek,
       COUNT(p.PositionID) AS PositionCount
FROM   Trade.PositionTreeInfo pti WITH (NOLOCK)
       INNER JOIN Trade.PositionTbl p WITH (NOLOCK)
           ON p.TreeID = pti.TreeID AND ABS(p.TreeID % 50) = pti.PartitionCol
WHERE  p.StatusID = 1
GROUP BY pti.TreeID, pti.StopRate, pti.LimitRate, pti.IsTslEnabled, pti.CloseOnEndOfWeek
ORDER BY PositionCount DESC;
```

### 8.2 Trees with trailing stop enabled
```sql
SELECT pti.TreeID, pti.StopRate, pti.LimitRate, pti.NextThresHold,
       pti.SLManualVer, pti.SLManualVerTimestamp
FROM   Trade.PositionTreeInfo pti WITH (NOLOCK)
WHERE  pti.IsTslEnabled = 1
ORDER BY pti.TreeID;
```

### 8.3 Resolve tree to root position and instrument
```sql
SELECT pti.TreeID, pti.StopRate, pti.LimitRate, p.CID AS RootCID, p.InstrumentID,
       p.Amount, p.IsBuy, p.InitDateTime
FROM   Trade.PositionTreeInfo pti WITH (NOLOCK)
       INNER JOIN Trade.PositionTbl p WITH (NOLOCK)
           ON p.PositionID = pti.TreeID AND ABS(p.TreeID) % 50 = pti.PartitionCol
WHERE  p.StatusID = 1
       AND p.ParentPositionID IN (0, 1)
ORDER BY pti.TreeID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 15+ analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PositionTreeInfo | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.PositionTreeInfo.sql*
