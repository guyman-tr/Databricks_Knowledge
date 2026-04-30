# Monitoring.GetRequestStatusLoop

> Detects requests that have the same status ID recorded an excessive number of times (above a configurable threshold), indicating a status update loop or retry storm.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns request/status pairs with excessive repetition counts |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetRequestStatusLoop identifies runaway status update patterns where the same status is being written repeatedly for the same request. This typically indicates a retry loop in the application - a service keeps trying to update a request's status and keeps getting the same result, generating hundreds of duplicate status records.

Without this procedure, status table bloat from retry storms would go undetected until storage or performance issues emerge. Early detection allows the engineering team to identify and fix the looping code path.

---

## 2. Business Logic

### 2.1 Status Repetition Detection

**What**: Finds request/status combinations that exceed a repetition threshold.

**Columns/Parameters Involved**: `@AmountThreshold`, `@HoursTimeframe`, `RequestStatusId`

**Rules**:
- Groups RequestStatuses by (RequestId, RequestStatusId) within the time window
- HAVING COUNT(*) > @AmountThreshold filters to abnormal repetition
- Default threshold: 100 repetitions of the same status for the same request
- Default window: last 3 hours

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AmountThreshold | INT | NO | 100 | CODE-BACKED | Minimum number of repetitions to trigger alert. Default 100. |
| 2 | @HoursTimeframe | INT | NO | 3 | CODE-BACKED | Lookback window in hours. Default 3 hours. |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RequestId | BIGINT | NO | - | CODE-BACKED | Request with excessive status repetitions. |
| 2 | RequestStatusId | TINYINT | NO | - | CODE-BACKED | The status ID being repeated excessively. |
| 3 | RowCount | INT | NO | - | CODE-BACKED | Number of times this status was recorded for this request. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.RequestStatuses | FROM (read) | Source of status records for loop detection |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetRequestStatusLoop (procedure)
  └── Wallet.RequestStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.RequestStatuses | Table | FROM - status repetition analysis |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check with default thresholds
```sql
EXEC Monitoring.GetRequestStatusLoop;
```

### 8.2 Lower threshold for sensitive detection
```sql
EXEC Monitoring.GetRequestStatusLoop @AmountThreshold = 20, @HoursTimeframe = 1;
```

### 8.3 View top status repetitions in last day
```sql
SELECT TOP 20 RequestId, RequestStatusId, COUNT(*) AS Reps
FROM Wallet.RequestStatuses WITH (NOLOCK)
WHERE Timestamp >= DATEADD(DAY, -1, GETUTCDATE())
GROUP BY RequestId, RequestStatusId
HAVING COUNT(*) > 10
ORDER BY Reps DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetRequestStatusLoop | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetRequestStatusLoop.sql*
