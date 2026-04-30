# Trade.SSRS_Market_Open_Data

> Multi-mode SSRS dashboard procedure providing real-time trading activity metrics (position opens, closes, failures, and 5-minute time-series) since a given timestamp, scoped to a maximum 7-day lookback.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ResultSetType INT (selects which metric to return) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the data source for a market-open monitoring dashboard used by trading operations teams to track system health at market open and during trading hours. It provides seven distinct views of trading activity - from simple counts to granular breakdown by action type to 5-minute bucket time-series - all driven by a single `@ResultSetType` parameter.

The procedure exists to give operations teams a fast, parameterized way to answer the key market-open question: "Is the platform processing positions normally?" It surfaces open counts, close counts, failure counts, and a live time-series chart in a single SSRS report that refreshes on a schedule.

Data flows as follows: `@dtFrom` defines the start of the monitoring window (e.g., market open time). `@ResultSetType` controls which metric to produce. A hard 7-day guard prevents querying stale historical windows. The `@ShowPositionFail` flag gates the failure result sets (5 and 6) to avoid noise when failure monitoring is not needed.

---

## 2. Business Logic

### 2.1 Result Set Type Dispatch

**What**: A single parameter selects which metric is returned, allowing the same procedure to power multiple report tabs or charts.

**Columns/Parameters Involved**: `@ResultSetType`

**Rules**:
- 1 = Total count of positions opened since @dtFrom
- 2 = Breakdown of opened positions: total, by Copy/Manual, by OpenActionType name
- 3 = Total count of positions closed since @dtFrom
- 4 = Breakdown of closed positions: total, by Copy/Manual (Mirror), by CloseActionType name
- 5 = Total count of failed positions since @dtFrom (requires @ShowPositionFail = 1)
- 6 = Breakdown of failed positions by FailType and ErrorCode (requires @ShowPositionFail = 1)
- 7 = 5-minute time-series of open and close counts over the last 2 hours (ignores @dtFrom)
- Any unrecognized type returns no rows (falls through all IF blocks)

**Diagram**:
```
@ResultSetType:
  1  -> COUNT(opened positions)
  2  -> GROUP BY [Manual/Copy] + OpenActionType name
  3  -> COUNT(closed positions)
  4  -> GROUP BY [Manual/Copy mirror] + CloseActionType name
  5  -> COUNT(failed positions)          [requires @ShowPositionFail=1]
  6  -> GROUP BY FailType + ErrorCode    [requires @ShowPositionFail=1]
  7  -> 5-min buckets: opens + closes for last 2 hours  [ignores @dtFrom]
```

### 2.2 7-Day Guard

**What**: Prevents accidentally running expensive queries against a very wide historical window.

**Columns/Parameters Involved**: `@dtFrom`

**Rules**:
- If `DATEDIFF(day, @dtFrom, GETDATE()) > 7`, the procedure returns immediately with no result set.
- Designed to prevent mis-use as a historical reporting tool - it is intended for real-time/same-day monitoring only.
- The default value of @dtFrom (`'1/8/2023 2:31:12 PM'`) is a legacy hardcoded example date and will always trigger the 7-day guard if not overridden.

### 2.3 Copy vs Manual Classification

**What**: Classifies positions as copy-trade or manual based on structural fields.

**Columns/Parameters Involved**: `OrigParentPositionID` (opens), `MirrorID` (closes)

**Rules**:
- Opens: `CASE WHEN OrigParentPositionID = 0 THEN 'Manual' ELSE 'Copy'` - a non-zero original parent ID means the position was opened as a copy.
- Closes: `CASE WHEN MirrorID = 0 THEN 'Manual' ELSE 'Copy'` - a non-zero MirrorID means the closed position was part of a copy relationship.
- The two sources use different fields for copy detection: OrigParentPositionID for opens, MirrorID for closes.

### 2.4 5-Minute Bucket Time-Series (ResultType 7)

**What**: Produces a per-5-minute-bucket count of opens and closes for the last 2 hours, regardless of @dtFrom.

