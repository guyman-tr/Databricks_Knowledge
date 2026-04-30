# Trade.GetPositionsByInstrumentIDAndModDIV

> Returns header positions and aggregated hedge units for a given instrument and partition shard - used by hedge servers to determine net hedge exposure per position tree.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID + @ModDivider + @ModResult - instrument and shard scope |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetPositionsByInstrumentIDAndModDIV` returns "header" (root) positions for a given instrument and partition shard, along with the aggregated AmountInUnitsDecimal across all positions in each tree that are marked `IsComputeForHedge=1`. It is used by hedge servers to determine the net units they need to hedge for each position tree.

**WHY:** eToro's hedging system partitions positions across multiple hedge servers (using PositionID % N = shard). Each hedge server processes its own shard to compute the total units that need external hedging for each copy tree. This SP delivers the tree-root context plus the sum of hedgeable units per tree-RootHedgeServer combination.

**HOW:** CTE `Headers` finds root positions (where `PositionID * @IsReal = TreeID` - in real mode IsReal=1 so PositionID=TreeID, meaning root owns itself) for the instrument and partition. Then joins back to Trade.Position for all positions in each tree, uses a windowed SUM OVER (PARTITION BY TreeID, RootHedgeServerID) to aggregate hedgeable units per tree-server.

**Note on IsReal:** `@IsReal = CASE WHEN CAST(Value AS INT) = 1 THEN 1 ELSE -1 END` from Maintenance.Feature FeatureID=22. In real (1), filter is `PositionID * 1 = TreeID` -> root positions. In demo (-1), filter is `PositionID * -1 = TreeID` -> which would be negative TreeID... this seems like demo mode returns no rows (negative TreeID never matches). The -1 behavior for demo may be intentional (demo doesn't need hedging).

---

## 2. Business Logic

### 2.1 Root Position Detection (Headers CTE)

**What:** Identifies root/parent positions for a given instrument and shard.

**Columns/Parameters Involved:** `@IsReal`, `PositionID`, `TreeID`, `@ModDivider`, `@ModResult`

**Rules:**
- `WHERE (PositionID * @IsReal) = TreeID` - in real mode: PositionID = TreeID (root is its own tree)
- `AND InstrumentID = @InstrumentID`
- `AND PositionID % @ModDivider = @ModResult` - partition shard filter
- @ModDivider = total number of shards; @ModResult = which shard this hedge server handles

### 2.2 Hedgeable Units Aggregation

**What:** Sums units for all positions in each tree that have IsComputeForHedge=1.

**Columns/Parameters Involved:** `IsComputeForHedge`, `AmountInUnitsDecimal`, `TreeID`, `RootHedgeServerID`

**Rules:**
- `SUM(CASE WHEN TPOS.IsComputeForHedge = 1 THEN TPOS.AmountInUnitsDecimal ELSE 0 END) OVER (PARTITION BY TPOS.TreeID, TPOS.RootHedgeServerID) AS AmountInUnitsDecimal`
- Windowed SUM (not GROUP BY) - every row gets the tree total
- IsComputeForHedge=0 positions are excluded from hedge calculation (e.g., settled/real-stock positions)
- Partitioned by both TreeID AND RootHedgeServerID because a tree can span multiple hedge servers

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | Instrument to return hedging data for. |
| 2 | @ModDivider | INT | NO | - | CODE-BACKED | Total number of hedge server shards. |
| 3 | @ModResult | INT | NO | - | CODE-BACKED | Shard index this hedge server handles (0 to @ModDivider-1). |
| 4 | InstrumentID | INT | NO | - | CODE-BACKED | Echo of @InstrumentID. |
| 5 | PositionID | BIGINT | NO | - | CODE-BACKED | Root position ID (header). TreeID=PositionID in real mode. |
| 6 | CID | INT | NO | - | CODE-BACKED | Root position owner (leader CID). |
| 7 | InitDateTime | DATETIME | YES | - | CODE-BACKED | Root position open timestamp. |
| 8 | StopRate | DECIMAL | YES | - | CODE-BACKED | Stop loss rate on root position. |
| 9 | LimitRate | DECIMAL | YES | - | CODE-BACKED | Take profit rate on root position. |
| 10 | IsBuy | BIT | NO | - | CODE-BACKED | Direction of root position. |
| 11 | RootHedgeServerID | INT | YES | - | CODE-BACKED | Hedge server ID for the root position. |
| 12 | TreeID | BIGINT | YES | - | CODE-BACKED | Tree root ID (same as PositionID in real mode). |
| 13 | AmountInUnitsDecimal | DECIMAL | YES | - | CODE-BACKED | Total hedgeable units across all IsComputeForHedge=1 positions in this tree-server partition. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID + modulo | Trade.Position | CTE + JOIN | Root positions (shard) + full tree for unit aggregation |
| FeatureID=22 | Maintenance.Feature | Lookup | IsReal flag for root position detection |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by hedge servers to compute hedge positions per shard.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionsByInstrumentIDAndModDIV (procedure)
|- Trade.Position (view) - open positions
|- Maintenance.Feature (table) - IsReal flag (FeatureID=22)
```

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by hedge servers |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| IsReal = 1 ELSE -1 | Environment routing | Real: roots have PositionID=TreeID; Demo: produces no roots (negative TreeID) |
| PositionID % @ModDivider = @ModResult | Partition routing | Modulo-based hedge server sharding |
| OVER (PARTITION BY TreeID, RootHedgeServerID) | Windowed aggregation | Sum per tree+server, not global |
| DISTINCT on final SELECT | Dedup | Removes duplicate rows from windowed join |

---

## 8. Sample Queries

### 8.1 Get hedging data for shard 3 of 10 for instrument 1001

```sql
EXEC Trade.GetPositionsByInstrumentIDAndModDIV
    @InstrumentID = 1001,
    @ModDivider = 10,
    @ModResult = 3
```

### 8.2 Full scan of instrument (all shards - shard 0 of 1)

```sql
EXEC Trade.GetPositionsByInstrumentIDAndModDIV
    @InstrumentID = 1001,
    @ModDivider = 1,
    @ModResult = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 7.5/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPositionsByInstrumentIDAndModDIV | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPositionsByInstrumentIDAndModDIV.sql*
