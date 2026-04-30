# Dictionary.AdminPositionState

> Lookup table defining the 4 administrative position order states — Pending, Placed, Filled, and Rejected — used to track admin-initiated position operations through the execution pipeline.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (INT, no PK constraint) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 0 (heap — no indexes) |

---

## 1. Business Meaning

Dictionary.AdminPositionState defines the lifecycle states for administrative position operations — positions opened or closed by BackOffice operators rather than by customers directly. When an admin initiates a position operation (e.g., closing a customer's position for risk management), the operation progresses through these states.

This table supports the admin trade execution workflow where BackOffice operators can intervene in customer positions. Unlike customer-initiated trades that execute immediately against the market, admin operations may need approval or go through an order-matching process, hence the Pending→Placed→Filled/Rejected lifecycle.

The table is referenced by Trade.SetAdminPositionState (writes the state) and Trade.OrderForOpenCreateWrapper (reads the state during order creation). The lack of a PK constraint and indexes (heap table) suggests this is a rarely-modified reference table that was created with minimal schema overhead.

---

## 2. Business Logic

### 2.1 Admin Position Order Lifecycle

**What**: The state progression of admin-initiated position operations.

**Columns/Parameters Involved**: `Id`, `State`

**Rules**:
- **Pending (1)**: Admin has requested a position operation but it hasn't been submitted to the execution engine yet. May be awaiting additional validation or approval.
- **Placed (2)**: The position order has been submitted to the execution engine and is awaiting fill. The order is live in the market.
- **Filled (3)**: The position order has been successfully executed. The position is now open or closed as requested.
- **Rejected (4)**: The position order was rejected by the execution engine. Common reasons include insufficient margin, market closed, or instrument restrictions.

**Diagram**:
```
Admin Position Operation Lifecycle:

  Admin Request
       │
       ▼
  ┌──────────┐
  │ Pending  │ (1) — Awaiting submission
  └────┬─────┘
       │ Submit to execution
       ▼
  ┌──────────┐
  │ Placed   │ (2) — Order live in market
  └────┬─────┘
       │
       ├──────────► Filled (3)   — Successfully executed ✓
       │
       └──────────► Rejected (4) — Execution failed ✗
```

---

## 3. Data Overview

| Id | State | Meaning |
|---|---|---|
| 1 | Pending | Admin position request created but not yet submitted to execution. May require validation or operator confirmation before proceeding. |
| 2 | Placed | Order submitted to the trading execution engine. Waiting for market fill. Position is actively being matched. |
| 3 | Filled | Order successfully executed at market price. Position has been opened or closed as requested by the admin operator. |
| 4 | Rejected | Execution engine rejected the order. The admin operation failed — common causes include market closure, insufficient customer margin, or trading restrictions on the instrument. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | Identifier for the admin position state. 1=Pending, 2=Placed, 3=Filled, 4=Rejected. No PK constraint defined (heap table). Referenced by Trade.SetAdminPositionState and Trade.OrderForOpenCreateWrapper. |
| 2 | State | varchar(50) | NO | - | CODE-BACKED | Human-readable state name. Describes the current stage of the admin position operation lifecycle. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SetAdminPositionState | @State | Parameter UPDATE | Sets the admin position state during execution lifecycle |
| Trade.OrderForOpenCreateWrapper | AdminPositionState | WHERE/SELECT | Reads admin position state during order creation |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.SetAdminPositionState | Stored Procedure | Writer — updates admin position state |
| Trade.OrderForOpenCreateWrapper | Stored Procedure | Reader — checks state during order creation |

---

## 7. Technical Details

### 7.1 Indexes

No indexes defined. Table is a heap on DICTIONARY filegroup.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all admin position states
```sql
SELECT  Id,
        State
FROM    Dictionary.AdminPositionState WITH (NOLOCK)
ORDER BY Id;
```

### 8.2 Find the state name by ID
```sql
SELECT  State
FROM    Dictionary.AdminPositionState WITH (NOLOCK)
WHERE   Id = 2;
```

### 8.3 List all states with lifecycle order
```sql
SELECT  Id,
        State,
        CASE Id
            WHEN 1 THEN 'Initial'
            WHEN 2 THEN 'In Progress'
            WHEN 3 THEN 'Terminal (Success)'
            WHEN 4 THEN 'Terminal (Failure)'
        END AS LifecycleStage
FROM    Dictionary.AdminPositionState WITH (NOLOCK)
ORDER BY Id;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AdminPositionState | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.AdminPositionState.sql*
