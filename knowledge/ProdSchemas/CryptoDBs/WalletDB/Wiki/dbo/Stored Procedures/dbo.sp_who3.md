# dbo.sp_who3

> DBA utility procedure that returns active session information with SQL statement text, query plans, and execution details. An enhanced alternative to sp_who and sp_who2.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns active session details from DMVs |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a custom DBA diagnostic stored procedure that provides enhanced session monitoring similar to the built-in sp_who and sp_who2, but with additional details such as the currently executing SQL statement text, the query execution plan, and detailed execution metrics. It is designed for ad-hoc use by database administrators to diagnose performance issues, identify blocking, and review active workload.

This procedure has no business logic relationship to WalletDB's crypto wallet operations. It is a DBA operational tool installed for database performance monitoring and troubleshooting. It queries system Dynamic Management Views (DMVs) exclusively and does not read from or write to any user tables.

The procedure uses READ UNCOMMITTED transaction isolation level to minimize locking impact on the server while gathering diagnostic information. This means the results may include uncommitted data, which is acceptable for diagnostic purposes.

---

## 2. Business Logic

No business logic -- this is a DBA diagnostic tool. The procedure performs the following steps:

1. Sets transaction isolation level to READ UNCOMMITTED to avoid adding lock contention.
2. Queries sys.dm_exec_requests to get currently executing requests with status, wait type, CPU time, reads, writes, and other execution metrics.
3. Joins to sys.dm_exec_sessions to get session-level details such as login name, host name, program name, and database context.
4. Joins to sys.dm_exec_connections to get connection-level details such as client IP address and protocol.
5. Uses CROSS APPLY with sys.dm_exec_sql_text to retrieve the full SQL statement text for each active request.
6. Uses CROSS APPLY with sys.dm_exec_query_plan to retrieve the XML query execution plan for each active request.
7. Returns a consolidated result set with all active session information.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

This procedure takes no parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (none) | - | - | - | - | No input parameters. Returns a result set of active sessions. |

### Output Columns (typical)

| # | Column | Source DMV | Description |
|---|--------|-----------|-------------|
| 1 | session_id | sys.dm_exec_requests | The session ID (SPID) of the active request. |
| 2 | status | sys.dm_exec_requests | Current status of the request (running, runnable, suspended, etc.). |
| 3 | blocking_session_id | sys.dm_exec_requests | The session ID that is blocking this request, or 0 if not blocked. |
| 4 | wait_type | sys.dm_exec_requests | The current wait type if the session is waiting. |
| 5 | wait_time | sys.dm_exec_requests | Duration of the current wait in milliseconds. |
| 6 | cpu_time | sys.dm_exec_requests | CPU time consumed by the request in milliseconds. |
| 7 | total_elapsed_time | sys.dm_exec_requests | Total elapsed time since the request started in milliseconds. |
| 8 | reads | sys.dm_exec_requests | Number of logical reads performed by the request. |
| 9 | writes | sys.dm_exec_requests | Number of writes performed by the request. |
| 10 | logical_reads | sys.dm_exec_requests | Number of logical reads performed. |
| 11 | login_name | sys.dm_exec_sessions | The login name associated with the session. |
| 12 | host_name | sys.dm_exec_sessions | The client host name. |
| 13 | program_name | sys.dm_exec_sessions | The client program name. |
| 14 | database_name | sys.dm_exec_sessions | The current database context (via DB_NAME). |
| 15 | sql_text | sys.dm_exec_sql_text | The full SQL statement text being executed. |
| 16 | query_plan | sys.dm_exec_query_plan | The XML query execution plan for the active statement. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Referenced Object | Type | Relationship |
|-------------------|------|-------------|
| sys.dm_exec_requests | DMV | Reads active request details |
| sys.dm_exec_sessions | DMV | Reads session-level information |
| sys.dm_exec_connections | DMV | Reads connection-level information |
| sys.dm_exec_sql_text | DMF | Retrieves SQL statement text via CROSS APPLY |
| sys.dm_exec_query_plan | DMF | Retrieves XML query plan via CROSS APPLY |

### 5.2 Referenced By (other objects point to this)

No database objects reference this procedure. Called ad-hoc by DBAs for diagnostic purposes.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no schema dependencies (system DMVs only).

### 6.1 Objects This Depends On

No user-schema dependencies. References system DMVs and DMFs only:
- sys.dm_exec_requests
- sys.dm_exec_sessions
- sys.dm_exec_connections
- sys.dm_exec_sql_text (table-valued function)
- sys.dm_exec_query_plan (table-valued function)

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- Uses SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED to avoid adding lock pressure during diagnostics.
- Requires VIEW SERVER STATE permission to access DMVs.
- Read-only operation -- does not modify any data.
- Returns only currently active/executing requests (not idle sessions).

---

## 8. Sample Queries

### 8.1 View all active sessions
```sql
EXEC dbo.sp_who3
```

### 8.2 Use in troubleshooting context
```sql
-- Run sp_who3 to identify blocking chains and long-running queries
EXEC dbo.sp_who3
-- Then investigate specific session_id values from the output
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. This is a custom DBA diagnostic tool.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 6.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.sp_who3 | Type: Stored Procedure | Source: WalletDB/dbo/Stored Procedures/dbo.sp_who3.sql*
