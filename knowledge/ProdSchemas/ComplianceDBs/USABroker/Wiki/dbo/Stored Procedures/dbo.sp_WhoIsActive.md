# dbo.sp_WhoIsActive

> Third-party SQL Server monitoring tool by Adam Machanic (v11.32, 2018) that provides detailed real-time information about currently executing queries, blocking chains, and resource usage.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns active session details |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.sp_WhoIsActive is Adam Machanic's widely-used open-source SQL Server monitoring tool ("Who Is Active?"). It provides a comprehensive real-time view of all currently executing sessions on the SQL Server instance, including query text, execution plans, blocking information, resource usage (CPU, reads, writes), wait types, and tempdb usage.

This is NOT custom business logic - it is a standard DBA/operations tool deployed on the USABroker database for performance monitoring and troubleshooting. It is used by the operations team to diagnose slow queries, identify blocking chains, and monitor server health.

The tool is free for personal, educational, and internal corporate use per its license (redistribution or sale is prohibited without the author's consent). Version 11.32 (2018-07-03).

---

## 2. Business Logic

### 2.1 Session Monitoring and Filtering

**What**: Comprehensive session monitoring with extensive filtering and output customization options.

**Columns/Parameters Involved**: `@filter`, `@filter_type`, `@not_filter`, `@output_column_list`, `@sort_order`

**Rules**:
- Filter types: session, program, database, login, host (supports % wildcards)
- Can show blocking chains, execution plans, query text, and resource metrics
- Supports output to a table via @destination_table parameter
- Default sort by elapsed time descending
- Documentation and updates: http://whoisactive.com

---

## 3. Data Overview

N/A for Stored Procedure. Output is real-time session data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @filter | sysname | YES | '' | CODE-BACKED | Inclusive filter value. Session ID, or wildcard pattern for program/database/login/host. Empty string disables. |
| 2 | @filter_type | varchar(10) | YES | 'session' | CODE-BACKED | Type of filter: session, program, database, login, host. |
| 3 | @not_filter | sysname | YES | '' | CODE-BACKED | Exclusive filter. Same types as @filter but excludes matching sessions. |

**Returns**: Dynamic result set with columns for session details, query text, execution metrics, blocking information, and resource usage. Column set varies based on @output_column_list parameter.

---

## 5. Relationships

### 5.1 References To (this object points to)

This procedure queries SQL Server DMVs (sys.dm_exec_sessions, sys.dm_exec_requests, etc.). No user tables referenced.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Used interactively by DBAs.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object depends only on SQL Server system DMVs.

### 6.1 Objects This Depends On

No user-table dependencies. Uses SQL Server Dynamic Management Views.

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

### 8.1 Show all active sessions

```sql
EXEC dbo.sp_WhoIsActive;
```

### 8.2 Filter by database

```sql
EXEC dbo.sp_WhoIsActive @filter = 'USABroker', @filter_type = 'database';
```

### 8.3 Show blocking chains with query plans

```sql
EXEC dbo.sp_WhoIsActive @get_plans = 1, @get_outer_command = 1, @find_block_leaders = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.sp_WhoIsActive | Type: Stored Procedure | Source: USABroker/dbo/Stored Procedures/dbo.sp_WhoIsActive.sql*
