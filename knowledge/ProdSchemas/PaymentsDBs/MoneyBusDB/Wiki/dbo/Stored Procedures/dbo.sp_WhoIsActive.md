# dbo.sp_WhoIsActive

> Third-party open-source diagnostic stored procedure (by Adam Machanic, v11.35) that provides a real-time snapshot of active sessions, running queries, blocking chains, and resource consumption on the SQL Server instance.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Dynamic result set keyed by session_id |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`sp_WhoIsActive` is a widely adopted, open-source **SQL Server activity monitor** created by Adam Machanic. It replaces the built-in `sp_who` and `sp_who2` with a far richer, more configurable view of what is currently happening on the server. It is the de facto standard diagnostic tool used by DBAs and on-call engineers to troubleshoot performance issues, blocking, and long-running queries.

This procedure exists in MoneyBusDB to give operations and DBA teams instant visibility into server activity without needing to switch to `master` or install monitoring agents. During incidents - such as transaction processing slowdowns, withdrawal timeouts, or blocking chains - this is typically the first tool invoked to identify the root cause.

The procedure queries only SQL Server Dynamic Management Views (DMVs) such as `sys.dm_exec_requests`, `sys.dm_exec_sessions`, `sys.dm_exec_query_plan`, and related system views. It does NOT read from or write to any MoneyBusDB user tables. All data is gathered in a single pass (or two passes when using `@delta_interval`) with `READ UNCOMMITTED` isolation to minimize impact on the production workload.

---

## 2. Business Logic

### 2.1 Session Filtering and Visibility Control

**What**: A layered filtering system that controls which sessions appear in the output, allowing operators to focus on relevant activity.

**Columns/Parameters Involved**: `@filter`, `@filter_type`, `@not_filter`, `@not_filter_type`, `@show_own_spid`, `@show_system_spids`, `@show_sleeping_spids`

**Rules**:
- Inclusive filter (`@filter` + `@filter_type`) selects only sessions matching a session ID, program name, database name, login, or host. Supports `%` and `_` wildcards for all types except session.
- Exclusive filter (`@not_filter` + `@not_filter_type`) removes matching sessions from the result.
- Sleeping sessions are controlled by `@show_sleeping_spids`: 0 = active only, 1 = active + sleeping with open transactions, 2 = all sleeping included.
- The caller's own SPID is excluded by default (`@show_own_spid = 0`) to reduce noise.
- System SPIDs are excluded by default (`@show_system_spids = 0`).

### 2.2 Delta Measurement Mode

**What**: A two-snapshot comparison mode that measures actual resource consumption over a specified interval, rather than showing cumulative counters.

**Columns/Parameters Involved**: `@delta_interval`, `*_delta` output columns

