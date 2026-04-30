# History.ExecutedCloseOrders

> Synonym aliasing the DB_Logs database table that stores successfully executed close orders, providing the History schema with a stable local name for querying the cross-database executed-close-order log.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Synonym |
| **Key Identifier** | N/A - pointer to [DB_Logs].[History].[ExecutedCloseOrders] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.ExecutedCloseOrders` is a synonym pointing to `[DB_Logs].[History].[ExecutedCloseOrders]` in the `DB_Logs` database. The target table records close orders that have been fully executed - meaning a customer's request to close a position has been processed by the trading engine and the position was actually closed.

This is the "success" counterpart in the order flow: `History.OrderForClose` captures orders submitted for close (pending execution), `History.ExecutedCloseOrders` captures those that completed successfully, and `History.OrdersFail` / `History.OrdersMarketFail` capture those that failed. Together, this set of synonyms forms the complete audit trail of close order lifecycle within DB_Logs.

The synonym exists to give History-schema code a clean, stable local name rather than repeating the cross-database path `[DB_Logs].[History].[ExecutedCloseOrders]` across multiple procedures and views.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a synonym (pointer object). See the target table in `DB_Logs` for full business logic. Companion synonyms: `History.OrderForClose` (submitted), `History.ExecutedOpenOrders` (executed opens), `History.OrdersFail` (failures).

---

## 3. Data Overview

N/A for Synonym. Data resides in the target: `[DB_Logs].[History].[ExecutedCloseOrders]`.

---

## 4. Elements

N/A for Synonym. All elements are defined on the target table `[DB_Logs].[History].[ExecutedCloseOrders]`.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym) | [DB_Logs].[History].[ExecutedCloseOrders] | Synonym | Points to the executed close order log in DB_Logs |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ExecutedCloseOrders (synonym)
+-- [DB_Logs].[History].[ExecutedCloseOrders] (external table - DB_Logs database)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [DB_Logs].[History].[ExecutedCloseOrders] | External Table | Target of this synonym |

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
FROM History.ExecutedCloseOrders WITH (NOLOCK)
```

### 8.2 Close order lifecycle - from submission to execution

```sql
-- OrderForClose = submitted, ExecutedCloseOrders = completed
SELECT TOP 5 'OrderForClose' AS Stage, * FROM History.OrderForClose WITH (NOLOCK)
-- Then compare with executed:
SELECT TOP 5 'ExecutedCloseOrders' AS Stage, * FROM History.ExecutedCloseOrders WITH (NOLOCK)
```

### 8.3 Check synonym definition

```sql
SELECT s.name, s.base_object_name
FROM sys.synonyms s WITH (NOLOCK)
WHERE s.name = 'ExecutedCloseOrders'
  AND SCHEMA_NAME(s.schema_id) = 'History'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.5/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ExecutedCloseOrders | Type: Synonym | Source: etoro/etoro/History/Synonyms/History.ExecutedCloseOrders.sql*
