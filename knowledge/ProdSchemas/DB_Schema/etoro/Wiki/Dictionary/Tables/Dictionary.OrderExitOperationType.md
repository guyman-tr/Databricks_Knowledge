# Dictionary.OrderExitOperationType

> Defines the types of operations that can be performed on exit orders (stop-loss, take-profit), controlling whether an exit order opens, closes, converts, or edits position units.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | OrderExitOperationTypeID (int, IDENTITY, PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

Dictionary.OrderExitOperationType classifies the operations that can be performed on exit orders (stop-loss and take-profit orders attached to positions). When an exit order triggers, the system needs to know what action to take — fully open the exit, close the exit, convert between full and partial close, or edit the units to deduct.

Without this table, the order execution engine could not classify exit order operations, making it impossible to support partial closes, exit order conversions, or unit-level edits on triggered SL/TP orders.

Referenced by Trade.OrderExitEdit procedure which processes modifications to exit orders.

---

## 2. Business Logic

### 2.1 Exit Order Operation Types

**What**: Five operations controlling how exit orders are processed.

**Columns/Parameters Involved**: `OrderExitOperationTypeID`, `Name`

**Rules**:
- Open (1): Activate/create an exit order on a position
- Close (2): Deactivate/remove an exit order from a position
- ConvertToFullClose (3): Change a partial close exit order to close the entire position
- ConvertToPartialClose (4): Change a full close exit order to only close a portion of the position
- EditUnitsToDeduct (5): Modify the number of units that the exit order will close when triggered

**Diagram**:
```
Exit Order Lifecycle:
  Open (1) ──> Create SL/TP on position
       │
       ├── Close (2) ──> Remove SL/TP
       │
       ├── ConvertToFullClose (3) ──> Change to close 100% on trigger
       │
       ├── ConvertToPartialClose (4) ──> Change to close N% on trigger
       │
       └── EditUnitsToDeduct (5) ──> Modify units closed on trigger
```

---

## 3. Data Overview

| OrderExitOperationTypeID | Name | Meaning |
|---|---|---|
| 1 | Open | Create or activate a stop-loss or take-profit order on an existing position |
| 2 | Close | Remove or deactivate an existing exit order from a position — the SL/TP is cancelled |
| 3 | ConvertToFullClose | Convert a partial-close exit order to close the entire position when triggered — used when trader wants full protection instead of partial |
| 4 | ConvertToPartialClose | Convert a full-close exit order to only close a portion of the position — allows partial profit-taking while maintaining exposure |
| 5 | EditUnitsToDeduct | Modify the specific number of units that the exit order will sell/close when triggered — fine-grained position management |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderExitOperationTypeID | int (IDENTITY) | NO | - | CODE-BACKED | Auto-incrementing unique identifier: 1=Open, 2=Close, 3=ConvertToFullClose, 4=ConvertToPartialClose, 5=EditUnitsToDeduct. NOT FOR REPLICATION. Referenced by Trade.OrderExitEdit. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable operation name describing what happens to the exit order. Used by the order execution engine to determine the action. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OrderExitEdit | OrderExitOperationTypeID | Implicit | Exit order edit procedure uses this to determine the operation type |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderExitEdit | Stored Procedure | Reads operation type to determine exit order action |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryOrderExitOperationType | CLUSTERED PK | OrderExitOperationTypeID | - | - | Active |

### 7.2 Constraints

None beyond PK.

---

## 8. Sample Queries

### 8.1 List all exit operation types
```sql
SELECT  OrderExitOperationTypeID,
        Name
FROM    [Dictionary].[OrderExitOperationType] WITH (NOLOCK)
ORDER BY OrderExitOperationTypeID;
```

### 8.2 Find conversion operations
```sql
SELECT  *
FROM    [Dictionary].[OrderExitOperationType] WITH (NOLOCK)
WHERE   Name LIKE 'Convert%';
```

### 8.3 All operations with category
```sql
SELECT  OrderExitOperationTypeID,
        Name,
        CASE
            WHEN OrderExitOperationTypeID IN (1, 2) THEN 'Lifecycle'
            WHEN OrderExitOperationTypeID IN (3, 4) THEN 'Conversion'
            WHEN OrderExitOperationTypeID = 5 THEN 'Edit'
        END AS Category
FROM    [Dictionary].[OrderExitOperationType] WITH (NOLOCK)
ORDER BY OrderExitOperationTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.OrderExitOperationType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.OrderExitOperationType.sql*
