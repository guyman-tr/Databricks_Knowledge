# dbo.sp_WhoIsActive

> Community-standard SQL Server monitoring procedure (by Adam Machanic, v11.30) that provides a comprehensive real-time snapshot of active sessions, running queries, blocking chains, and resource consumption - the primary tool for live database troubleshooting.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Primary output: result set of active sessions with query text, wait info, and resource metrics |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

sp_WhoIsActive is the industry-standard replacement for sp_who and sp_who2, created by Adam Machanic. It provides a real-time view of everything happening on the SQL Server instance - active queries, sleeping sessions with open transactions, blocking chains, query plans, wait statistics, and resource consumption. It is the first tool DBAs and developers reach for when investigating performance issues, blocking, or runaway queries.

This procedure exists in the RecurringManager database as a convenience deployment, allowing developers and DBAs to quickly diagnose issues without needing to switch to master or another database. It queries SQL Server DMVs (Dynamic Management Views) exclusively and has no dependencies on any RecurringManager business objects.

The procedure is called ad-hoc by DBAs, developers, and monitoring scripts. It reads from sys.dm_exec_requests, sys.dm_exec_sessions, sys.dm_exec_sql_text, sys.dm_exec_query_plan, sys.dm_tran_active_transactions, sys.dm_os_waiting_tasks, and other system DMVs. It never modifies data. The @destination_table parameter allows automated monitoring by writing snapshots to a history table for trend analysis.

---

## 2. Business Logic

### 2.1 Session Filtering and Visibility

**What**: Flexible inclusion/exclusion filters control which sessions appear in the output, with multiple filter dimensions.

**Columns/Parameters Involved**: `@filter`, `@filter_type`, `@not_filter`, `@not_filter_type`, `@show_own_spid`, `@show_system_spids`, `@show_sleeping_spids`

**Rules**:
- @filter_type supports: session (SPID), program, database, login, host - with wildcard support (% and _)
- @show_sleeping_spids controls sleeping session visibility: 0=hide all, 1=only those with open transactions (default), 2=show all
- @show_own_spid=0 (default) excludes the calling session from results
- @show_system_spids=0 (default) excludes system sessions
- Inclusive and exclusive filters can be combined for precise targeting

### 2.2 Data Collection Depth Control

**What**: Multiple toggle parameters control the depth of information collected, trading detail for performance.

**Columns/Parameters Involved**: `@get_plans`, `@get_task_info`, `@get_transaction_info`, `@get_locks`, `@get_avg_time`, `@get_additional_info`, `@get_full_inner_text`, `@get_outer_command`

**Rules**:
- @get_plans: 0=none, 1=statement-level plan (default), 2=full batch plan
- @get_task_info: 0=none, 1=top wait + blocker info (default), 2=full task metrics (I/O, context switches)
- Each additional feature adds DMV queries, increasing execution time
- @find_block_leaders walks the full blocking chain and counts downstream blocked SPIDs

### 2.3 Delta Mode

**What**: Captures two snapshots separated by a configurable interval and returns the deltas, showing activity RATE rather than cumulative totals.

**Columns/Parameters Involved**: `@delta_interval`

