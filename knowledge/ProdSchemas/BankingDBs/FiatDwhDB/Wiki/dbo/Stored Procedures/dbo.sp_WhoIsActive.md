# dbo.sp_WhoIsActive

> Third-party diagnostic stored procedure by Adam Machanic that provides detailed information about currently executing sessions/queries on the SQL Server instance.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Diagnostic tool - shows active sessions, blocking, wait stats |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

sp_WhoIsActive is a widely-used open-source diagnostic procedure created by Adam Machanic. It provides detailed real-time information about currently executing sessions on the SQL Server, including query text, wait types, blocking chains, CPU/IO usage, and execution plans. It is deployed in FiatDwhDB for DBA troubleshooting and performance monitoring.

This is NOT a business logic procedure - it's an administrative/diagnostic tool. It does not read from or write to any dbo schema tables.

---

## 2. Business Logic

No business logic. This is a system diagnostic tool that queries DMVs (Dynamic Management Views) like sys.dm_exec_sessions, sys.dm_exec_requests, sys.dm_os_waiting_tasks, etc.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

The procedure accepts many optional parameters for filtering and output control. Key parameters include:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @filter | sysname | YES | '' | CODE-BACKED | Filter active sessions by database, login, host, or program. |
| 2 | @filter_type | varchar(10) | YES | 'session' | CODE-BACKED | What to filter on: 'session', 'program', 'database', 'login', 'host'. |
| 3 | @not_filter | sysname | YES | '' | CODE-BACKED | Exclude sessions matching this filter. |
| 4 | @show_own_spid | bit | YES | 0 | CODE-BACKED | Whether to include the current session in results. |
| 5 | @show_sleeping_spids | tinyint | YES | 1 | CODE-BACKED | Whether to include sleeping sessions. |
| 6 | @get_plans | tinyint | YES | 0 | CODE-BACKED | Whether to include execution plans. |
| 7 | @get_full_inner_text | bit | YES | 0 | CODE-BACKED | Whether to return the full SQL batch text. |
| 8 | @sort_order | varchar(8000) | YES | '[start_time] ASC' | CODE-BACKED | Column(s) to sort results by. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This procedure queries SQL Server DMVs only. No dbo schema tables referenced.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

No dbo schema dependencies. Queries sys.dm_* DMVs.

### 6.1 Objects This Depends On

No dbo schema dependencies.

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

### 8.2 Show active sessions with execution plans
```sql
EXEC dbo.sp_WhoIsActive @get_plans = 1;
```

### 8.3 Filter by database
```sql
EXEC dbo.sp_WhoIsActive @filter = 'FiatDwhDB', @filter_type = 'database';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.sp_WhoIsActive | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.sp_WhoIsActive.sql*
