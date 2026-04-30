# Trade.EffectiveLeveragePositions_Job

> Transfers ELS hedge server change log records from the DBA staging database to ElsAzure via BCP bulk export, processing one summary batch at a time.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Processes and transfers ELS change log batches |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the data transfer companion to `Trade.EffectiveLeveragePositions`. After the ELS calculation procedure identifies positions that need hedge server reassignment and writes change records to the local DBA staging tables, this job procedure handles the physical transfer of those records to the remote ElsAzure database using BCP (Bulk Copy Program).

The procedure exists because the ELS calculation runs on the production trading database, but the actual hedge server change execution happens on a separate Azure-hosted ELS database. Direct cross-server writes via linked servers may face security restrictions, so BCP is used as a file-based transfer mechanism. This procedure runs as a SQL Agent Job, which has the necessary permissions to execute `xp_cmdshell` that services cannot invoke directly.

The procedure iterates through unprocessed summary IDs in `DBA.Trade.ELSPositionsHedgeServerChangeLog`, exports each batch to a BCP file on the D: drive, imports the file into the ElsAzure database, deletes the file, purges the staged records, and updates the summary log's EndTime. This loop continues until no more unprocessed summary batches remain.

---

## 2. Business Logic

### 2.1 BCP Export-Import Pipeline

**What**: File-based data transfer from DBA staging to ElsAzure using BCP command-line utility.

**Columns/Parameters Involved**: `@SQL`, `@filename`, `@SummaryID`

**Rules**:
- Export phase: BCP queryout exports selected columns from DBA.Trade.ELSPositionsHedgeServerChangeLog filtered by OperationSummaryID to a .bcp file at `D:\BCP\ELS_{SummaryID}.bcp`
- Import phase: BCP in loads the .bcp file into [Trade].[ELSPositionsHedgeServerChangeLog] on els-fg.database.windows.net (ElsAzure) using SQL authentication, batch size 100,000 rows, character mode (-c)
- Cleanup phase: DEL removes the .bcp file, then DELETE purges the staged records from DBA
- Summary update: EndTime set to GETUTCDATE() after each summary batch completes
- All xp_cmdshell calls use `no_output` to suppress console output

**Diagram**:
```
DBA.Trade.ELSPositionsHedgeServerChangeLog
  |
  v  [BCP queryout -> D:\BCP\ELS_{ID}.bcp]
  |
  v  [BCP in -> els-fg.database.windows.net / Els DB]
  |
  v  [DEL file, DELETE from DBA, UPDATE SummaryLog EndTime]
  |
  v  Next SummaryID (loop until none remain)
```

### 2.2 Summary-Based Batch Processing

**What**: Processes one ELS operation summary at a time in ascending order.

**Columns/Parameters Involved**: `@SummaryID`, `OperationSummaryID`

**Rules**:
- Selects the MIN(OperationSummaryID) from the DBA staging table
- Processes that entire summary batch (export, import, cleanup)
- Resets @SummaryID to NULL, then selects next MIN - ensures processing in chronological order
- Loop terminates when no more OperationSummaryID values remain in the staging table

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure takes no parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SQL | varchar(1000) | - | - | CODE-BACKED | Internal variable holding dynamically constructed BCP command strings for export, import, and file deletion operations. |
| 2 | @filename | nvarchar(200) | - | - | CODE-BACKED | BCP output file path, constructed as `D:\BCP\ELS_{SummaryID}.bcp`. Temporary file created during export and deleted after import. |
| 3 | @SummaryID | int | - | - | CODE-BACKED | Current operation summary batch being processed. Corresponds to ELSPositionsHedgeServerChangeSummaryLog.ID and ELSPositionsHedgeServerChangeLog.OperationSummaryID. Set to MIN(OperationSummaryID) each iteration. |