**Rules**:
- @delta_interval=0 (default) returns a single point-in-time snapshot
- When > 0, waits N seconds between two snapshots and calculates deltas for CPU, reads, writes, tempdb, context switches
- Useful for identifying which sessions are consuming the most resources RIGHT NOW vs. historically

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @filter | sysname | - | '' | CODE-BACKED | Inclusive filter value. When non-empty, only sessions matching this value (for the specified @filter_type) are returned. Supports % and _ wildcards for all types except session. Empty string disables the filter. |
| 2 | @filter_type | VARCHAR(10) | - | 'session' | CODE-BACKED | Dimension for @filter: 'session' (SPID number), 'program' (application name), 'database' (DB name), 'login' (login name), 'host' (client hostname). |
| 3 | @not_filter | sysname | - | '' | CODE-BACKED | Exclusive filter value. Sessions matching this value are removed from results. Same wildcard rules as @filter. Empty string disables exclusion. |
| 4 | @not_filter_type | VARCHAR(10) | - | 'session' | CODE-BACKED | Dimension for @not_filter. Same options as @filter_type. |
| 5 | @show_own_spid | BIT | - | 0 | CODE-BACKED | Whether to include the calling session in results. 0=exclude (default), 1=include. Usually excluded to avoid noise. |
| 6 | @show_system_spids | BIT | - | 0 | CODE-BACKED | Whether to include system sessions (SPID < 50). 0=exclude (default), 1=include. |
| 7 | @show_sleeping_spids | TINYINT | - | 1 | CODE-BACKED | Sleeping session visibility level. 0=hide all sleeping SPIDs, 1=only sleeping SPIDs with open transactions (default - catches uncommitted transaction holders), 2=show all sleeping SPIDs. |
| 8 | @get_full_inner_text | BIT | - | 0 | CODE-BACKED | 0=get only the currently executing statement within a batch (default), 1=get the full stored procedure or batch text. |
| 9 | @get_plans | TINYINT | - | 1 | CODE-BACKED | Query plan retrieval level. 0=no plans, 1=statement-level plan based on statement offset (default), 2=entire batch plan from plan_handle. |
| 10 | @get_outer_command | BIT | - | 0 | CODE-BACKED | Whether to retrieve the outer ad-hoc query or stored procedure call that initiated the current batch. 0=skip (default), 1=retrieve. |
| 11 | @get_transaction_info | BIT | - | 0 | CODE-BACKED | Whether to pull transaction log write information and transaction duration. 0=skip (default), 1=include. Adds overhead from querying dm_tran_active_transactions. |
| 12 | @get_task_info | TINYINT | - | 1 | CODE-BACKED | Task-level information depth. 0=none, 1=lightweight - top non-CXPACKET wait with blocker preference (default), 2=full - all task metrics including active tasks, wait stats, physical I/O, context switches, blocker info. |
| 13 | @get_locks | BIT | - | 0 | CODE-BACKED | Whether to retrieve lock information for each request, returned as aggregated XML. 0=skip (default), 1=include. Can be expensive on systems with many locks. |
| 14 | @get_avg_time | BIT | - | 0 | CODE-BACKED | Whether to calculate average execution time for past runs of the active query, based on plan_handle + sql_handle + offset combination. 0=skip (default), 1=include. |
| 15 | @get_additional_info | BIT | - | 0 | CODE-BACKED | Whether to retrieve non-performance session settings (text_size, language, date_format, isolation_level, lock_timeout, etc.) and SQL Agent job info (job_id, job_name, step_id, step_name) as XML subnodes. |
| 16 | @find_block_leaders | BIT | - | 0 | CODE-BACKED | Whether to walk the entire blocking chain and count total SPIDs blocked downstream by each session. 0=skip (default), 1=enable. Also implicitly enables @get_task_info level 1 if set to 0. |
| 17 | @delta_interval | TINYINT | - | 0 | CODE-BACKED | Seconds to wait between two data snapshots for delta calculation. 0=single snapshot (default). When > 0, returns delta columns showing resource consumption RATE (CPU_delta, reads_delta, writes_delta, etc.). |
| 18 | @output_column_list | VARCHAR(8000) | - | '[dd%][session_id]...[%]' | CODE-BACKED | Bracket-delimited list of desired output columns in desired order. Only columns associated with enabled features appear. Supports % wildcards within brackets. Default includes most common columns. |
| 19 | @sort_order | VARCHAR(500) | - | '[start_time] ASC' | CODE-BACKED | Output sort order using bracket-delimited column names with optional ASC/DESC. Supports all output columns. Default sorts by query start time ascending (longest-running first). |
| 20 | @format_output | TINYINT | - | 1 | CODE-BACKED | Output formatting mode. 0=raw values (best for @destination_table), 1=formatted for variable-width fonts (default - human-readable in SSMS grid), 2=formatted for fixed-width fonts (text output). |
| 21 | @destination_table | VARCHAR(4000) | - | '' | CODE-BACKED | Target table for INSERT instead of returning a result set. Supports 1/2/3-part table names. Empty string (default) returns a result set. Does not validate table existence or schema compatibility before insert. |
| 22 | @return_schema | BIT | - | 0 | CODE-BACKED | Schema discovery mode. 0=normal execution (default), 1=returns a CREATE TABLE statement via @schema OUTPUT that matches the result set schema for the current parameter combination. No data is collected. |
| 23 | @schema | VARCHAR(MAX) | YES | NULL OUTPUT | CODE-BACKED | OUTPUT parameter that receives the CREATE TABLE statement when @return_schema=1. Contains a `<table_name>` placeholder token for the actual table name. |
| 24 | @help | BIT | - | 0 | CODE-BACKED | When 1, displays built-in help documentation instead of executing. Shows parameter descriptions, output column descriptions, and usage examples. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (internal) | sys.dm_exec_requests | DMV Read | Active request information (wait type, CPU, reads, writes) |
| (internal) | sys.dm_exec_sessions | DMV Read | Session information (login, host, program) |
| (internal) | sys.dm_exec_sql_text | DMV Read | SQL text for running queries |
| (internal) | sys.dm_exec_query_plan | DMV Read | Execution plans for active queries |
| (internal) | sys.dm_os_waiting_tasks | DMV Read | Current wait information per task |
| (internal) | sys.dm_tran_active_transactions | DMV Read | Transaction info when @get_transaction_info=1 |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Typically called ad-hoc by DBAs or from monitoring scripts/jobs.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies on RecurringManager business objects. It queries only SQL Server system DMVs.

### 6.1 Objects This Depends On

No dependencies on user objects. Depends on SQL Server system DMVs (sys.dm_exec_*, sys.dm_os_*, sys.dm_tran_*).

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| EXECUTE AS 'dbo' | Execution Context | Runs under dbo context to ensure access to all DMVs regardless of caller's permissions |
| License | Legal | Free for personal, educational, and internal corporate use. Redistribution/sale prohibited without author consent. |

---

## 8. Sample Queries

### 8.1 Quick check - what is running right now
```sql
EXEC dbo.sp_WhoIsActive
```

### 8.2 Find blocking chains with full query text
```sql
EXEC dbo.sp_WhoIsActive
    @get_full_inner_text = 1,
    @get_plans = 1,
    @find_block_leaders = 1,
    @sort_order = '[blocked_session_count] DESC'
```

### 8.3 Monitor resource consumption deltas over 5 seconds
```sql
EXEC dbo.sp_WhoIsActive
    @delta_interval = 5,
    @output_column_list = '[session_id][login_name][database_name][CPU_delta][reads_delta][writes_delta][sql_text]',
    @sort_order = '[CPU_delta] DESC'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 2.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 24 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.sp_WhoIsActive | Type: Stored Procedure | Source: RecurringManager/dbo/Stored Procedures/dbo.sp_WhoIsActive.sql*
