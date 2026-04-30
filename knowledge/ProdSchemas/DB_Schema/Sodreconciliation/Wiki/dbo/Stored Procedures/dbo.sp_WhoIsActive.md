# dbo.sp_WhoIsActive

> Adam Machanic's well-known open-source SQL Server monitoring stored procedure. Shows currently executing queries with detailed session, wait, and resource information. This is a community tool, not custom code.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Author** | Adam Machanic (community/open-source) |
| **Website** | http://whoisactive.com |
| **Parameters** | ~30+ optional parameters controlling output and filtering |
| **Returns** | Result set of currently executing sessions with detailed diagnostics |

---

## 1. Business Meaning

`sp_WhoIsActive` is Adam Machanic's widely-adopted open-source SQL Server diagnostic stored procedure. It is the de facto standard for real-time monitoring of active queries on SQL Server instances. This is **not** custom eToro code -- it is a community tool installed in the Sodreconciliation database for DBA and developer use.

The procedure provides a comprehensive view of what is currently executing on the SQL Server, including:
- Active queries and their SQL text
- Wait types and durations
- Blocking chains
- CPU and I/O usage per session
- Tempdb usage
- Memory grants
- Login and host information

It is commonly used by the operations team to troubleshoot performance issues, identify blocking queries, and monitor long-running reconciliation processes.

---

## 2. Business Logic

### 2.1 Active Session Monitoring

**What**: Returns detailed information about currently executing sessions.

**Rules**:
- By default, shows only active requests (sessions currently executing a query)
- Can be configured via parameters to show sleeping sessions, system processes, etc.
- Supports filtering by database, login, host, and other criteria
- Can output to a destination table for historical tracking
- Supports delta mode to show resource usage changes between two snapshots

---

## 3. Data Overview

N/A - Dynamic monitoring procedure that returns real-time server state.

---

## 4. Elements

### 4.1 Key Parameters (subset)

| # | Parameter | Type | Default | Description |
|---|-----------|------|---------|-------------|
| 1 | @filter | sysname | '' | Filter by session attribute (e.g., database name, login) |
| 2 | @filter_type | varchar(10) | 'session' | What @filter applies to: session, program, database, login, host |
| 3 | @not_filter | sysname | '' | Exclusion filter |
| 4 | @show_own_spid | bit | 0 | Whether to include the caller's own session |
| 5 | @show_system_spids | bit | 0 | Whether to include system sessions |
| 6 | @get_full_inner_text | bit | 0 | Get full stored procedure text (not just current statement) |
| 7 | @get_plans | tinyint | 0 | Include execution plans (1=actual, 2=estimated) |
| 8 | @get_outer_command | bit | 0 | Get the outer calling command |
| 9 | @get_transaction_info | bit | 0 | Include transaction log usage details |
| 10 | @get_locks | bit | 0 | Include lock information |
| 11 | @find_block_leaders | bit | 0 | Highlight sessions at the head of blocking chains |
| 12 | @sort_order | varchar(500) | '[start_time] ASC' | Column and direction to sort results |
| 13 | @destination_table | varchar(4000) | '' | Table to INSERT results into (for historical capture) |
| 14 | @delta_interval | tinyint | 0 | Seconds between two snapshots for delta mode |

### 4.2 Key Result Set Columns (subset)

| # | Column | Description |
|---|--------|-------------|
| 1 | session_id | SQL Server session ID (SPID) |
| 2 | sql_text | Currently executing SQL statement |
| 3 | login_name | Login used by the session |
| 4 | wait_info | Current wait type and duration |
| 5 | CPU | CPU time consumed |
| 6 | reads | Logical reads performed |
| 7 | writes | Writes performed |
| 8 | tempdb_allocations | Tempdb pages allocated |
| 9 | blocking_session_id | SPID of the session causing blocking (if any) |
| 10 | status | Session status (running, suspended, sleeping) |
| 11 | start_time | When the current request started |
| 12 | database_name | Database context of the session |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Internal | sys.dm_exec_sessions | DMV read | Core session information |
| Internal | sys.dm_exec_requests | DMV read | Active request information |
| Internal | sys.dm_exec_sql_text | DMF read | SQL text of executing queries |
| Internal | sys.dm_exec_query_plan | DMF read | Execution plans (when requested) |

### 5.2 Referenced By (other objects point to this)

No database objects reference this procedure. Called ad-hoc by DBAs and developers.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.sp_WhoIsActive (stored procedure)
  └── SQL Server DMVs/DMFs (system objects)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| sys.dm_exec_sessions | DMV | Active session data |
| sys.dm_exec_requests | DMV | Active request data |
| sys.dm_exec_sql_text | DMF | SQL text retrieval |
| sys.dm_exec_query_plan | DMF | Execution plan retrieval |
| sys.dm_tran_active_transactions | DMV | Transaction info (when requested) |

### 6.2 Objects That Depend On This

None. This is a standalone diagnostic tool.

---

## 7. Technical Details

### 7.1 Origin and Versioning

- **Author**: Adam Machanic (b_machanic@hotmail.com)
- **Website**: http://whoisactive.com
- **License**: Open source (community contribution)
- **Typical size**: ~2000+ lines of T-SQL
- This is a widely-used community tool installed on thousands of SQL Server instances worldwide

### 7.2 Performance Notes

- The procedure queries system DMVs which are lightweight and do not block user queries
- Using @get_plans = 1 can add overhead as it retrieves full execution plans
- @get_locks = 1 can be expensive on servers with many concurrent locks
- @delta_interval causes the procedure to snapshot twice with a wait between, so it takes at least that many seconds to return

---

## 8. Sample Queries

### 8.1 Basic active query monitoring

```sql
EXEC dbo.sp_WhoIsActive;
```

### 8.2 Show active queries with execution plans

```sql
EXEC dbo.sp_WhoIsActive @get_plans = 1;
```

### 8.3 Find blocking chains

```sql
EXEC dbo.sp_WhoIsActive @find_block_leaders = 1, @sort_order = '[blocked_session_count] DESC';
```

### 8.4 Filter to a specific database

```sql
EXEC dbo.sp_WhoIsActive @filter = 'Sodreconciliation', @filter_type = 'database';
```

### 8.5 Capture to a logging table

```sql
EXEC dbo.sp_WhoIsActive @destination_table = 'dbo.WhoIsActiveLog';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources reference this community tool.

---

*Generated: 2026-04-11 | Quality: 6.0/10 (Elements: 6/10, Logic: 6/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Note: Community open-source tool by Adam Machanic, not custom eToro code.*
*Object: dbo.sp_WhoIsActive | Type: Stored Procedure | Source: Sodreconciliation/Sodreconciliation/dbo/Stored Procedures/dbo.sp_WhoIsActive.sql*
