# History.DelayedOrderForClose

> Synonym aliasing the DB_Logs database table that records close orders that were delayed before execution, providing local History-schema access to the cross-database delayed order audit log.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Synonym |
| **Key Identifier** | N/A - pointer to [DB_Logs].[History].[DelayedOrderForClose] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.DelayedOrderForClose` is a synonym that maps the local `History` schema to `[DB_Logs].[History].[DelayedOrderForClose]` in the `DB_Logs` database. The `DB_Logs` database is a dedicated logging database on the same server (or a linked server) that stores operational event logs for the trading engine.

This synonym provides local procedures a stable reference to the delayed-close-order log without hardcoding the cross-database path. A "delayed order for close" is a close order that was queued but not immediately executed - for example, when the market is closed, when the position is temporarily locked, or when the order is pending a condition before execution. The target table records these delayed orders so the system can track, retry, or audit them.

The synonym pattern (local alias -> DB_Logs) is used consistently for all order-flow event tables: open orders, close orders, order failures, execution plans, and their change logs all follow this same synonym-to-DB_Logs pattern.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a synonym (pointer object). See the target table in `DB_Logs` for full business logic around the delayed order lifecycle.

---

## 3. Data Overview

N/A for Synonym. Data resides in the target: `[DB_Logs].[History].[DelayedOrderForClose]`.

---

## 4. Elements

N/A for Synonym. All elements are defined on the target table `[DB_Logs].[History].[DelayedOrderForClose]`.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym) | [DB_Logs].[History].[DelayedOrderForClose] | Synonym | Points to the delayed close order log in the DB_Logs database |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.DelayedOrderForClose (synonym)
+-- [DB_Logs].[History].[DelayedOrderForClose] (external table - DB_Logs database)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [DB_Logs].[History].[DelayedOrderForClose] | External Table | Target of this synonym - all queries routed to DB_Logs |

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

### 8.1 Query through the synonym

```sql
SELECT TOP 10 *
FROM History.DelayedOrderForClose WITH (NOLOCK)
```

### 8.2 Related DB_Logs synonyms for order flow

```sql
-- All DB_Logs order-flow synonyms in History schema
SELECT s.name, s.base_object_name
FROM sys.synonyms s WITH (NOLOCK)
WHERE SCHEMA_NAME(s.schema_id) = 'History'
  AND s.base_object_name LIKE '%DB_Logs%'
ORDER BY s.name
```

### 8.3 Check synonym definition

```sql
SELECT s.name, s.base_object_name
FROM sys.synonyms s WITH (NOLOCK)
WHERE s.name = 'DelayedOrderForClose'
  AND SCHEMA_NAME(s.schema_id) = 'History'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.5/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.DelayedOrderForClose | Type: Synonym | Source: etoro/etoro/History/Synonyms/History.DelayedOrderForClose.sql*
