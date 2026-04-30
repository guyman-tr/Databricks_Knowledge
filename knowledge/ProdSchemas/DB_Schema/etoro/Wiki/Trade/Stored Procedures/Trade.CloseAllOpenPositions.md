# Trade.CloseAllOpenPositions

> Disabled legacy procedure that was intended to trigger end-of-week (EOW) fee processing across 10 SQL Agent jobs. Currently returns 0 immediately without executing any logic.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ActionType, @CloseAll (unused - procedure disabled) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CloseAllOpenPositions is a disabled legacy procedure that was originally part of the end-of-week (EOW) fee processing system. Its name is misleading - it did not literally close all open positions, but rather triggered 10 SQL Agent jobs (EOW0 through EOW9) that processed end-of-week fees across sharded position data.

The procedure was disabled by Yitzchak with the comment "RO Fee Disable Old EOW Fees" - the `RETURN 0` on the first executable line ensures no code runs. The EOW fee system has been replaced by a newer mechanism, making this procedure obsolete. It remains in the SSDT project for reference but is not called by any other procedure.

The procedure uses `WITH EXECUTE AS OWNER` to elevate permissions for starting SQL Agent jobs via `msdb.dbo.sp_start_job`.

---

## 2. Business Logic

### 2.1 Disabled EOW Fee Processing

**What**: Was intended to start 10 parallel SQL Agent jobs for end-of-week fee calculation.

**Columns/Parameters Involved**: `@ActionType`, `@CloseAll`, `@Mod`, `@ModResults`

**Rules**:
- RETURN 0 on first line - ALL subsequent logic is unreachable
- Would have started jobs EOW0 through EOW9 via msdb.dbo.sp_start_job
- Parameters suggest configurability: @ActionType (default 2), @CloseAll (default 1=yes), @Mod/@ModResults for partitioning/reporting
- None of these parameters are used since the procedure exits immediately

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ActionType | INT | NO | 2 | CODE-BACKED | Legacy parameter (unused - procedure disabled). Originally controlled the type of EOW fee action to perform. Default value of 2 suggests a specific action mode. |
| 2 | @CloseAll | BIT | NO | 1 | CODE-BACKED | Legacy parameter (unused - procedure disabled). Originally controlled whether to process all positions (1) or a subset. |
| 3 | @Mod | TINYINT | NO | 1 | CODE-BACKED | Legacy parameter (unused - procedure disabled). Likely a modulus value for sharding/partitioning the workload across jobs. |
| 4 | @ModResults | TINYINT | NO | 0 | CODE-BACKED | Legacy parameter (unused - procedure disabled). Likely a modulus result filter for shard selection. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (unreachable) | msdb.dbo.sp_start_job | EXEC | Would start SQL Agent jobs EOW0-EOW9 (code is unreachable due to RETURN 0) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (none) | - | - | No callers found - this is a disabled legacy procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CloseAllOpenPositions (procedure) [DISABLED]
+-- msdb.dbo.sp_start_job (system procedure, unreachable)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| msdb.dbo.sp_start_job | System procedure | EXEC (unreachable - starts EOW0-EOW9 agent jobs) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none) | - | No dependents |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH EXECUTE AS OWNER | Security | Impersonates the schema owner to have permission to start SQL Agent jobs |
| RETURN 0 at line 1 | Disabled | All logic after RETURN 0 is unreachable dead code |

---

## 8. Sample Queries

### 8.1 Check if EOW agent jobs still exist

```sql
SELECT name, enabled, date_created, date_modified
FROM   msdb.dbo.sysjobs WITH (NOLOCK)
WHERE  name LIKE 'EOW%'
ORDER BY name;
```

### 8.2 Verify procedure is disabled (first executable statement)

```sql
SELECT OBJECT_DEFINITION(OBJECT_ID('Trade.CloseAllOpenPositions'));
```

### 8.3 Check for any recent EOW fee activity

```sql
SELECT TOP 10 j.name, h.run_date, h.run_time, h.run_status
FROM   msdb.dbo.sysjobhistory h WITH (NOLOCK)
       INNER JOIN msdb.dbo.sysjobs j WITH (NOLOCK) ON j.job_id = h.job_id
WHERE  j.name LIKE 'EOW%'
ORDER BY h.run_date DESC, h.run_time DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CloseAllOpenPositions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CloseAllOpenPositions.sql*
