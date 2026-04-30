# BILoad.GetLastRevshareRuntime

> Returns the last successful ADF pipeline execution timestamp and a computed next-run time, providing Azure Data Factory with the scheduling information needed to coordinate pipeline runs.

| Property | Value |
|----------|-------|
| **Schema** | BILoad |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: LastRun datetime, NextRun datetime |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BILoad.GetLastRevshareRuntime is a lightweight query procedure that exposes the current state of the ADF pipeline sync checkpoint. It returns two values: the LastRun timestamp (when the pipeline last completed successfully) and a computed NextRun timestamp (current UTC time minus 4 hours). Azure Data Factory calls this procedure to determine when to schedule the next pipeline run and what @LastRunDate value to pass to LoadClosedPositionsAndAggregates_ADF.

This procedure exists to decouple the pipeline scheduling logic from direct table access. ADF calls this procedure rather than querying BILoad.LastRevshareRuntime directly, providing an abstraction layer that can be extended with additional scheduling logic if needed.

ADF calls this procedure before each pipeline run. The returned NextRun value becomes the @NextRunTime parameter for LoadClosedPositionsAndAggregates_ADF, and the LastRun value becomes @LastRunDate for the sync guard check. The 4-hour UTC offset in NextRun likely aligns with the US Eastern Time business day boundary.

---

## 2. Business Logic

### 2.1 NextRun Offset Calculation

**What**: Computes the next pipeline run time as UTC minus 4 hours.

**Columns/Parameters Involved**: None (no input parameters)

**Rules**:
- NextRun = DATEADD(hour, -4, GETUTCDATE())
- The -4 hour offset produces a timestamp that is 4 hours behind current UTC
- This offset aligns with US Eastern Time (ET) during non-DST periods, or US Atlantic Time during DST
- ADF uses this value as @NextRunTime when calling LoadClosedPositionsAndAggregates_ADF
- The pattern ensures the pipeline processes data up to a consistent daily cutoff point

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LastRun (output column) | datetime | YES | - | CODE-BACKED | The timestamp stored in BILoad.LastRevshareRuntime.LastRun. Represents when the ADF pipeline last completed successfully. ADF uses this as @LastRunDate for the sync guard in LoadClosedPositionsAndAggregates_ADF. |
| 2 | NextRun (output column) | datetime | NO | - | CODE-BACKED | Computed value: DATEADD(hour, -4, GETUTCDATE()). Current UTC minus 4 hours. ADF uses this as @NextRunTime - the value that LastRun will be updated to upon successful completion of the next pipeline run. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LastRun | BILoad.LastRevshareRuntime | READ (SELECT) | Reads the single-row sync checkpoint table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Azure Data Factory (external) | - | Caller | ADF calls this procedure to get scheduling parameters before each pipeline run |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BILoad.GetLastRevshareRuntime (procedure)
+-- BILoad.LastRevshareRuntime (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BILoad.LastRevshareRuntime | Table | SELECT FROM with NOLOCK - reads LastRun value |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Azure Data Factory (external) | External | Calls this procedure for pipeline scheduling |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute the procedure to see current pipeline state
```sql
EXEC BILoad.GetLastRevshareRuntime
```

### 8.2 Compare pipeline state with current time
```sql
DECLARE @LastRun TABLE (LastRun DATETIME, NextRun DATETIME)
INSERT INTO @LastRun EXEC BILoad.GetLastRevshareRuntime

SELECT LastRun,
       NextRun,
       DATEDIFF(HOUR, LastRun, GETUTCDATE()) AS HoursSinceLastRun,
       DATEDIFF(HOUR, NextRun, GETUTCDATE()) AS HoursAheadOfNextRun
FROM @LastRun
```

### 8.3 Check if pipeline is overdue (more than 48 hours since last run)
```sql
DECLARE @Result TABLE (LastRun DATETIME, NextRun DATETIME)
INSERT INTO @Result EXEC BILoad.GetLastRevshareRuntime

SELECT CASE
         WHEN DATEDIFF(HOUR, LastRun, GETUTCDATE()) > 48 THEN 'OVERDUE'
         ELSE 'OK'
       END AS PipelineStatus,
       LastRun,
       NextRun
FROM @Result
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PART-5265 (referenced in SQL comments) | Jira | Original ticket for ADF pipeline implementation by Noga (Feb 2026). Created this procedure to expose pipeline runtime for ADF scheduling. |

No direct Confluence pages found for this object.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 1 Jira (ref only) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BILoad.GetLastRevshareRuntime | Type: Stored Procedure | Source: fiktivo/BILoad/Stored Procedures/BILoad.GetLastRevshareRuntime.sql*
