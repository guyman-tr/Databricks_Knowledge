# dbo.sp_WhoIsActive

> Third-party diagnostic stored procedure by Adam Machanic that provides detailed information about currently executing queries, blocking chains, and resource usage on the SQL Server instance.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns result set of active sessions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`sp_WhoIsActive` is a widely-used, open-source SQL Server diagnostic tool created by Adam Machanic. It provides real-time visibility into what queries are currently running on the server, who is blocked, what resources are being consumed, and other session-level diagnostics. It is NOT a custom business procedure - it is a DBA/operations utility deployed across many SQL Server instances.

The procedure exists to help DBAs and developers diagnose performance issues, identify blocking chains, and monitor long-running queries. It is the de facto replacement for `sp_who` and `sp_who2` with significantly richer output.

This is a third-party tool with ~61,000 tokens of code. It has no dependencies on any business tables in the RiskClassification database and is purely an operational utility.

---

## 2. Business Logic

N/A - third-party diagnostic tool. No business logic. See Adam Machanic's documentation for parameter reference.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

This procedure has extensive optional parameters for filtering and controlling output. Key parameters include `@filter`, `@filter_type`, `@not_filter`, `@show_sleeping_spids`, `@get_plans`, `@get_locks`, `@get_task_info`, `@output_column_list`, among many others. Full parameter documentation is available at the sp_WhoIsActive project site.

---

## 5. Relationships

### 5.1 References To (this object points to)

This procedure queries only system DMVs (sys.dm_exec_sessions, sys.dm_exec_requests, etc.). No business table references.

### 5.2 Referenced By (other objects point to this)

No other objects reference this procedure.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no business dependencies. It uses only SQL Server system DMVs.

### 6.1 Objects This Depends On

No business object dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Basic usage - show active queries
```sql
EXEC dbo.sp_WhoIsActive
```

### 8.2 Show queries with execution plans
```sql
EXEC dbo.sp_WhoIsActive @get_plans = 1
```

### 8.3 Show blocked sessions only
```sql
EXEC dbo.sp_WhoIsActive @show_sleeping_spids = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Third-party tool - see Adam Machanic's whoisactive.com for documentation.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 7.0/10 (Elements: 8.0/10, Logic: 2.0/10, Relationships: 8.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.sp_WhoIsActive | Type: Stored Procedure | Source: RiskClassification/dbo/Stored Procedures/dbo.sp_WhoIsActive.sql*
