# History.SbrEventsQueueTable

> Synonym aliasing the DB_Logs database table that stores the SBR (Stock-Based Reward or Share Buy-back) events queue, providing History-schema code a stable local reference to the cross-database SBR event processing queue.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Synonym |
| **Key Identifier** | N/A - pointer to [DB_Logs].[History].[SbrEventsQueueTable] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.SbrEventsQueueTable` is a synonym pointing to `[DB_Logs].[History].[SbrEventsQueueTable]` in the `DB_Logs` database. "SBR" likely refers to the Stock-Based Reward or Share Buy-back system - a feature where customers receive stock rewards or participate in buy-back programs.

The "QueueTable" suffix indicates this functions as a processing queue: events (stock reward eligibility, buy-back eligibility, corporate action notifications, or similar) are enqueued here for asynchronous processing by the SBR system. Records are typically inserted when a qualifying event occurs and dequeued/processed by a background service.

The synonym provides History-schema procedures a local reference for querying or joining against the SBR event queue without hardcoding the cross-database path.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a synonym (pointer object). See `[DB_Logs].[History].[SbrEventsQueueTable]` for the queue event structure.

---

## 3. Data Overview

N/A for Synonym. Data resides in the target: `[DB_Logs].[History].[SbrEventsQueueTable]`.

---

## 4. Elements

N/A for Synonym. All elements are defined on the target table in DB_Logs.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym) | [DB_Logs].[History].[SbrEventsQueueTable] | Synonym | Points to the SBR events queue in DB_Logs |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.SbrEventsQueueTable (synonym)
+-- [DB_Logs].[History].[SbrEventsQueueTable] (external table - DB_Logs database)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [DB_Logs].[History].[SbrEventsQueueTable] | External Table | Target of this synonym |

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

### 8.1 Query the SBR events queue

```sql
SELECT TOP 10 *
FROM History.SbrEventsQueueTable WITH (NOLOCK)
```

### 8.2 Check synonym definition

```sql
SELECT s.name, s.base_object_name
FROM sys.synonyms s WITH (NOLOCK)
WHERE s.name = 'SbrEventsQueueTable'
  AND SCHEMA_NAME(s.schema_id) = 'History'
```

### 8.3 List all DB_Logs synonyms in History schema

```sql
SELECT s.name, s.base_object_name
FROM sys.synonyms s WITH (NOLOCK)
WHERE SCHEMA_NAME(s.schema_id) = 'History'
  AND s.base_object_name LIKE '%DB_Logs%'
ORDER BY s.name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.5/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.SbrEventsQueueTable | Type: Synonym | Source: etoro/etoro/History/Synonyms/History.SbrEventsQueueTable.sql*
