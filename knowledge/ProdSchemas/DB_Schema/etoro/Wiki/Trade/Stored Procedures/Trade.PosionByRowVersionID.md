# Trade.PosionByRowVersionID

> Returns all positions from Trade.PositionForExternalUse where either the position row-version or the tree row-version is at or above a specified version ID - enabling change-feed style incremental reads.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @VersionID (row-version lower bound) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

External systems (risk engines, reporting, audit) need to receive changes to open positions incrementally without polling the entire position set. This procedure provides a change-feed interface: the caller passes the last-seen `rowversion` value and receives all positions that changed since that point.

The `Trade.PositionForExternalUse` view is a read-optimized, external-facing projection of Trade.PositionTbl - it presents position data in the format expected by downstream consumers without exposing internal implementation details.

The two-column OR condition covers both types of changes:
- `RowVersionPosition`: the rowversion of this specific position record (direct changes to the position)
- `RowVersionTree`: the rowversion of the position's CopyTrader tree root (tree-level changes affecting this position)

This means the caller is notified of both direct position changes AND tree-structural changes to which this position belongs. The `OPTION(RECOMPILE)` hint forces SQL Server to recompile the query plan each time, which is appropriate because the optimal plan varies significantly based on the @VersionID value (range of rows changes dramatically).

Note: The procedure name has a typo - "PosION" instead of "PositION" - this is an existing name in production.

---

## 2. Business Logic

### 2.1 Dual Row-Version Predicate

**What**: Returns positions changed directly OR changed via tree-level updates.

**Columns/Parameters Involved**: `Trade.PositionForExternalUse.RowVersionPosition`, `Trade.PositionForExternalUse.RowVersionTree`

**Rules**:
- WHERE RowVersionPosition >= @VersionID OR RowVersionTree >= @VersionID
- Both conditions use >= (inclusive of @VersionID itself)
- Returns SELECT * (all columns from PositionForExternalUse view)
- NOLOCK hint: external reads do not block internal trade execution

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @VersionID | VARBINARY | NO | - | CODE-BACKED | The row-version lower bound for the change-feed query. Returns all positions where RowVersionPosition>=@VersionID OR RowVersionTree>=@VersionID. Caller should pass the MAX rowversion from the previous batch to get the next incremental set. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @VersionID | Trade.PositionForExternalUse | READ (SELECT *) | External-facing view queried with row-version predicate for incremental change feed |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PosionByRowVersionID (procedure)
+-- Trade.PositionForExternalUse (view) [READ - change-feed query with RowVersionPosition/RowVersionTree predicates]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionForExternalUse | View | SELECT * with RowVersionPosition >= @VersionID OR RowVersionTree >= @VersionID predicate |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OPTION(RECOMPILE) | Performance | Forces plan recompilation each call; appropriate because optimal plan depends heavily on @VersionID range size |
| WITH (NOLOCK) | Consistency | Non-locking read on PositionForExternalUse for zero blocking impact on trade execution |
| Name typo: PosION | Note | Procedure name is "PosionByRowVersionID" - "Posion" instead of "Position" - existing production name |
| SELECT * | Design | Returns all columns from PositionForExternalUse; column set is controlled by the view definition |

---

## 8. Sample Queries

### 8.1 Get all positions changed since a specific row-version
```sql
DECLARE @LastVersion VARBINARY(8) = 0x000000000001A3F5;

EXEC Trade.PosionByRowVersionID @VersionID = @LastVersion;
```

### 8.2 Incremental polling pattern (track the latest version)
```sql
-- Get the current max version to use as next polling baseline
SELECT MAX(CASE WHEN RowVersionPosition > RowVersionTree THEN RowVersionPosition ELSE RowVersionTree END)
FROM Trade.PositionForExternalUse WITH (NOLOCK);
```

### 8.3 Initial full load (all positions)
```sql
-- Pass version 0 to get all positions
EXEC Trade.PosionByRowVersionID @VersionID = 0x0000000000000000;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (1,5,8,9B,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 additional analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PosionByRowVersionID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PosionByRowVersionID.sql*
