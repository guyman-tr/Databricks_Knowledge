# Trade.TAPI_GetTotalInvestedHistoryAndLivePrivatePositionsByCid

> Returns a single-row aggregate of total amount invested and position count for a customer across both live (open) and historical (closed) positions within a 1-year window, used for activity summary and tier/level calculations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT (single aggregate row, 1-year cap, combines live + history) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure answers the question: "How much has this customer invested and in how many positions, across all their activity (open and closed) within the last year?" It is used for private/internal analytics, player level calculations, or activity summary dashboards - the "Private" in the name distinguishes it from public-profile-facing endpoints.

The key design feature is the UNION ALL of two sources: `Trade.Position` (currently open positions, filtered by when they were opened) and `History.PositionSlim` (closed positions, filtered by open date). By using `OpenOccurred` / `Occurred` as the filter timestamp - not the close date - the procedure captures the investment activity at position-open time, regardless of whether the position is still active. This gives a true picture of how much was deployed during the period.

If @startTime is not provided or is older than 1 year, it is automatically capped at exactly 1 year ago, ensuring the window is always bounded and query performance is predictable.

No privacy check is applied - this is intended for internal use (the "Private" in the name).

---

## 2. Business Logic

### 2.1 Start Time Capping at 1 Year

**What**: Normalizes @startTime to prevent unbounded queries.

**Columns/Parameters Involved**: `@startTime`

**Rules**:
- `IF @startTime IS NULL OR @startTime < DATEADD(year,-1,GETUTCDATE()) -> SET @startTime = DATEADD(year,-1,GETUTCDATE())`
- This means even if a caller passes a date 5 years ago, it is silently capped to 1 year
- The effective @startTime is returned in the output as `StartTime` so the caller knows the actual window used
- Ensures consistent behavior and prevents full-table scans on large history tables

### 2.2 Unified Investment Amount - Live + Historical UNION ALL

**What**: Combines open positions and closed positions into a single amount stream for aggregation.

**Columns/Parameters Involved**: `@cid`, `@startTime`, `Amount`, `Occurred` (Trade.Position), `OpenOccurred` (History.PositionSlim)

**Rules**:
- Branch 1 (live): `Trade.Position WHERE CID=@cid AND Occurred >= @startTime` - open positions opened within the window
  - Comment: "all opened positions (no from time limitation)" - the comment is slightly misleading; it IS filtered by @startTime via Occurred
  - `Occurred` in Trade.Position = when the position was opened
- Branch 2 (closed): `History.PositionSlim WHERE CID=@cid AND OpenOccurred >= @startTime` - closed positions that were opened within the window
  - Filters by open date (`OpenOccurred`), not close date - captures investment deployed in the period
  - Does NOT filter by MirrorID - includes both manual and copy-trade positions
- ISNULL(Amount, 0) applied to both branches to handle NULLs safely
- `OPTION(RECOMPILE)` - prevents bad parameter sniffing on the UNION ALL subquery
- Result: single value per position (Amount)

### 2.3 Single-Row Aggregate Output

**What**: Produces one summary row per call.

**Rules**:
- `TotalInvested = ISNULL(SUM(t.Amount), 0)` - total dollars invested across all positions in the period
- `NumberOfPositionsOpened = ISNULL(COUNT(t.Amount), 0)` - total position count (COUNT on Amount, not *; positions with NULL Amount before ISNULL would be excluded, but ISNULL(Amount,0) ensures they are counted)
- `CID = @cid` - echoed back for caller convenience
- `StartTime = @startTime` - echoed back so caller knows the effective window (important when @startTime was auto-capped)
- Always returns exactly one row

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. All position data is scoped to this customer. No privacy check. |
| 2 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Optional look-back window start. If NULL or older than 1 year ago, auto-capped to DATEADD(year,-1,GETUTCDATE()). The effective value used is returned in the StartTime output column. |

### Output - Single Aggregate Row

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | NO | - | CODE-BACKED | The customer ID - echoed from @cid. |
| 2 | TotalInvested | MONEY | NO | 0 | CODE-BACKED | Total amount invested across all positions (open and closed) that were OPENED within the @startTime window. ISNULL defaults to 0 if no positions found. Includes both manual and copy-trade positions. |
| 3 | NumberOfPositionsOpened | INT | NO | 0 | CODE-BACKED | Count of positions (open and closed) that were opened within the @startTime window. ISNULL defaults to 0. Includes copy and manual positions. |
| 4 | StartTime | DATETIME | NO | - | CODE-BACKED | The effective start time used for the query - either the original @startTime if within 1 year, or DATEADD(year,-1,GETUTCDATE()) if @startTime was NULL or older. Allows callers to know the actual window applied. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, Occurred, Amount | Trade.Position | Lookup (READ) | Source of live (open) positions opened within @startTime. |
| CID, OpenOccurred, Amount | History.PositionSlim | Lookup (READ) | Source of closed positions that were opened within @startTime. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. The "Private" naming and absence of a privacy check suggests internal use - likely called by player-level services or activity analytics.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetTotalInvestedHistoryAndLivePrivatePositionsByCid (procedure)
├── Trade.Position (table)
└── History.PositionSlim (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | Table | Live open positions - queried for Amount where Occurred >= @startTime. |
| History.PositionSlim | Table | Closed positions - queried for Amount where OpenOccurred >= @startTime. |

### 6.2 Objects That Depend On This

No dependents found from procedure search.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get total invested for a customer in the last year
```sql
EXEC Trade.TAPI_GetTotalInvestedHistoryAndLivePrivatePositionsByCid
    @cid = 12345,
    @startTime = NULL
-- Returns: CID=12345, TotalInvested, NumberOfPositionsOpened, StartTime (= 1 year ago)
```

### 8.2 Get total invested for a custom date range (capped at 1 year)
```sql
EXEC Trade.TAPI_GetTotalInvestedHistoryAndLivePrivatePositionsByCid
    @cid = 12345,
    @startTime = '2024-06-01'
-- Effective window: 2024-06-01 to now (since within 1 year)
```

### 8.3 Equivalent inline query for diagnostic use
```sql
DECLARE @cid INT = 12345
DECLARE @startTime DATETIME = DATEADD(year, -1, GETUTCDATE())

SELECT @cid AS CID,
    ISNULL(SUM(t.Amount), 0) AS TotalInvested,
    ISNULL(COUNT(t.Amount), 0) AS NumberOfPositionsOpened,
    @startTime AS StartTime
FROM (
    SELECT ISNULL(Amount, 0) AS Amount
    FROM Trade.Position WITH (NOLOCK)
    WHERE CID = @cid AND Occurred >= @startTime
    UNION ALL
    SELECT ISNULL(Amount, 0) AS Amount
    FROM History.PositionSlim WITH (NOLOCK)
    WHERE CID = @cid AND OpenOccurred >= @startTime
) t
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetTotalInvestedHistoryAndLivePrivatePositionsByCid | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetTotalInvestedHistoryAndLivePrivatePositionsByCid.sql*
