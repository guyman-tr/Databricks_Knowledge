# History.OrdersFail

> Synonym aliasing the DB_Logs database table that stores failed trading orders, providing History-schema code a stable local reference to the cross-database order failure audit log.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Synonym |
| **Key Identifier** | N/A - pointer to [DB_Logs].[History].[OrdersFail] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.OrdersFail` is a synonym pointing to `[DB_Logs].[History].[OrdersFail]` in the `DB_Logs` database. The target table records trading orders that failed - whether the failure occurred during order submission, routing, provider execution, or any other stage before successful completion.

This table captures all order failure types in a single location. The companion `History.OrdersMarketFail` handles a specific subset (market-side failures), while `History.OrdersFail` covers the broader category of all failed orders. Together these two synonyms, combined with `History.ExecutedOpenOrders` and `History.ExecutedCloseOrders`, form the complete order lifecycle audit trail in DB_Logs.

Order failures here are distinct from position failures in `History.PositionFailLocal`/`History.PositionFailWrite`: order failures occur before a position is fully established, while position failures occur during operations on an existing position.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a synonym (pointer object). See `[DB_Logs].[History].[OrdersFail]` for the failure record structure.

---

## 3. Data Overview

N/A for Synonym. Data resides in the target: `[DB_Logs].[History].[OrdersFail]`.

---

## 4. Elements

N/A for Synonym. All elements are defined on the target table `[DB_Logs].[History].[OrdersFail]`.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym) | [DB_Logs].[History].[OrdersFail] | Synonym | Points to the order failure log in DB_Logs |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.OrdersFail (synonym)
+-- [DB_Logs].[History].[OrdersFail] (external table - DB_Logs database)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [DB_Logs].[History].[OrdersFail] | External Table | Target of this synonym |

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

### 8.1 Query failed orders

```sql
SELECT TOP 10 *
FROM History.OrdersFail WITH (NOLOCK)
```

### 8.2 Compare order failures vs market failures

```sql
SELECT 'OrdersFail' AS FailType, COUNT(*) AS RowCount
FROM History.OrdersFail WITH (NOLOCK)
UNION ALL
SELECT 'OrdersMarketFail', COUNT(*)
FROM History.OrdersMarketFail WITH (NOLOCK)
```

### 8.3 Check synonym definition

```sql
SELECT s.name, s.base_object_name
FROM sys.synonyms s WITH (NOLOCK)
WHERE s.name = 'OrdersFail'
  AND SCHEMA_NAME(s.schema_id) = 'History'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.5/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.OrdersFail | Type: Synonym | Source: etoro/etoro/History/Synonyms/History.OrdersFail.sql*
