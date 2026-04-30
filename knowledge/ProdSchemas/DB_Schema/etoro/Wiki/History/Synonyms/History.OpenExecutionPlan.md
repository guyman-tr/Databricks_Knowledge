# History.OpenExecutionPlan

> Synonym aliasing the DB_Logs database table storing currently active execution plans for open positions, giving History-schema code a local reference to the live execution routing data.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Synonym |
| **Key Identifier** | N/A - pointer to [DB_Logs].[History].[OpenExecutionPlan] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.OpenExecutionPlan` is a synonym pointing to `[DB_Logs].[History].[OpenExecutionPlan]` in the `DB_Logs` database. The target table stores the active execution plans associated with currently open positions - the routing and execution strategy that governs how a given open position will be handled when operations occur on it (price updates, close attempts, stop-loss triggers, etc.).

An execution plan describes: which liquidity provider is handling the position, what execution parameters apply, and which execution route is active. When a position is opened, an execution plan is assigned. When the plan changes, a record is written to `History.ExecutionPlanChangeLog`. This table holds the "current" or "open" state - execution plans for positions that are still active.

The synonym gives History-schema procedures a local name for querying open execution plan data alongside other position and order data.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a synonym (pointer object). Companion synonym: `History.ExecutionPlanChangeLog` (change audit). See `[DB_Logs].[History].[OpenExecutionPlan]` for the full plan structure.

---

## 3. Data Overview

N/A for Synonym. Data resides in the target: `[DB_Logs].[History].[OpenExecutionPlan]`.

---

## 4. Elements

N/A for Synonym. All elements are defined on the target table `[DB_Logs].[History].[OpenExecutionPlan]`.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym) | [DB_Logs].[History].[OpenExecutionPlan] | Synonym | Points to the active execution plan table in DB_Logs |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.OpenExecutionPlan (synonym)
+-- [DB_Logs].[History].[OpenExecutionPlan] (external table - DB_Logs database)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [DB_Logs].[History].[OpenExecutionPlan] | External Table | Target of this synonym |

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

### 8.1 Query active execution plans

```sql
SELECT TOP 10 *
FROM History.OpenExecutionPlan WITH (NOLOCK)
```

### 8.2 Correlate open plans with change history

```sql
SELECT TOP 5 * FROM History.OpenExecutionPlan WITH (NOLOCK)
SELECT TOP 5 * FROM History.ExecutionPlanChangeLog WITH (NOLOCK)
```

### 8.3 Check synonym definition

```sql
SELECT s.name, s.base_object_name
FROM sys.synonyms s WITH (NOLOCK)
WHERE s.name = 'OpenExecutionPlan'
  AND SCHEMA_NAME(s.schema_id) = 'History'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.5/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.OpenExecutionPlan | Type: Synonym | Source: etoro/etoro/History/Synonyms/History.OpenExecutionPlan.sql*
