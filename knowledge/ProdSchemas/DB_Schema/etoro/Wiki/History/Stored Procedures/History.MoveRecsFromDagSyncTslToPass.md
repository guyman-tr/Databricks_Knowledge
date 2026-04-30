# History.MoveRecsFromDagSyncTslToPass

> TSL pipeline Stage 3 transfer procedure - waits for History.SyncTSLSwitch to be populated (post-TABLE-SWITCH), then inserts its records in batches of 500 into the DAG downstream system via linked server ([synctsl].[synctsl].History.SyncTSL).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - polling/batch procedure executed as a job step |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.MoveRecsFromDagSyncTslToPass` is the linked-server INSERT variant for Stage 3 of eToro's TSL (Trailing Stop Loss) event pipeline. After `ALTER TABLE History.SyncTSL SWITCH TO History.SyncTSLSwitch` atomically transfers the pending TSL event batch to the switch table, this procedure reads from `History.SyncTSLSwitch` and pushes the records via linked server to `[synctsl].[synctsl].History.SyncTSL` - the DAG (Data Analytics Gateway or downstream analytics system) on the synctsl.database.windows.net Azure SQL server.

The procedure implements a polling wait pattern: it loops with a 20-second delay until `History.SyncTSLSwitch` contains rows (signaling that the TABLE SWITCH has occurred). Once data is present, it processes the rows in batches of 500 ordered by row number. This ensures reliable processing even if the table switch and the procedure execution are not perfectly synchronized.

Note: `History.MoveRecsFromHistorySyncTSLToPass_BCP` is the alternative transfer mechanism for the same pipeline stage, using BCP (Bulk Copy Program) instead of linked server INSERT. The two procedures represent different delivery strategies for the same data.

---

## 2. Business Logic

### 2.1 Poll-Wait Pattern

**What**: The procedure waits for SyncTSLSwitch to be populated before starting, polling every 20 seconds.

**Columns/Parameters Involved**: `History.SyncTSLSwitch`

**Rules**:
- WHILE NOT EXISTS (SELECT TOP 1 1 FROM History.SyncTSLSwitch) -> WAITFOR DELAY '00:00:20'
- Loop exits only when at least 1 row exists in History.SyncTSLSwitch
- No timeout - the procedure will wait indefinitely if SyncTSLSwitch is never populated
- Designed to be run after (or concurrently with) the TABLE SWITCH operation

### 2.2 Batch INSERT to Linked Server

**What**: Records are loaded into a temp table with row numbers, then inserted to the linked server in sequential batches of 500.

**Columns/Parameters Involved**: `#SyncTSLSwitch`, `@MinRecID`, `@MaxRecID`

**Rules**:
- SELECT ROW_NUMBER() OVER (ORDER BY ID) AS row_number, ID INTO #SyncTSLSwitch FROM History.SyncTSLSwitch WITH (NOLOCK)
- CREATE CLUSTERED INDEX cix ON #SyncTSLSwitch (row_number) - for efficient batch range scans
- WHILE @MinRecID <= @MaxRecID: INSERT 500 rows at a time WHERE row_number BETWEEN @MinRecID AND @MinRecID + 500
- @MinRecID += 500 per iteration
- Destination: [synctsl].[synctsl].History.SyncTSL - four-part name: linked server = synctsl, database = synctsl, schema = History, table = SyncTSL
- Columns transferred: ID, PositionID, StopLoss, SLManualVer, NextThresHold, IsBuy, DateInserted
- BEGIN TRY / BEGIN CATCH: on error THROW re-raises (no silent swallowing)
- Does NOT delete or truncate SyncTSLSwitch after inserting - the TRUNCATE is performed by the pipeline coordinator separately

**Diagram**:
```
[TABLE SWITCH completes: SyncTSLSwitch populated]
        |
        v
WHILE NOT EXISTS SyncTSLSwitch: WAITFOR DELAY 00:00:20
        |
        v
SELECT ROW_NUMBER() OVER (ORDER BY ID), ID INTO #SyncTSLSwitch
CREATE CLUSTERED INDEX cix ON #SyncTSLSwitch (row_number)
        |
        v
WHILE @MinRecID <= @MaxRecID:
  INSERT INTO [synctsl].[synctsl].History.SyncTSL
  FROM History.SyncTSLSwitch
  JOIN #SyncTSLSwitch WHERE row_number BETWEEN @MinRecID AND @MinRecID+500
  @MinRecID += 500
        |
        v
[All rows transferred to DAG linked server]
[TRUNCATE SyncTSLSwitch done by pipeline coordinator]
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|

No input or output parameters. Returns no result set. Executes as a fire-and-complete operation typically triggered by a SQL Agent job after the TABLE SWITCH.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | History.SyncTSLSwitch | Reads | Existence check (poll loop) + SELECT INTO #SyncTSLSwitch for batch processing |
| (body) | [synctsl].[synctsl].History.SyncTSL | Writes (INSERT via linked server) | Destination for all TSL event records on the DAG Azure SQL server |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| TSL pipeline coordinator (SQL Agent job) | - | Caller | Executed as a job step after the TABLE SWITCH; no callers found in SSDT repository |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.MoveRecsFromDagSyncTslToPass (procedure)
+-- History.SyncTSLSwitch (table - source: post-TABLE-SWITCH TSL event batch)
+-- [synctsl].[synctsl].History.SyncTSL (linked server table - destination DAG system)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.SyncTSLSwitch | Table | Poll existence check; SELECT source into temp table for batch processing |
| [synctsl].[synctsl].History.SyncTSL | Linked Server Table | INSERT destination on synctsl.database.windows.net Azure SQL |

### 6.2 Objects That Depend On This

No callers found in the etoro SSDT repository. Executed by the TSL pipeline job coordinator.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Implementation notes**:
- SET NOCOUNT ON applied
- Commented-out header: `---WITH EXECUTE AS OWNER` - indicates at some point execution context impersonation was considered for the linked server access
- Polling: WHILE NOT EXISTS ... WAITFOR DELAY '00:00:20' - blocks the session until SyncTSLSwitch has data
- Batch size: 500 rows per linked server INSERT (different from typical batch-loop patterns that use TOP; here it uses row_number range)
- THROW in CATCH: re-raises the error to the caller (different from many History procedures that use RAISERROR or print error message)
- Does NOT handle the post-transfer cleanup (TRUNCATE SyncTSLSwitch) - the pipeline coordinator does this step separately
- Alternative: History.MoveRecsFromHistorySyncTSLToPass_BCP provides the same transfer using BCP instead of linked server INSERT

---

## 8. Sample Queries

### 8.1 Check current SyncTSLSwitch row count before triggering the procedure

```sql
SELECT COUNT(*) AS PendingTSLRows
FROM History.SyncTSLSwitch WITH (NOLOCK)
```

### 8.2 Verify rows transferred to linked server

```sql
-- Check source still has rows (should be empty after successful transfer + truncate)
SELECT COUNT(*) AS SwitchRows FROM History.SyncTSLSwitch WITH (NOLOCK)
```

### 8.3 View the TSL records that will be transferred

```sql
SELECT TOP 10
    ID,
    PositionID,
    StopLoss,
    SLManualVer,
    NextThresHold,
    IsBuy,
    DateInserted
FROM History.SyncTSLSwitch WITH (NOLOCK)
ORDER BY ID ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9B, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 1 repo / 0 files | Corrections: 0 applied*
*Object: History.MoveRecsFromDagSyncTslToPass | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.MoveRecsFromDagSyncTslToPass.sql*
