# Trade.TAPI_GetPrivateUserHistoryClosedPositionsCount

> Trading API procedure that returns the count of a customer's own closed manual (non-copy-trade, root) positions from history, capped to a maximum look-back window of one year.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT + @StartTime DATETIME (private closed positions count, 1-year cap) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure counts how many manually-opened, non-copy-trade root closed positions a customer has in their history, within a time window starting at @StartTime (or 1 year ago if no @StartTime is supplied or the supplied date is older than 1 year). The result is used to initialize pagination for the customer's private history view - the "Private" prefix indicates this data is for the customer's own account view (not publicly visible to other users).

The "one year back at most" cap is explicitly enforced by the code comment and logic: `DECLARE @DateLimit DATETIME = DATEADD(year, -1, GETUTCDATE())`. History is truncated to one year to keep the query performant on a high-volume history table.

The filter `OrigParentPositionID = 0 OR OrigParentPositionID IS NULL` restricts the count to root/original positions - excluding positions that are children in a copy-trade tree (those have OrigParentPositionID > 0). Combined with `MirrorID = 0`, this produces a count of purely manual, independently-opened positions.

The output row only exists when the customer has at least one matching position (GROUP BY CID means no row = zero results, not a row with TotalManualItems=0). The ISNULL on count(*) is redundant in this context but defensive.

---

## 2. Business Logic

### 2.1 One-Year Look-Back Cap

**What**: Enforces a maximum one-year history window regardless of the @StartTime supplied.

**Columns/Parameters Involved**: `@StartTime`, `@DateLimit`, `CloseOccurred`

**Rules**:
- `@DateLimit = DATEADD(year, -1, GETUTCDATE())` - 1 year ago from now
- `IF (@StartTime IS NULL OR @StartTime < @DateLimit) SET @StartTime = @DateLimit` - if no start time, or start time is older than 1 year, clamp to 1 year ago
- `CloseOccurred >= @StartTime` - positions closed within the effective window only
- Code comment explicitly states intent: "WE FETCH DATA ONE YEAR BACK AT THE MOST"

### 2.2 Manual Root Position Filter

**What**: Counts only the customer's own directly-opened, non-hierarchy positions.

**Columns/Parameters Involved**: `CID`, `MirrorID`, `OrigParentPositionID`

**Rules**:
- `CID = @CID` - scopes to the specified customer
- `MirrorID = 0` - manual positions only; copy-trade positions (MirrorID > 0) are excluded
- `OrigParentPositionID = 0 OR OrigParentPositionID IS NULL` - root positions only; positions that were copied from another position (OrigParentPositionID > 0) are excluded. NULL and 0 both indicate a root/original position not derived from another.
- `GROUP BY a.CID` and `COUNT(*)` - aggregate count; one row returned when matching positions exist
- `ISNULL(count(*), 0)` - defensive null handling (redundant since COUNT(*) never returns NULL)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Scopes the count to this customer's closed positions only. |
| 2 | @StartTime | DATETIME | YES | NULL | CODE-BACKED | Optional start of the look-back window. When NULL: uses 1 year ago. When provided but older than 1 year: clamped to 1 year ago. When provided and within 1 year: used as-is. |

### Output - Closed Manual Position Count

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | NO | - | CODE-BACKED | Customer ID. Matches @CID. Only present when at least one matching position exists. |
| 2 | TotalManualItems | INT | NO | 0 | CODE-BACKED | Count of closed manual (MirrorID=0, root OrigParentPositionID) positions for this customer within the effective @StartTime window. Used to determine the total pages for closed positions pagination. ISNULL defaults to 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, MirrorID, OrigParentPositionID, CloseOccurred | History.PositionSlim | Lookup (READ) | Source of closed position data for the count |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser service account.
Family: `Trade.TAPI_GetPrivateUsersHistoryClosedPositionsCount` (bulk version for multiple CIDs).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetPrivateUserHistoryClosedPositionsCount (procedure)
└── History.PositionSlim (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionSlim | Table (cross-schema) | Source of closed position count (CID, MirrorID, OrigParentPositionID, CloseOccurred) |

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
- One-year hard cap on look-back window (enforced via @DateLimit)
- No output row if no positions match (GROUP BY CID: empty set = no rows)
- ISNULL on COUNT(*) is defensive but effectively redundant (COUNT(*) never returns NULL)
- WITH (NOLOCK) on History.PositionSlim for read performance

---

## 8. Sample Queries

### 8.1 Get closed manual position count for a customer (last year)

```sql
EXEC Trade.TAPI_GetPrivateUserHistoryClosedPositionsCount
    @CID = 12345,
    @StartTime = NULL
```

### 8.2 Get count from a specific date

```sql
EXEC Trade.TAPI_GetPrivateUserHistoryClosedPositionsCount
    @CID = 12345,
    @StartTime = '2026-01-01'
```

### 8.3 Preview directly - same filter logic

```sql
DECLARE @StartTime DATETIME = DATEADD(year, -1, GETUTCDATE());

SELECT
    a.CID,
    COUNT(*) AS TotalManualItems
FROM History.PositionSlim a WITH (NOLOCK)
WHERE a.CID = 12345
    AND a.CloseOccurred >= @StartTime
    AND a.MirrorID = 0
    AND (a.OrigParentPositionID = 0 OR a.OrigParentPositionID IS NULL)
GROUP BY a.CID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetPrivateUserHistoryClosedPositionsCount | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetPrivateUserHistoryClosedPositionsCount.sql*
