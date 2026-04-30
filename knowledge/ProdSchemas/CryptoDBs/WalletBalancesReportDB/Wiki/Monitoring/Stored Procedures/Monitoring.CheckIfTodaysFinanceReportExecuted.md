# Monitoring.CheckIfTodaysFinanceReportExecuted

> Health-check procedure that verifies whether the daily crypto wallet balance reconciliation has completed today, returning a count of finished runs for use by Datadog and Splunk monitoring agents.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: single-column result set (Value INT) - count of completed runs today |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.CheckIfTodaysFinanceReportExecuted is an operational health-check procedure that answers one question: "Has the daily crypto wallet balance reconciliation run completed today?" It returns a count of completed reconciliation runs for the current calendar day, where 0 means the reconciliation has not yet run or has not finished, and any value >= 1 means at least one successful run exists.

This procedure exists because the wallet balance reconciliation is a critical daily process that compares balances across eToro (internal ledger), BitGo (custody provider), and Blox (portfolio tracker). If reconciliation fails to run, balance discrepancies could go undetected, creating financial risk. Without this monitoring check, operations teams would have no automated way to know that reconciliation completed on schedule.

The procedure is called externally by two monitoring agents - **Datadog** and **SplunkUser** - which have GRANT EXECUTE permissions. These agents poll the procedure on a schedule and raise alerts when the return value is 0 past the expected completion time (reconciliation normally runs daily around 02:00 UTC and completes within minutes). The procedure reads from `Wallet.FinanceReportRuns`, filtering on StartTime (cast to date) matching today and EndTime being NOT NULL (confirming the run finished).

---

## 2. Business Logic

### 2.1 Completion Detection Logic

**What**: The procedure determines run completion by requiring both a same-day start time AND a non-NULL end time.

**Columns/Parameters Involved**: `Wallet.FinanceReportRuns.StartTime`, `Wallet.FinanceReportRuns.EndTime`

**Rules**:
- `CAST(StartTime AS DATE) = CAST(GETDATE() AS DATE)` ensures only runs that started today are counted - runs from yesterday or earlier are excluded regardless of their completion status
- `EndTime IS NOT NULL` ensures only completed runs are counted - a run that started today but is still in progress (EndTime = NULL) is not counted
- Both conditions must be true simultaneously - a completed run from yesterday or an in-progress run from today both return 0
- The COUNT is wrapped in ISNULL(..., 0) as a defensive measure, though COUNT(*) already returns 0 for empty result sets
- Returns a single-row, single-column result set named `Value` containing the integer count

**Diagram**:
```
Datadog / Splunk
       |
       | EXEC Monitoring.CheckIfTodaysFinanceReportExecuted
       v
  +-----------------------------------------+
  | SELECT ISNULL(COUNT(*), 0) AS Value     |
  | FROM Wallet.FinanceReportRuns           |
  | WHERE StartTime = today                 |
  |   AND EndTime IS NOT NULL               |
  +-----------------------------------------+
       |
       v
  Value = 0 --> ALERT: Reconciliation not yet complete
  Value >= 1 --> OK: At least one run completed today
```

### 2.2 Timezone Consideration

**What**: The procedure uses GETDATE() (local server time) for date comparison, while the reconciliation engine writes StartTime using GETUTCDATE().

**Columns/Parameters Involved**: `Wallet.FinanceReportRuns.StartTime`

**Rules**:
- StartTime is stored in UTC (set by GETUTCDATE() in Wallet.CreateNewReportRun)
- This procedure compares against GETDATE() (server local time), which could cause a mismatch if the server timezone is significantly offset from UTC
- In practice, reconciliation runs around 02:00 UTC, so for most server timezones the date cast would match
- If the SQL Server is configured in UTC (common for cloud deployments), there is no mismatch

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Value (return column) | int | NO | - | CODE-BACKED | Count of completed reconciliation runs that started today. Computed as `ISNULL(COUNT(*), 0)` from `Wallet.FinanceReportRuns` where `CAST(StartTime AS DATE) = CAST(GETDATE() AS DATE) AND EndTime IS NOT NULL`. A value of 0 means no run has completed today (either not started or still in progress). A value >= 1 means at least one run finished successfully. Typical production values are 1-2 (the system normally executes 1-2 reconciliation runs per day around 02:00 UTC). Consumed by Datadog and Splunk monitoring agents to trigger alerts when the daily reconciliation is overdue. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (FROM clause) | Wallet.FinanceReportRuns | Direct read | Reads StartTime and EndTime to count completed runs for today. Uses IX_FinanceReportRuns__StartTime (StartTime DESC) index for efficient date filtering. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Datadog (external agent) | GRANT EXECUTE | Permission | Monitoring agent polls this procedure to detect whether the daily reconciliation completed. Triggers alerts when Value = 0 past the expected completion window. |
| SplunkUser (external agent) | GRANT EXECUTE | Permission | Log aggregation agent calls this procedure for operational dashboards and alerting on reconciliation health. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.CheckIfTodaysFinanceReportExecuted (procedure)
  +-- Wallet.FinanceReportRuns (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.FinanceReportRuns | Table | SELECT COUNT(*) with filter on StartTime (date) and EndTime (NOT NULL) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Datadog (external) | Monitoring Agent | Polls this procedure to verify daily reconciliation completion |
| SplunkUser (external) | Log Aggregation | Calls this procedure for operational monitoring dashboards |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. However, this procedure benefits from:
- `IX_FinanceReportRuns__StartTime` (NC, StartTime DESC) on `Wallet.FinanceReportRuns` for efficient date-based filtering.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute the monitoring check directly
```sql
EXEC Monitoring.CheckIfTodaysFinanceReportExecuted;
-- Returns: Value (int) - 0 if no completed run today, >= 1 if at least one completed
```

### 8.2 Equivalent inline query with additional context
```sql
SELECT ISNULL(COUNT(*), 0) AS CompletedToday,
       MIN(StartTime) AS EarliestRunToday,
       MAX(EndTime) AS LatestCompletionToday
FROM Wallet.FinanceReportRuns WITH (NOLOCK)
WHERE CAST(StartTime AS DATE) = CAST(GETDATE() AS DATE)
  AND EndTime IS NOT NULL;
```

### 8.3 Check reconciliation status for the last 7 days
```sql
SELECT CAST(StartTime AS DATE) AS RunDate,
       COUNT(*) AS CompletedRuns,
       MIN(StartTime) AS EarliestStart,
       MAX(EndTime) AS LatestEnd
FROM Wallet.FinanceReportRuns WITH (NOLOCK)
WHERE CAST(StartTime AS DATE) >= CAST(DATEADD(DAY, -7, GETDATE()) AS DATE)
  AND EndTime IS NOT NULL
GROUP BY CAST(StartTime AS DATE)
ORDER BY RunDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Searches for "CheckIfTodaysFinanceReportExecuted" and "Datadog wallet reconciliation" returned no relevant Confluence results.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.CheckIfTodaysFinanceReportExecuted | Type: Stored Procedure | Source: WalletBalancesReportDB/Monitoring/Stored Procedures/Monitoring.CheckIfTodaysFinanceReportExecuted.sql*