**Columns/Parameters Involved**: `TM` (time bucket label)

**Rules**:
- Hard-coded window: last 2 hours from `GETUTCDATE()`. @dtFrom is ignored for this result type.
- Bucket key: `HH:MM-HH:MM` formatted string (e.g., '09:00-09:05') using `DATEPART(minute)/5 * 5`.
- Opens (from Trade.Position) and closes (from History.Position_Active) are unioned with zero-filled opposite counts, then summed in an outer GROUP BY TM.
- Result ordered by TM ascending (chronological).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ResultSetType | INT | NO | 1 | CODE-BACKED | Selects which metric to return: 1=open count, 2=open breakdown, 3=close count, 4=close breakdown, 5=fail count, 6=fail breakdown, 7=5-min time-series. Controls all conditional branching in the procedure. |
| 2 | @dtFrom | DATETIME | NO | '1/8/2023 2:31:12 PM' | CODE-BACKED | Start of the monitoring window. All position open/close/fail timestamps are filtered >= @dtFrom. The default value is a legacy example date and will trigger the 7-day guard (procedure returns nothing) if not overridden. Typically set to market open time on the current day. |
| 3 | @ShowPositionFail | BIT | NO | 0 | CODE-BACKED | Gates failure result sets: 0 = procedure exits before result types 5 and 6 (failure data not shown). 1 = failure result sets are enabled. Allows the report to suppress failure data when not relevant (e.g., pre-market monitoring). |

### Output Columns - Result Type 1 (Open Count)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Positions Opened Count | INT | NO | - | CODE-BACKED | Total number of positions opened since @dtFrom. Simple aggregate count from Trade.Position. |

### Output Columns - Result Type 2 (Open Breakdown)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Order | INT | NO | - | CODE-BACKED | Sort key for UNION rows: 0 = total row, 1 = by copy/manual, 2 = by action type. |
| 2 | Opened as Copy | VARCHAR | NO | - | CODE-BACKED | 'Manual' when OrigParentPositionID = 0, 'Copy' otherwise. Empty string on total and action-type rows. |
| 3 | Open Action Type | VARCHAR | NO | - | CODE-BACKED | OpenPositionActionType name from Dictionary.OpenPositionActionType. Empty string on total and copy/manual rows. |
| 4 | Positions Opened Count | INT | NO | - | CODE-BACKED | Count of positions in this grouping. |

### Output Columns - Result Type 3 (Close Count)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Positions Closed Count | INT | NO | - | CODE-BACKED | Total number of positions closed since @dtFrom. From History.Position_Active. |

### Output Columns - Result Type 4 (Close Breakdown)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Order | INT | NO | - | CODE-BACKED | Sort key: 0 = total, 1 = by mirror/manual, 2 = by action type. |
| 2 | Is Mirror | VARCHAR | NO | - | CODE-BACKED | 'Manual' when MirrorID = 0, 'Copy' when MirrorID > 0. Empty string on non-grouping rows. |
| 3 | Close Action Type | VARCHAR | NO | - | CODE-BACKED | ClosePositionActionType name from Dictionary.ClosePositionActionType. Empty string on non-action rows. |
| 4 | Positions Closed Count | INT | NO | - | CODE-BACKED | Count of closed positions in this grouping. |

### Output Columns - Result Type 5 (Fail Count)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Positions Fail Count | INT | NO | - | CODE-BACKED | Total number of position failures since @dtFrom. From History.PositionFail. Only populated when @ShowPositionFail = 1. |

### Output Columns - Result Type 6 (Fail Breakdown)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Order | INT | NO | - | CODE-BACKED | Sort key: 0 = total, 1 = by fail type, 2 = by fail type + error code. |
| 2 | Fail Type Name | VARCHAR | YES | - | CODE-BACKED | Failure category name from Dictionary.FailType. Describes the category of the failure (e.g., validation, system error). |
| 3 | Error Message | VARCHAR | NO | - | CODE-BACKED | Trading error code string from Dictionary.TradingErrorCode.ErrorMessagesCode. 'Unspecified' when ErrorCode is not in the dictionary. |
| 4 | Positions Fail Count | INT | NO | - | CODE-BACKED | Count of failures in this grouping. |

