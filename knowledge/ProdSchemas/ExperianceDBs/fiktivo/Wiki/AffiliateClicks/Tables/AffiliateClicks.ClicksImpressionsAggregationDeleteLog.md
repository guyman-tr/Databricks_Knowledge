# AffiliateClicks.ClicksImpressionsAggregationDeleteLog

> Audit log that records every execution of the click/impression data purge procedure, tracking start time, end time, completion, and rows deleted for operational monitoring.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateClicks |
| **Object Type** | Table |
| **Key Identifier** | ID (int, IDENTITY) - no explicit PK constraint |
| **Partition** | No |
| **Indexes** | 0 |

---

## 1. Business Meaning

AffiliateClicks.ClicksImpressionsAggregationDeleteLog is an operational audit table that tracks every execution of the DeleteClicksImpressionsAggregationByDate purge procedure. Each row represents one purge run, recording when it started, when each batch iteration ended, and when the entire purge finished. This provides observability into the data retention process for the click/impression tracking system.

This table exists to enable debugging and monitoring of the purge process. When the purge runs (approximately every 30 minutes based on current scheduling), operators can verify it executed, how long it took, and how many rows were deleted. If the purge fails or takes unexpectedly long, this log provides the diagnostic trail.

Data flows in exclusively from the DeleteClicksImpressionsAggregationByDate procedure: an INSERT at the start of each run (recording StartTime), followed by iterative UPDATEs during the batched delete loop (recording EndTime and RowDeleted per iteration), and a final UPDATE when complete (recording FinishDelete). The table grows monotonically and is never purged itself.

---

## 2. Business Logic

### 2.1 Three-Phase Logging Pattern

**What**: Each purge run creates one log row that is progressively updated through three phases.

**Columns/Parameters Involved**: `StartTime`, `EndTime`, `FinishDelete`, `RowDeleted`

**Rules**:
- Phase 1 (INSERT): Row created with StartTime=GETUTCDATE(), RowDeleted=0
- Phase 2 (Loop UPDATE): During each batch delete iteration, EndTime is updated to GETUTCDATE() and RowDeleted is set to the @@ROWCOUNT of that iteration
- Phase 3 (Final UPDATE): After the WHILE loop exits (@@ROWCOUNT = 0), FinishDelete is set to GETUTCDATE() and RowDeleted = 0 (final iteration found nothing)
- Note: RowDeleted tracks the LAST iteration's count, not the cumulative total

**Diagram**:
```
DeleteClicksImpressionsAggregationByDate starts
    |
    | INSERT (StartTime, RowDeleted=0) -> get @LogID
    v
WHILE @Rows > 0:
    | DELETE TOP(5000) FROM ClicksImpressionsAggregation
    | UPDATE log SET EndTime=now, RowDeleted=@@ROWCOUNT
    v
Loop exits (@@ROWCOUNT = 0)
    |
    | UPDATE log SET FinishDelete=now, RowDeleted=0
    v
Done
```

---

## 3. Data Overview

| ID | StartTime | EndTime | FinishDelete | RowDeleted | Meaning |
|---|---|---|---|---|---|
| 42495 | 2026-04-13 05:39:00 | 2026-04-13 05:39:00 | 2026-04-13 05:39:00 | 0 | Most recent purge run - completed instantly, no rows to delete (data is within 6-month retention window) |
| 42494 | 2026-04-13 05:08:00 | 2026-04-13 05:08:00 | 2026-04-13 05:08:00 | 0 | Previous run ~31 minutes earlier - same result, no deletions needed |
| 42493 | 2026-04-13 04:38:00 | 2026-04-13 04:38:00 | 2026-04-13 04:38:00 | 0 | Consistent ~30 minute scheduling pattern visible across all recent runs |

*Note: 24,521 total rows. All recent entries show RowDeleted=0 - the purge consistently finds nothing to delete. The procedure runs approximately every 30 minutes via scheduled job.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate key. No explicit PK constraint declared, but IDENTITY ensures uniqueness. Used by the purge procedure as @LogID to locate the current run's row for UPDATE operations. |
| 2 | StartTime | datetime | NO | - | CODE-BACKED | UTC timestamp when the purge procedure began execution. Set to GETUTCDATE() on INSERT at the start of each run. The first recorded timestamp for the purge run. |
| 3 | EndTime | datetime | YES | - | CODE-BACKED | UTC timestamp of the most recent batch delete iteration. Updated during each WHILE loop iteration to GETUTCDATE(). Shows the last time a DELETE batch was attempted. NULL only if the procedure fails before the first DELETE iteration. |
| 4 | FinishDelete | datetime | YES | - | CODE-BACKED | UTC timestamp when the entire purge run completed (WHILE loop exited). Set to GETUTCDATE() after the final iteration finds 0 rows to delete. NULL if the purge is still running or failed mid-execution. The presence of FinishDelete confirms the run completed successfully. |
| 5 | RowDeleted | int | YES | - | CODE-BACKED | Number of rows deleted in the LAST batch iteration. Set to 0 on initial INSERT, updated to @@ROWCOUNT during each loop iteration, and reset to 0 on the final UPDATE (because the final iteration found nothing). Note: this is NOT the cumulative total - it only reflects the last iteration's count. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateClicks.DeleteClicksImpressionsAggregationByDate | - | WRITER + MODIFIER | INSERT at start of purge, UPDATE during and after batched delete loop |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateClicks.DeleteClicksImpressionsAggregationByDate | Stored Procedure | WRITER + MODIFIER - INSERT/UPDATE for purge run logging |

---

## 7. Technical Details

### 7.1 Indexes

No indexes defined. The table is accessed primarily by MAX(ID) to find the current log row, and the IDENTITY column provides natural ordering.

### 7.2 Constraints

None. No PK, no FKs, no CHECK constraints. The IDENTITY column provides de facto uniqueness without an explicit constraint.

---

## 8. Sample Queries

### 8.1 Check the most recent purge run
```sql
SELECT TOP 1 ID, StartTime, EndTime, FinishDelete, RowDeleted,
       DATEDIFF(MILLISECOND, StartTime, FinishDelete) AS DurationMs
FROM AffiliateClicks.ClicksImpressionsAggregationDeleteLog WITH (NOLOCK)
ORDER BY ID DESC
```

### 8.2 Find purge runs that actually deleted data
```sql
SELECT ID, StartTime, FinishDelete, RowDeleted
FROM AffiliateClicks.ClicksImpressionsAggregationDeleteLog WITH (NOLOCK)
WHERE RowDeleted > 0
ORDER BY ID DESC
```

### 8.3 Check purge scheduling pattern (runs per day)
```sql
SELECT CAST(StartTime AS DATE) AS RunDate,
       COUNT(*) AS RunsPerDay,
       MIN(StartTime) AS FirstRun,
       MAX(StartTime) AS LastRun
FROM AffiliateClicks.ClicksImpressionsAggregationDeleteLog WITH (NOLOCK)
GROUP BY CAST(StartTime AS DATE)
ORDER BY RunDate DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PART-2689 (referenced in SQL comments) | Jira | Purge procedure created as part of original Affiliate Clicks feature (Apr 2024, Noga) |

No direct Confluence pages found for this specific table.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.1/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 1 Jira (ref) | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateClicks.ClicksImpressionsAggregationDeleteLog | Type: Table | Source: fiktivo/AffiliateClicks/Tables/AffiliateClicks.ClicksImpressionsAggregationDeleteLog.sql*
