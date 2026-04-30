# BILoad.Progress_Log

> Operational audit log that records each step of the ADF revenue-share pipeline execution, providing observability into pipeline progress, failures, and data volumes.

| Property | Value |
|----------|-------|
| **Schema** | BILoad |
| **Object Type** | Table |
| **Key Identifier** | ID (int, IDENTITY, clustered PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK on ID) |

---

## 1. Business Meaning

BILoad.Progress_Log is an append-only operational log table that tracks the execution steps of the ADF (Azure Data Factory) revenue-share pipeline. Each row represents a discrete pipeline action - a truncation, a data load safeguard exit, or a successful completion - with a human-readable step name, an optional row count, and a UTC timestamp.

This table exists to provide operational visibility into the ADF pipeline without requiring access to ADF monitoring tools or SQL Server logs. When the pipeline fails or produces unexpected results, operators can query this table to see exactly which steps executed, when they ran, and how many rows were affected. It is the primary troubleshooting tool for the BILoad ETL process.

Data flows in exclusively through BILoad.UpdateProgress_Log, which is called by multiple procedures throughout the pipeline: LoadClosedPositionsAndAggregates_ADF logs safeguard exits ("No data", "LastRun not sync") and successful completion ("Finished"), while TruncateLoadTable logs each dynamic TRUNCATE command it executes. The table grows monotonically and is never truncated or purged by the pipeline itself.

---

## 2. Business Logic

### 2.1 Pipeline Step Logging Pattern

**What**: Every significant pipeline action is logged as a row in this table via the UpdateProgress_Log wrapper procedure.

**Columns/Parameters Involved**: `StepName`, `RowUpdated`, `StartDate`

**Rules**:
- StepName is a free-text label identifying the action (e.g., "LoadClosedPositionsAndAggregates_ADF, Finished")
- RowUpdated is optional (NULL for non-DML steps like safeguard exits, populated for truncations or data loads)
- StartDate is always GETUTCDATE() at the moment of logging
- Logging is done via EXEC BILoad.UpdateProgress_Log, never direct INSERT

**Known StepName values from code**:
- `'LoadClosedPositionsAndAggregates_ADF,No data in BILoad.HistoryClosedPosition. Exit'` - safeguard: no ADF data loaded
- `'LoadClosedPositionsAndAggregates_ADF, {LastRunDate} LastRun not sync. Exit'` - safeguard: pipeline out of sync
- `'LoadClosedPositionsAndAggregates_ADF, Finished'` - successful completion of the 3-phase load
- `'TRUNCATE TABLE [BILoad].[{TableName}]'` - dynamic truncation of a BILoad staging table

**Diagram**:
```
ADF Pipeline Run
    |
    +-- TruncateLoadTable --> Log: "TRUNCATE TABLE [BILoad].[X]"
    |
    +-- ADF loads staging tables (external)
    |
    +-- LoadClosedPositionsAndAggregates_ADF
         |
         +-- No data? --> Log: "No data...Exit"
         +-- Not sync? --> Log: "LastRun not sync. Exit"
         +-- Success --> (process data) --> Log: "Finished"
```

---

## 3. Data Overview

Table is currently empty (0 rows). This indicates the ADF pipeline has not yet executed in this environment, or the log was recently cleared. Once the pipeline runs, rows accumulate chronologically.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate key. Clustered PK. Provides chronological ordering since IDs increase monotonically with each logged step. |
| 2 | StepName | varchar(100) | NO | - | CODE-BACKED | Human-readable label identifying the pipeline step or action. Populated by BILoad.UpdateProgress_Log from its @StepName parameter. Values include safeguard exit messages, TRUNCATE commands, and completion markers. Free-text format - not FK to a lookup table. |
| 3 | RowUpdated | int | YES | - | CODE-BACKED | Number of rows affected by the logged step. NULL for non-DML actions (safeguard exits, status messages). Populated when the calling procedure passes a row count (e.g., after TRUNCATE or data load). Currently always passed as NULL from TruncateLoadTable. |
| 4 | StartDate | datetime | NO | - | CODE-BACKED | UTC timestamp when the log entry was created. Set to GETUTCDATE() by UpdateProgress_Log. Provides the execution timeline for pipeline monitoring and troubleshooting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BILoad.UpdateProgress_Log | - | WRITER (INSERT) | Sole entry point for writing log rows - all pipeline steps call this procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BILoad.UpdateProgress_Log | Stored Procedure | WRITER - inserts log entries via direct INSERT |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ID | CLUSTERED | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ID | PRIMARY KEY | Unique identity for each log entry; ensures chronological ordering via IDENTITY |

---

## 8. Sample Queries

### 8.1 View recent pipeline activity
```sql
SELECT TOP 20 ID, StepName, RowUpdated, StartDate
FROM BILoad.Progress_Log WITH (NOLOCK)
ORDER BY ID DESC
```

### 8.2 Check if pipeline completed successfully in last 24 hours
```sql
SELECT TOP 1 StepName, StartDate
FROM BILoad.Progress_Log WITH (NOLOCK)
WHERE StepName LIKE '%Finished%'
ORDER BY StartDate DESC
```

### 8.3 Identify pipeline failures and safeguard exits
```sql
SELECT StepName,
       COUNT(*) AS Occurrences,
       MAX(StartDate) AS LastOccurrence
FROM BILoad.Progress_Log WITH (NOLOCK)
WHERE StepName LIKE '%Exit%' OR StepName LIKE '%not sync%'
GROUP BY StepName
ORDER BY LastOccurrence DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PART-5265 (referenced in SQL comments) | Jira | Original ticket for ADF pipeline implementation by Noga (Feb 2026). Created this progress logging table as part of the BILoad schema. |

No direct Confluence pages found for this object.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 1 Jira (ref only) | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BILoad.Progress_Log | Type: Table | Source: fiktivo/BILoad/Tables/BILoad.Progress_Log.sql*
