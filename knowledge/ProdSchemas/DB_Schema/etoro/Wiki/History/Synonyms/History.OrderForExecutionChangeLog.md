# History.OrderForExecutionChangeLog

> Synonym aliasing the DB_Logs table that logs changes to orders that are in the execution queue, providing History-schema code a local reference to the execution-queue-order change audit trail.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Synonym |
| **Key Identifier** | N/A - pointer to [DB_Logs].[History].[OrderForExecutionChangeLog] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.OrderForExecutionChangeLog` is a synonym pointing to `[DB_Logs].[History].[OrderForExecutionChangeLog]` in the `DB_Logs` database. The target table records changes to orders while they are in the execution queue - capturing modifications made between when an order was submitted and when it was executed or failed.

Orders in eToro's trading engine can be modified while pending: stop-loss and take-profit rates can be updated, order parameters can be adjusted, or the execution routing can change while an order is queued. Each such modification generates a change record here. This table is used to audit "what was the order when it entered the queue vs what it looked like when it was executed?"

Companion tables: `History.OrderForClose` and `History.OrderForOpen` (the orders being tracked), and `History.ExecutionPlanChangeLog` (changes to execution plans, distinct from order changes).

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a synonym (pointer object). See `[DB_Logs].[History].[OrderForExecutionChangeLog]` for the change event structure.

---

## 3. Data Overview

N/A for Synonym. Data resides in the target: `[DB_Logs].[History].[OrderForExecutionChangeLog]`.

---

## 4. Elements

N/A for Synonym. All elements are defined on the target table `[DB_Logs].[History].[OrderForExecutionChangeLog]`.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym) | [DB_Logs].[History].[OrderForExecutionChangeLog] | Synonym | Points to the execution-queue order change log in DB_Logs |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.OrderForExecutionChangeLog (synonym)
+-- [DB_Logs].[History].[OrderForExecutionChangeLog] (external table - DB_Logs database)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [DB_Logs].[History].[OrderForExecutionChangeLog] | External Table | Target of this synonym |

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

### 8.1 Query order changes during execution queue

```sql
SELECT TOP 10 *
FROM History.OrderForExecutionChangeLog WITH (NOLOCK)
```

### 8.2 Check synonym definition

```sql
SELECT s.name, s.base_object_name
FROM sys.synonyms s WITH (NOLOCK)
WHERE s.name = 'OrderForExecutionChangeLog'
  AND SCHEMA_NAME(s.schema_id) = 'History'
```

### 8.3 Order + execution change context

```sql
SELECT TOP 5 * FROM History.OrderForOpen WITH (NOLOCK)
SELECT TOP 5 * FROM History.OrderForClose WITH (NOLOCK)
SELECT TOP 5 * FROM History.OrderForExecutionChangeLog WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.5/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.OrderForExecutionChangeLog | Type: Synonym | Source: etoro/etoro/History/Synonyms/History.OrderForExecutionChangeLog.sql*