### Output Columns - Result Type 7 (5-Minute Time-Series)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TM | VARCHAR | NO | - | CODE-BACKED | 5-minute time bucket label in 'HH:MM-HH:MM' format (e.g., '09:00-09:05'). Based on UTC time. |
| 2 | Positions Opened Count | INT | NO | - | CODE-BACKED | Number of positions opened within the 5-minute bucket. Sourced from Trade.Position.Occurred. |
| 3 | Positions Closed Count | INT | NO | - | CODE-BACKED | Number of positions closed within the 5-minute bucket. Sourced from History.Position_Active.CloseOccurred. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (open positions) | Trade.Position | Lookup (READ) | Source for result types 1, 2, and 7 (open positions) |
| (closed positions) | History.Position_Active | Lookup (READ) | Source for result types 3, 4, and 7 (closed positions) |
| (failed positions) | History.PositionFail | Lookup (READ) | Source for result types 5 and 6 (failed positions, gated by @ShowPositionFail) |
| OpenActionType | Dictionary.OpenPositionActionType | Lookup (JOIN) | Resolves OpenActionType ID to human-readable name for result type 2 |
| ActionType | Dictionary.ClosePositionActionType | Lookup (JOIN) | Resolves close ActionType ID to human-readable name for result type 4 |
| FailTypeID | Dictionary.FailType | Lookup (JOIN) | Resolves FailTypeID to failure category name for result type 6 |
| ErrorCode | Dictionary.TradingErrorCode | Lookup (JOIN) | Resolves ErrorCode to error string for result type 6 |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called directly from SSRS report server.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SSRS_Market_Open_Data (procedure)
├── Trade.Position (view)
├── History.Position_Active (view - cross-schema)
├── History.PositionFail (table - cross-schema)
├── Dictionary.OpenPositionActionType (table - cross-schema)
├── Dictionary.ClosePositionActionType (table - cross-schema)
├── Dictionary.FailType (table - cross-schema)
└── Dictionary.TradingErrorCode (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | SELECT source for opened positions (result types 1, 2, 7) |
| History.Position_Active | View (cross-schema) | SELECT source for closed positions (result types 3, 4, 7) |
| History.PositionFail | Table (cross-schema) | SELECT source for failed positions (result types 5, 6) |
| Dictionary.OpenPositionActionType | Table (cross-schema) | INNER JOIN to resolve OpenActionType name (result type 2) |
| Dictionary.ClosePositionActionType | Table (cross-schema) | INNER JOIN to resolve CloseActionType name (result type 4) |
| Dictionary.FailType | Table (cross-schema) | LEFT JOIN to resolve FailTypeID name (result type 6) |
| Dictionary.TradingErrorCode | Table (cross-schema) | LEFT JOIN to resolve ErrorCode string (result type 6) |

### 6.2 Objects That Depend On This

No dependents found. Called directly from SSRS report server.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Temp tables (#OpenPositions, #ClosePositions, #FailedPositions) each create a nonclustered index `IX_CUBE` on their grouping columns with `OPTION(RECOMPILE)` for performance.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get total positions opened today since market open

```sql
EXEC Trade.SSRS_Market_Open_Data
    @ResultSetType = 1,
    @dtFrom = '2026-03-17 08:00:00',
    @ShowPositionFail = 0
```

### 8.2 Get 5-minute time-series for the last 2 hours

```sql
EXEC Trade.SSRS_Market_Open_Data
    @ResultSetType = 7,
    @dtFrom = '2026-03-17 08:00:00',
    @ShowPositionFail = 0
```

### 8.3 Get full failure breakdown including error codes

```sql
EXEC Trade.SSRS_Market_Open_Data
    @ResultSetType = 6,
    @dtFrom = '2026-03-17 08:00:00',
    @ShowPositionFail = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 24 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SSRS_Market_Open_Data | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SSRS_Market_Open_Data.sql*
