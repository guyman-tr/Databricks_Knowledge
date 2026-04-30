# History.MoveRecsFromTradeSyncTSLToPass

> TSL pipeline Stage 2+3 orchestrator - switches the active History.SyncTSL table to the staging History.SyncTSLSwitch partition, triggers BCP transfer to Azure, and truncates the staging table on success.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - executes a complete TSL batch move cycle |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.MoveRecsFromTradeSyncTSLToPass` is the orchestrating procedure for Stage 2 and Stage 3 of eToro's TSL (Trailing Stop Loss) event pipeline. TSL events are initially written to `History.SyncTSL` in real time as trailing stop loss positions are updated. Periodically, this procedure is called (typically by a SQL Server Agent job) to move accumulated TSL events out of the active table and deliver them to the Azure SyncTSL database.

The procedure exists to decouple the write path (fast, live TSL event inserts into History.SyncTSL) from the transfer path (slower BCP export to Azure). By using a partition SWITCH, the move of records from the active table to the staging switch table is instantaneous and metadata-only - no row-by-row movement occurs. Only after the switch does the slower BCP transfer begin.

Data flow: (1) ALTER TABLE SWITCH atomically empties `History.SyncTSL` into `History.SyncTSLSwitch`; (2) `History.MoveRecsFromHistorySyncTSLToPass_BCP` is called to export `SyncTSLSwitch` to a network BCP file and import to Azure SQL; (3) on BCP success (return=1), TRUNCATE TABLE clears `SyncTSLSwitch`; (4) on BCP failure (return!=1), a severity-10 error is raised (informational, non-aborting) and the records remain in SyncTSLSwitch for investigation. The CATCH block captures any ALTER TABLE SWITCH errors and selects the error message.

---

## 2. Business Logic

### 2.1 Atomic Partition Switch (Stage 2)

**What**: Records are atomically "moved" from the live TSL table to the staging switch table using an ALTER TABLE SWITCH operation - no row-level movement, just metadata update.

**Columns/Parameters Involved**: `History.SyncTSL`, `History.SyncTSLSwitch`

**Rules**:
- `ALTER TABLE History.SyncTSL SWITCH TO History.SyncTSLSwitch` - atomic metadata-only operation
- After the switch, History.SyncTSL is empty (new TSL events will accumulate fresh); History.SyncTSLSwitch holds the batch to be transferred
- Requires that SyncTSLSwitch is empty before the switch can proceed (standard partition switch requirement)
- DEADLOCK_PRIORITY LOW: if a deadlock occurs during the switch, this procedure will be chosen as the deadlock victim, yielding to higher-priority transactions

**Diagram**:
```
History.SyncTSL          History.SyncTSLSwitch
(live, N rows)    SWITCH       (empty)
      |
      v
History.SyncTSL          History.SyncTSLSwitch
(empty, ready     <====       (N rows, ready
 for new writes)              for BCP transfer)
```

### 2.2 BCP Transfer and Cleanup (Stage 3)

**What**: After the switch, the BCP procedure transfers rows to Azure and the staging table is truncated on success.

**Columns/Parameters Involved**: `@ISBCPSuccessful`, `History.SyncTSLSwitch`

**Rules**:
- EXEC History.MoveRecsFromHistorySyncTSLToPass_BCP returns 1 on success, 0 on failure
- On success (=1): TRUNCATE TABLE History.SyncTSLSwitch - staging table is cleared and ready for next partition switch
- On failure (!=1): RAISERROR severity 10 (informational, does not abort the batch) - records remain in SyncTSLSwitch and the BCP file is retained for investigation
- The old BCP proc (History.SYN_MoveRecsFromDagSyncTslToPass_BCP) is commented out; the current proc is History.MoveRecsFromHistorySyncTSLToPass_BCP

**Diagram**:
```
EXEC MoveRecsFromHistorySyncTSLToPass_BCP
     |
     +-- @ISBCPSuccessful = 1? --> TRUNCATE SyncTSLSwitch (cleanup)
     |
     +-- @ISBCPSuccessful != 1? --> RAISERROR severity 10 (alert, non-aborting)
                                    SyncTSLSwitch retains rows for investigation
```

### 2.3 Error Handling

**What**: CATCH block captures errors from the ALTER TABLE SWITCH and surfaces the error message.

**Rules**:
- BEGIN TRY / END TRY wraps the entire body
- CATCH block: SELECT ERROR_MESSAGE() - returns the error to the caller/job output
- Note: CATCH block does NOT re-raise the error; it selects the message and exits, returning NULL (no RETURN statement in CATCH)
- @ISBCPSuccessful is initialized to NULL and stays NULL if the SWITCH fails (CATCH path never calls BCP)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (none) | - | - | - | - | - | This procedure has no parameters. It operates on fixed, well-known tables in the History schema and returns no output. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | History.SyncTSL | DDL operation | ALTER TABLE SWITCH source - the live TSL event accumulation table that is atomically emptied into SyncTSLSwitch |
| (body) | History.SyncTSLSwitch | DDL operation | ALTER TABLE SWITCH target and TRUNCATE target - staging table that holds the batch being transferred to Azure |
| (body) | History.MoveRecsFromHistorySyncTSLToPass_BCP | Procedure call | Called after the SWITCH to execute the actual BCP export to network file and import to Azure SQL SyncTSL database; returns 1 on success |

### 5.2 Referenced By (other objects point to this)

No callers found in SSDT repository. This procedure is expected to be invoked by a SQL Server Agent job on a scheduled interval.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.MoveRecsFromTradeSyncTSLToPass (procedure)
+-- History.SyncTSL (table)
+-- History.SyncTSLSwitch (table)
+-- History.MoveRecsFromHistorySyncTSLToPass_BCP (procedure)
      (exports SyncTSLSwitch -> BCP file -> Azure SQL SyncTSL database)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.SyncTSL | Table | ALTER TABLE SWITCH source - all current rows are atomically moved to SyncTSLSwitch |
| History.SyncTSLSwitch | Table | ALTER TABLE SWITCH target; TRUNCATE after successful BCP transfer |
| History.MoveRecsFromHistorySyncTSLToPass_BCP | Procedure | Executes BCP export+import to Azure; return value determines whether SyncTSLSwitch is truncated |

### 6.2 Objects That Depend On This

No dependents found in SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DEADLOCK_PRIORITY LOW | Session setting | This procedure yields to other transactions in deadlock resolution - ensures TSL batch jobs do not block real-time trading writes |
| Partition switch prerequisite | DDL | History.SyncTSLSwitch must be empty for ALTER TABLE SWITCH to succeed (standard SQL Server requirement) |
| Error 10 (severity) | RAISERROR | Severity 10 is informational and does not abort; BCP failure is reported but does not stop the SQL Agent job step |

---

## 8. Sample Queries

### 8.1 Check current row count in live TSL table before execution

```sql
SELECT COUNT(*) AS PendingTSLEvents
FROM History.SyncTSL WITH (NOLOCK)
```

### 8.2 Check staging switch table (should be empty before next run)

```sql
SELECT COUNT(*) AS SwitchTableRows
FROM History.SyncTSLSwitch WITH (NOLOCK)
```

### 8.3 Monitor recent TSL events pending transfer

```sql
SELECT TOP 10
    PositionID,
    StopLoss,
    IsBuy,
    DateInserted
FROM History.SyncTSL WITH (NOLOCK)
ORDER BY DateInserted DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (MoveRecsFromHistorySyncTSLToPass_BCP dependency) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.MoveRecsFromTradeSyncTSLToPass | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.MoveRecsFromTradeSyncTSLToPass.sql*
