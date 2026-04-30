# History.ExecutedOpenOrders

> Synonym aliasing the DB_Logs database table that stores successfully executed open orders, providing the History schema with a stable local name for the cross-database executed-open-order audit log.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Synonym |
| **Key Identifier** | N/A - pointer to [DB_Logs].[History].[ExecutedOpenOrders] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.ExecutedOpenOrders` is a synonym pointing to `[DB_Logs].[History].[ExecutedOpenOrders]` in the `DB_Logs` database. The target table records open orders that have been fully executed - a customer submitted a request to open a position, the trading engine processed it, and the position was successfully opened.

This is the "success" counterpart in the open order flow: `History.OrderForOpen` captures orders submitted for open (pending execution), and `History.ExecutedOpenOrders` captures those that completed successfully. Orders that failed are captured in `History.OrdersFail` / `History.OrdersMarketFail`.

The `DB_Logs` database acts as the operational event store for the trading engine, with all order lifecycle events written there. The History schema synonym pattern provides a stable local reference for queries without embedding cross-database paths in every consuming procedure or view.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a synonym (pointer object). Companion synonyms: `History.OrderForOpen` (submitted opens), `History.ExecutedCloseOrders` (executed closes), `History.OrdersFail` (failures).

---

## 3. Data Overview

N/A for Synonym. Data resides in the target: `[DB_Logs].[History].[ExecutedOpenOrders]`.

---

## 4. Elements

N/A for Synonym. All elements are defined on the target table `[DB_Logs].[History].[ExecutedOpenOrders]`.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym) | [DB_Logs].[History].[ExecutedOpenOrders] | Synonym | Points to the executed open order log in DB_Logs |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ExecutedOpenOrders (synonym)
+-- [DB_Logs].[History].[ExecutedOpenOrders] (external table - DB_Logs database)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [DB_Logs].[History].[ExecutedOpenOrders] | External Table | Target of this synonym |

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
FROM History.ExecutedOpenOrders WITH (NOLOCK)
```

### 8.2 Open order lifecycle - from submission to execution

```sql
-- OrderForOpen = submitted, ExecutedOpenOrders = completed
SELECT TOP 5 * FROM History.OrderForOpen WITH (NOLOCK)
SELECT TOP 5 * FROM History.ExecutedOpenOrders WITH (NOLOCK)
```

### 8.3 Check synonym definition

```sql
SELECT s.name, s.base_object_name
FROM sys.synonyms s WITH (NOLOCK)
WHERE s.name = 'ExecutedOpenOrders'
  AND SCHEMA_NAME(s.schema_id) = 'History'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.5/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ExecutedOpenOrders | Type: Synonym | Source: etoro/etoro/History/Synonyms/History.ExecutedOpenOrders.sql*
