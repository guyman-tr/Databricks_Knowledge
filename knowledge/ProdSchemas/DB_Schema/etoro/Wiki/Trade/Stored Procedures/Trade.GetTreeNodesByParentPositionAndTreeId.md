# Trade.GetTreeNodesByParentPositionAndTreeId

> Retrieves all copy-trading position nodes in a tree by TreeID, excluding positions that already have a pending close order, and optionally adds a mock root node in demo environments.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ParentPositionID + @TreeID - root position and tree identifier |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetTreeNodesByParentPositionAndTreeId` retrieves the set of open positions that form a copy-trading tree, identified by a specific `@TreeID`. Unlike `GetTreeNodesByParentCID` which traverses by customer relationships, this procedure works at the position level: it returns each position in the tree along with its mirror status, hedge server assignment, settlement type, and whether the root position is still open.

This procedure is called during the position-close pre-execution phase when the system needs to close an entire copy-trading tree. Before closing, it must identify all positions in the tree, verify none have a conflicting pending close order (to prevent double-close), and determine which nodes are still active copies. The `@ParentPositionID` marks which position in the tree is the root of the close operation; its `ParentPositionID` is set to -1 in the output (sentinel value meaning "this is the root").

Data flows as follows: the close execution engine calls this SP with the tree's root position ID and TreeID. The SP performs two INSERTs into a memory-optimized table variable (`@Position` of type `Trade.GetTreeNodesByParentPositionAndTreeId_MOT`): first, it collects all positions from `Trade.Position` (the view over open positions) that belong to the `@TreeID`, filtering out any that have a non-terminal pending close order; second, it adds the root position itself from `Trade.PositionTbl` if it was not already included (open status check). A final UNION ALL adds a mock row when `@IsRealDB = 0` (demo environment) to simulate a parent. Results are returned from the table variable.

---

## 2. Business Logic

### 2.1 Pending Close Order Exclusion

**What**: Positions that already have a pending (non-terminal) close order are excluded from the result to prevent double-close conflicts.

**Columns/Parameters Involved**: `@OrderID`, `Trade.CloseExecutionPlan`, `Trade.OrderForClose`, `Dictionary.OrderForExecutionStatus.IsTerminal`

**Rules**:
- For each position in the tree, an OUTER APPLY checks `Trade.CloseExecutionPlan` for an existing OrderID where `OrderID != @OrderID` (exclude the current order being processed) and `Dictionary.OrderForExecutionStatus.IsTerminal = 0` (non-terminal = still active/pending)
- Positions where `OrderForClose.OrderID IS NULL` are included (no conflicting order)
- Additionally, `Trade.DelayedOrderForClose` is checked: positions with a delayed close order are also excluded (`TDOC.OrderID IS NULL`)
- `@OrderID = 0` (default) means "no current order to exclude" - used when simply querying the tree without a specific order context

### 2.2 Two-Pass Population Strategy

**What**: The SP uses two INSERT passes to ensure both tree members and the parent position are included.

**Rules**:
- **Pass 1**: Queries `Trade.Position` (view of open positions) filtered by `TreeID = @TreeID` AND `TreePartitionCol = @TreeID % 50` AND `TM.IsActive = 1` (active mirror only). This gets all child positions in the tree.
- **Pass 2**: Queries `Trade.PositionTbl` directly for the `@ParentPositionID` with `StatusID = 1` (open) and `PartitionCol = @ParentPositionID % 50`, only if `PositionID NOT IN @Position` (avoids duplicates). This ensures the root position is included even if it didn't appear in Pass 1 (e.g., its mirror is no longer active).
- The `@ParentPositionID` row in output has `ParentPositionID = -1` (sentinel for "root of this close operation")

### 2.3 Demo Mode Mock Row

**What**: In demo environments (IsRealDB=0), a mock parent row is added to simulate the root.

**Rules**:
- When `@IsRealDB = 0`, a UNION ALL adds a row with `CID=0, PositionID=@ParentPositionID, MirrorID=0, ParentPositionID=-1, all other fields = 0`
- This is purely for testing/demo purposes and is never returned in production
- The mock row has `IsSettled=0, IsComputeForHedge=0, IsMirrorActive=0, IsFundCopy=0`

### 2.4 Root Position Identification

**What**: The `@ParentPositionID` is marked as the tree root using ParentPositionID = -1.

**Rules**:
- All rows use `IIF(TP.PositionID = @ParentPositionID, -1, TP.ParentPositionID) AS ParentPositionID`
- This means the root position's ParentPositionID output is -1 regardless of its actual ParentPositionID in the table
- Consumers use ParentPositionID = -1 to identify the root of the close cascade

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ParentPositionID | BIGINT | NO | - | CODE-BACKED | PositionID of the root position for this close operation. This position's ParentPositionID is output as -1 (root sentinel). Also used as the PartitionCol key for Pass 2: `PartitionCol = @ParentPositionID % 50`. |
| 2 | @TreeID | BIGINT | NO | - | CODE-BACKED | TreeID of the copy-trading position tree to retrieve. All positions where `Trade.Position.TreeID = @TreeID` and `TreePartitionCol = @TreeID % 50` are candidates. TreeID is the PositionID of the first position in a copy tree. |
| 3 | @OrderID | BIGINT | NO | 0 | CODE-BACKED | Current order being processed. Positions that have a non-terminal close execution plan for any OrderID != @OrderID are excluded (pending conflict check). Default 0 = no exclusion by order. |

**Output columns (from Trade.GetTreeNodesByParentPositionAndTreeId_MOT type):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | Level | INT | YES | NULL | NAME-INFERRED | Hierarchy level within the position tree. Populated as NULL by this SP (the MOT column exists but is not computed here - level assignment is done by the caller). |
| 5 | CID | INT | NO | - | CODE-BACKED | Customer ID of the position owner. |
| 6 | PositionID | BIGINT | NO | - | CODE-BACKED | Position ID of this tree node. |
| 7 | MirrorID | INT | YES | - | CODE-BACKED | Mirror relationship ID for this position. 0 for non-copy positions. FK to Trade.Mirror. |
| 8 | ParentPositionID | BIGINT | NO | - | CODE-BACKED | Parent position ID in the copy tree. Set to -1 when PositionID = @ParentPositionID (marks this as the root node of the close operation). |
| 9 | Units | DECIMAL | NO | - | CODE-BACKED | Current position size in units (Trade.Position.AmountInUnitsDecimal). |
| 10 | Amount | MONEY | NO | - | CODE-BACKED | Position investment amount in account currency. |
| 11 | IsSettled | BIT/TINYINT | NO | - | CODE-BACKED | Settlement type flag: 1 = real stock position (actual ownership), 0 = CFD. Legacy field predating SettlementTypeID. See Trade.PositionTbl documentation for full semantics. |
| 12 | IsComputeForHedge | BIT | YES | - | CODE-BACKED | 1 = include in hedge exposure calculation; 0 = exclude. Comes from Trade.Position.IsComputeForHedge. |
| 13 | RootHedgeServerID | INT | YES | - | CODE-BACKED | Hedge server ID for the root of the copy tree. Used for hedge routing. FK to Trade.HedgeServer. |
| 14 | HedgeServerID | INT | YES | - | CODE-BACKED | Hedge server ID for this specific position node. May differ from root for multi-level copies. FK to Trade.HedgeServer. |
| 15 | TreeID | BIGINT | NO | - | CODE-BACKED | Copy tree identifier. Same value as @TreeID for all rows. Equals the PositionID of the first position opened in this copy chain. |
| 16 | IsMirrorActive | BIT | NO | - | CODE-BACKED | 1 = the mirror relationship for this position is currently active; 0 = inactive mirror (ISNULL(TM.IsActive, 0)). Used to determine if a copier is still following the parent. |
| 17 | IsFundCopy | BIT | NO | - | CODE-BACKED | 1 = Fund Copy position (MirrorTypeID=4); 0 = regular CopyTrader position. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Position table var | Trade.GetTreeNodesByParentPositionAndTreeId_MOT | UDT | Memory-optimized table type used as temporary storage for the two-pass population |
| Pass 1 source | Trade.Position | FROM | View of open positions - queried by TreeID partition |
| Pass 2 source | Trade.PositionTbl | FROM | Base positions table - queried for root position by PartitionCol |
| Pass 1 JOIN | Trade.Mirror | LEFT JOIN | Mirror status check (IsActive, MirrorTypeID for IsFundCopy) |
| Pending close check | Trade.CloseExecutionPlan | OUTER APPLY | Checks for conflicting pending close orders |
| Pending close check | Trade.OrderForClose | INNER JOIN | Joins to get order status |
| Status lookup | Dictionary.OrderForExecutionStatus | INNER JOIN | IsTerminal=0 means non-terminal (pending) order |
| Delayed close check | Trade.DelayedOrderForClose | LEFT JOIN | Additional check for delayed close orders |
| IsRealDB | Maintenance.Feature | (via @IsRealDB local var) | FeatureID=22 determines demo vs. production behavior |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (close execution engine) | @ParentPositionID, @TreeID | EXEC caller | Called during pre-execution close to identify tree nodes to close |
| Trade.GetTreeNodesByParentPositionAndTreeIdTest | - | Sibling | Optimized test version with same signature and logic |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetTreeNodesByParentPositionAndTreeId (procedure)
├── Trade.GetTreeNodesByParentPositionAndTreeId_MOT (UDT - table variable type)
├── Trade.Position (view)
│     ├── Trade.PositionTbl (table)
│     └── Trade.PositionTreeInfo (table)
├── Trade.PositionTbl (table) [Pass 2 direct query]
├── Trade.Mirror (table)
├── Trade.CloseExecutionPlan (table)
├── Trade.OrderForClose (table)
├── Dictionary.OrderForExecutionStatus (table)
├── Trade.DelayedOrderForClose (table)
└── Maintenance.Feature (table) [IsRealDB]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetTreeNodesByParentPositionAndTreeId_MOT | User Defined Type | Table variable to accumulate results across two passes |
| Trade.Position | View | Pass 1: get tree positions by TreeID |
| Trade.PositionTbl | Table | Pass 2: get root position by PositionID/PartitionCol |
| Trade.Mirror | Table | LEFT JOIN for mirror IsActive and MirrorTypeID |
| Trade.CloseExecutionPlan | Table | OUTER APPLY - pending close detection |
| Trade.OrderForClose | Table | JOIN to get order status for pending close check |
| Dictionary.OrderForExecutionStatus | Table | IsTerminal check |
| Trade.DelayedOrderForClose | Table | Additional delayed close check |
| Maintenance.Feature | Table | FeatureID=22 IsRealDB flag |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetTreeNodesByParentPositionAndTreeIdTest | Stored Procedure | Performance-optimized version with identical interface |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED | Isolation | Reads dirty/uncommitted data for performance during close pre-execution |
| TreePartitionCol = @TreeID % 50 | Partition filter | Must match partition column to use partition elimination on Trade.Position |
| PartitionCol = @ParentPositionID % 50 | Partition filter | Must match partition column on Trade.PositionTbl for Pass 2 |

---

## 8. Sample Queries

### 8.1 Get all nodes in a copy tree for close pre-execution
```sql
EXEC Trade.GetTreeNodesByParentPositionAndTreeId
    @ParentPositionID = 987654321,
    @TreeID = 987654321,  -- TreeID usually equals the root PositionID
    @OrderID = 0
