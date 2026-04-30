# Wallet.GetLastReportRun

> Retrieves the most recent reconciliation run from the current FinanceReportRuns table for monitoring and status checking.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: Id, StartTime, EndTime, Parameters of the latest run |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetLastReportRun is the primary monitoring procedure for the current crypto wallet balance reconciliation system. It returns the single most recent row from Wallet.FinanceReportRuns, providing the run's ID, start/end times, and the JSON parameters that controlled its behavior (Threshold, ProcessAllRecords, RetryDays).

This procedure exists as the health-check endpoint for the active reconciliation pipeline. Operations teams and the application layer use it to verify that the daily reconciliation ran on schedule, check if it completed (EndTime != NULL), determine how long it took, and inspect the parameters used. It is the current-system counterpart to the legacy Wallet.GetLastReport.

The procedure is a pure READER with no side effects. It selects TOP 1 from Wallet.FinanceReportRuns ordered by Id DESC, leveraging the clustered PK index for an efficient single-row lookup. Unlike its legacy counterpart, this table is actively receiving new data (2 runs per day since October 2024), so the result changes daily.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple single-row retrieval procedure.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id (output) | bigint | NO | - | CODE-BACKED | Auto-incrementing PK of the most recent reconciliation run from Wallet.FinanceReportRuns. Currently in the 620+ range, incrementing by ~2 per day (two daily runs). |
| 2 | StartTime (output) | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when the most recent run began. Set by Wallet.CreateNewReportRun using GETUTCDATE(). Daily runs typically start at ~02:00 UTC. |
| 3 | EndTime (output) | datetime2(7) | YES | - | CODE-BACKED | Timestamp when the most recent run completed. NULL if the run is still in progress. Set by Wallet.UpdateReportRun using GETDATE(). In production, all historical runs have EndTime populated -- no abandoned runs exist. Note: uses GETDATE() (local time) vs GETUTCDATE() for StartTime, creating a potential timezone inconsistency. |
| 4 | Parameters (output) | varchar(max) | YES | - | CODE-BACKED | JSON-serialized execution parameters: {"Threshold": decimal, "ProcessAllRecords": bool, "RetryDays": int}. Threshold = balance difference tolerance; ProcessAllRecords = recheck all wallets or only changed; RetryDays = lookback window for retrying discrepant records. All production runs use: Threshold=0, ProcessAllRecords=false, RetryDays=1. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (query) | Wallet.FinanceReportRuns | SELECT | Reads the most recent row from the current reconciliation run table |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Called by the application layer directly.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetLastReportRun (procedure)
+-- Wallet.FinanceReportRuns (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.FinanceReportRuns | Table | SELECT TOP 1 ... ORDER BY Id DESC - reads the most recent run |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository. Called directly by the application.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute the procedure
```sql
EXEC Wallet.GetLastReportRun;
```

### 8.2 Check if the latest run completed and inspect parameters
```sql
DECLARE @Id BIGINT, @Start DATETIME2, @End DATETIME2, @Params VARCHAR(MAX);

SELECT TOP 1 @Id = Id, @Start = StartTime, @End = EndTime, @Params = Parameters
FROM Wallet.FinanceReportRuns WITH (NOLOCK)
ORDER BY Id DESC;

SELECT @Id AS LastRunId,
       @Start AS StartTime,
       @End AS EndTime,
       CASE WHEN @End IS NULL THEN 'IN PROGRESS' ELSE 'COMPLETED' END AS Status,
       DATEDIFF(SECOND, @Start, @End) AS DurationSeconds,
       JSON_VALUE(@Params, '$.Threshold') AS Threshold,
       JSON_VALUE(@Params, '$.ProcessAllRecords') AS ProcessAllRecords,
       JSON_VALUE(@Params, '$.RetryDays') AS RetryDays;
```

### 8.3 Show last 5 runs with duration
```sql
SELECT TOP 5 Id, StartTime, EndTime, Parameters,
       DATEDIFF(SECOND, StartTime, EndTime) AS DurationSeconds
FROM Wallet.FinanceReportRuns WITH (NOLOCK)
ORDER BY Id DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetLastReportRun | Type: Stored Procedure | Source: WalletBalancesReportDB/Wallet/Stored Procedures/Wallet.GetLastReportRun.sql*
