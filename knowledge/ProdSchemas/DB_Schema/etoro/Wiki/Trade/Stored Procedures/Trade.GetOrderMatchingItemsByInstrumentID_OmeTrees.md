# Trade.GetOrderMatchingItemsByInstrumentID_OmeTrees

> Returns position tree data (copy-trade trees with aggregated hedge amounts) for open positions across a batch of instruments - provides the OME with trailing stop-loss and position tree context for SL/TP management.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @instrumentsTable (Trade.InstrumentIDsTbl TVP) |
| **Partition** | N/A |
| **Indexes** | Creates #PositionHeaders with NONCLUSTERED INDEX IX on (TreeID, RootHedgeServerID) |

---

## 1. Business Meaning

**WHAT:** `GetOrderMatchingItemsByInstrumentID_OmeTrees` returns position tree data for open positions in the given instrument set. A "tree" is a copy-trade group: a leader's position plus all copiers' positions sharing the same SL/TP rules. The SP identifies the "tree head" position (the one whose PositionID equals the TreeID - the root of the copy group) and aggregates the total hedge-eligible units across the tree per hedge server partition.

**WHY:** The OME uses this for trailing stop-loss (TSL) management: it needs to know each position tree's current state (stop rate, limit rate, TSL threshold, version) and the total hedgeable amount. This drives the OME's automatic SL adjustment logic when prices move favorably.

**HOW:**
1. Read Maintenance.Feature FeatureID=22: when enabled (value=1), @IsReal=1 (TreeID = PositionID for head position); when disabled, @IsReal=-1 (TreeID = -PositionID for head - legacy negative tree ID convention).
2. Load #PositionHeaders by joining PositionTreeInfo + PositionTbl + CustomerStatic + instrument TVP. Filter: `(PositionID * @IsReal) = TreeID AND StatusID=1` - selects only the "head" position of each tree.
3. Add NONCLUSTERED INDEX on (TreeID, RootHedgeServerID) to #PositionHeaders.
4. Final SELECT: DISTINCT from #PositionHeaders joined with Trade.Position (the view), computing `AmountInUnitsDecimal` as the windowed SUM of units where IsComputeForHedge=1, partitioned by (TreeID, RootHedgeServerID).

WITH RECOMPILE is specified - prevents plan caching for this parameter-sensitive query.

---

## 2. Business Logic

### 2.1 Feature Flag Gated Tree ID Convention (@IsReal Multiplier)

**What:** The relationship between PositionID and TreeID changed with Feature 22. Before: TreeID = -PositionID (negative). After: TreeID = PositionID (positive). @IsReal (-1 or 1) adapts the filter to work in both modes.

**Columns/Parameters Involved:** `TreeID`, `PositionID`, `@IsReal` (derived from Maintenance.Feature FeatureID=22)

**Rules:**
- Feature 22 enabled (value=1): `@IsReal=1` -> `WHERE (PositionID * 1) = TreeID` -> TreeID = PositionID
- Feature 22 disabled (value!=1): `@IsReal=-1` -> `WHERE (PositionID * -1) = TreeID` -> TreeID = -PositionID (negative)
- This selects the "tree head" position - the position that anchors the copy-trade group
- Only StatusID=1 (open) positions qualify as tree heads

### 2.2 Aggregated Hedge Amount per Tree-Server Partition

**What:** The final SELECT computes the total amount of units eligible for hedging, aggregated across all positions in the tree on the same hedge server.

**Columns/Parameters Involved:** `AmountInUnitsDecimal`, `IsComputeForHedge`, `TreeID`, `RootHedgeServerID`

**Rules:**
- `SUM(CASE WHEN TPOS.IsComputeForHedge = 1 THEN TPOS.AmountInUnitsDecimal ELSE 0 END) OVER (PARTITION BY TPOS.TreeID, TPOS.RootHedgeServerID) AS AmountInUnitsDecimal`
- Only positions with `IsComputeForHedge=1` contribute to the hedge amount
- Partitioned by (TreeID, RootHedgeServerID): each tree may span multiple hedge servers
- The DISTINCT in the outer SELECT ensures one row per (PositionID, TreeID) pair

