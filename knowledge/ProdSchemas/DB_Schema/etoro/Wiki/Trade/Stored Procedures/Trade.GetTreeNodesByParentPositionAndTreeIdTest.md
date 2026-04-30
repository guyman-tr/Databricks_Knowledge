# Trade.GetTreeNodesByParentPositionAndTreeIdTest

> Performance-optimized variant of Trade.GetTreeNodesByParentPositionAndTreeId - uses a pre-materialized temp table for pending close detection and INNER JOIN for active mirror lookup, eliminating per-row OUTER APPLY overhead.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ParentPositionID + @TreeID - root position and tree identifier |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetTreeNodesByParentPositionAndTreeIdTest` is the performance-optimized counterpart to `Trade.GetTreeNodesByParentPositionAndTreeId`. It is identical in signature, output shape, and business semantics - both retrieve the full set of positions in a copy-trading tree by TreeID for close pre-execution - but applies three targeted SQL optimizations to reduce query cost on large trees.

The "Test" suffix is a historical naming artifact (the procedure was introduced as a test of the optimized approach); it is not exclusively a test/debug procedure. The optimizations are:
1. **#PendingOrders temp table** (with unique clustered index): pending close checks are batched into a single pre-scan with a temp table join, replacing the per-row OUTER APPLY that was used in the original.
2. **INNER JOIN for Trade.Mirror** in Pass 1 (instead of LEFT JOIN + filter): since only rows with `IsActive=1` are needed, an INNER JOIN eliminates rows earlier and allows IsMirrorActive to be hardcoded to 1.
3. **NOT EXISTS instead of NOT IN** for Pass 2 duplicate check: avoids the NULL-handling ambiguity and can produce better plans than `NOT IN @TVP`.

The procedure is intended to replace the original once the performance characteristics are validated in production. Until then, both coexist with identical interfaces.

---

## 2. Business Logic

### 2.1 Optimization 1: Pre-Materialized Pending Close Table

**What**: Pending close detection is pre-computed once into `#PendingOrders` instead of evaluated per row via OUTER APPLY.

**Rules**:
- Creates `#PendingOrders (PositionID BIGINT, OrderID BIGINT)` with a UNIQUE CLUSTERED INDEX on (PositionID, OrderID)
- Populated from `Trade.CloseExecutionPlan INNER JOIN Trade.OrderForClose INNER JOIN Dictionary.OrderForExecutionStatus` where `TCEP.OrderID <> @OrderID AND DOFE.IsTerminal = 0`
- Both Pass 1 and Pass 2 join to `#PendingOrders` via LEFT JOIN and filter `PO.PositionID IS NULL` (no pending order exists)
- Temp table is dropped before the final SELECT
- This changes the execution pattern from N OUTER APPLY sub-queries to 1 pre-scan + 2 indexed lookups

### 2.2 Optimization 2: INNER JOIN for Active Mirror (Pass 1)

**What**: Pass 1 uses INNER JOIN instead of LEFT JOIN with filter, and hardcodes IsMirrorActive = 1.

**Rules**:
- Original used `LEFT JOIN Trade.Mirror ... ON TP.MirrorID = TM.MirrorID` then filtered `TM.IsActive = 1`
- Optimized uses `INNER JOIN Trade.Mirror ... ON TP.MirrorID = TM.MirrorID AND TM.IsActive = 1`
- Because the join condition guarantees IsActive=1, IsMirrorActive is hardcoded as literal `1` (not `ISNULL(TM.IsActive, 0)`)
- Pass 2 still uses LEFT JOIN (root position may have no active mirror) and retains `ISNULL(TM.IsActive, 0)`

### 2.3 Optimization 3: NOT EXISTS Instead of NOT IN (Pass 2)

**What**: Pass 2 duplicate check uses NOT EXISTS instead of NOT IN @Position.

**Rules**:
- Original: `AND PositionID NOT IN @Position` (TVP scan)
- Optimized: `AND NOT EXISTS (SELECT 1 FROM @Position P WHERE P.PositionID = TP.PositionID)`
- NOT EXISTS with a correlated subquery on a memory-optimized table variable can produce better plans; also avoids the edge case where NOT IN returns no rows if the subquery contains NULLs

### 2.4 Two-Pass Population Strategy (Same as Production)

