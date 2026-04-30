# History.OrderExecutionData

> Synonym aliasing the DB_Logs database table that stores detailed execution data for processed orders, providing History-schema code a local reference to the cross-database order execution detail log.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Synonym |
| **Key Identifier** | N/A - pointer to [DB_Logs].[History].[OrderExecutionData] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.OrderExecutionData` is a synonym pointing to `[DB_Logs].[History].[OrderExecutionData]` in the `DB_Logs` database. The target table stores detailed execution data for orders that have been processed by the trading engine - capturing the execution context, timing, price achieved, and routing details for each order execution event.

While `History.ExecutedOpenOrders` and `History.ExecutedCloseOrders` record the order-level completion, `OrderExecutionData` stores the deeper execution detail: provider response, slippage, execution latency, and other technical execution metrics. This data is used for execution quality analysis, TCA (transaction cost analysis), and debugging of execution anomalies.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a synonym (pointer object). See `[DB_Logs].[History].[OrderExecutionData]` for the full execution detail structure.

---

## 3. Data Overview

N/A for Synonym. Data resides in the target: `[DB_Logs].[History].[OrderExecutionData]`.

---

## 4. Elements

N/A for Synonym. All elements are defined on the target table `[DB_Logs].[History].[OrderExecutionData]`.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym) | [DB_Logs].[History].[OrderExecutionData] | Synonym | Points to the order execution detail log in DB_Logs |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.OrderExecutionData (synonym)
+-- [DB_Logs].[History].[OrderExecutionData] (external table - DB_Logs database)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [DB_Logs].[History].[OrderExecutionData] | External Table | Target of this synonym |

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
FROM History.OrderExecutionData WITH (NOLOCK)
```

### 8.2 Check synonym definition

```sql
SELECT s.name, s.base_object_name
FROM sys.synonyms s WITH (NOLOCK)
WHERE s.name = 'OrderExecutionData'
  AND SCHEMA_NAME(s.schema_id) = 'History'
```

### 8.3 Compare order execution data with executed orders

```sql
SELECT TOP 5 * FROM History.OrderExecutionData WITH (NOLOCK)
SELECT TOP 5 * FROM History.ExecutedOpenOrders WITH (NOLOCK)
SELECT TOP 5 * FROM History.ExecutedCloseOrders WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.5/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.OrderExecutionData | Type: Synonym | Source: etoro/etoro/History/Synonyms/History.OrderExecutionData.sql*
