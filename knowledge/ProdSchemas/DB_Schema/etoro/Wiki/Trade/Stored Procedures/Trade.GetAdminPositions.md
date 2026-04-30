# Trade.GetAdminPositions

> Router procedure that delegates paginated admin position log retrieval to either the CID-filtered or global variant based on whether a customer ID is provided.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns paginated admin position log via cursor-based navigation |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the single entry point for the admin back-office UI to retrieve paginated admin position log entries. Admin positions are system-initiated trading operations (compensations, corporate actions, manual position adjustments) performed by support agents or automated processes. This procedure allows administrators to browse these operations with optional filters.

The procedure exists as a routing layer that simplifies the calling pattern for the application. Instead of the application deciding which variant to call, it always calls `Trade.GetAdminPositions` and the procedure internally routes based on whether a customer ID (@cid) is supplied. When @cid is NULL, it calls `Trade.GetAdminPositionsWithoutCID` (global, cross-customer search). When @cid is provided, it calls `Trade.GetAdminPositionsWithCID` (scoped to one customer).

The application layer (`AdminPositionRepository.GetAdminPositionsAsync` in trading-shared) calls this procedure directly, passing nullable filter parameters. The procedure's output parameters (@previousCursor, @nextCursor) are read back to enable forward/backward page navigation in the UI.

---

## 2. Business Logic

### 2.1 CID-Based Routing

**What**: Routes to the appropriate sub-procedure based on whether a customer ID is provided.

**Columns/Parameters Involved**: `@cid`

**Rules**:
- If @cid IS NULL -> calls `Trade.GetAdminPositionsWithoutCID` (global search across all customers)
- If @cid IS NOT NULL -> calls `Trade.GetAdminPositionsWithCID` (filtered to specific customer)
- All other parameters are passed through unchanged to the selected sub-procedure
- Both OUTPUT parameters (@previousCursor, @nextCursor) are passed through to the sub-procedure

**Diagram**:
```
Application (AdminPositionRepository)
       |
       v
Trade.GetAdminPositions
       |
       +-- @cid IS NULL ----> Trade.GetAdminPositionsWithoutCID
       |                       (global admin position browse)
       |
       +-- @cid IS NOT NULL -> Trade.GetAdminPositionsWithCID
                                (customer-scoped admin position browse)
```

### 2.2 Cursor-Based Pagination (Delegated)

**What**: Pagination is fully handled by the sub-procedures; this router passes parameters through.

**Columns/Parameters Involved**: `@cursor`, `@previousCursor`, `@nextCursor`, `@itemsPerPage`

