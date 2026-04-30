# Trade.GetClosingTreeUnitsByPositionID

> Traverses the copy-trading tree downward from a given position using a recursive CTE, returning either the total hedgeable units or the list of affected child positions - used by the hedge service to calculate net exposure before closing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns SUM of units or CID+PositionID list for a position's subtree |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a position in a copy-trading tree is about to be closed, the hedge service needs to know the total exposure across the entire subtree (the position itself plus all its children, grandchildren, etc.). This procedure walks the tree using a recursive CTE on ParentPositionID, collecting all open positions (StatusID=1) in the hierarchy, then returns either the aggregate units (for hedge calculation) or the individual position IDs (for tree detachment operations).

This procedure exists because copy-trading creates hierarchical position trees where closing a parent cascades to all children. The hedge service must adjust its market exposure BEFORE the actual close executes. Without knowing the full tree's unit total, the hedge calculations would be incorrect, potentially leaving the platform with unhedged risk.

Data flow: The Hedge.Services.UnitsCalculator calls this procedure with a position ID and hedge server, receives either aggregate units or position list, and uses the result to compute the net hedge adjustment needed on the relevant hedge server.

---

## 2. Business Logic

### 2.1 Recursive Tree Traversal

**What**: Walks the copy-trading hierarchy downward from a root position to find all descendant positions.

**Columns/Parameters Involved**: `@PositionID`, `ParentPositionID`, `StatusID`

**Rules**:
- Anchor: starts with the specified position where StatusID=1 (open) and PartitionCol matches (partition-aligned for performance)
- Recursive step: finds all positions whose ParentPositionID equals the current level's PositionID AND StatusID=1
- Only includes OPEN positions - closed or pending positions in the tree are excluded
- Results go to a temp table #Positions for subsequent queries

**Diagram**:
```
Position Tree Example:
     [Root: 1001]        <-- @PositionID starts here
        /       \
  [1002]       [1003]    <-- Level 1 children (copiers)
    |             |
  [1004]       [1005]    <-- Level 2 grandchildren

If all StatusID=1, all 5 positions are collected.
If 1003 is closed (StatusID=2), it and 1005 are excluded.
```

### 2.2 Dual Output Mode

**What**: Returns different result sets based on the @GetPositionIDs flag.

**Columns/Parameters Involved**: `@GetPositionIDs`

**Rules**:
- @GetPositionIDs = 0 (default): Returns SUM(AmountInUnitsDecimal) filtered to matching HedgeServerID and IsComputeForHedge=1. This is the "how many units to hedge" answer.
- @GetPositionIDs = 1: Returns CID + PositionID for all positions in the tree. Used by the tree detachment operation to identify affected customers and positions.
- Returns 0 (via ISNULL) when no hedgeable positions exist on the specified hedge server

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | VERIFIED | Root position from which to traverse the tree downward. The recursive CTE starts here and finds all descendants via ParentPositionID. (Source: Hedge.Services.UnitsCalculator) |
| 2 | @HedgeServerID | INT | NO | - | VERIFIED | Hedge server filter. Only positions assigned to this hedge server contribute to the unit sum. Irrelevant when @GetPositionIDs=1. (Source: Hedge.Services.UnitsCalculator) |
| 3 | @GetPositionIDs | BIT | YES | 0 | VERIFIED | Output mode switch: 0=return aggregate unit sum (default), 1=return individual CID+PositionID pairs. (Source: Hedge.Services.UnitsCalculator - called with 0 for units, implicit 1 for GetDetachedTreePositionIDs) |

### Return Columns (Mode 0 - Unit Sum)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (unnamed) | DECIMAL(16,6) | NO | - | CODE-BACKED | Total AmountInUnitsDecimal across all open positions in the subtree that are assigned to @HedgeServerID and have IsComputeForHedge=1. Returns 0 if no matching positions. |

### Return Columns (Mode 1 - Position List)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | YES | - | CODE-BACKED | Customer ID for each position in the tree. Used to identify affected customers during tree detachment. |
| 2 | PositionID | BIGINT | NO | - | CODE-BACKED | Position ID for each position in the tree (root + all descendants). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionID / ParentPositionID | Trade.PositionTbl | Recursive JOIN | Self-referencing recursive CTE traverses the copy-trading tree via ParentPositionID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.Services.UnitsCalculator | command.CommandText | Caller | Called to get closing tree units and detached tree position IDs (Source: trading-shared) |
| PROD\BIadmins | VIEW DEFINITION | Permission | BI admins can view the procedure definition |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetClosingTreeUnitsByPositionID (procedure)
└── Trade.PositionTbl (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Recursive CTE source - anchor and recursive member both query this table with NOLOCK |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.Services.UnitsCalculator | C# Service | Calls for hedge unit calculation and tree detachment (Source: trading-shared) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Uses NOLOCK hints on the recursive CTE for performance
- Partition-aligned lookup on anchor: `PartitionCol = @PositionID % 50`
- No max recursion set - relies on tree depth being naturally bounded

---

## 8. Sample Queries

### 8.1 Get total hedgeable units for a position tree

```sql
EXEC Trade.GetClosingTreeUnitsByPositionID
    @PositionID = 123456789,
    @HedgeServerID = 1;
```

### 8.2 Get all position IDs in a tree for detachment

```sql
EXEC Trade.GetClosingTreeUnitsByPositionID
    @PositionID = 123456789,
    @HedgeServerID = 1,
    @GetPositionIDs = 1;
```

### 8.3 Manually traverse a position tree to see the hierarchy

```sql
;WITH TreeCTE AS (
    SELECT pos.PositionID, pos.ParentPositionID, pos.CID,
           pos.AmountInUnitsDecimal, pos.HedgeServerID, 0 AS TreeLevel
    FROM Trade.PositionTbl pos WITH (NOLOCK)
    WHERE pos.PositionID = 123456789
          AND pos.StatusID = 1
          AND pos.PartitionCol = 123456789 % 50
    UNION ALL
    SELECT pos.PositionID, pos.ParentPositionID, pos.CID,
           pos.AmountInUnitsDecimal, pos.HedgeServerID, c.TreeLevel + 1
    FROM Trade.PositionTbl pos WITH (NOLOCK)
    INNER JOIN TreeCTE c ON c.PositionID = pos.ParentPositionID AND pos.StatusID = 1
)
SELECT TreeLevel, PositionID, ParentPositionID, CID,
       AmountInUnitsDecimal, HedgeServerID
FROM TreeCTE
ORDER BY TreeLevel, PositionID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 2 files | Corrections: 0 applied*
*Object: Trade.GetClosingTreeUnitsByPositionID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetClosingTreeUnitsByPositionID.sql*
