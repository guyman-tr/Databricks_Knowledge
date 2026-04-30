# dbo.CheckExternalLogs

> Retrieves external trading system logs for open and close position actions within a specified date range, used to audit and investigate trading activity relayed through the affiliate platform's external log store.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Unknown |
| **Created** | Unknown |

---

## 1. Business Meaning

The affiliate platform records outbound calls to external trading systems (open position, close position) in dbo.ExternalLogs. These logs capture the full request/response lifecycle for trading actions initiated through affiliated channels, including client type, provider, execution timing, and status.

This procedure is a diagnostic and audit tool: it retrieves all open/close position log entries within a given time window so that support teams, developers, or compliance staff can investigate failed trades, latency issues, or suspicious activity. The WITH RECOMPILE option means the query plan is regenerated on every execution, ensuring optimal performance regardless of the date range passed (avoiding parameter sniffing for a wide-range vs. narrow-range query).

ClientType = 2 scopes the results to a specific integration channel (likely the affiliate-facing or IB trading client, as opposed to internal or other client types).

---

## 2. Business Logic

### 2.1 Date Range Filtering

**What**: Returns only log entries whose Date falls within the supplied time window.

**Columns/Parameters Involved**: `@FromDate`, `@ToDate`, `ExternalLogs.Date`

**Rules**:
- Both @FromDate and @ToDate are inclusive boundaries (WHERE Date BETWEEN @FromDate AND @ToDate or equivalent)
- The caller should pass datetime values with appropriate precision; time components are considered
- Large date ranges may return very high row counts; callers should apply appropriate ranges for operational queries

### 2.2 Action Type Filter

**What**: Only open and close position events are returned, not other action types stored in ExternalLogs.

**Columns/Parameters Involved**: `ActionString`

**Rules**:
- ActionString = 'openPosition' captures position-open requests sent to the trading system
- ActionString = 'closePosition' captures position-close requests
- All other ActionString values (e.g., updates, deposits) are excluded from results

### 2.3 Client Type Filter

**What**: Results are scoped to ClientType = 2.

**Columns/Parameters Involved**: `ClientType`

**Rules**:
- ClientType = 2 represents a specific external integration channel (precise meaning is system-specific)
- Other client types present in ExternalLogs are excluded from this procedure's results

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| 1 | @FromDate | IN | datetime | (required) | Start of the date range (inclusive). Filters ExternalLogs.Date >= @FromDate. |
| 2 | @ToDate | IN | datetime | (required) | End of the date range (inclusive). Filters ExternalLogs.Date <= @ToDate. |

### Result Set

| Column | Type | Description |
|--------|------|-------------|
| ID | (int/bigint) | Primary key of the ExternalLogs row |
| CID | (int/bigint) | Customer ID associated with the trading action |
| PositionID | (int/bigint) | The trading position identifier being opened or closed |
| ActionString | nvarchar | The action type: 'openPosition' or 'closePosition' |
| Date | datetime | Timestamp when the external log entry was recorded |
| ExecutionInterval | (numeric) | Time taken to execute the external call, used for latency analysis |
| StatusString | nvarchar | Response status from the external trading system |
| ClientType | int | Client integration type; always 2 in this result set |
| ExtendedInfo | nvarchar | Additional context or payload data from the external system |
| TimeStamp | (datetime/rowversion) | Row-level timestamp for ordering or change detection |
| ExtendedInfo2 | nvarchar | Secondary extended context field |
| ProviderID | int | The external trading provider identifier |
| IP | nvarchar | IP address of the client that initiated the action |

---

## 5. Relationships

### 5.1 Tables Written

None. Read-only procedure.

### 5.2 Tables Read

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.ExternalLogs | SELECT | Read with NOLOCK hint; filtered by Date range, ClientType=2, and ActionString IN ('closePosition','openPosition') |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.CheckExternalLogs (stored procedure)
+-- dbo.ExternalLogs (table) [SELECT WITH NOLOCK]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.ExternalLogs | Table | Source of external trading action log entries |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Support/audit tools | Application | Called during investigation of trading action failures or latency analysis |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- WITH RECOMPILE is specified; the execution plan is not cached. This avoids parameter sniffing issues when the same procedure is called with very different date ranges (e.g., one day vs. one month)
- WITH (NOLOCK) on ExternalLogs allows reads without shared locks, suitable for high-volume diagnostic queries that must not block writes
- The fixed filter ClientType = 2 AND ActionString IN ('closePosition', 'openPosition') means this procedure is purpose-built for position action auditing; it is not a general-purpose log viewer

---

## 8. Sample Queries

### 8.1 Retrieve position logs for a specific day

```sql
EXEC dbo.CheckExternalLogs
    @FromDate = '2026-04-01 00:00:00',
    @ToDate   = '2026-04-01 23:59:59';
```

### 8.2 Investigate a specific position across a week

```sql
EXEC dbo.CheckExternalLogs
    @FromDate = '2026-04-01',
    @ToDate   = '2026-04-07';
-- Filter in application layer or wrap in a CTE:
-- WHERE PositionID = 99999
```

### 8.3 Equivalent direct query (reference/debugging)

```sql
SELECT ID, CID, PositionID, ActionString, Date,
       ExecutionInterval, StatusString, ClientType,
       ExtendedInfo, TimeStamp, ExtendedInfo2, ProviderID, IP
FROM dbo.ExternalLogs WITH (NOLOCK)
WHERE Date        BETWEEN '2026-04-01' AND '2026-04-07'
  AND ClientType  = 2
  AND ActionString IN ('closePosition', 'openPosition')
ORDER BY Date DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10*
*Object: dbo.CheckExternalLogs | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.CheckExternalLogs.sql*
