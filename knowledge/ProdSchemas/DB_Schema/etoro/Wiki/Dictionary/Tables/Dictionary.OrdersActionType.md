# Dictionary.OrdersActionType

> Lookup table defining the 5 lifecycle actions for pending orders — from client creation through conversion to positions, manual BackOffice removal, and order-for-open conversion.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ActionTypeID (INT, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.OrdersActionType classifies the actions that can occur on a pending order throughout its lifecycle. When a client creates a delayed/pending order, it transitions through states — from creation, through potential conversions or removals, until it is either executed or cancelled.

This table exists because the order lifecycle is audited in History.Orders and used in reporting. Each action type identifies what happened to a pending order — whether the client created it, the client removed it, BackOffice intervened, or the system converted it to either a live position or an order-for-open.

The ActionTypeID is used by Trade.PositionOpen to track order-to-position conversions and by BackOffice.GetCustomerClosedOrders to display closed order history with the appropriate action labels.

---

## 2. Business Logic

### 2.1 Order Lifecycle Actions

**What**: The 5 action types track the complete lifecycle of a pending order from creation to termination.

**Columns/Parameters Involved**: `ActionTypeID`, `ActionName`

**Rules**:
- **ClientRemove (1)** — The client cancelled the pending order before it could execute.
- **ConvertedToPosition (2)** — The pending order's trigger condition was met and it was converted into a live trading position.
- **ManualBackOffice (3)** — A BackOffice operator manually intervened to close or modify the order.
- **ClientCreated (4)** — A new pending order was created by the client (the initial creation event).
- **ConvertedToOrderForOpen (5)** — The pending order was converted into an order-for-open (a different execution pathway, typically for CopyTrading scenarios).

**Diagram**:
```
Pending Order Lifecycle
      │
      ▼
  4 = ClientCreated (order placed)
      │
      ├── 2 = ConvertedToPosition (trigger hit → live position)
      ├── 5 = ConvertedToOrderForOpen (converted to open order)
      ├── 1 = ClientRemove (client cancels)
      └── 3 = ManualBackOffice (BO intervention)
```

---

## 3. Data Overview

| ActionTypeID | ActionName | Meaning |
|---|---|---|
| 1 | ClientRemove | Client cancelled the pending order voluntarily before it triggered. Recorded in History.Orders for audit. |
| 2 | ConvertedToPosition | The order's price/condition was met and it was automatically executed, creating a live position. The successful outcome. |
| 3 | ManualBackOffice | A BackOffice operator manually closed or intervened on the order. Used for compliance actions or error corrections. |
| 4 | ClientCreated | A new pending order was placed by the client. The initial lifecycle event recorded when the order is first submitted. |
| 5 | ConvertedToOrderForOpen | The pending order was converted into an order-for-open. Used in CopyTrading or batch execution scenarios where the order format changes. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ActionTypeID | int | NO | - | VERIFIED | Primary key identifying the order action type. 1=ClientRemove, 2=ConvertedToPosition, 3=ManualBackOffice, 4=ClientCreated, 5=ConvertedToOrderForOpen. Used in History.Orders and Trade.PositionOpen. |
| 2 | ActionName | varchar(30) | YES | - | VERIFIED | Human-readable label for the action. Displayed in BackOffice closed orders reports and order audit history. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.Orders | ActionTypeID | Implicit | Stores the action type for each historical order event |
| Trade.PositionOpen | ActionTypeID | Implicit | References action type during order-to-position conversion |
| BackOffice.GetCustomerClosedOrders | ActionTypeID | Lookup | Joins to display action labels in closed order reports |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.Orders | Table | Stores ActionTypeID per order event |
| Trade.PositionOpen | Stored Procedure | References during order conversion |
| BackOffice.GetCustomerClosedOrders | Stored Procedure | Reader — joins for display labels |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DICT_ORDA | CLUSTERED PK | ActionTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DICT_ORDA | PRIMARY KEY | Unique order action type identifier |

---

## 8. Sample Queries

### 8.1 List all order action types
```sql
SELECT  ActionTypeID,
        ActionName
FROM    [Dictionary].[OrdersActionType] WITH (NOLOCK)
ORDER BY ActionTypeID;
```

### 8.2 Count historical orders by action type
```sql
SELECT  oat.ActionName,
        COUNT(*) AS OrderCount
FROM    [History].[Orders] o WITH (NOLOCK)
JOIN    [Dictionary].[OrdersActionType] oat WITH (NOLOCK)
        ON o.ActionTypeID = oat.ActionTypeID
GROUP BY oat.ActionName
ORDER BY OrderCount DESC;
```

### 8.3 Find orders converted to positions
```sql
SELECT  oat.ActionName,
        oat.ActionTypeID
FROM    [Dictionary].[OrdersActionType] oat WITH (NOLOCK)
WHERE   oat.ActionName LIKE 'Converted%';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.OrdersActionType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.OrdersActionType.sql*