**Columns exported via BCP (from DBA.Trade.ELSPositionsHedgeServerChangeLog):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OperationSummaryID | int | NO | - | CODE-BACKED | Links to ELSPositionsHedgeServerChangeSummaryLog.ID. Groups change records by ELS calculation run. |
| 2 | PositionID | bigint | NO | - | CODE-BACKED | Position being reassigned to a different hedge server. |
| 3 | ADM_DATE | datetime | NO | - | CODE-BACKED | Timestamp when the change was recorded (GETUTCDATE at insert time). |
| 4 | FromHedgeServerID | int | NO | - | CODE-BACKED | Hedge server the position was on before reassignment. |
| 5 | ToHedgeServerID | int | NO | - | CODE-BACKED | Target hedge server the position should move to. |
| 6 | FromRootHedgeServerID | int | YES | - | CODE-BACKED | Root hedge server for copy-trading tree before reassignment. |
| 7 | ToRootHedgeServerID | int | YES | - | CODE-BACKED | Root hedge server for copy-trading tree after reassignment. |
| 8 | VolatilityThreshold | numeric | NO | - | CODE-BACKED | Instrument's volatility threshold at the time of evaluation. |
| 9 | EffectiveLeverage | decimal | NO | - | CODE-BACKED | Position's calculated effective leverage that triggered the reassignment. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT/DELETE | DBA.Trade.ELSPositionsHedgeServerChangeLog | READ + DELETE | Reads staged change records, exports via BCP, then deletes after successful transfer |
| UPDATE | dbo.ELSPositionsHedgeServerChangeSummaryLog | MODIFIER | Updates EndTime after each summary batch is fully transferred |
| BCP in target | ElsAzure.Els.Trade.ELSPositionsHedgeServerChangeLog | WRITER (remote) | Remote target for BCP import of change records |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Agent Job | Scheduled execution | Job | Runs as a SQL Agent Job to leverage xp_cmdshell permissions unavailable to application services |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.EffectiveLeveragePositions_Job (procedure)
+-- DBA.Trade.ELSPositionsHedgeServerChangeLog (table, cross-DB)
+-- dbo.ELSPositionsHedgeServerChangeSummaryLog (synonym -> ElsAzure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| DBA.Trade.ELSPositionsHedgeServerChangeLog | Table (cross-DB) | SELECT to read staged records, DELETE to purge after transfer |
| dbo.ELSPositionsHedgeServerChangeSummaryLog | Synonym | UPDATE to set EndTime after each batch transfer completes |
| ElsAzure.Els.Trade.ELSPositionsHedgeServerChangeLog | Table (remote) | BCP import target for change records |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.EffectiveLeveragePositions | Stored Procedure | Companion procedure that generates the change records this job transfers |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

**Security Note**: Uses `xp_cmdshell` for BCP operations. This requires sysadmin privileges or explicit proxy configuration. The procedure header comment notes it was created specifically because application services cannot call xp_cmdshell, hence it runs as a SQL Agent Job.

**Credential Note**: Contains hardcoded SQL authentication credentials for the ElsAzure database connection (`-U"InterestAdmin"` with password). This is a security concern for credential rotation.

---

## 8. Sample Queries

### 8.1 Run the ELS Transfer Job Manually

```sql
EXEC Trade.EffectiveLeveragePositions_Job
```

### 8.2 Check for Pending ELS Batches in DBA Staging

```sql
SELECT OperationSummaryID,
       COUNT(*) AS RecordCount,
       MIN(ADM_DATE) AS EarliestRecord,
       MAX(ADM_DATE) AS LatestRecord
  FROM DBA.Trade.ELSPositionsHedgeServerChangeLog WITH (NOLOCK)
 GROUP BY OperationSummaryID
 ORDER BY OperationSummaryID
```

### 8.3 View ELS Summary Log Status

```sql
SELECT TOP 20
       ID,
       StartTime,
       EndTime,
       Comments,
       DATEDIFF(SECOND, StartTime, EndTime) AS DurationSeconds
  FROM ELSPositionsHedgeServerChangeSummaryLog WITH (NOLOCK)
 ORDER BY ID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.EffectiveLeveragePositions_Job | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.EffectiveLeveragePositions_Job.sql*