**What**: Identical two-pass logic as the production SP - see Trade.GetTreeNodesByParentPositionAndTreeId Section 2.2.

**Rules**: Same partition filters, same sentinel (ParentPositionID = -1 for root), same StatusID=1 check in Pass 2.

### 2.5 Demo Mode Mock Row (Same as Production)

**What**: Identical demo row UNION ALL as the production SP.

**Rules**: When `@IsRealDB = 0`, UNION ALL adds a mock row with CID=0, all numeric fields=0. Never returned in production.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ParentPositionID | BIGINT | NO | - | CODE-BACKED | PositionID of the root position for this close operation. Same semantics as production SP. Used as PartitionCol key for Pass 2. |
| 2 | @TreeID | BIGINT | NO | - | CODE-BACKED | TreeID of the copy-trading tree to retrieve. All positions where `Trade.Position.TreeID = @TreeID` are candidates. |
| 3 | @OrderID | BIGINT | NO | 0 | CODE-BACKED | Current order being processed. Positions with a non-terminal close order for any OrderID != @OrderID are pre-excluded into #PendingOrders. |

**Output columns (from Trade.GetTreeNodesByParentPositionAndTreeId_MOT type - identical to production SP):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | Level | INT | YES | NULL | CODE-BACKED | Hierarchy level - populated as NULL by this SP; computed by caller. |
| 5 | CID | INT | NO | - | CODE-BACKED | Customer ID of the position owner. |
| 6 | PositionID | BIGINT | NO | - | CODE-BACKED | Position ID of this tree node. |
| 7 | MirrorID | INT | YES | - | CODE-BACKED | Mirror relationship ID. 0 for non-copy positions. FK to Trade.Mirror. |
| 8 | ParentPositionID | BIGINT | NO | - | CODE-BACKED | Parent position ID. Set to -1 when PositionID = @ParentPositionID (root sentinel). |
| 9 | Units | DECIMAL | NO | - | CODE-BACKED | Current position size in units (Trade.Position.AmountInUnitsDecimal). |
| 10 | Amount | MONEY | NO | - | CODE-BACKED | Position investment amount in account currency. |
| 11 | IsSettled | BIT/TINYINT | NO | - | CODE-BACKED | 1 = real stock (actual ownership), 0 = CFD. Legacy settlement flag. |
| 12 | IsComputeForHedge | BIT | YES | - | CODE-BACKED | 1 = include in hedge exposure; 0 = exclude. From Trade.Position.IsComputeForHedge. |
| 13 | RootHedgeServerID | INT | YES | - | CODE-BACKED | Hedge server ID for the copy tree root. FK to Trade.HedgeServer. |
| 14 | HedgeServerID | INT | YES | - | CODE-BACKED | Hedge server ID for this position node. FK to Trade.HedgeServer. |
| 15 | TreeID | BIGINT | NO | - | CODE-BACKED | Copy tree identifier. Same value as @TreeID for all rows. |
| 16 | IsMirrorActive | BIT | NO | - | CODE-BACKED | Pass 1 rows: hardcoded to 1 (INNER JOIN guarantees active mirror). Pass 2 row: ISNULL(TM.IsActive, 0). |
| 17 | IsFundCopy | BIT | NO | - | CODE-BACKED | 1 = Fund Copy (MirrorTypeID=4); 0 = regular CopyTrader. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Position table var | Trade.GetTreeNodesByParentPositionAndTreeId_MOT | UDT | Memory-optimized table type for two-pass accumulation |
| #PendingOrders | Trade.CloseExecutionPlan | FROM | Pre-scan source for pending close detection |
| #PendingOrders | Trade.OrderForClose | INNER JOIN | Order status for pending close check |
| #PendingOrders | Dictionary.OrderForExecutionStatus | INNER JOIN | IsTerminal=0 means active/pending order |
| Pass 1 source | Trade.Position | FROM | View of open positions - queried by TreeID partition |
| Pass 1 JOIN | Trade.Mirror | INNER JOIN | Active mirror check (IsActive=1 in join condition) |
| Pass 1 filter | #PendingOrders | LEFT JOIN | Exclude positions with pending close (PO.PositionID IS NULL) |
| Pass 2 source | Trade.PositionTbl | FROM | Base table for root position lookup |
| Pass 2 filter | #PendingOrders | LEFT JOIN | Same pending close exclusion |
| IsRealDB | Maintenance.Feature | SELECT | FeatureID=22 determines demo vs. production |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (close execution engine) | @ParentPositionID, @TreeID | EXEC caller | Potential replacement for production SP once validated |
| Trade.GetTreeNodesByParentPositionAndTreeId | - | Sibling | Production SP with identical interface, different implementation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetTreeNodesByParentPositionAndTreeIdTest (procedure)
+-- Trade.GetTreeNodesByParentPositionAndTreeId_MOT (UDT - table variable type)
+-- Trade.Position (view)
|     +-- Trade.PositionTbl (table)
|     +-- Trade.PositionTreeInfo (table)
+-- Trade.PositionTbl (table) [Pass 2 direct query]
+-- Trade.Mirror (table)
+-- Trade.CloseExecutionPlan (table) [#PendingOrders pre-scan]
+-- Trade.OrderForClose (table)
+-- Dictionary.OrderForExecutionStatus (table)
+-- Maintenance.Feature (table) [IsRealDB]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetTreeNodesByParentPositionAndTreeId_MOT | User Defined Type | Table variable for result accumulation |
| Trade.Position | View | Pass 1: get tree positions by TreeID |
| Trade.PositionTbl | Table | Pass 2: get root position by PositionID/PartitionCol |
| Trade.Mirror | Table | INNER JOIN (Pass 1) / LEFT JOIN (Pass 2) for mirror data |
| Trade.CloseExecutionPlan | Table | #PendingOrders pre-scan |
| Trade.OrderForClose | Table | JOIN for order status |
| Dictionary.OrderForExecutionStatus | Table | IsTerminal check |
| Maintenance.Feature | Table | FeatureID=22 IsRealDB flag |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetTreeNodesByParentPositionAndTreeId | Stored Procedure | Sibling - production SP with same interface |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED | Isolation | Dirty reads for performance during close pre-execution |
| #PendingOrders UNIQUE CLUSTERED INDEX | Temp table index | CIX on (PositionID, OrderID) - enables fast lookups from Pass 1 and Pass 2 LEFT JOINs |
| TreePartitionCol = @TreeID % 50 | Partition filter | Partition elimination on Trade.Position |
| PartitionCol = @ParentPositionID % 50 | Partition filter | Partition elimination on Trade.PositionTbl |

---

## 8. Sample Queries

### 8.1 Get all nodes in a copy tree (optimized version)
```sql
EXEC Trade.GetTreeNodesByParentPositionAndTreeIdTest
    @ParentPositionID = 987654321,
    @TreeID = 987654321,
    @OrderID = 0
```

### 8.2 Compare performance between original and optimized
```sql
-- Original
SET STATISTICS TIME ON;
EXEC Trade.GetTreeNodesByParentPositionAndTreeId
    @ParentPositionID = 987654321, @TreeID = 987654321, @OrderID = 0;

-- Optimized
EXEC Trade.GetTreeNodesByParentPositionAndTreeIdTest
    @ParentPositionID = 987654321, @TreeID = 987654321, @OrderID = 0;
SET STATISTICS TIME OFF;
```

### 8.3 Verify pending order exclusion (reference)
```sql
-- Check what pending orders exist for positions in a tree
SELECT TCEP.PositionID, TCEP.OrderID, TOFC.StatusID, DOFE.IsTerminal
FROM Trade.CloseExecutionPlan TCEP WITH (NOLOCK)
     INNER JOIN Trade.OrderForClose TOFC WITH (NOLOCK) ON TCEP.OrderID = TOFC.OrderID
     INNER JOIN Dictionary.OrderForExecutionStatus DOFE WITH (NOLOCK) ON TOFC.StatusID = DOFE.ID
     INNER JOIN Trade.Position TP WITH (NOLOCK) ON TCEP.PositionID = TP.PositionID
WHERE TP.TreeID = 987654321
      AND DOFE.IsTerminal = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Performance test variant not documented in the official TRAD/DB Confluence folder.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetTreeNodesByParentPositionAndTreeIdTest | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetTreeNodesByParentPositionAndTreeIdTest.sql*
