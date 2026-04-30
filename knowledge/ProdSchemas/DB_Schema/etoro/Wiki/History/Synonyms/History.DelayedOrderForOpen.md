# History.DelayedOrderForOpen

> Synonym aliasing the DB_Logs database table that records open orders that were delayed before execution, providing local History-schema access to the cross-database delayed open-order audit log.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Synonym |
| **Key Identifier** | N/A - pointer to [DB_Logs].[History].[DelayedOrderForOpen] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.DelayedOrderForOpen` is a synonym that maps the local `History` schema to `[DB_Logs].[History].[DelayedOrderForOpen]` in the `DB_Logs` database. This is the open-order counterpart to `History.DelayedOrderForClose`.

A "delayed order for open" is an open position order that was queued but not immediately executed - common when trading on instruments that have pre-market or at-open order types, when the market is outside trading hours, or when the order is pending a specific price trigger. The target table records these pending open orders, their creation time, requested parameters, and their eventual status.

The synonym enables History-schema procedures to query delayed open orders via the local name `History.DelayedOrderForOpen` rather than cross-database references. This is part of the broader pattern where `DB_Logs` serves as the operational event log for the trading engine, with the `History` schema providing stable local aliases via synonyms.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a synonym (pointer object). See the target table in `DB_Logs` for full business logic around the delayed order lifecycle.

---

## 3. Data Overview

N/A for Synonym. Data resides in the target: `[DB_Logs].[History].[DelayedOrderForOpen]`.

---

## 4. Elements

N/A for Synonym. All elements are defined on the target table `[DB_Logs].[History].[DelayedOrderForOpen]`.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym) | [DB_Logs].[History].[DelayedOrderForOpen] | Synonym | Points to the delayed open order log in the DB_Logs database |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.DelayedOrderForOpen (synonym)
+-- [DB_Logs].[History].[DelayedOrderForOpen] (external table - DB_Logs database)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [DB_Logs].[History].[DelayedOrderForOpen] | External Table | Target of this synonym - all queries routed to DB_Logs |

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
FROM History.DelayedOrderForOpen WITH (NOLOCK)
```

### 8.2 Compare delayed open vs close orders

```sql
SELECT 'DelayedOrderForOpen' AS Synonym, COUNT(*) AS RowCount
FROM History.DelayedOrderForOpen WITH (NOLOCK)
UNION ALL
SELECT 'DelayedOrderForClose', COUNT(*)
FROM History.DelayedOrderForClose WITH (NOLOCK)
```

### 8.3 Check synonym definition

```sql
SELECT s.name, s.base_object_name
FROM sys.synonyms s WITH (NOLOCK)
WHERE s.name = 'DelayedOrderForOpen'
  AND SCHEMA_NAME(s.schema_id) = 'History'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.5/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.DelayedOrderForOpen | Type: Synonym | Source: etoro/etoro/History/Synonyms/History.DelayedOrderForOpen.sql*
