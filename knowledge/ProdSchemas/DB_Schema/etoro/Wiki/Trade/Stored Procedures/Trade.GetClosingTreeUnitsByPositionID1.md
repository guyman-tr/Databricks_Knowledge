# Trade.GetClosingTreeUnitsByPositionID1

> Simplified variant of GetClosingTreeUnitsByPositionID that traverses the copy-trading tree and returns only the total hedgeable units - no position list mode and no NOLOCK hints.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns SUM of hedgeable units for a position's subtree |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a simplified version of Trade.GetClosingTreeUnitsByPositionID. It performs the same recursive CTE traversal of the copy-trading tree via ParentPositionID but only supports the aggregate unit sum output (no @GetPositionIDs switch). It also lacks NOLOCK hints and partition-aligned anchor lookups, making it potentially slower and more blocking than its newer counterpart.

This procedure likely predates the more feature-rich GetClosingTreeUnitsByPositionID and may be retained for backward compatibility with callers that do not need the position list mode. The BI team has VIEW DEFINITION permission, suggesting it may also be used for analytical inspection.

Data flow is identical to GetClosingTreeUnitsByPositionID: a recursive CTE walks the tree from the specified position through all open descendants, then sums AmountInUnitsDecimal where HedgeServerID matches and IsComputeForHedge=1.

---

## 2. Business Logic

### 2.1 Recursive Tree Traversal (Legacy)

**What**: Walks the copy-trading hierarchy downward from a root position - same algorithm as GetClosingTreeUnitsByPositionID but without NOLOCK or partition alignment.

**Columns/Parameters Involved**: `@PositionID`, `ParentPositionID`

**Rules**:
- Anchor: finds the specified position (no StatusID filter on anchor - includes all states)
- Recursive step: finds all positions whose ParentPositionID equals the current level's PositionID (no StatusID filter on recursive member either)
- Final SELECT filters to HedgeServerID=@HedgeServerID AND IsComputeForHedge=1
- Key difference from GetClosingTreeUnitsByPositionID: NO StatusID=1 filter in the CTE, meaning it may traverse through closed positions

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | Root position from which to traverse the tree downward. The recursive CTE starts here. |
| 2 | @HedgeServerID | INT | NO | - | CODE-BACKED | Hedge server filter. Only positions assigned to this hedge server contribute to the unit sum. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (unnamed) | DECIMAL(16,6) | NO | - | CODE-BACKED | Total AmountInUnitsDecimal across all positions in the subtree that are assigned to @HedgeServerID and have IsComputeForHedge=1. Returns 0 if no matching positions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionID / ParentPositionID | Trade.PositionTbl | Recursive JOIN | Self-referencing recursive CTE traverses the copy-trading tree |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD\BIadmins | VIEW DEFINITION | Permission | BI admins can view the procedure definition |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetClosingTreeUnitsByPositionID1 (procedure)
└── Trade.PositionTbl (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Recursive CTE source - both anchor and recursive member query this table (without NOLOCK) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD\BIadmins | DB Role | Has VIEW DEFINITION permission |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- No NOLOCK hints - may experience blocking under load
- No partition alignment on anchor query - may scan all partitions
- No max recursion set

---

## 8. Sample Queries

### 8.1 Get total hedgeable units for a position tree

```sql
EXEC Trade.GetClosingTreeUnitsByPositionID1
    @PositionID = 123456789,
    @HedgeServerID = 1;
```

### 8.2 Compare results between the two variants

```sql
DECLARE @Units1 DECIMAL(16,6), @Units2 DECIMAL(16,6);
EXEC Trade.GetClosingTreeUnitsByPositionID @PositionID = 123456789, @HedgeServerID = 1;
EXEC Trade.GetClosingTreeUnitsByPositionID1 @PositionID = 123456789, @HedgeServerID = 1;
```

### 8.3 Manually check tree depth and unit distribution

```sql
;WITH TreeCTE AS (
    SELECT pos.PositionID, pos.AmountInUnitsDecimal,
           pos.HedgeServerID, pos.IsComputeForHedge, 0 AS Depth
    FROM Trade.PositionTbl pos WITH (NOLOCK)
    WHERE pos.PositionID = 123456789
    UNION ALL
    SELECT pos.PositionID, pos.AmountInUnitsDecimal,
           pos.HedgeServerID, pos.IsComputeForHedge, c.Depth + 1
    FROM Trade.PositionTbl pos WITH (NOLOCK)
    INNER JOIN TreeCTE c ON c.PositionID = pos.ParentPositionID
)
SELECT Depth, COUNT(*) AS Positions,
       SUM(CASE WHEN HedgeServerID = 1 AND IsComputeForHedge = 1
                THEN AmountInUnitsDecimal ELSE 0 END) AS HedgeableUnits
FROM TreeCTE
GROUP BY Depth
ORDER BY Depth;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetClosingTreeUnitsByPositionID1 | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetClosingTreeUnitsByPositionID1.sql*