### 2.3 Customer Country for Regional Rules

**What:** `Customer.CustomerStatic.CountryID` is included to allow the OME to apply country-specific SL/TP rules.

**Columns/Parameters Involved:** `CountryID`

**Rules:**
- `INNER JOIN Customer.CustomerStatic Cus ON Cus.CID = TPOS.CID`
- CountryID enables the OME to apply regulatory constraints (e.g., leverage limits, minimum SL distances) per customer jurisdiction

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @instrumentsTable | Trade.InstrumentIDsTbl | NO | - | CODE-BACKED | Table-valued parameter with InstrumentID INT. Returns position tree data for open positions in these instruments. |

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument ID of the position. From the input TVP via position join. |
| 2 | PositionID | BIGINT | NO | - | CODE-BACKED | Position ID of the tree head. (PositionID * @IsReal) = TreeID selects the head. |
| 3 | CID | INT | NO | - | CODE-BACKED | Customer ID of the tree head position owner. |
| 4 | InitDateTime | DATETIME | YES | - | CODE-BACKED | Open timestamp of the head position. |
| 5 | StopRate | DECIMAL | YES | - | CODE-BACKED | Current stop-loss rate for this position. From Trade.PositionTbl. |
| 6 | LimitRate | DECIMAL | YES | - | CODE-BACKED | Current take-profit rate for this position. From Trade.PositionTbl. |
| 7 | IsBuy | BIT | NO | - | CODE-BACKED | Direction of the position: 1=Buy/Long, 0=Sell/Short. |
| 8 | RootHedgeServerID | INT | YES | - | CODE-BACKED | Root hedge server ID for this position's tree partition. |
| 9 | TreeID | BIGINT | NO | - | CODE-BACKED | Copy-trade tree ID. Equals PositionID (or -PositionID in legacy mode). All positions in the copy group share this TreeID. |
| 10 | IsTslEnabled | BIT | YES | - | CODE-BACKED | Aliased as 'IsTslEnabled'. 1 if Trailing Stop Loss is active for this tree. From Trade.PositionTreeInfo. |
| 11 | StopLossVersion | INT | YES | - | CODE-BACKED | Aliased from SLManualVer. Version counter for manual stop-loss updates; incremented each time SL is manually changed. Used by OME to detect concurrent modifications. |
| 12 | TrailingStopLossThreshold | DECIMAL | YES | - | CODE-BACKED | Aliased from NextThresHold. The next price threshold that triggers a TSL adjustment. |
| 13 | StopLossVersionTimestamp | DATETIME | YES | - | CODE-BACKED | Aliased from SLManualVerTimestamp. Timestamp of the last manual SL version change. |
| 14 | AmountInUnitsDecimal | DECIMAL | YES | - | CODE-BACKED | Windowed SUM of AmountInUnitsDecimal for positions where IsComputeForHedge=1, partitioned by (TreeID, RootHedgeServerID). Represents total hedgeable units for this tree-server combination. |
| 15 | Leverage | INT | YES | - | CODE-BACKED | Leverage of the head position. |
| 16 | IsNoStopLoss | BIT | YES | - | CODE-BACKED | 1 if this tree has no stop-loss protection. From Trade.PositionTreeInfo. |
| 17 | IsNoTakeProfit | BIT | YES | - | CODE-BACKED | 1 if this tree has no take-profit level. From Trade.PositionTreeInfo. |
| 18 | IsSettled | BIT | YES | - | CODE-BACKED | Legacy settlement flag: 1=Real stock position, 0=CFD. From Trade.PositionTbl. |
| 19 | CountryID | INT | YES | - | CODE-BACKED | Customer's country ID for regional regulatory rule application. From Customer.CustomerStatic. |
| 20 | OrderID | INT | YES | - | CODE-BACKED | Order ID that opened this position. From Trade.PositionTbl. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @instrumentsTable | Trade.InstrumentIDsTbl | TVP Type | Input batch of instrument IDs |
| treeInfo.TreeID = TPOS.TreeID | Trade.PositionTreeInfo | JOIN | Copy-trade tree SL/TP/TSL configuration |
| INNER JOIN | Trade.PositionTbl | JOIN | Open positions (StatusID=1 implied, tree head filter) |
| INNER JOIN | Customer.CustomerStatic | JOIN | Customer country for regional rules |
| INNER JOIN Trade.Position | Trade.Position | VIEW JOIN | Aggregated position data for hedge amount computation |
| Feature FeatureID=22 | Maintenance.Feature | Lookup | Feature flag for tree ID convention (@IsReal) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrderMatchingItemsByInstrumentID_OmeTrees (procedure)
|- Trade.InstrumentIDsTbl (user defined type) - TVP for instrument batch
|- Trade.PositionTreeInfo (table) - tree SL/TP/TSL config
|- Trade.PositionTbl (table) - open positions
|- Customer.CustomerStatic (table) - customer country
|- Trade.Position (view) - aggregated position data for hedge calculation
|- Maintenance.Feature (table) - FeatureID=22 for tree ID convention
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentIDsTbl | User Defined Type | TVP type for input |
| Trade.PositionTreeInfo | Table | Tree SL/TP/TSL configuration (IsTslEnabled, StopRate, LimitRate, etc.) |
| Trade.PositionTbl | Table | Open positions; tree head filter via (PositionID * @IsReal) = TreeID |
| Customer.CustomerStatic | Table | Country ID for regional rules |
| Trade.Position | View | Windowed hedge amount aggregation (IsComputeForHedge, AmountInUnitsDecimal) |
| Maintenance.Feature | Table | FeatureID=22 determines @IsReal multiplier for tree head identification |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by OME application for TSL management |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. (Temp table #PositionHeaders has NONCLUSTERED INDEX IX on (TreeID, RootHedgeServerID) to optimize the final JOIN with Trade.Position)

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH RECOMPILE | Query hint | Forces plan recompilation each execution - prevents suboptimal cached plans for different instrument sets |
| (PositionID * @IsReal) = TreeID | Filter | Selects only tree head positions; adapts to positive/negative TreeID convention via feature flag |
| StatusID = 1 | Implied | Only open positions qualify as tree heads |

---

## 8. Sample Queries

### 8.1 Execute for specific instruments

```sql
DECLARE @instruments Trade.InstrumentIDsTbl
INSERT INTO @instruments VALUES (1), (2)

EXEC Trade.GetOrderMatchingItemsByInstrumentID_OmeTrees
    @instrumentsTable = @instruments
```

### 8.2 Check current tree head positions for an instrument

```sql
DECLARE @IsReal INT
SELECT @IsReal = CASE WHEN CAST(Value AS INT) = 1 THEN 1 ELSE -1 END
FROM Maintenance.Feature WITH (NOLOCK) WHERE FeatureID = 22

SELECT TOP 10
    TPOS.PositionID, TPOS.TreeID, TPOS.CID, TPOS.InstrumentID,
    treeInfo.IsTslEnabled, treeInfo.NextThresHold
FROM Trade.PositionTreeInfo treeInfo WITH (NOLOCK)
INNER JOIN Trade.PositionTbl TPOS WITH (NOLOCK) ON treeInfo.TreeID = TPOS.TreeID
WHERE (TPOS.PositionID * @IsReal) = treeInfo.TreeID
AND TPOS.StatusID = 1 AND TPOS.InstrumentID = 1
```

### 8.3 Check feature 22 (tree ID convention)

```sql
SELECT FeatureID, Value, Description
FROM Maintenance.Feature WITH (NOLOCK)
WHERE FeatureID = 22
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9.5/10, Logic: 8.0/10, Relationships: 7.5/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrderMatchingItemsByInstrumentID_OmeTrees | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrderMatchingItemsByInstrumentID_OmeTrees.sql*
