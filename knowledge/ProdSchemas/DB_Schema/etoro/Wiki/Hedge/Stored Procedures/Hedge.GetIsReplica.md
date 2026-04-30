# Hedge.GetIsReplica

> SQL Server Always On replica detection procedure: queries sys.dm_hadr_database_replica_states to determine whether this database instance is running on a secondary replica. Returns the last_commit_time for this replica (NULL date 1900-01-01 = not a replica or HADR not enabled). Used by the hedge engine to detect secondary-replica execution context.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | None - no parameters; queries system DMVs |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Hedge.GetIsReplica detects whether the current SQL Server instance is a secondary replica in an Always On Availability Group (HADR). The hedge engine calls this at startup to understand its execution context:

- **Primary replica**: All operations are allowed (reads and writes).
- **Secondary replica**: Read-only. The hedge engine cannot write to local Feature tables; it must use OPENQUERY linked server writes to the primary (as in GetHBCEstimationsDiscrepencies_Child which writes via OPENQUERY to [AO-REAL-DB]).

The procedure name ("GetIsReplica") implies it returns whether this instance is a replica, but the actual return value is `last_commit_time` - the timestamp when this replica last committed a transaction from the primary's log stream. The caller infers replica status from this: a real timestamp = active HADR replica; the sentinel date `1/1/1900` = not a replica (or HADR disabled, or DMV access failed).

`WITH EXECUTE AS OWNER` is required because `sys.dm_hadr_database_replica_states` demands VIEW SERVER STATE permission, which the procedure's owner has but the calling login may not.

---

## 2. Business Logic

### 2.1 HADR Detection Three-Path Logic

**What**: The procedure handles three scenarios: HADR not enabled, HADR enabled but this DB not in an AG, and HADR enabled with this DB in an AG.

**Rules**:
- **Path 1 - HADR not enabled**: `SERVERPROPERTY('IsHadrEnabled') IS NULL` -> ELSE branch: return `CAST('1/1/1900' AS DATETIME2(7))` as `last_commit_time`. Sentinel value indicating non-HADR instance.
- **Path 2 - HADR enabled but DB not in replica states**: TRY block checks `sys.dm_hadr_database_replica_states WHERE database_id = DB_ID()`. If no rows exist: return sentinel `1/1/1900`.
- **Path 3 - HADR enabled, DB in AG**: Joins `sys.databases + sys.dm_hadr_database_replica_states + sys.availability_replicas` WHERE `d.name = DB_NAME() AND ars.replica_server_name = @@servername`. Returns actual `rc.last_commit_time`.
- **CATCH block**: Any error (e.g., permission denied on DMV despite EXECUTE AS OWNER) returns sentinel `1/1/1900`. Fail-safe: unknown replica state = assume non-replica behavior.

### 2.2 WITH EXECUTE AS OWNER (Elevated DMV Access)

**What**: The procedure impersonates the owner to access restricted system DMVs.

**Rules**:
- `sys.dm_hadr_database_replica_states` requires `VIEW SERVER STATE` permission.
- The procedure's schema owner (dbo or Hedge schema owner) has this permission.
- Calling logins (application service accounts) typically do not.
- `WITH EXECUTE AS OWNER` allows the procedure to access DMVs on behalf of any caller.

### 2.3 Sentinel Date 1/1/1900 = Non-Replica

**What**: The return value semantics: real date = replica, 1900-01-01 = not a replica.

**Rules**:
- Returns single row, single column: `last_commit_time DATETIME2(7)`.
- If `last_commit_time = '1900-01-01 00:00:00.0000000'`: HADR not active, or DB not in an AG. Treat as primary.
- If `last_commit_time` is a recent timestamp: this is an active secondary replica. The lag = NOW - last_commit_time.
- The hedge engine uses a recent timestamp to determine: (a) it is on a secondary, (b) how far behind the primary it is.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Output Columns** (returned resultset - single row, single column):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | last_commit_time | datetime2(7) | NO | - | CODE-BACKED | Last commit time for this replica from sys.dm_hadr_database_replica_states. Sentinel value 1900-01-01 = not a HADR replica (or HADR unavailable). Recent timestamp = active secondary replica. Replication lag = GETUTCDATE() - last_commit_time. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HADR check | sys.databases | System DMV Read | Database context lookup by DB_NAME(). |
| Replica state | sys.dm_hadr_database_replica_states | System DMV Read | Per-database replica state including last_commit_time. Requires VIEW SERVER STATE. |
| Replica metadata | sys.availability_replicas | System DMV Read | Replica server names for filtering to current server (@@servername). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge engine (external) | last_commit_time | Caller | Startup check: determines if running on secondary replica to switch to OPENQUERY write patterns. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetIsReplica (procedure)
├── sys.databases (system catalog)
├── sys.dm_hadr_database_replica_states (system DMV - requires VIEW SERVER STATE)
└── sys.availability_replicas (system DMV - requires VIEW SERVER STATE)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| sys.databases | System Catalog | Lookup by DB_NAME() to find database_id. |
| sys.dm_hadr_database_replica_states | System DMV | Replica status per database: last_commit_time, group_id, replica_id. |
| sys.availability_replicas | System DMV | Replica server names: filter to @@servername for current instance. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge engine (external) | Application | Startup replica detection; switches to OPENQUERY-based cursor writes when on secondary. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

`WITH EXECUTE AS OWNER` - elevated execution context for DMV access. TRY/CATCH - fail-safe returns sentinel on any error. No temp tables. No table data reads. Three code paths based on HADR state. Returns exactly 1 row always.

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC Hedge.GetIsReplica;
-- Returns 1 row: last_commit_time
-- If 1900-01-01: not a replica (or HADR disabled)
-- If recent timestamp: this is a secondary replica; lag = GETUTCDATE() - last_commit_time
```

### 8.2 Check replication lag directly

```sql
SELECT rc.last_commit_time,
       DATEDIFF(SECOND, rc.last_commit_time, GETUTCDATE()) AS LagSeconds
FROM   sys.databases d
JOIN   sys.dm_hadr_database_replica_states rc ON rc.database_id = d.database_id
JOIN   sys.availability_replicas ars ON rc.group_id = ars.group_id AND rc.replica_id = ars.replica_id
WHERE  d.name = DB_NAME()
AND    ars.replica_server_name = @@servername;
```

### 8.3 Determine if current instance is primary or secondary

```sql
DECLARE @LastCommit DATETIME2(7);
EXEC Hedge.GetIsReplica; -- capture via result
-- If last_commit_time = '1900-01-01' -> primary or standalone
-- If last_commit_time is recent (< 60 seconds ago) -> healthy secondary
-- If last_commit_time is old -> lagging secondary
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HedgeServer Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11710727812) | Confluence (DROD) | Always On replica detection for hedge engine execution context; secondary replica uses OPENQUERY write pattern. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,9B,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos searched / 0 files matched | Corrections: 0 applied*
*Object: Hedge.GetIsReplica | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetIsReplica.sql*
