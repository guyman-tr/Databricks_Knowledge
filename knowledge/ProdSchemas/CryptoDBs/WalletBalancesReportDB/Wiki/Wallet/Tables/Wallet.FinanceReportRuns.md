# Wallet.FinanceReportRuns

> Tracks individual executions of the crypto wallet balance reconciliation process, recording when each run started, ended, and what parameters controlled its behavior.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (PK + 1 NC) |

---

## 1. Business Meaning

Wallet.FinanceReportRuns is the run-level audit log for the crypto wallet balance reconciliation system. Each row represents a single execution of the reconciliation engine that compares wallet balances across eToro's internal ledger, BitGo (custody provider), and Blox (portfolio tracker). The table captures when the run started, when it completed, and the JSON-serialized parameters that governed its behavior (threshold tolerance, whether to reprocess all records, and retry window).

This table exists to provide operational visibility into the reconciliation pipeline. Without it, there would be no way to know when reconciliation last ran, how long it took, or what parameters it used. Operations teams use it to verify scheduled runs completed successfully and to diagnose timing issues when discrepancies are reported.

Data flows into this table exclusively through Wallet.CreateNewReportRun, which inserts a row at the start of each reconciliation run with the StartTime and Parameters. After the run completes, Wallet.UpdateReportRun sets the EndTime. Child records in Wallet.FinanceReportRecords reference this table via ReportId (FK) to link individual wallet-crypto reconciliation results back to their parent run. Wallet.GetLastReportRun retrieves the most recent run for monitoring. Wallet.UpdateReportRecords reads the Parameters JSON to determine processing behavior (e.g., whether to prune unchanged records).

---

## 2. Business Logic

### 2.1 Reconciliation Run Lifecycle

**What**: Each run follows a create-process-complete lifecycle tracked by StartTime and EndTime.

**Columns/Parameters Involved**: `Id`, `StartTime`, `EndTime`, `Parameters`

**Rules**:
- A run is created by Wallet.CreateNewReportRun within a transaction: StartTime is set to GETUTCDATE(), EndTime remains NULL
- Child FinanceReportRecords are inserted in the same transaction, all referencing the new run's Id
- After all reconciliation results are processed (via Wallet.UpdateReportRecords), Wallet.UpdateReportRun sets EndTime to GETDATE()
- All historical runs have EndTime populated (no abandoned runs in production data), indicating the pipeline has been reliable since inception

**Diagram**:
```
Wallet.CreateNewReportRun
       |
       | BEGIN TRAN
       | INSERT FinanceReportRuns (StartTime, Parameters)
       | INSERT FinanceReportRecords (child rows)
       | COMMIT
       v
  Run is "in progress" (EndTime = NULL)
       |
       | Application processes each wallet-crypto pair
       | Calls Wallet.UpdateReportRecords with results
       |
       v
Wallet.UpdateReportRun
       |
       | UPDATE SET EndTime = GETDATE()
       v
  Run is "complete"
```

### 2.2 Run Parameters (JSON Configuration)

**What**: Each run captures its execution parameters as a JSON string for auditability and runtime behavior control.

**Columns/Parameters Involved**: `Parameters`

**Rules**:
- Parameters is a JSON object with three fields: Threshold (decimal - balance difference tolerance), ProcessAllRecords (bool - whether to reprocess unchanged records), RetryDays (int - how far back to retry discrepant records)
- Wallet.UpdateReportRecords reads ProcessAllRecords from the JSON at runtime to decide whether to prune unchanged records from the result set
- Current production usage: Threshold=0, ProcessAllRecords=false, RetryDays=1 (only retry records changed within the last day)
- The first-ever run (Id=1) took ~2 hours; subsequent runs complete in seconds to minutes due to incremental processing

---

## 3. Data Overview

