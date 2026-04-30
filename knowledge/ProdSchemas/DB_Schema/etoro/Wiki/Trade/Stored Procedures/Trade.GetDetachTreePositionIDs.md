# Trade.GetDetachTreePositionIDs

> Recursively walks a copy-trade position tree starting from a given position, returning all descendant PositionIDs and their CIDs.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID (tree root) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetDetachTreePositionIDs walks a copy-trade position tree starting from a given position and returns all positions in the tree (the root and all descendants). In the CopyTrader system, when a position is copied, the copier's position has ParentPositionID pointing to the original. Copies of copies form a tree. This procedure finds the entire tree so the system can detach or close all related positions.

This procedure exists because detaching from a copy-trade tree requires knowing all positions in the hierarchy. A tree head position may have been copied by multiple customers, each of whose positions may have been further copied. The recursive CTE traverses this entire chain.

Data flows from Trade.PositionTbl using a recursive CTE: the anchor selects the starting @PositionID (if StatusID=1 and partition-aligned), and the recursive member follows ParentPositionID links where StatusID=1.

---

## 2. Business Logic

### 2.1 Recursive Tree Traversal

**What**: Walks the copy-trade position tree via ParentPositionID linkage.

**Columns/Parameters Involved**: `@PositionID`, `ParentPositionID`, `StatusID`

**Rules**:
- Anchor: SELECT PositionID, CID WHERE PositionID = @PositionID AND StatusID = 1
- Recursive: JOIN on pos.ParentPositionID = c.PositionID AND pos.StatusID = 1
- Only open positions (StatusID=1) are included
- Partition-aligned for the anchor: PartitionCol = @PositionID % 50

**Diagram**:
```
@PositionID (root)
  |
  +-- Child positions (ParentPositionID = root, StatusID=1)
  |     |
  |     +-- Grandchild positions (ParentPositionID = child, StatusID=1)
  |           |
  |           +-- ... (recursive)
  |
  Output: All PositionIDs + CIDs in the tree
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | bigint | NO | - | CODE-BACKED | Starting position (tree root or subtree root) to traverse from. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Position in the tree (root or descendant). |
| 2 | CID | int | NO | - | CODE-BACKED | Customer who owns this position. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID, ParentPositionID | Trade.PositionTbl | FROM (recursive CTE) | Position tree traversal |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetDetachTreePositionIDs (procedure)
+-- Trade.PositionTbl (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Recursive CTE - tree traversal via ParentPositionID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found) | - | Called by CopyTrader detach workflow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Uses recursive CTE with default MAXRECURSION (100).

---

## 8. Sample Queries

### 8.1 Get all positions in a tree

```sql
EXEC Trade.GetDetachTreePositionIDs @PositionID = 123456789;
```

### 8.2 Direct recursive query equivalent

```sql
;WITH TreePositions AS (
    SELECT PositionID, CID
    FROM   Trade.PositionTbl WITH (NOLOCK)
    WHERE  PositionID = 123456789 AND StatusID = 1 AND PartitionCol = 123456789 % 50
    UNION ALL
    SELECT pos.PositionID, pos.CID
    FROM   Trade.PositionTbl pos WITH (NOLOCK)
    INNER JOIN TreePositions c ON c.PositionID = pos.ParentPositionID AND pos.StatusID = 1
)
SELECT PositionID, CID FROM TreePositions;
```

### 8.3 Count descendants in a copy tree

```sql
;WITH TreePositions AS (
    SELECT PositionID, CID
    FROM   Trade.PositionTbl WITH (NOLOCK)
    WHERE  PositionID = 123456789 AND StatusID = 1 AND PartitionCol = 123456789 % 50
    UNION ALL
    SELECT pos.PositionID, pos.CID
    FROM   Trade.PositionTbl pos WITH (NOLOCK)
    INNER JOIN TreePositions c ON c.PositionID = pos.ParentPositionID AND pos.StatusID = 1
)
SELECT COUNT(*) AS TreeSize FROM TreePositions;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.4/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetDetachTreePositionIDs | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetDetachTreePositionIDs.sql*
