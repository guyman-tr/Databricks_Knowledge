# History.AsyncFailedSteps_temp

> Staging/scratch table with the same schema as History.AsyncFailedSteps but with no indexes, no primary key, and no current data - used for ad-hoc bulk migrations or analysis of async pipeline failure records.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY - no PK constraint, no indexes) |
| **Partition** | No |
| **Indexes** | None |

---

## 1. Business Meaning

History.AsyncFailedSteps_temp is a staging table that mirrors the schema of `History.AsyncFailedSteps` but without any constraints or indexes. It exists as a scratch space for DBA operations: bulk-loading, migrating, or analyzing subsets of async failure data without impacting the heavily-used primary failure table.

The table is currently empty (0 rows) and no stored procedures reference it - it is used exclusively through ad-hoc SQL by DBAs or operations teams. Common use cases include:
- Staging rows from `History.AsyncFailedSteps` before a bulk delete or archive operation
- Holding a subset of failure records for analysis without locking the live table
- Temporary destination during schema migration or data repair operations

The absence of a primary key and indexes makes it faster for bulk INSERT operations (no index maintenance overhead) at the cost of query performance - appropriate for a scratch/staging purpose.

---

## 2. Business Logic

### 2.1 Schema Mirror of AsyncFailedSteps

**What**: Identical column set to History.AsyncFailedSteps, allowing direct INSERT ... SELECT transfers.

**Rules**:
- Same 7 columns: ID (IDENTITY), ActionID, StepID, RetVal, ErrorID, Params (xml), Occurred
- Difference from parent table: no PRIMARY KEY constraint, no NOT FOR REPLICATION on identity, no indexes
- No procedures write to this table - used only via ad-hoc SQL
- Currently empty; populated only during specific DBA operations

---

## 3. Data Overview

0 rows. Table is empty. No data history available.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-generated identity. Unlike the parent table, this has no NOT FOR REPLICATION flag and no PK constraint. Used as a row identifier during staging operations. |
| 2 | ActionID | int | YES | - | CODE-BACKED | Type of async action that failed. Same as History.AsyncFailedSteps.ActionID. References Dictionary.Actions. |
| 3 | StepID | int | YES | - | CODE-BACKED | The step that failed within the action pipeline. Same as History.AsyncFailedSteps.StepID. References Dictionary.Steps. |
| 4 | RetVal | int | YES | - | CODE-BACKED | Return value from the failed step execution. Non-zero = failure. Same semantics as History.AsyncFailedSteps.RetVal. |
| 5 | ErrorID | int | YES | - | CODE-BACKED | Error code (always NULL in the parent table - same expected here). |
| 6 | Params | xml | YES | - | CODE-BACKED | XML parameters from the failed action - full business context. Same format as History.AsyncFailedSteps.Params. |
| 7 | Occurred | datetime | YES | - | CODE-BACKED | UTC timestamp of the failure. Same as History.AsyncFailedSteps.Occurred. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No FK constraints.

### 5.2 Referenced By (other objects point to this)

No stored procedures or other objects reference this table.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.AsyncFailedSteps_temp (table)
  - leaf node: no dependencies, no dependents
```

### 6.1 Objects This Depends On

None.

### 6.2 Objects That Depend On This

None. No stored procedures or views reference this table.

---

## 7. Technical Details

### 7.1 Indexes

No indexes defined.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (none) | - | No PK, FK, or check constraints. Bare staging table. |

---

## 8. Sample Queries

### 8.1 Stage a subset of failed steps for analysis
```sql
-- Stage failed registration actions (ActionID=8) from last 24 hours
INSERT INTO History.AsyncFailedSteps_temp (ActionID, StepID, RetVal, ErrorID, Params, Occurred)
SELECT ActionID, StepID, RetVal, ErrorID, Params, Occurred
FROM History.AsyncFailedSteps WITH (NOLOCK)
WHERE ActionID = 8
  AND Occurred >= DATEADD(hour, -24, GETUTCDATE());

-- Analyze the staged data
SELECT StepID, RetVal, COUNT(*) AS Cnt
FROM History.AsyncFailedSteps_temp WITH (NOLOCK)
GROUP BY StepID, RetVal
ORDER BY Cnt DESC;

-- Clean up when done
-- TRUNCATE TABLE History.AsyncFailedSteps_temp;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 7.8/10 (Elements: 8.5/10, Logic: 7.5/10, Relationships: 6.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.AsyncFailedSteps_temp | Type: Table | Source: etoro/etoro/History/Tables/History.AsyncFailedSteps_temp.sql*