| Id | StartTime | EndTime | Parameters | Meaning |
|----|-----------|---------|------------|---------|
| 1 | 2024-10-27 10:24:03 | 2024-10-27 12:36:28 | {"Threshold":0,"ProcessAllRecords":false,"RetryDays":1} | First-ever reconciliation run -- took ~2 hours to process all wallets from scratch (initial baseline). |
| 2 | 2024-10-28 02:09:10 | 2024-10-28 02:09:53 | {"Threshold":0,"ProcessAllRecords":false,"RetryDays":1} | Second run -- only 43 seconds because incremental processing skipped unchanged wallets. Establishes the daily 02:00 UTC schedule. |
| 620 | 2026-04-15 02:03:23 | 2026-04-15 02:03:45 | {"Threshold":0,"ProcessAllRecords":false,"RetryDays":1} | Typical recent run -- 22 seconds, first of two daily runs. Fast because few wallets changed since previous day. |
| 621 | 2026-04-15 02:05:58 | 2026-04-15 02:06:17 | {"Threshold":0,"ProcessAllRecords":false,"RetryDays":1} | Second daily run -- 19 seconds, follows shortly after the first. Two runs per day is the standard pattern. |
| 622 | 2026-04-16 02:06:59 | 2026-04-16 02:11:29 | {"Threshold":0,"ProcessAllRecords":false,"RetryDays":1} | Most recent run -- 4.5 minutes, longer than typical which may indicate more wallets with balance changes. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint IDENTITY(1,1) | NO | IDENTITY | CODE-BACKED | Auto-incrementing primary key identifying each reconciliation run. Referenced as ReportId by Wallet.FinanceReportRecords (FK) to link individual wallet-crypto results back to their parent run. Also read by Wallet.UpdateReportRecords to extract Parameters JSON. |
| 2 | StartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when the reconciliation run began. Set to GETUTCDATE() by Wallet.CreateNewReportRun at the start of the transaction. Used by Wallet.GetLastReportRun (ORDER BY Id DESC) to identify the most recent run. Indexed (IX_FinanceReportRuns__StartTime DESC) for efficient latest-run lookups. |
| 3 | EndTime | datetime2(7) | YES | - | CODE-BACKED | Timestamp when the reconciliation run completed. NULL while the run is in progress; set to GETDATE() by Wallet.UpdateReportRun after all reconciliation results have been processed. In production, all 621 historical runs have EndTime populated -- no abandoned runs exist. Note: uses GETDATE() (local time) rather than GETUTCDATE(), creating a potential timezone inconsistency with StartTime. |
| 4 | Parameters | varchar(max) | YES | - | CODE-BACKED | JSON-serialized execution parameters that controlled this run's behavior. Structure: {"Threshold": decimal, "ProcessAllRecords": bool, "RetryDays": int}. Threshold = balance difference tolerance for flagging discrepancies; ProcessAllRecords = whether to recheck all wallets or only changed ones; RetryDays = lookback window for retrying discrepant records. Read at runtime by Wallet.UpdateReportRecords to determine pruning behavior. All production runs use identical parameters: Threshold=0, ProcessAllRecords=false, RetryDays=1. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.FinanceReportRecords | ReportId | FK (explicit) | Each wallet-crypto reconciliation result row links back to its parent run via FK__FinanceReportRecords__ReportId |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.FinanceReportRecords | Table | FK on ReportId - child rows link to parent run |
| Wallet.CreateNewReportRun | Stored Procedure | WRITER - inserts new run row at reconciliation start |
| Wallet.UpdateReportRun | Stored Procedure | MODIFIER - sets EndTime when run completes |
| Wallet.GetLastReportRun | Stored Procedure | READER - retrieves the most recent run for monitoring |
| Wallet.UpdateReportRecords | Stored Procedure | READER - reads Parameters JSON to control pruning behavior |
| Monitoring.CheckIfTodaysFinanceReportExecuted | Stored Procedure | READER - counts completed runs for today (StartTime date match + EndTime IS NOT NULL) for Datadog/Splunk monitoring |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FinanceReportRuns | CLUSTERED PK | Id ASC | - | - | Active |
| IX_FinanceReportRuns__StartTime | NC | StartTime DESC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_FinanceReportRuns | PRIMARY KEY | Clustered on Id. DATA_COMPRESSION = PAGE. Ensures each run has a unique sequential identifier. |

---

## 8. Sample Queries

### 8.1 Get the most recent reconciliation run
```sql
SELECT TOP 1 Id, StartTime, EndTime, Parameters,
       DATEDIFF(SECOND, StartTime, EndTime) AS DurationSeconds
FROM Wallet.FinanceReportRuns WITH (NOLOCK)
ORDER BY Id DESC;
```

### 8.2 Find runs that took longer than 5 minutes
```sql
SELECT Id, StartTime, EndTime, Parameters,
       DATEDIFF(SECOND, StartTime, EndTime) AS DurationSeconds
FROM Wallet.FinanceReportRuns WITH (NOLOCK)
WHERE DATEDIFF(SECOND, StartTime, EndTime) > 300
ORDER BY StartTime DESC;
```

### 8.3 Daily run count and average duration for the last 30 days
```sql
SELECT CAST(StartTime AS DATE) AS RunDate,
       COUNT(*) AS RunCount,
       AVG(DATEDIFF(SECOND, StartTime, EndTime)) AS AvgDurationSeconds
FROM Wallet.FinanceReportRuns WITH (NOLOCK)
WHERE StartTime >= DATEADD(DAY, -30, GETUTCDATE())
GROUP BY CAST(StartTime AS DATE)
ORDER BY RunDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Searches for "FinanceReportRuns" and "WalletBalancesReport" returned no Confluence results.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.FinanceReportRuns | Type: Table | Source: WalletBalancesReportDB/Wallet/Tables/Wallet.FinanceReportRuns.sql*