**Rules**:
- When `@delta_interval > 0`, the procedure collects two snapshots separated by N seconds, then reports the difference in reads, writes, CPU, tempdb, context switches, and memory.
- Requests that started after the first snapshot show NULL for delta columns.
- This mode is essential for identifying queries that are actively consuming resources RIGHT NOW, as opposed to sessions with high cumulative counters from earlier work.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @filter | sysname (IN) | NO | '' | CODE-BACKED | Inclusive filter value. When non-empty, only sessions matching this value (per @filter_type) are returned. For session type, use a SPID number or 0/'' for all. For other types, supports `%` and `_` wildcards. |
| 2 | @filter_type | VARCHAR(10) (IN) | NO | 'session' | CODE-BACKED | Type of inclusive filter to apply. Valid values: 'session' (by SPID), 'program' (by application name), 'database' (by connected DB), 'login' (by login name), 'host' (by client hostname). |
| 3 | @not_filter | sysname (IN) | NO | '' | CODE-BACKED | Exclusive filter value. Sessions matching this value (per @not_filter_type) are removed from results. Same wildcard rules as @filter. |
| 4 | @not_filter_type | VARCHAR(10) (IN) | NO | 'session' | CODE-BACKED | Type of exclusive filter. Same valid values as @filter_type. |
| 5 | @show_own_spid | BIT (IN) | NO | 0 | CODE-BACKED | Whether to include the calling session in results. 0 = exclude (default, reduces noise), 1 = include. |
| 6 | @show_system_spids | BIT (IN) | NO | 0 | CODE-BACKED | Whether to include system sessions (background SQL Server processes). 0 = exclude (default), 1 = include. |
| 7 | @show_sleeping_spids | TINYINT (IN) | NO | 1 | CODE-BACKED | Controls sleeping session visibility. 0 = active requests only, 1 = also show sleeping sessions with open transactions (default), 2 = show all sleeping sessions regardless of transaction state. |
| 8 | @get_full_inner_text | BIT (IN) | NO | 0 | CODE-BACKED | Controls SQL text scope. 0 = show only the currently executing statement within the batch (default), 1 = show the full stored procedure or batch text. |
| 9 | @get_plans | TINYINT (IN) | NO | 1 | CODE-BACKED | Controls query plan retrieval. 0 = no plans, 1 = plan for the current statement offset (default), 2 = entire cached plan based on plan_handle. |
| 10 | @get_outer_command | BIT (IN) | NO | 0 | CODE-BACKED | Whether to retrieve the outer ad hoc query or RPC call text. 0 = skip (default), 1 = include in sql_command output column. |
| 11 | @get_transaction_info | BIT (IN) | NO | 0 | CODE-BACKED | Whether to include transaction log write info and transaction start time. 0 = skip (default), 1 = populate tran_start_time and tran_log_writes output columns. |
| 12 | @get_task_info | TINYINT (IN) | NO | 1 | CODE-BACKED | Controls task-level detail. 0 = no task info, 1 = lightweight mode showing top non-CXPACKET wait with blocker preference (default), 2 = full metrics including active task count, wait stats, physical I/O, context switches, and blocker info. |
| 13 | @get_locks | BIT (IN) | NO | 0 | CODE-BACKED | Whether to retrieve aggregated lock information in XML format. 0 = skip (default), 1 = populate locks output column with lock mode, locked object, and request counts. |
| 14 | @get_avg_time | BIT (IN) | NO | 0 | CODE-BACKED | Whether to calculate average elapsed time for past runs of the active query. 0 = skip (default), 1 = compute from plan handle + sql handle + offset combination. |
| 15 | @get_additional_info | BIT (IN) | NO | 0 | CODE-BACKED | Whether to retrieve non-performance session settings (text_size, language, isolation_level, etc.) and SQL Agent job info (job_name, step_name) if applicable. 0 = skip (default), 1 = populate additional_info XML column. |
| 16 | @find_block_leaders | BIT (IN) | NO | 0 | CODE-BACKED | Whether to walk the full blocking chain and count total SPIDs blocked by each session. 0 = skip (default), 1 = populate blocked_session_count and implicitly enable task_info level 1. |
| 17 | @delta_interval | TINYINT (IN) | NO | 0 | CODE-BACKED | Seconds to wait between two data snapshots for delta measurement. 0 = single snapshot (default), >0 = two-pass mode reporting differences in reads, writes, CPU, tempdb, context switches, and memory. |
| 18 | @output_column_list | VARCHAR(8000) (IN) | NO | '[dd%][session_id]...[%]' | CODE-BACKED | Bracket-delimited list of desired output columns in display order. Output is the intersection of enabled features and this list. Supports `%` wildcards in column names. Removing a column from the list may implicitly disable its feature. |
| 19 | @sort_order | VARCHAR(500) (IN) | NO | '[start_time] ASC' | CODE-BACKED | Bracket-delimited column name(s) with optional ASC/DESC for result sorting. Valid sort columns include session_id, reads, writes, CPU, tempdb_allocations, used_memory, blocked_session_count, start_time, login_name, database_name, and their _delta variants. |
| 20 | @format_output | TINYINT (IN) | NO | 1 | CODE-BACKED | Output formatting mode. 0 = raw values (best for programmatic consumption), 1 = formatted for variable-width fonts (default), 2 = formatted for fixed-width fonts (best for SSMS text output). |
| 21 | @destination_table | VARCHAR(4000) (IN) | NO | '' | CODE-BACKED | When non-empty, results are INSERT-ed into the specified table instead of returned as a result set. Table must already exist with a matching schema. Supports 1-, 2-, or 3-part table names. |
| 22 | @return_schema | BIT (IN) | NO | 0 | CODE-BACKED | Schema discovery mode. When 1, no data is collected; instead a CREATE TABLE statement matching the result set schema is returned via @schema OUTPUT parameter. Table name placeholder: `<table_name>`. |
| 23 | @schema | VARCHAR(MAX) (OUT) | YES | NULL | CODE-BACKED | OUTPUT parameter that receives the CREATE TABLE DDL when @return_schema = 1. Used to programmatically create destination tables for logging sp_WhoIsActive output over time. |
| 24 | @help | BIT (IN) | NO | 0 | CODE-BACKED | Built-in help mode. When 1, displays parameter descriptions and output column documentation instead of collecting session data. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references to user tables. It queries SQL Server DMVs exclusively:
- `sys.dm_exec_requests` - active request details
- `sys.dm_exec_sessions` - session information
- `sys.dm_exec_sql_text` - query text retrieval
- `sys.dm_exec_query_plan` - execution plan retrieval
- `sys.dm_exec_query_statistics_xml` - query stats
- `sys.dm_tran_session_transactions` - transaction info
- `sys.dm_os_tasks` / `sys.dm_os_waiting_tasks` - task-level metrics

### 5.2 Referenced By (other objects point to this)

No references found in the MoneyBusDB SSDT project. This procedure is called ad hoc by DBAs and monitoring tools, not by other database objects.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies on user objects. It depends solely on SQL Server system DMVs.

### 6.1 Objects This Depends On

No user object dependencies. Depends on SQL Server system views (DMVs).

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NULL parameter check | Validation | All 24 parameters are validated as non-NULL at entry; RAISERROR('Input parameters cannot be NULL', 16, 1) on violation |
| @filter_type validation | Validation | Must be one of: 'session', 'program', 'database', 'login', 'host'; RAISERROR on invalid value |

---

## 8. Sample Queries

### 8.1 Basic active session snapshot
```sql
EXEC dbo.sp_WhoIsActive
```

### 8.2 Find blocking chains with leader counts
```sql
EXEC dbo.sp_WhoIsActive
    @find_block_leaders = 1,
    @sort_order = '[blocked_session_count] DESC'
```

### 8.3 Delta measurement - identify top CPU consumers over 5 seconds
```sql
EXEC dbo.sp_WhoIsActive
    @delta_interval = 5,
    @output_column_list = '[session_id][login_name][database_name][CPU_delta][reads_delta][writes_delta][sql_text]',
    @sort_order = '[CPU_delta] DESC'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object in the MoneyBusDB context. Generic infrastructure pages mention sp_WhoIsActive as a standard DBA diagnostic tool but provide no MoneyBusDB-specific knowledge.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 6.3/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 2.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 24 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.sp_WhoIsActive | Type: Stored Procedure | Source: MoneyBusDB/dbo/Stored Procedures/dbo.sp_WhoIsActive.sql*