**Rules**:
- @cursor = 0 for the initial page (start from beginning)
- @itemsPerPage defaults to 10 if not specified
- Sub-procedures set @previousCursor and @nextCursor for page navigation
- Both sub-procedures use AdminPositionID as the cursor column and read N+1 rows to detect next-page existence

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @eventID | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Optional filter for admin position event group. Each batch of admin positions (e.g., a bulk compensation event) shares a common AdminPositionEventID (GUID). When provided, only entries belonging to that event are returned. When NULL, all events are included. |
| 2 | @openPositionActionType | INT | YES | NULL | CODE-BACKED | Optional filter for the type of admin open action (e.g., compensation, corporate action, manual open). Maps to OpenActionType in Trade.AdminPositionLog. When NULL, all action types are included. Application maps this from `AdminPositionOpenRequestData.OpenPositionActionType`. |
| 3 | @cid | INT | YES | NULL | CODE-BACKED | Customer ID filter. When provided, routes to `Trade.GetAdminPositionsWithCID` to scope results to a single customer. When NULL, routes to `Trade.GetAdminPositionsWithoutCID` for cross-customer global search. This is the routing parameter that determines which sub-procedure executes. |
| 4 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Optional lower bound for the RequestOccurred date range filter. When NULL, no lower date bound is applied. Works with @endTime to define a time window for admin position operations. |
| 5 | @endTime | DATETIME | YES | NULL | CODE-BACKED | Optional upper bound for the RequestOccurred date range filter. When NULL, no upper date bound is applied. Works with @startTime to define a time window for admin position operations. |
| 6 | @itemsPerPage | INT | NO | 10 | CODE-BACKED | Number of admin position log entries to return per page. Sub-procedures internally read @itemsPerPage + 1 rows to detect whether a next page exists. Default of 10 matches the standard admin UI page size. |
| 7 | @cursor | BIGINT | NO | 0 | CODE-BACKED | Cursor position for pagination, representing the AdminPositionID boundary. Value of 0 starts from the beginning. For subsequent pages, use the @nextCursor or @previousCursor value from a prior call. The sub-procedures use `AdminPositionID > @cursor` for forward navigation. |
| 8 | @previousCursor | BIGINT | YES | - | CODE-BACKED | OUTPUT. Set by the sub-procedure to enable backward page navigation. Contains the AdminPositionID boundary for the previous page. NULL when on the first page (no previous page exists). Application reads this as `AdminPositionOpenResponsePagedData.PreviousCursor`. |
| 9 | @nextCursor | BIGINT | YES | - | CODE-BACKED | OUTPUT. Set by the sub-procedure to enable forward page navigation. Contains the AdminPositionID boundary for the next page. NULL when on the last page (no more data). Application reads this as `AdminPositionOpenResponsePagedData.NextCursor`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.GetAdminPositionsWithCID | EXEC call | Called when @cid is not NULL to retrieve customer-scoped admin positions |
| (body) | Trade.GetAdminPositionsWithoutCID | EXEC call | Called when @cid is NULL to retrieve global admin positions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AdminPositionRepository (C#) | GetAdminPositionsAsync | Application call | trading-shared repository that invokes this procedure for admin UI pagination (Source: trading-shared) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAdminPositions (procedure)
+-- Trade.GetAdminPositionsWithCID (procedure)
+-- Trade.GetAdminPositionsWithoutCID (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetAdminPositionsWithCID | Stored Procedure | Called via EXEC when @cid is not NULL |
| Trade.GetAdminPositionsWithoutCID | Stored Procedure | Called via EXEC when @cid is NULL |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AdminPositionRepository (C#) | Application | Calls this procedure from `GetAdminPositionsAsync` method (Source: trading-shared) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Call with customer filter (pages through one customer's admin positions)
```sql
DECLARE @prevCursor BIGINT, @nextCursor BIGINT;

EXEC Trade.GetAdminPositions
    @eventID = NULL,
    @openPositionActionType = NULL,
    @cid = 12345,
    @startTime = '2026-01-01',
    @endTime = '2026-03-16',
    @itemsPerPage = 20,
    @cursor = 0,
    @previousCursor = @prevCursor OUTPUT,
    @nextCursor = @nextCursor OUTPUT;

SELECT @prevCursor AS PreviousCursor, @nextCursor AS NextCursor;
```

### 8.2 Call without customer filter (global admin position browse)
```sql
DECLARE @prevCursor BIGINT, @nextCursor BIGINT;

EXEC Trade.GetAdminPositions
    @eventID = NULL,
    @openPositionActionType = NULL,
    @cid = NULL,
    @startTime = '2026-03-01',
    @endTime = '2026-03-16',
    @itemsPerPage = 10,
    @cursor = 0,
    @previousCursor = @prevCursor OUTPUT,
    @nextCursor = @nextCursor OUTPUT;
```

### 8.3 Filter by specific event ID
```sql
DECLARE @prevCursor BIGINT, @nextCursor BIGINT;

EXEC Trade.GetAdminPositions
    @eventID = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890',
    @openPositionActionType = NULL,
    @cid = NULL,
    @startTime = NULL,
    @endTime = NULL,
    @itemsPerPage = 50,
    @cursor = 0,
    @previousCursor = @prevCursor OUTPUT,
    @nextCursor = @nextCursor OUTPUT;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 1 repos / 2 files | Corrections: 0 applied*
*Object: Trade.GetAdminPositions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAdminPositions.sql*
