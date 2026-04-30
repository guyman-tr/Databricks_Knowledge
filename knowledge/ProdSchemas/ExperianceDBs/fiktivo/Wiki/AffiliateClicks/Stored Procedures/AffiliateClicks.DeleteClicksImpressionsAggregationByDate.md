# AffiliateClicks.DeleteClicksImpressionsAggregationByDate

> Scheduled purge procedure that deletes click/impression aggregation data older than a configurable retention period (default 6 months) in batches, with full execution logging to the delete log table.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateClicks |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Batched DELETE from ClicksImpressionsAggregation by UpdateDate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffiliateClicks.DeleteClicksImpressionsAggregationByDate is a data retention procedure that purges old click and impression aggregation data. The affiliate tracking system only needs recent data (default: last 6 months) for active reporting. Older data is deleted in controlled batches to avoid long-running locks on the partitioned ClicksImpressionsAggregation table.

This procedure exists to prevent unbounded table growth. Without it, the aggregation table would accumulate historical click/impression data indefinitely, degrading query performance and consuming storage. The 6-month default retention aligns with the typical affiliate reporting window.

The procedure runs on a scheduled cadence (approximately every 30 minutes based on log evidence). It inserts a log row into ClicksImpressionsAggregationDeleteLog at the start, iteratively deletes batches of rows WHERE UpdateDate <= the cutoff date, updates the log after each batch, and records the completion timestamp when done. The batched approach (default 5,000 rows per iteration) prevents lock escalation and minimizes impact on concurrent reads.

---

## 2. Business Logic

### 2.1 Batched Delete with Configurable Retention

**What**: Deletes old aggregation data in controlled batches to avoid locking issues.

**Columns/Parameters Involved**: `@UpdateDate`, `@BulkSize`

**Rules**:
- Default retention: @UpdateDate = DATEADD(MONTH, -6, GETUTCDATE()) - 6 months from today
- @UpdateDate can be overridden to purge data up to any specific date
- Deletion criteria: WHERE UpdateDate <= @UpdateDate (leverages clustered index leading column)
- Batch size: @BulkSize (default 5,000 rows per DELETE TOP)
- WHILE loop continues until @@ROWCOUNT = 0 (no more rows to delete)
- SET NOCOUNT ON prevents row count messages from interfering with the loop

### 2.2 Execution Logging

**What**: Every purge run is logged to ClicksImpressionsAggregationDeleteLog for operational monitoring.

**Columns/Parameters Involved**: `@LogID`, `StartTime`, `EndTime`, `FinishDelete`, `RowDeleted`

**Rules**:
- INSERT at start: creates log row with StartTime=GETUTCDATE(), RowDeleted=0
- @LogID = MAX(ID) after INSERT (captures the new row's identity)
- During each batch iteration: UPDATE EndTime=GETUTCDATE(), RowDeleted=@@ROWCOUNT
- After loop exits: UPDATE FinishDelete=GETUTCDATE(), RowDeleted=0 (final iteration count)
- Note: RowDeleted reflects the LAST iteration only, not cumulative total

**Diagram**:
```
@UpdateDate (default: 6 months ago)
@BulkSize (default: 5000)
    |
    | INSERT log row (StartTime)
    v
WHILE @Rows > 0:
    | DELETE TOP(@BulkSize) WHERE UpdateDate <= @UpdateDate
    | UPDATE log (EndTime, RowDeleted=@@ROWCOUNT)
    v
Loop exit (@Rows = 0)
    |
    | UPDATE log (FinishDelete, RowDeleted=0)
    v
Done
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UpdateDate | date | YES | NULL (-> 6 months ago) | CODE-BACKED | Retention cutoff date. Rows with UpdateDate <= this value are deleted. When NULL (default), automatically set to DATEADD(MONTH, -6, GETUTCDATE()) for 6-month retention. Can be explicitly set to purge data up to a specific date. |
| 2 | @BulkSize | int | NO | 5000 | CODE-BACKED | Maximum number of rows to delete in each batch iteration. Controls lock duration and tempdb usage. Lower values reduce per-batch impact but increase total iterations. Default of 5,000 balances throughput and concurrency. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateClicks.ClicksImpressionsAggregation | DELETE | Purges rows WHERE UpdateDate <= @UpdateDate in batches |
| - | AffiliateClicks.ClicksImpressionsAggregationDeleteLog | WRITE (INSERT + UPDATE) | Logs purge execution: start, per-batch progress, and completion |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Agent Job (external) | - | Scheduled Caller | Runs approximately every 30 minutes based on log evidence |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateClicks.DeleteClicksImpressionsAggregationByDate (procedure)
+-- AffiliateClicks.ClicksImpressionsAggregation (table)
+-- AffiliateClicks.ClicksImpressionsAggregationDeleteLog (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateClicks.ClicksImpressionsAggregation | Table | DELETE target - purges old rows by UpdateDate |
| AffiliateClicks.ClicksImpressionsAggregationDeleteLog | Table | INSERT + UPDATE - logs purge execution |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL Agent Job (external) | Scheduled Job | Calls this procedure on approximately 30-minute intervals |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Run the purge with default 6-month retention
```sql
EXEC AffiliateClicks.DeleteClicksImpressionsAggregationByDate
```

### 8.2 Purge data older than a specific date with smaller batches
```sql
EXEC AffiliateClicks.DeleteClicksImpressionsAggregationByDate
    @UpdateDate = '2025-06-01',
    @BulkSize = 1000
```

### 8.3 Check what would be deleted (dry run query)
```sql
SELECT COUNT(*) AS RowsToDelete,
       MIN(UpdateDate) AS OldestRow,
       MAX(UpdateDate) AS NewestRowToDelete
FROM AffiliateClicks.ClicksImpressionsAggregation WITH (NOLOCK)
WHERE UpdateDate <= DATEADD(MONTH, -6, CAST(GETUTCDATE() AS DATE))
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PART-2689 (referenced in SQL comments) | Jira | Original implementation: purge data older than 6 months (Apr 2024, Noga) |

No direct Confluence pages found for this specific procedure. Feature context from the "Clicks and Impressions" Confluence page applies to the overall system.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 1 Jira (ref) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateClicks.DeleteClicksImpressionsAggregationByDate | Type: Stored Procedure | Source: fiktivo/AffiliateClicks/Stored Procedures/AffiliateClicks.DeleteClicksImpressionsAggregationByDate.sql*
