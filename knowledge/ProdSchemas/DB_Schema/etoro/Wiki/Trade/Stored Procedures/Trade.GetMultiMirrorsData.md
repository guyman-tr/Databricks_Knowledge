# Trade.GetMultiMirrorsData

> Returns core mirror metadata for a batch of mirror IDs supplied as a table-valued parameter, used to retrieve key configuration fields for multiple mirrors in a single call.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MirrorIDs - table-valued parameter (dbo.IDIntList) supplying the set of MirrorIDs to look up |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetMultiMirrorsData` is a batch lookup procedure for mirror configuration data. Given a set of mirror IDs (passed as a `dbo.IDIntList` table-valued parameter), it returns key metadata from `Trade.Mirror` for each: the copier (CID), leader (ParentCID), mirror type, pause state, calculation type, and status.

This procedure exists to avoid the N+1 query problem when a service needs data for multiple mirrors at once. Instead of calling a single-mirror lookup N times, the caller passes all IDs in one TVP call and gets all results in one round-trip. The procedure materializes the ID list into a temp table with a clustered index for efficient JOIN performance.

Data flows: Used by services that process batches of mirrors (e.g., a notification service handling a batch of affected copiers, or a batch status check). Returns no status filter - both active and closed mirrors are returned.

---

## 2. Business Logic

### 2.1 Temp Table with Clustered Index for TVP Performance

**What**: The TVP is materialized into a temp table with a clustered index before the JOIN.

**Columns/Parameters Involved**: `@MirrorIDs`, `#tblMirrorIDs`, `IX_ID`

**Rules**:
- `SELECT ID INTO #tblMirrorIDs FROM @MirrorIDs`: Materializes the TVP into a temp table.
- `CREATE CLUSTERED INDEX IX_ID ON #tblMirrorIDs(ID)`: Builds a clustered index on the ID column. This is a deliberate performance pattern: SQL Server cannot use statistics on TVP parameters, but a temp table with an index enables the optimizer to produce an efficient nested-loop or merge join against `Trade.Mirror`.
- This pattern is used when the TVP may contain many IDs (10+); the index pays off at larger set sizes.

### 2.2 No Active Filter - All Mirror States Returned

**What**: Returns mirrors regardless of IsActive/MirrorStatusID.

**Columns/Parameters Involved**: `MirrorStatusID`

**Rules**:
- No `WHERE IsActive=1` or `WHERE MirrorStatusID=...` filter.
- The caller receives data for all requested mirrors - active, paused, or closed - and is responsible for filtering by status if needed.
- `MirrorStatusID` is included in the output for the caller to perform its own filtering.

### 2.3 Key Configuration Fields

**What**: Returns the six most commonly needed mirror configuration attributes.

**Columns/Parameters Involved**: `MirrorID`, `CID`, `MirrorTypeID`, `ParentCID`, `PauseCopy`, `MirrorCalculationType`, `MirrorStatusID`

**Rules**:
- `CID`: The copier's customer ID. Who is copying.
- `ParentCID`: The leader's customer ID. Who is being copied.
- `MirrorTypeID`: Type of copy arrangement (e.g., standard copy, fund, CopyPortfolio).
- `PauseCopy`: 1 = copy is paused (new trades from leader not mirrored); 0 = active copying.
- `MirrorCalculationType`: Determines how the mirror calculates equity distribution (proportional, fixed amount, etc.).
- `MirrorStatusID`: Current status code (active, closing, closed, etc.).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MirrorIDs | dbo.IDIntList READONLY | NO | - | CODE-BACKED | Table-valued parameter containing the set of MirrorID values to look up. dbo.IDIntList is a user-defined table type with a single INT column (ID). |

**Output columns** (result set):

| # | Column | Description |
|---|--------|-------------|
| 1 | MirrorID | The mirror identifier. Matches input IDs from @MirrorIDs. |
| 2 | CID | The copier's customer ID. The customer who initiated the copy relationship. |
| 3 | MirrorTypeID | Mirror type identifier. Determines copy arrangement type (standard, fund, portfolio copy, etc.). |
| 4 | ParentCID | The leader's (popular investor's) customer ID. The customer being copied. |
| 5 | PauseCopy | 1 = new trades from leader are NOT mirrored to copier (copy paused). 0 = copy is active. |
| 6 | MirrorCalculationType | Determines equity distribution calculation method for this mirror. |
| 7 | MirrorStatusID | Current status code of the mirror. Returned for caller-side filtering since no server-side status filter is applied. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MirrorID | Trade.Mirror | Primary read | Batch lookup of mirror configuration. INNER JOIN with temp table from @MirrorIDs. |
| @MirrorIDs | dbo.IDIntList | Input TVP | User-defined table type used to pass batch of MirrorID values. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMultiMirrorsData (procedure)
├── Trade.Mirror (table)
└── dbo.IDIntList (user-defined table type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | INNER JOIN on MirrorID to retrieve MirrorID, CID, MirrorTypeID, ParentCID, PauseCopy, MirrorCalculationType, MirrorStatusID |
| dbo.IDIntList | User Defined Table Type | Input parameter type: table with INT column ID, used to pass multiple MirrorIDs |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure (temp table index `IX_ID` is created dynamically at runtime).

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get data for multiple mirrors using TVP

```sql
DECLARE @ids dbo.IDIntList;
INSERT INTO @ids VALUES (100001), (100002), (100003);
EXEC Trade.GetMultiMirrorsData @MirrorIDs = @ids;
```

### 8.2 Get data for mirrors belonging to a specific leader

```sql
-- First, find all mirrors for a leader
DECLARE @leaderMirrors dbo.IDIntList;
INSERT INTO @leaderMirrors
SELECT MirrorID FROM Trade.Mirror WHERE ParentCID = 12345 AND IsActive = 1;

-- Then batch-retrieve their configuration
EXEC Trade.GetMultiMirrorsData @MirrorIDs = @leaderMirrors;
```

### 8.3 Equivalent direct query

```sql
SELECT mr.MirrorID, mr.CID, mr.MirrorTypeID, mr.ParentCID,
       mr.PauseCopy, mr.MirrorCalculationType, mr.MirrorStatusID
FROM Trade.Mirror mr WITH (NOLOCK)
WHERE mr.MirrorID IN (100001, 100002, 100003);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMultiMirrorsData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMultiMirrorsData.sql*
