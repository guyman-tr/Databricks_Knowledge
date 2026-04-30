# dbo.sp_WhoIsActive

> Third-party DBA diagnostic tool (v11.33, by Adam Machanic) that provides comprehensive information about currently running sessions, blocking chains, and resource consumption.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Primary output: result set of active sessions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is Adam Machanic's widely-used `sp_WhoIsActive` (v11.33, 2019-07-28), a comprehensive replacement for `sp_who` and `sp_who2`. It provides detailed real-time information about all active sessions on the SQL Server instance, including the executing SQL text, wait types, blocking chains, CPU usage, I/O statistics, and tempdb consumption.

This procedure has no business logic relationship to WalletDB's crypto wallet operations. It is a DBA operational tool installed for database performance monitoring and troubleshooting. It queries system DMVs (sys.dm_exec_requests, sys.dm_exec_sessions, sys.dm_exec_connections, etc.) and supports extensive filtering and output customization via parameters.

The procedure is open source, licensed under the terms at https://github.com/amachanic/sp_whoisactive/blob/master/LICENSE. Documentation is available at http://whoisactive.com.

---

## 2. Business Logic

No business logic - this is a system diagnostic tool. It provides session monitoring with extensive parameter-based filtering for sessions, programs, databases, logins, and hosts.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @filter (IN) | sysname | YES | '' | CODE-BACKED | Inclusive filter value. Combined with @filter_type to limit results (e.g., specific session ID, database name, login). |
| 2 | @filter_type (IN) | VARCHAR(10) | YES | 'session' | CODE-BACKED | Filter type: 'session', 'program', 'database', 'login', 'host'. Determines what @filter is compared against. |
| 3 | @not_filter (IN) | sysname | YES | '' | CODE-BACKED | Exclusive filter value. Sessions matching this are excluded from results. |
| 4 | @not_filter_type (IN) | VARCHAR(10) | YES | 'session' | CODE-BACKED | Exclusive filter type (same options as @filter_type). |
| 5 | @show_own_spid (IN) | BIT | YES | 0 | CODE-BACKED | Whether to include the calling session in results. Default 0 (exclude self). |

Note: The procedure has 30+ additional parameters for controlling output columns, sorting, blocking analysis, plan capture, and delta mode. Only the primary filter parameters are listed here. See http://whoisactive.com for full documentation.

---

## 5. Relationships

### 5.1 References To (this object points to)

This procedure references only system DMVs (sys.dm_exec_requests, sys.dm_exec_sessions, sys.dm_exec_connections, sys.dm_os_tasks, sys.dm_exec_sql_text, sys.dm_exec_query_plan, etc.).

### 5.2 Referenced By (other objects point to this)

No database objects reference this procedure. Called ad-hoc by DBAs.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no schema dependencies (system DMVs only).

### 6.1 Objects This Depends On

No schema dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Basic active session listing
```sql
EXEC dbo.sp_WhoIsActive
```

### 8.2 Filter to a specific database
```sql
EXEC dbo.sp_WhoIsActive @filter = 'WalletDB', @filter_type = 'database'
```

### 8.3 Show blocking chains with SQL text
```sql
EXEC dbo.sp_WhoIsActive @get_locks = 1, @find_block_leaders = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. External documentation: http://whoisactive.com

---

*Generated: 2026-04-15 | Enriched: - | Quality: 6.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.sp_WhoIsActive | Type: Stored Procedure | Source: WalletDB/dbo/Stored Procedures/dbo.sp_WhoIsActive.sql*
