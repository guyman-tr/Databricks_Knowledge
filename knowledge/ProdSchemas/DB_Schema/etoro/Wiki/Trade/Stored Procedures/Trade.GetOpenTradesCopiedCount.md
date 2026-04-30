# Trade.GetOpenTradesCopiedCount

> Returns the count of currently open positions that were copied from a specific leader (guru) - used to show how many trades are actively being copied under a leader's mirrors.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GuruID INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOpenTradesCopiedCount` returns a single integer (`Counter`) representing how many open positions across all of a leader's active mirrors are currently being copied. It counts open positions that have a non-zero MirrorID matching any mirror where the leader is the `ParentCID`.

**WHY:** Used in leader profile displays and copy-trading analytics to show how many trades the leader currently has copied across all their followers. This is a key social-trading metric: a leader with many copied open trades signals active management and follower engagement.

**HOW:** A CTE first collects all open positions that have a MirrorID > 0 (meaning they are copy positions). Then it counts those whose MirrorID belongs to any mirror where `ParentCID = @GuruID`. The double-level lookup (CTE + subquery) avoids a direct JOIN between Position and Mirror.

---

## 2. Business Logic

### 2.1 CTE Pre-Filter for Copy Positions

**What:** The CTE `Positions` pre-filters `Trade.Position` to only rows with `MirrorID > 0`, reducing the outer query's scope to copy positions only.

**Columns/Parameters Involved:** `MirrorID`

**Rules:**
- `MirrorID > 0` -> position is a copy (copied from a leader via a mirror)
- `MirrorID = 0` (or NULL) -> self-opened position; excluded
- The CTE only selects `MirrorID` - minimal column projection for efficiency

### 2.2 Mirror Lookup by Leader

**What:** The `WHERE MirrorID IN (SELECT DISTINCT MirrorID FROM Trade.Mirror WHERE ParentCID = @GuruID)` finds all mirrors where the given leader is the copied party.

**Columns/Parameters Involved:** `@GuruID`, `Trade.Mirror.ParentCID`, `Trade.Mirror.MirrorID`

**Rules:**
- `ParentCID = @GuruID` -> the leader's customer ID. All their followers' mirrors are returned.
- `DISTINCT MirrorID` -> deduplicates in case of any data anomalies
- No MirrorStatusID filter is applied -> counts positions from ALL mirrors of this leader, including stopped/paused mirrors. (The underlying Trade.Position view filters to StatusID=1 open positions only.)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GuruID | int | NO | - | CODE-BACKED | The leader's customer ID (ParentCID in Trade.Mirror). All mirrors where this user is the leader are included in the count. |

**Return Columns:**

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| R1 | Counter | int | NO | CODE-BACKED | Count of open copy positions across all of this leader's mirrors. Returns 0 if no copied positions exist. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MirrorID filter | Trade.Position | Direct query (CTE) | Filters open positions with MirrorID > 0 |
| ParentCID = @GuruID | Trade.Mirror | Subquery | Gets all MirrorIDs for this leader |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Leader profile / copy-trading UI | N/A | CALLER | Displays copied trade count on leader cards and profiles |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOpenTradesCopiedCount (procedure)
├── Trade.Position (view)
└── Trade.Mirror (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | CTE source - open positions with MirrorID > 0 |
| Trade.Mirror | Table | Subquery - get MirrorIDs where ParentCID = @GuruID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Copy trading UI / API | External | Displays copied trade count for leader |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Hint:** Both queries use `WITH (NOLOCK)`. Note that `Trade.Position` is a view - its underlying tables (PositionTbl, PositionTreeInfo) may also apply NOLOCK internally.

**Caveat:** No `MirrorStatusID` filter on Trade.Mirror means positions from closed or paused mirrors are included if the underlying position is still open (StatusID=1). This could include positions that were opened before the mirror was stopped.

---

## 8. Sample Queries

### 8.1 Get copied trade count for a leader
```sql
EXEC Trade.GetOpenTradesCopiedCount @GuruID = 12345678
```

### 8.2 Manual equivalent
```sql
WITH Positions AS (
    SELECT MirrorID
    FROM   Trade.Position WITH (NOLOCK)
    WHERE  MirrorID > 0
)
SELECT COUNT(*) AS Counter
FROM   Positions
WHERE  MirrorID IN (
    SELECT DISTINCT MirrorID
    FROM   Trade.Mirror WITH (NOLOCK)
    WHERE  ParentCID = 12345678
)
```

### 8.3 Breakdown by mirror
```sql
SELECT m.MirrorID, m.CID AS CopierCID, COUNT(p.PositionID) AS CopiedPositions
FROM   Trade.Mirror m WITH (NOLOCK)
       LEFT JOIN Trade.Position p WITH (NOLOCK) ON p.MirrorID = m.MirrorID
WHERE  m.ParentCID = 12345678
GROUP  BY m.MirrorID, m.CID
ORDER  BY CopiedPositions DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 9/10, Logic: 7/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B skipped-no app refs)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOpenTradesCopiedCount | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOpenTradesCopiedCount.sql*
