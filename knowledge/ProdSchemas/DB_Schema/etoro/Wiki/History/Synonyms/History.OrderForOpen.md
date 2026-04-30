# History.OrderForOpen

> Synonym aliasing the DB_Logs database table that stores open orders submitted to the trading engine (pending execution), providing History-schema code a stable local name for the pending-open-order queue.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Synonym |
| **Key Identifier** | N/A - pointer to [DB_Logs].[History].[OrderForOpen] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.OrderForOpen` is a synonym pointing to `[DB_Logs].[History].[OrderForOpen]` in the `DB_Logs` database. The target table records open orders that have been received by the trading engine and are pending execution. This is the entry point in the open order lifecycle before the position is created.

The full open-order lifecycle uses these synonyms:
1. `History.OrderForOpen` - order received, pending execution
2. `History.ExecutedOpenOrders` - order executed, position created
3. `History.OrdersFail` / `History.OrdersMarketFail` - order failed before execution

The `DB_Logs` database functions as the operational event queue/log for the trading engine. The `History` schema synonyms give local procedures stable cross-database names.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a synonym (pointer object). See `[DB_Logs].[History].[OrderForOpen]` for the open order record structure.

---

## 3. Data Overview

N/A for Synonym. Data resides in the target: `[DB_Logs].[History].[OrderForOpen]`.

---

## 4. Elements

N/A for Synonym. All elements are defined on the target table `[DB_Logs].[History].[OrderForOpen]`.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym) | [DB_Logs].[History].[OrderForOpen] | Synonym | Points to the pending open order log in DB_Logs |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.OrderForOpen (synonym)
+-- [DB_Logs].[History].[OrderForOpen] (external table - DB_Logs database)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [DB_Logs].[History].[OrderForOpen] | External Table | Target of this synonym |

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

### 8.1 Query pending open orders

```sql
SELECT TOP 10 *
FROM History.OrderForOpen WITH (NOLOCK)
```

### 8.2 Open order lifecycle overview

```sql
SELECT TOP 3 * FROM History.OrderForOpen WITH (NOLOCK)
SELECT TOP 3 * FROM History.ExecutedOpenOrders WITH (NOLOCK)
SELECT TOP 3 * FROM History.OrdersFail WITH (NOLOCK)
```

### 8.3 Check synonym definition

```sql
SELECT s.name, s.base_object_name
FROM sys.synonyms s WITH (NOLOCK)
WHERE s.name = 'OrderForOpen'
  AND SCHEMA_NAME(s.schema_id) = 'History'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.5/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.OrderForOpen | Type: Synonym | Source: etoro/etoro/History/Synonyms/History.OrderForOpen.sql*
