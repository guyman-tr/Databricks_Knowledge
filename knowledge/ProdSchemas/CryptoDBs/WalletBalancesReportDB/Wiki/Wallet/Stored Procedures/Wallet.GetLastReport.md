# Wallet.GetLastReport

> Retrieves the most recent legacy reconciliation run from the FinanceReports table for monitoring and status checking.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: Id, StartTime, EndTime of the latest legacy run |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetLastReport is a simple monitoring procedure that returns the single most recent row from the legacy reconciliation run table (Wallet.FinanceReports). It provides a quick way for the application or operations tooling to check when the last legacy reconciliation ran and whether it completed (EndTime populated vs NULL).

This procedure exists as the primary health-check endpoint for the legacy reconciliation system. By returning the latest run's start/end times, callers can determine if reconciliation ran on schedule, how long it took, and whether it completed successfully. Without it, callers would need to query the table directly.

The procedure is a pure READER with no side effects. It selects TOP 1 from Wallet.FinanceReports ordered by Id DESC, leveraging the clustered PK index for an efficient single-row lookup. Since the legacy system stopped receiving new data in December 2024 (replaced by Wallet.FinanceReportRuns), this procedure now always returns the same historical row (Id=2141, the last-ever legacy run).

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
| 1 | Id (output) | bigint | NO | - | CODE-BACKED | Auto-incrementing PK of the most recent legacy reconciliation run from Wallet.FinanceReports. Always returns the highest Id value (currently 2141, the final legacy run from 2024-12-09). |
| 2 | StartTime (output) | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when the most recent legacy run began. Set by Wallet.CreateNewReports using GETUTCDATE(). For the final legacy run, this is 2024-12-09 02:13:05. |
| 3 | EndTime (output) | datetime2(7) | YES | - | CODE-BACKED | Timestamp when the most recent legacy run completed. NULL if the run is still in progress or was abandoned. Set by Wallet.UpdateReports using GETDATE(). For the final legacy run, this is 2024-12-09 04:14:38. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (query) | Wallet.FinanceReports | SELECT | Reads the most recent row from the legacy reconciliation run table |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Called by the application layer directly.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetLastReport (procedure)
+-- Wallet.FinanceReports (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.FinanceReports | Table | SELECT TOP 1 ... ORDER BY Id DESC - reads the most recent legacy run |

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
EXEC Wallet.GetLastReport;
```

### 8.2 Check if the last legacy run completed
```sql
DECLARE @Id BIGINT, @Start DATETIME2, @End DATETIME2;

SELECT TOP 1 @Id = Id, @Start = StartTime, @End = EndTime
FROM Wallet.FinanceReports WITH (NOLOCK)
ORDER BY Id DESC;

SELECT @Id AS LastRunId,
       @Start AS StartTime,
       @End AS EndTime,
       CASE WHEN @End IS NULL THEN 'IN PROGRESS / ABANDONED' ELSE 'COMPLETED' END AS Status,
       DATEDIFF(MINUTE, @Start, @End) AS DurationMinutes;
```

### 8.3 Compare legacy vs current system last runs
```sql
SELECT 'Legacy' AS System, Id, StartTime, EndTime
FROM (SELECT TOP 1 * FROM Wallet.FinanceReports WITH (NOLOCK) ORDER BY Id DESC) legacy
UNION ALL
SELECT 'Current', Id, StartTime, EndTime
FROM (SELECT TOP 1 * FROM Wallet.FinanceReportRuns WITH (NOLOCK) ORDER BY Id DESC) current_run;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetLastReport | Type: Stored Procedure | Source: WalletBalancesReportDB/Wallet/Stored Procedures/Wallet.GetLastReport.sql*
