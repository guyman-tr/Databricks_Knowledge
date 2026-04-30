# Dictionary.TradingDbOperationType

> Classifies trading database operation types for position lifecycle management (Close, Reopen, ReopenMirror).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | OperationTypeId (int, PK) |
| **Row Count** | 3 |
| **Indexes** | 1 (clustered PK, FILLFACTOR 95, PAGE compression) |
| **Filegroup** | DICTIONARY |

---

## 1. Business Meaning

### What It Is
Dictionary.TradingDbOperationType defines the types of database-level trading operations that can be performed on positions. It provides a small taxonomy of the three fundamental position lifecycle operations.

### Why It Exists
When the trading engine performs database operations on positions, the operation type needs to be classified for logging, auditing, and routing. This table provides the three operation categories: closing a position, reopening a closed position, and reopening a mirror (CopyTrading) relationship.

### How It Works
The `OperationTypeId` is used internally by the trading database layer to classify operations. The table is not referenced by any stored procedures in the SSDT project, suggesting it's consumed by the application-layer trading engine or used for operational logging.

---

## 2. Business Logic

### Value Map (Complete — 3 rows)

| OperationTypeId | OperationType | Business Meaning |
|-----------------|---------------|------------------|
| 1 | Close | Standard position close operation |
| 2 | ReopenPosition | Reopen a previously closed position (corrections, splits, corporate actions) |
| 5 | ReopenMirror | Reopen a CopyTrading mirror relationship |

### ID Gap Pattern
IDs 3 and 4 are not assigned, suggesting either deprecated operations or reserved slots.

---

## 3. Data Overview

| OperationTypeId | OperationType | Scenario |
|-----------------|---------------|----------|
| 1 | Close | User sells their stock position |
| 2 | ReopenPosition | Position reopened after erroneous close or corporate action |
| 5 | ReopenMirror | CopyTrading mirror re-activated after temporary suspension |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OperationTypeId | int | NO | — | HIGH | Primary key identifying the DB operation type. `1`=Close, `2`=ReopenPosition, `5`=ReopenMirror. |
| 2 | OperationType | varchar(50) | NO | — | HIGH | PascalCase operation label. |

---

## 5. Relationships

No SQL procedure or table references found in SSDT — consumed by application-layer trading engine.

---

## 6. Dependencies

### Depends On
None — leaf dictionary table.

### Depended On By
- Application-layer trading database operations

---

## 7. Technical Details

| Index Name | Type | Key Columns | Notes |
|-----------|------|-------------|-------|
| PK_Dictionary_TradingDbOperationType | CLUSTERED PK | OperationTypeId ASC | FILLFACTOR 95, PAGE compression |

---

## 8. Sample Queries

```sql
-- Get all trading DB operation types
SELECT  OperationTypeId, OperationType
FROM    Dictionary.TradingDbOperationType WITH (NOLOCK)
ORDER BY OperationTypeId;
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira references found for `TradingDbOperationType`.

---

*Generated: 2026-03-14 | Quality: 9.0/10*
*Object: Dictionary.TradingDbOperationType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.TradingDbOperationType.sql*