```

### 8.2 Exclude a specific order's conflicts (during active close processing)
```sql
EXEC Trade.GetTreeNodesByParentPositionAndTreeId
    @ParentPositionID = 987654321,
    @TreeID = 987654321,
    @OrderID = 111222333  -- exclude positions being closed by this order
```

### 8.3 Inspect the tree structure directly (reference)
```sql
-- See what Trade.Position holds for a given TreeID
SELECT  TP.PositionID, TP.CID, TP.MirrorID, TP.ParentPositionID, TP.TreeID,
        TP.IsSettled, TP.HedgeServerID, TP.IsComputeForHedge,
        TM.IsActive AS MirrorIsActive, IIF(TM.MirrorTypeID=4,1,0) AS IsFundCopy
FROM    Trade.Position TP WITH (NOLOCK)
        LEFT JOIN Trade.Mirror TM WITH (NOLOCK) ON TP.MirrorID = TM.MirrorID
WHERE   TP.TreeID = 987654321
        AND TP.TreePartitionCol = 987654321 % 50
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Not listed in the configured TRAD/DB Confluence folder. The folder focuses on core execution SPs (open/close) rather than tree-traversal utilities.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetTreeNodesByParentPositionAndTreeId | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetTreeNodesByParentPositionAndTreeId.sql*
