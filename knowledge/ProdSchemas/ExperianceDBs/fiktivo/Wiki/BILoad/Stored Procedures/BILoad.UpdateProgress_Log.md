# BILoad.UpdateProgress_Log

> Wrapper procedure that inserts a single row into the BILoad.Progress_Log table, providing a centralized logging API for all ADF pipeline operations.

| Property | Value |
|----------|-------|
| **Schema** | BILoad |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Inserts into BILoad.Progress_Log |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BILoad.UpdateProgress_Log is a lightweight logging wrapper that provides a single, consistent entry point for recording ADF pipeline activity in the BILoad.Progress_Log table. Every pipeline step - truncations, safeguard exits, successful completions - logs through this procedure rather than inserting directly into Progress_Log.

This procedure exists to centralize logging logic. By routing all log entries through one procedure, the pipeline maintains a consistent format: the caller provides a step name and optional row count, and the procedure handles the timestamp (GETUTCDATE()). If the logging format or destination ever needs to change, only this procedure needs to be modified.

Called by BILoad.TruncateLoadTable (logging each dynamic TRUNCATE command) and AffiliateCommission.LoadClosedPositionsAndAggregates_ADF (logging safeguard exits and successful completion). All calls use EXEC - this procedure is never called from application code directly.

---

## 2. Business Logic

### 2.1 Centralized Logging Pattern

**What**: All pipeline steps log through this single procedure, which handles timestamping and formatting.

**Columns/Parameters Involved**: `@StepName`, `@RowUpdated`

**Rules**:
- @StepName is a free-text description of the pipeline action (max 100 chars)
- @RowUpdated defaults to NULL if not provided - used only when the caller has a meaningful row count
- StartDate is always set to GETUTCDATE() - the caller never controls the timestamp
- The INSERT is unconditional - every call produces exactly one row
- No error handling or transaction management - logging is fire-and-forget

**Known callers and their step names**:
- TruncateLoadTable: `'TRUNCATE TABLE [BILoad].[{TableName}]'` with RowUpdated = NULL
- LoadClosedPositionsAndAggregates_ADF (no data): `'LoadClosedPositionsAndAggregates_ADF,No data in BILoad.HistoryClosedPosition. Exit'`
- LoadClosedPositionsAndAggregates_ADF (not sync): `'LoadClosedPositionsAndAggregates_ADF, {date} LastRun not sync. Exit'`
- LoadClosedPositionsAndAggregates_ADF (success): `'LoadClosedPositionsAndAggregates_ADF, Finished'`

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StepName | varchar(100) | NO | - | CODE-BACKED | Human-readable label identifying the pipeline step being logged. Passed by the calling procedure. Examples: TRUNCATE commands, safeguard exit messages, completion markers. Inserted into Progress_Log.StepName. |
| 2 | @RowUpdated | int | YES | NULL | CODE-BACKED | Optional row count affected by the logged step. Defaults to NULL when the step does not produce a meaningful row count (e.g., safeguard exits). Currently always passed as NULL by TruncateLoadTable. Inserted into Progress_Log.RowUpdated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | BILoad.Progress_Log | WRITE (INSERT) | Inserts one row per call with StepName, RowUpdated, and GETUTCDATE() |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BILoad.TruncateLoadTable | - | Caller (EXEC) | Logs each dynamic TRUNCATE TABLE command |
| AffiliateCommission.LoadClosedPositionsAndAggregates_ADF | - | Caller (EXEC) | Logs safeguard exits (no data, not sync) and successful completion |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BILoad.UpdateProgress_Log (procedure)
+-- BILoad.Progress_Log (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BILoad.Progress_Log | Table | INSERT INTO - writes log entries |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BILoad.TruncateLoadTable | Stored Procedure | Calls via EXEC to log TRUNCATE operations |
| AffiliateCommission.LoadClosedPositionsAndAggregates_ADF | Stored Procedure | Calls via EXEC to log pipeline progress and exits |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Call the procedure to log a manual step
```sql
EXEC BILoad.UpdateProgress_Log 'Manual pipeline test', NULL
```

### 8.2 Call with a row count
```sql
EXEC BILoad.UpdateProgress_Log 'Manual data load', 1500
```

### 8.3 Verify the log entry was created
```sql
SELECT TOP 1 *
FROM BILoad.Progress_Log WITH (NOLOCK)
ORDER BY ID DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PART-5265 (referenced in SQL comments) | Jira | Original ticket for ADF pipeline implementation by Noga (Feb 2026). Created this logging procedure as part of the BILoad schema. |

No direct Confluence pages found for this object.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 1 Jira (ref only) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BILoad.UpdateProgress_Log | Type: Stored Procedure | Source: fiktivo/BILoad/Stored Procedures/BILoad.UpdateProgress_Log.sql*
