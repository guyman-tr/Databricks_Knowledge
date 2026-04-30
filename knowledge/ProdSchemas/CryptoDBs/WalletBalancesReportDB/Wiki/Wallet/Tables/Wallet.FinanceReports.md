# Wallet.FinanceReports

> Legacy run-level audit table for the original crypto wallet balance reconciliation system, tracking when each reconciliation execution started and ended.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Wallet.FinanceReports is the original run-tracking table for the crypto wallet balance reconciliation system. Each row represents one execution of the legacy reconciliation process. It stores only the start and end timestamps -- unlike its successor Wallet.FinanceReportRuns, it does not capture execution parameters.

This table was the primary reconciliation run tracker from April 2019 through December 2024. It was superseded by Wallet.FinanceReportRuns (introduced October 2024), which added a Parameters column for JSON-serialized execution configuration (Threshold, ProcessAllRecords, RetryDays). After a two-month overlap period (Oct-Dec 2024) where both systems ran in parallel, FinanceReports stopped receiving new rows. It remains in the schema for historical reference.

Data was created by Wallet.CreateNewReports (INSERT with StartTime) and completed by Wallet.UpdateReports (SET EndTime). Child reconciliation results were stored in Wallet.FinanceReportsBalances (and the legacy partition Wallet.FinanceReportsBalances_old), linked via ReportId. Wallet.GetLastReport retrieves the most recent run for monitoring.

---

## 2. Business Logic

### 2.1 Legacy Reconciliation Run Lifecycle

**What**: Simple start/end lifecycle for reconciliation runs without parameter tracking.

**Columns/Parameters Involved**: `Id`, `StartTime`, `EndTime`

**Rules**:
- Created by Wallet.CreateNewReports: inserts a row with StartTime = GETUTCDATE() in a transaction that also creates child FinanceReportsBalances rows
- Completed by Wallet.UpdateReports: sets EndTime = GETDATE() after processing
- 68 out of 2,094 runs (3.2%) have NULL EndTime, indicating runs that started but never completed -- likely due to errors or timeouts
- Runs typically started at ~02:00-05:40 UTC and took 15-120 minutes to complete
- This table stopped receiving new data after December 9, 2024, when the system migrated to Wallet.FinanceReportRuns

**Diagram**:
```
Wallet.CreateNewReports (LEGACY)          Wallet.CreateNewReportRun (CURRENT)
       |                                         |
       | INSERT FinanceReports                   | INSERT FinanceReportRuns
       | INSERT FinanceReportsBalances           | INSERT FinanceReportRecords
       |                                         |
       v                                         v
  2019-04 ---- overlap ---- 2024-12      2024-10 ---- ongoing ---->
                2024-10 to 2024-12
```

---

## 3. Data Overview

| Id | StartTime | EndTime | Meaning |
|----|-----------|---------|---------|
| 2 | 2019-04-04 05:40:36 | 2019-04-04 05:58:40 | Earliest surviving run -- took 18 minutes. The system was new and processing fewer wallets. Start time at 05:40 UTC differs from the later 02:00 UTC schedule. |
| 3 | 2019-04-05 05:40:37 | 2019-04-05 05:58:56 | Second run -- nearly identical timing, confirming a daily automated schedule at 05:40 UTC in the early period. |
| 2135 | 2024-12-05 02:12:56 | 2024-12-05 04:17:47 | Late-period run -- takes ~2 hours now (vs 18 min in 2019), reflecting wallet growth over 5 years. Schedule moved to 02:00 UTC. |
| 2139 | 2024-12-08 02:05:01 | 2024-12-08 04:11:31 | Penultimate run -- still functioning normally during the overlap with the new FinanceReportRuns system. |
| 2141 | 2024-12-09 02:13:05 | 2024-12-09 04:14:38 | Last-ever run in this table. After this date, all reconciliation tracking moved to Wallet.FinanceReportRuns. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint IDENTITY(1,1) | NO | IDENTITY | CODE-BACKED | Auto-incrementing primary key identifying each legacy reconciliation run. Referenced as ReportId by Wallet.FinanceReportsBalances and Wallet.FinanceReportsBalances_old (FK) to link child balance results back to their parent run. Gaps exist in the sequence (e.g., 2139 to 2141) suggesting occasional deleted or rolled-back runs. |
| 2 | StartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when the reconciliation run began. Set to GETUTCDATE() by Wallet.CreateNewReports at the start of the transaction. Originally ran at ~05:40 UTC (2019), later shifted to ~02:00 UTC. Used by Wallet.GetLastReport (ORDER BY Id DESC) to identify the most recent run. |
| 3 | EndTime | datetime2(7) | YES | - | CODE-BACKED | Timestamp when the reconciliation run completed. NULL while the run is in progress or if the run failed/was abandoned. Set to GETDATE() by Wallet.UpdateReports. 68 rows (3.2%) have NULL EndTime, indicating incomplete runs over the 5-year history. Note: uses GETDATE() (local time) rather than GETUTCDATE(), creating a potential timezone inconsistency with StartTime. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.FinanceReportsBalances_old | ReportId | FK (explicit) | Legacy child balance records link to their parent run via unnamed FK constraint |
| Wallet.FinanceReportsBalances | ReportId | Implicit | Partitioned child balance records reference the run ID (no explicit FK due to partitioning constraints) |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.FinanceReportsBalances_old | Table | FK on ReportId - legacy child balance records |
| Wallet.FinanceReportsBalances | Table | Implicit ref on ReportId - partitioned child balance records |
| Wallet.CreateNewReports | Stored Procedure | WRITER - inserts new run row at start of legacy reconciliation |
| Wallet.UpdateReports | Stored Procedure | MODIFIER - sets EndTime when legacy run completes |
| Wallet.GetLastReport | Stored Procedure | READER - retrieves the most recent legacy run |
| Wallet.GetWalletBalanceReport | Stored Procedure | READER/WRITER - reads run context and writes child balance rows |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FinanceReports | CLUSTERED PK | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_FinanceReports | PRIMARY KEY | Clustered on Id. DATA_COMPRESSION = PAGE. Ensures unique sequential run identifier. |

---

## 8. Sample Queries

### 8.1 Get the last legacy reconciliation run
```sql
SELECT TOP 1 Id, StartTime, EndTime,
       DATEDIFF(MINUTE, StartTime, EndTime) AS DurationMinutes
FROM Wallet.FinanceReports WITH (NOLOCK)
ORDER BY Id DESC;
```

### 8.2 Find legacy runs that never completed
```sql
SELECT Id, StartTime
FROM Wallet.FinanceReports WITH (NOLOCK)
WHERE EndTime IS NULL
ORDER BY StartTime DESC;
```

### 8.3 Compare legacy and current run systems
```sql
SELECT 'Legacy (FinanceReports)' AS System,
       COUNT(*) AS TotalRuns,
       MIN(StartTime) AS FirstRun,
       MAX(StartTime) AS LastRun
FROM Wallet.FinanceReports WITH (NOLOCK)
UNION ALL
SELECT 'Current (FinanceReportRuns)',
       COUNT(*),
       MIN(StartTime),
       MAX(StartTime)
FROM Wallet.FinanceReportRuns WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.3/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.FinanceReports | Type: Table | Source: WalletBalancesReportDB/Wallet/Tables/Wallet.FinanceReports.sql*
