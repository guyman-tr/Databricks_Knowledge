# History.P_Position_DataFactory

> Azure Data Factory (ADF) extract procedure - returns all 119 position columns from History.Position_DataFactory for a given close date range, with pending TSL (Trailing Stop Loss) actions from Internal.ActionsToExecute tables applied as real-time StopRate overrides.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FromDate + @ToDate - the closed position date range to extract |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.P_Position_DataFactory` is the Azure Data Factory (ADF) extract stored procedure for closed position data. ADF pipelines call this procedure with a date window to incrementally extract closed positions from the History schema and land them in the eToro data lake or downstream data warehouse.

The procedure's unique addition beyond a simple view query is the **pending TSL override**: before selecting position data, it reads all pending TSL (Trailing Stop Loss) action records from the `Internal.ActionsToExecute` tables (sharded as ActionsToExecute through ActionsToExecute9, all ActionID=1). These records contain updated StopRate values for positions that have a TSL adjustment queued but not yet fully processed. For any position in the result set that has a matching pending TSL action, the StopRate from the ActionsToExecute XML payload is substituted for the stored StopRate value. This ensures the extract always reflects the most current stop loss rate, even if the database update hasn't completed.

Data flow: (1) UNION ALL across Internal.ActionsToExecute{0-9} to collect all pending ActionID=1 (TSL) XML params; (2) parse PositionID and StopRate from the XML; (3) build a unique clustered index on PositionID for efficient lookup; (4) SELECT all 119 columns from History.Position_DataFactory filtered by CloseOccurred date range; (5) LEFT JOIN to the pending TSL updates - if a position has a pending update, its StopRate is overridden; (6) OPTION(RECOMPILE) to prevent plan caching issues across different date ranges.

---

## 2. Business Logic

### 2.1 Pending TSL Action Override

**What**: Positions with a queued TSL update in Internal.ActionsToExecute{0-9} have their StopRate replaced with the pending value before extraction.

**Columns/Parameters Involved**: `StopRate`, `Internal.ActionsToExecute.Params` (XML), `PositionID`

**Rules**:
- Reads ActionID=1 records from 10 sharded tables (ActionsToExecute + ActionsToExecute1 through ActionsToExecute9)
- XML structure: `<Root><PositionID Value="..."/><PositionStopLoss Value="..."/></Root>`
- StopRate override: `CASE WHEN b.PositionID IS NOT NULL THEN b.StopRate ELSE a.StopRate END`
- The `dtPrice` type alias is used when parsing StopRate from XML (custom type for price precision)
- A UNIQUE CLUSTERED INDEX on #step2(PositionID) is created to ensure deduplication and fast JOIN performance

**Diagram**:
```
Internal.ActionsToExecute{0-9} WHERE ActionID=1
     |
     v
Parse XML: PositionID, StopRate -> #step2
     |
     v
History.Position_DataFactory (119 cols, @FromDate <= CloseOccurred < @ToDate)
     |
LEFT JOIN #step2 ON PositionID
     |
     v
StopRate = pending rate if pending action exists, else stored rate
     +-- All other 118 columns pass through unchanged
```

### 2.2 Date Range Filtering

**What**: Only positions closed within the specified date window are returned.

**Columns/Parameters Involved**: `@FromDate`, `@ToDate`, `History.Position_DataFactory.CloseOccurred`

**Rules**:
- Filter: CloseOccurred >= @FromDate AND CloseOccurred < @ToDate (inclusive lower bound, exclusive upper bound)
- ADF pipelines typically call this with hourly or daily windows for incremental loading
- OPTION(RECOMPILE) forces a fresh query plan per execution to avoid parameter-sniffing issues with varying date ranges

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromDate | DATETIME | NO | - | CODE-BACKED | Start of the closed position date range (inclusive). Matched against History.Position_DataFactory.CloseOccurred >= @FromDate. ADF incremental pipelines pass the high-water mark from the previous run. |
| 2 | @ToDate | DATETIME | NO | - | CODE-BACKED | End of the closed position date range (exclusive). Matched against CloseOccurred < @ToDate. ADF typically passes @ToDate = GETUTCDATE() or the start of the next extraction window. |

**Result Set**: All 119 columns from `History.Position_DataFactory` (which maps to `History.PositionForExternalUse`), with `StopRate` potentially overridden from Internal.ActionsToExecute pending TSL actions. See `History.Position_DataFactory` view documentation for the full column list.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FromDate, @ToDate | History.Position_DataFactory | READER (view) | Primary source of closed position data for ADF extraction; filtered by CloseOccurred date range |
| PositionID, StopRate | Internal.ActionsToExecute | Lookup (x10 shards) | Reads pending TSL actions (ActionID=1) from all 10 sharded ActionsToExecute tables to override StopRate in extract |
| Internal.ActionsToExecute1 through ActionsToExecute9 | Internal.ActionsToExecute* | Lookup | Additional sharded ActionsToExecute tables in UNION ALL |

### 5.2 Referenced By (other objects point to this)

No callers found in SSDT repository. Called by Azure Data Factory pipeline for closed position incremental extraction.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.P_Position_DataFactory (procedure)
+-- History.Position_DataFactory (view)
|     +-- History.PositionForExternalUse (table/view)
|           +-- History.Position (table)
+-- Internal.ActionsToExecute (table)
+-- Internal.ActionsToExecute1 through ActionsToExecute9 (tables)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Position_DataFactory | View | SELECT all 119 columns WHERE CloseOccurred in date range; source of all output except StopRate override |
| Internal.ActionsToExecute | Table | UNION ALL member - reads pending TSL ActionID=1 records for StopRate override |
| Internal.ActionsToExecute1 through ActionsToExecute9 | Tables | UNION ALL members - sharded ActionsToExecute tables (10 total including base) |

### 6.2 Objects That Depend On This

No dependents found in SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| UNIQUE CLUSTERED INDEX on #step2 | Performance | Ensures PositionID deduplication in pending TSL overrides; fails if same PositionID appears in multiple ActionsToExecute shards with different values |
| OPTION(RECOMPILE) | Query hint | Prevents parameter sniffing plan reuse - ensures optimal plan for each @FromDate/@ToDate window |
| CloseOccurred >= @FromDate AND < @ToDate | Boundary | Inclusive-exclusive date range for consistent non-overlapping ADF pipeline windows |
| DROP TABLE IF EXISTS #step2, #step1 | Cleanup | Defensive cleanup of temp tables at start (handles prior failed executions) |

---

## 8. Sample Queries

### 8.1 Extract positions closed in the last hour (ADF incremental pattern)

```sql
EXEC History.P_Position_DataFactory
    @FromDate = DATEADD(hour, -1, GETUTCDATE()),
    @ToDate = GETUTCDATE()
```

### 8.2 Check pending TSL actions before calling

```sql
SELECT COUNT(*) AS PendingTSLActions
FROM Internal.ActionsToExecute WITH (NOLOCK)
WHERE ActionID = 1
UNION ALL
SELECT COUNT(*) FROM Internal.ActionsToExecute1 WITH (NOLOCK) WHERE ActionID = 1
```

### 8.3 Validate row count for a date window before extraction

```sql
SELECT COUNT(*) AS PositionCount
FROM History.Position_DataFactory WITH (NOLOCK)
WHERE CloseOccurred >= '2026-03-20 00:00:00'
  AND CloseOccurred < '2026-03-21 00:00:00'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. See History.Position_DataFactory (view) for related ADF pipeline documentation references.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.P_Position_DataFactory | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.P_Position_DataFactory.sql*
