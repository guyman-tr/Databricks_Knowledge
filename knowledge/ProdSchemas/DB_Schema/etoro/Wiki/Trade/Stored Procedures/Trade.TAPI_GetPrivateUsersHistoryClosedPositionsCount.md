# Trade.TAPI_GetPrivateUsersHistoryClosedPositionsCount

> Bulk version of the private closed-positions counter: returns counts of closed manual root positions within the past year for a batch of customer IDs supplied as a TVP.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CIDs Trade.CidList READONLY (bulk closed positions count, 1-year cap) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the bulk (multi-customer) variant of `Trade.TAPI_GetPrivateUserHistoryClosedPositionsCount`. It accepts a batch of customer IDs via the `Trade.CidList` TVP and returns one count row per customer that has qualifying positions, enabling the application to fetch pagination totals for multiple customers in a single round-trip.

The same business logic applies as the singular version: counts closed manual (non-copy-trade) root positions within the last year. Unlike the singular version, there is no configurable @StartTime - the 1-year cap is always hardcoded as `CloseOccurred > DATEADD(year, -1, GETUTCDATE())`.

The INNER JOIN to @CIDs ensures only the requested CIDs are processed. Customers with no qualifying positions return no row (not a zero-count row), so callers must handle the absence of a row as implying zero.

Note: The date filter uses strict greater-than (`>`) while the singular version uses `>=` with the clamped @StartTime. This is a minor behavioral difference.

---

## 2. Business Logic

### 2.1 Batch CID Filter with 1-Year Hard Cap

**What**: Counts closed manual root positions for each CID in the input batch, within the past year.

**Columns/Parameters Involved**: `@CIDs`, `CID`, `MirrorID`, `OrigParentPositionID`, `CloseOccurred`

**Rules**:
- `INNER JOIN @CIDs b ON a.CID = b.CID` - limits processing to only the CIDs in the input TVP
- `MirrorID = 0` - manual positions only; copy-trade positions excluded
- `OrigParentPositionID = 0 OR OrigParentPositionID IS NULL` - root/original positions only; positions derived from copy tree (OrigParentPositionID > 0) are excluded
- `CloseOccurred > DATEADD(year, -1, GETUTCDATE())` - strictly within the last year (exclusive lower bound). Hard-coded; no configurable @StartTime
- `GROUP BY a.CID` - one result row per CID with matches
- `ISNULL(count(*), 0)` - defensive null handling (redundant since COUNT(*) never returns NULL)

### 2.2 Difference from Singular Version

**What**: Behavioral differences vs `Trade.TAPI_GetPrivateUserHistoryClosedPositionsCount`.

**Columns/Parameters Involved**: `@StartTime`, `@CIDs`

**Rules**:
- Plural input: takes `Trade.CidList` TVP instead of single `@CID INT`
- No @StartTime: the 1-year window is always applied, not configurable
- Strict inequality: `CloseOccurred > @DateLimit` (exclusive) vs singular's `>= @StartTime` (inclusive)
- Same MirrorID=0 and OrigParentPositionID filter logic

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CIDs | Trade.CidList READONLY | NO | - | CODE-BACKED | Table-valued parameter containing the set of Customer IDs to count positions for. Each CID in the TVP will have at most one output row. |

### Output - Closed Manual Position Counts per Customer

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | NO | - | CODE-BACKED | Customer ID. Sourced from History.PositionSlim. One row per CID that has at least one qualifying closed manual position. CIDs with no qualifying positions return no row. |
| 2 | TotalManualItems | INT | NO | 0 | CODE-BACKED | Count of closed manual (MirrorID=0) root (OrigParentPositionID=0 or NULL) positions for this CID within the past year. Used for pagination initialization. ISNULL defaults to 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, MirrorID, OrigParentPositionID, CloseOccurred | History.PositionSlim | Lookup (READ) | Source of closed position data for the count |
| @CIDs | Trade.CidList | TVP Parameter | Batch of customer IDs to process |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser service account.
Family: `Trade.TAPI_GetPrivateUserHistoryClosedPositionsCount` (single-CID version).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetPrivateUsersHistoryClosedPositionsCount (procedure)
├── History.PositionSlim (table - cross-schema)
└── Trade.CidList (UDT - TVP)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionSlim | Table (cross-schema) | Source of closed position count data |
| Trade.CidList | User Defined Type | TVP type for the @CIDs parameter |

### 6.2 Objects That Depend On This

No SQL dependents. Called by TDAPIUser service account.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. Key behavioral characteristics:
- SET NOCOUNT ON - suppresses row count messages
- TRY/CATCH with THROW - exceptions re-raised to caller
- 1-year hard cap always applied; no @StartTime override
- Strict `>` for date comparison (vs `>=` in singular version)
- No output row for CIDs with no qualifying positions (not a zero row)
- WITH (NOLOCK) on History.PositionSlim

---

## 8. Sample Queries

### 8.1 Get closed manual position counts for multiple customers

```sql
DECLARE @CustomerList Trade.CidList;
INSERT INTO @CustomerList (CID) VALUES (12345), (67890), (11111);

EXEC Trade.TAPI_GetPrivateUsersHistoryClosedPositionsCount
    @CIDs = @CustomerList;
```

### 8.2 Preview directly for a set of CIDs

```sql
SELECT
    a.CID,
    COUNT(*) AS TotalManualItems
FROM History.PositionSlim a WITH (NOLOCK)
WHERE a.CID IN (12345, 67890, 11111)
    AND a.MirrorID = 0
    AND (a.OrigParentPositionID = 0 OR a.OrigParentPositionID IS NULL)
    AND a.CloseOccurred > DATEADD(year, -1, GETUTCDATE())
GROUP BY a.CID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetPrivateUsersHistoryClosedPositionsCount | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetPrivateUsersHistoryClosedPositionsCount.sql*
