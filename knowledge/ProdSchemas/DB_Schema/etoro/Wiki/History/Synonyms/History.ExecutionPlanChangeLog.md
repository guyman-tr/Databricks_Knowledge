# History.ExecutionPlanChangeLog

> Synonym aliasing the DB_Logs table that logs every change to an order execution plan, providing a stable local reference for querying the execution plan change audit trail across the trading engine.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Synonym |
| **Key Identifier** | N/A - pointer to [DB_Logs].[History].[ExecutionPlanChangeLog] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.ExecutionPlanChangeLog` is a synonym pointing to `[DB_Logs].[History].[ExecutionPlanChangeLog]` in the `DB_Logs` database. The target table records every change to an execution plan - the real-time routing and execution strategy that determines how orders for a given instrument are processed, which liquidity provider is used, and at what price levels.

An execution plan can change due to: provider switches, risk parameter updates, instrument configuration changes, or automated adjustments by the execution engine. Each change event is logged here to provide a complete audit trail of how execution routing evolved over time.

Companion synonyms `History.OpenExecutionPlan` (active execution plans) and `History.ExecutionPlanChangeLog` (changes to those plans) together form the execution plan audit system within DB_Logs.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a synonym (pointer object). See `[DB_Logs].[History].[ExecutionPlanChangeLog]` for the change event structure.

---

## 3. Data Overview

N/A for Synonym. Data resides in the target: `[DB_Logs].[History].[ExecutionPlanChangeLog]`.

---

## 4. Elements

N/A for Synonym. All elements are defined on the target table `[DB_Logs].[History].[ExecutionPlanChangeLog]`.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym) | [DB_Logs].[History].[ExecutionPlanChangeLog] | Synonym | Points to the execution plan change log in DB_Logs |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ExecutionPlanChangeLog (synonym)
+-- [DB_Logs].[History].[ExecutionPlanChangeLog] (external table - DB_Logs database)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [DB_Logs].[History].[ExecutionPlanChangeLog] | External Table | Target of this synonym |

### 6.2 Objects That Depend On This

No dependents found in local schema analysis.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Synonym.

### 7.2 Constraints

N/A for Synonym.

---

## 8. Sample Queries

### 8.1 Query execution plan changes

```sql
SELECT TOP 10 *
FROM History.ExecutionPlanChangeLog WITH (NOLOCK)
ORDER BY 1 DESC
```

### 8.2 Compare with current open execution plans

```sql
-- Active plans
SELECT TOP 5 * FROM History.OpenExecutionPlan WITH (NOLOCK)
-- Recent changes to plans
SELECT TOP 5 * FROM History.ExecutionPlanChangeLog WITH (NOLOCK)
```

### 8.3 Check synonym definition

```sql
SELECT s.name, s.base_object_name
FROM sys.synonyms s WITH (NOLOCK)
WHERE s.name = 'ExecutionPlanChangeLog'
  AND SCHEMA_NAME(s.schema_id) = 'History'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.5/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ExecutionPlanChangeLog | Type: Synonym | Source: etoro/etoro/History/Synonyms/History.ExecutionPlanChangeLog.sql*
