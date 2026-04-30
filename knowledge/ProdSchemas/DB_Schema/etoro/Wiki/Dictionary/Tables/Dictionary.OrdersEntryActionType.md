# Dictionary.OrdersEntryActionType

> Lookup table defining the 6 action types for entry orders — tracking how entry (pending) orders are resolved: manual close, execution success/failure, parent position closure, or client removal.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ActionTypeID (INT, PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.OrdersEntryActionType classifies how entry orders (stop-loss, take-profit, and other pending entry triggers) are resolved. Entry orders are conditional orders attached to existing positions — they wait for specific price conditions and then either execute or get cancelled for various reasons.

This table exists because entry order resolution needs to be audited and reported. Unlike the main order lifecycle (OrdersActionType), entry orders have a different set of outcomes focused on execution results and cascading closures from parent positions.

The 6 action types cover the full spectrum: manual closure, successful execution, execution failure (with and without retry exhaustion), closure cascading from the parent position, and client-initiated removal.

---

## 2. Business Logic

### 2.1 Entry Order Resolution Outcomes

**What**: Entry orders terminate through 6 distinct pathways — manual, execution, failure, cascade, or client removal.

**Columns/Parameters Involved**: `ActionTypeID`, `ActionName`

**Rules**:
- **Manual (0)** — The entry order was manually closed by a BackOffice operator or system admin.
- **CloseByExecution (1)** — The entry order's trigger price was hit and it was successfully executed.
- **CloseByExecutionFail (2)** — The entry order triggered but execution failed (transient failure, will retry).
- **CloseByExecutionFailDueToMaxRetries (3)** — Execution failed and the maximum retry count was exhausted. Order is abandoned.
- **Closed-Exit order was created on ParentPositionID (4)** — The parent position was closed, so the entry order was automatically cancelled since it is no longer relevant.
- **ClientRemove (5)** — The client manually cancelled the entry order.

**Diagram**:
```
Entry Order Resolution
├── 0 = Manual (BO/system close)
├── 1 = CloseByExecution (success → position modified)
├── Execution Failures
│   ├── 2 = CloseByExecutionFail (transient failure)
│   └── 3 = CloseByExecutionFailDueToMaxRetries (permanent failure)
├── 4 = Cascade from ParentPosition close
└── 5 = ClientRemove (user cancels)
```

---

## 3. Data Overview

| ActionTypeID | ActionName | Meaning |
|---|---|---|
| 0 | Manual | Entry order was manually closed by a BackOffice operator or system admin — typically for error correction or compliance actions. |
| 1 | CloseByExecution | The entry order's trigger condition was met and it executed successfully, modifying or creating the intended position. The happy-path outcome. |
| 2 | CloseByExecutionFail | The entry order triggered but execution failed (e.g., market moved away, insufficient liquidity). The system may retry. |
| 3 | CloseByExecutionFailDueToMaxRetries | Execution failed repeatedly and the maximum retry limit was reached. The order is permanently abandoned. Requires investigation. |
| 4 | Closed-Exit order was created on ParentPositionID | The parent position that this entry order was attached to was closed, making the entry order irrelevant. Automatically cancelled as a cascade effect. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ActionTypeID | int | NO | - | CODE-BACKED | Primary key identifying the entry order action type. 0=Manual, 1=CloseByExecution, 2=CloseByExecutionFail, 3=CloseByExecutionFailDueToMaxRetries, 4=Closed due to parent position close, 5=ClientRemove. |
| 2 | ActionName | varchar(50) | YES | - | CODE-BACKED | Human-readable label for the action. Displayed in order audit reports and execution tracking. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No direct FK consumers found in the SSDT codebase. Likely consumed by the entry order execution engine at the application layer.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in SSDT codebase.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryOrdersEntryActionType | CLUSTERED PK | ActionTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DictionaryOrdersEntryActionType | PRIMARY KEY | Unique entry order action type identifier |

---

## 8. Sample Queries

### 8.1 List all entry order action types
```sql
SELECT  ActionTypeID,
        ActionName
FROM    [Dictionary].[OrdersEntryActionType] WITH (NOLOCK)
ORDER BY ActionTypeID;
```

### 8.2 Find failure-related action types
```sql
SELECT  ActionTypeID,
        ActionName
FROM    [Dictionary].[OrdersEntryActionType] WITH (NOLOCK)
WHERE   ActionName LIKE '%Fail%'
ORDER BY ActionTypeID;
```

### 8.3 Categorize outcomes as success vs failure vs cancellation
```sql
SELECT  CASE WHEN ActionTypeID = 1 THEN 'Success'
             WHEN ActionTypeID IN (2, 3) THEN 'Failure'
             ELSE 'Cancellation'
        END AS OutcomeCategory,
        ActionTypeID,
        ActionName
FROM    [Dictionary].[OrdersEntryActionType] WITH (NOLOCK)
ORDER BY ActionTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.OrdersEntryActionType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.OrdersEntryActionType.sql*
