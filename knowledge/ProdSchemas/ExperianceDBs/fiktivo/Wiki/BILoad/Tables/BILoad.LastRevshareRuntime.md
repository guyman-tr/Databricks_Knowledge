# BILoad.LastRevshareRuntime

> Single-row configuration table that tracks the last successful execution timestamp of the ADF revenue-share pipeline, serving as both a sync guard and a scheduling reference.

| Property | Value |
|----------|-------|
| **Schema** | BILoad |
| **Object Type** | Table |
| **Key Identifier** | No PK - single-row table (always exactly 1 row) |
| **Partition** | No |
| **Indexes** | 0 |

---

## 1. Business Meaning

BILoad.LastRevshareRuntime is a single-row configuration table that stores the timestamp of the last successful ADF revenue-share pipeline execution. It acts as a synchronization checkpoint between Azure Data Factory and the commission loading procedure, preventing stale or duplicate data processing.

This table exists to coordinate the handoff between ADF (which populates BILoad staging tables) and the SQL-side processing (AffiliateCommission.LoadClosedPositionsAndAggregates_ADF). Without this sync mechanism, the load procedure could process data from a previous ADF run or run before ADF has finished loading, leading to data inconsistency in the commission system.

Data flow: ADF schedules a pipeline run and passes the expected run timestamp to LoadClosedPositionsAndAggregates_ADF as @LastRunDate. The procedure checks if LastRun matches @LastRunDate - if not, it exits with a "not sync" log entry. On successful processing, the procedure updates LastRun to @NextRunTime, advancing the checkpoint. BILoad.GetLastRevshareRuntime exposes the current LastRun alongside a computed NextRun (UTC minus 4 hours) for ADF scheduling.

---

## 2. Business Logic

### 2.1 Pipeline Sync Guard

**What**: Prevents the load procedure from processing data when ADF and SQL are out of sync.

**Columns/Parameters Involved**: `LastRun`

**Rules**:
- LoadClosedPositionsAndAggregates_ADF receives @LastRunDate from ADF
- It reads LastRun from this table and compares: IF LastRun <> @LastRunDate -> logs "LastRun not sync. Exit" and returns
- This ensures the procedure only runs when ADF has set up the expected state
- On successful completion, LastRun is updated to @NextRunTime (within the same transaction as the data load)
- The UPDATE is inside the TRY/TRAN block - if the transaction rolls back, LastRun remains unchanged (safe retry)

**Diagram**:
```
ADF Pipeline Start
    |
    | Calls LoadClosedPositionsAndAggregates_ADF(@LastRunDate, @NextRunTime)
    v
Check: LastRun == @LastRunDate?
    |
    +-- NO --> Log "not sync", EXIT
    |
    +-- YES --> Process data (3-phase load)
                    |
                    | On success (within TRAN):
                    v
                UPDATE LastRun = @NextRunTime
```

### 2.2 NextRun Calculation

**What**: GetLastRevshareRuntime provides both the current LastRun and a computed NextRun for ADF scheduling.

**Columns/Parameters Involved**: `LastRun`

**Rules**:
- NextRun = DATEADD(hour, -4, GETUTCDATE()) - current UTC time minus 4 hours
- The 4-hour offset likely accounts for the US Eastern Time business day boundary or a processing delay window
- ADF uses NextRun as the @NextRunTime parameter for the next pipeline invocation

---

## 3. Data Overview

| LastRun | Meaning |
|---------|---------|
| 2026-01-01 00:00:00 | The pipeline was last successfully run (or initialized) on Jan 1, 2026. This may represent an initialization value if the ADF pipeline has not yet executed a production run. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LastRun | datetime | YES | - | CODE-BACKED | Timestamp of the last successful ADF revenue-share pipeline execution. Read by LoadClosedPositionsAndAggregates_ADF as a sync guard (must match @LastRunDate). Updated to @NextRunTime on successful data load within the same transaction. Read by GetLastRevshareRuntime to expose the current checkpoint alongside a computed NextRun (UTC-4h). Nullable to allow an uninitialized state. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BILoad.GetLastRevshareRuntime | - | READ (SELECT) | Reads LastRun and computes NextRun for ADF scheduling |
| AffiliateCommission.LoadClosedPositionsAndAggregates_ADF | - | READ + WRITE | Reads LastRun for sync validation; updates to @NextRunTime on success |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| [BILoad.GetLastRevshareRuntime](../Stored Procedures/BILoad.GetLastRevshareRuntime.md) | Stored Procedure | READER - SELECTs LastRun and computes NextRun |
| AffiliateCommission.LoadClosedPositionsAndAggregates_ADF | Stored Procedure | READER + MODIFIER - reads for sync guard, updates on success |

---

## 7. Technical Details

### 7.1 Indexes

No indexes defined. Single-row table - indexing is unnecessary.

### 7.2 Constraints

None. No PK, no FK, no CHECK constraints. The single-row nature is enforced by application logic (only UPDATE, no INSERT from the processing side). The initial row must be seeded manually or by a deployment script.

---

## 8. Sample Queries

### 8.1 Check current pipeline sync state
```sql
SELECT LastRun,
       DATEADD(HOUR, -4, GETUTCDATE()) AS ComputedNextRun,
       DATEDIFF(HOUR, LastRun, GETUTCDATE()) AS HoursSinceLastRun
FROM BILoad.LastRevshareRuntime WITH (NOLOCK)
```

### 8.2 Verify sync readiness for a given run date
```sql
DECLARE @ExpectedLastRun DATETIME = '2026-01-01'
SELECT CASE
         WHEN LastRun = @ExpectedLastRun THEN 'IN SYNC - ready to process'
         ELSE 'OUT OF SYNC - pipeline will exit'
       END AS SyncStatus,
       LastRun AS CurrentValue,
       @ExpectedLastRun AS ExpectedValue
FROM BILoad.LastRevshareRuntime WITH (NOLOCK)
```

### 8.3 View runtime history via progress log
```sql
SELECT lr.LastRun,
       pl.StepName,
       pl.StartDate AS LogTime
FROM BILoad.LastRevshareRuntime lr WITH (NOLOCK)
CROSS JOIN BILoad.Progress_Log pl WITH (NOLOCK)
WHERE pl.StepName LIKE '%LoadClosedPositionsAndAggregates_ADF%'
ORDER BY pl.StartDate DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PART-5265 (referenced in SQL comments) | Jira | Original ticket for ADF pipeline implementation by Noga (Feb 2026). Created BILoad schema including this sync table. |

No direct Confluence pages found for this object.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 1 Jira (ref only) | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BILoad.LastRevshareRuntime | Type: Table | Source: fiktivo/BILoad/Tables/BILoad.LastRevshareRuntime.sql*
