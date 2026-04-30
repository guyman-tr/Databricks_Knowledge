# Trade.GetAdminPositionsWithCID

> Paginated retrieval of admin position log entries for a specific customer, with optional filters on event type, action type, and date range.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns paginated admin position log with cursor-based navigation |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure supports the admin back-office UI for browsing admin position operations scoped to a specific customer. It implements cursor-based pagination (forward and backward) with optional filtering by event type, action type, and date range. This allows support agents to browse through a customer's admin position history page by page.

The procedure exists because the admin position log can be very large, and a full unfiltered query would be impractical. Cursor-based pagination (using AdminPositionID as the cursor) provides efficient forward/backward navigation without the performance problems of OFFSET-based pagination.

Data flows from Trade.AdminPositionLog with multiple optional ISNULL-based filters. The procedure reads N+1 rows (one extra to detect if a next page exists), returns N rows to the caller, and provides both forward (@nextCursor) and backward (@previousCursor) cursor values for navigation.

---

## 2. Business Logic

### 2.1 Cursor-Based Pagination

**What**: Uses AdminPositionID as a cursor for efficient page navigation.

**Columns/Parameters Involved**: `@cursor`, `@nextCursor`, `@previousCursor`, `@itemsPerPage`, `AdminPositionID`

**Rules**:
- Reads TOP(@itemsPerPage + 1) rows to detect whether a next page exists
- Returns TOP(@itemsPerPage) rows as the current page
- If the extra row exists (count > @itemsPerPage), @nextCursor = MAX(AdminPositionID) - 1 from the full set
- @previousCursor is computed by reading @itemsPerPage rows BEFORE the current cursor position (AdminPositionID <= @cursor, DESC order), then MIN(AdminPositionID) - 1
- Initial call uses @cursor = 0 (start from beginning)

### 2.2 Optional ISNULL Filters

**What**: All filter parameters are optional, using ISNULL to bypass when NULL.

**Columns/Parameters Involved**: `@eventID`, `@openPositionActionType`, `@startTime`, `@endTime`

**Rules**:
- `AdminPositionEventID = ISNULL(@eventID, AdminPositionEventID)` - if @eventID is NULL, matches all events
- `OpenActionType = ISNULL(@openPositionActionType, OpenActionType)` - if NULL, matches all action types
- `RequestOccurred BETWEEN ISNULL(@startTime, RequestOccurred) AND ISNULL(@endTime, RequestOccurred)` - if dates are NULL, matches all dates
- CID filter is always applied (mandatory)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @eventID | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Optional filter: admin position event GUID. When provided, only operations from this event are returned. |
| 2 | @openPositionActionType | INT | YES | NULL | CODE-BACKED | Optional filter: type of open action. When provided, only operations of this action type are returned. |
| 3 | @cid | INT | NO | - | CODE-BACKED | Customer ID to retrieve admin position history for. Mandatory - always applied. |
| 4 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Optional filter: start of date range for RequestOccurred. |
| 5 | @endTime | DATETIME | YES | NULL | CODE-BACKED | Optional filter: end of date range for RequestOccurred. |
| 6 | @itemsPerPage | INT | YES | 10 | CODE-BACKED | Number of records per page. Defaults to 10. |
| 7 | @cursor | BIGINT | YES | 0 | CODE-BACKED | Current position cursor (AdminPositionID). Use 0 to start from beginning. Use @nextCursor from previous call to move forward. |
| 8 | @previousCursor | BIGINT | OUT | - | CODE-BACKED | OUTPUT: cursor value for the previous page. Use as @cursor to navigate backward. NULL if at the first page. |
| 9 | @nextCursor | BIGINT | OUT | - | CODE-BACKED | OUTPUT: cursor value for the next page. Use as @cursor to navigate forward. NULL if no more pages. |

**Output columns:** All columns from Trade.AdminPositionLog (SELECT *). See [Trade.GetAdminPositionLogByAdminPositionID](Trade.GetAdminPositionLogByAdminPositionID.md) Section 4 for full column descriptions.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.AdminPositionLog | Direct Read | Reads admin position log with cursor-based pagination |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase. | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAdminPositionsWithCID (procedure)
└── Trade.AdminPositionLog (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.AdminPositionLog | Table | SELECT with READ UNCOMMITTED - paginated retrieval |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Isolation Level | SET | READ UNCOMMITTED - equivalent to NOLOCK for all reads in the procedure |

---

## 8. Sample Queries

### 8.1 Get first page of admin positions for a customer

```sql
DECLARE @prevCursor BIGINT, @nextCursor BIGINT;

EXEC Trade.GetAdminPositionsWithCID
    @cid = 12345678,
    @itemsPerPage = 20,
    @cursor = 0,
    @previousCursor = @prevCursor OUTPUT,
    @nextCursor = @nextCursor OUTPUT;

SELECT @prevCursor AS PreviousCursor, @nextCursor AS NextCursor;
```

### 8.2 Get next page using cursor

```sql
DECLARE @prevCursor BIGINT, @nextCursor BIGINT;

EXEC Trade.GetAdminPositionsWithCID
    @cid = 12345678,
    @itemsPerPage = 20,
    @cursor = 5000,
    @previousCursor = @prevCursor OUTPUT,
    @nextCursor = @nextCursor OUTPUT;
```

### 8.3 Filter by date range and action type

```sql
DECLARE @prevCursor BIGINT, @nextCursor BIGINT;

EXEC Trade.GetAdminPositionsWithCID
    @cid = 12345678,
    @openPositionActionType = 1,
    @startTime = '2026-01-01',
    @endTime = '2026-03-16',
    @itemsPerPage = 50,
    @cursor = 0,
    @previousCursor = @prevCursor OUTPUT,
    @nextCursor = @nextCursor OUTPUT;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAdminPositionsWithCID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAdminPositionsWithCID.sql*
