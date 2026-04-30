# Trade.GetAdminPositionsWithoutCID

> Paginated retrieval of admin position log entries across all customers, with optional filters on event type, action type, and date range.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns paginated admin position log with cursor-based navigation (no CID filter) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the global (cross-customer) variant of Trade.GetAdminPositionsWithCID. It supports the admin back-office UI for browsing admin position operations across ALL customers. This is used when an administrator needs to review all admin position operations system-wide rather than for a specific customer - for example, viewing all compensation positions opened in a date range, or all operations of a particular event type.

The procedure exists to provide the same cursor-based pagination as GetAdminPositionsWithCID but without the CID filter constraint, enabling global admin operation auditing and monitoring.

Data flows from Trade.AdminPositionLog with the same cursor-based pagination pattern and optional ISNULL filters as the CID variant, but without any customer filter.

---

## 2. Business Logic

### 2.1 Cursor-Based Pagination (Global)

**What**: Same pagination mechanism as Trade.GetAdminPositionsWithCID but without CID filter.

**Columns/Parameters Involved**: `@cursor`, `@nextCursor`, `@previousCursor`, `@itemsPerPage`, `AdminPositionID`

**Rules**:
- Identical cursor logic: TOP(@itemsPerPage + 1) read, current page returned, next/previous cursors computed
- No CID filter - scans across ALL customers (potentially more expensive query)
- Uses READ UNCOMMITTED isolation level for non-blocking reads

### 2.2 Optional ISNULL Filters

**What**: All filter parameters are optional.

**Columns/Parameters Involved**: `@eventID`, `@openPositionActionType`, `@startTime`, `@endTime`

**Rules**:
- Same ISNULL pattern as Trade.GetAdminPositionsWithCID
- Without CID filter, results can be very large - use date range filters for practical queries

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @eventID | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Optional filter: admin position event GUID. |
| 2 | @openPositionActionType | INT | YES | NULL | CODE-BACKED | Optional filter: type of open action. |
| 3 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Optional filter: start of date range for RequestOccurred. |
| 4 | @endTime | DATETIME | YES | NULL | CODE-BACKED | Optional filter: end of date range for RequestOccurred. |
| 5 | @itemsPerPage | INT | YES | 10 | CODE-BACKED | Number of records per page. Defaults to 10. |
| 6 | @cursor | BIGINT | YES | 0 | CODE-BACKED | Current position cursor (AdminPositionID). Use 0 to start from beginning. |
| 7 | @previousCursor | BIGINT | OUT | - | CODE-BACKED | OUTPUT: cursor value for the previous page. NULL if at first page. |
| 8 | @nextCursor | BIGINT | OUT | - | CODE-BACKED | OUTPUT: cursor value for the next page. NULL if no more pages. |

**Output columns:** All columns from Trade.AdminPositionLog (SELECT *). See [Trade.GetAdminPositionLogByAdminPositionID](Trade.GetAdminPositionLogByAdminPositionID.md) Section 4 for full column descriptions.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.AdminPositionLog | Direct Read | Reads admin position log with cursor-based pagination (global, no CID filter) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase. | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAdminPositionsWithoutCID (procedure)
└── Trade.AdminPositionLog (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.AdminPositionLog | Table | SELECT with READ UNCOMMITTED - paginated global retrieval |

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
| Isolation Level | SET | READ UNCOMMITTED - equivalent to NOLOCK for all reads |

---

## 8. Sample Queries

### 8.1 Get first page of all admin positions

```sql
DECLARE @prevCursor BIGINT, @nextCursor BIGINT;

EXEC Trade.GetAdminPositionsWithoutCID
    @itemsPerPage = 20,
    @cursor = 0,
    @previousCursor = @prevCursor OUTPUT,
    @nextCursor = @nextCursor OUTPUT;

SELECT @prevCursor AS PreviousCursor, @nextCursor AS NextCursor;
```

### 8.2 Filter global admin positions by date range

```sql
DECLARE @prevCursor BIGINT, @nextCursor BIGINT;

EXEC Trade.GetAdminPositionsWithoutCID
    @startTime = '2026-03-01',
    @endTime = '2026-03-16',
    @itemsPerPage = 50,
    @cursor = 0,
    @previousCursor = @prevCursor OUTPUT,
    @nextCursor = @nextCursor OUTPUT;
```

### 8.3 Filter by specific event type

```sql
DECLARE @prevCursor BIGINT, @nextCursor BIGINT;

EXEC Trade.GetAdminPositionsWithoutCID
    @eventID = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890',
    @itemsPerPage = 100,
    @cursor = 0,
    @previousCursor = @prevCursor OUTPUT,
    @nextCursor = @nextCursor OUTPUT;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAdminPositionsWithoutCID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAdminPositionsWithoutCID.sql*
