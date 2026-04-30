# Dictionary.OrderForExecutionCloseActionType

> Lookup table defining the 12 possible outcomes when an order-for-execution is closed — ranging from successful execution to various cancellation reasons (user, system, BackOffice, liquidation, mirror, delist, technical).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (TINYINT, clustered index — not a PK constraint) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (CIX clustered on ID) |

---

## 1. Business Meaning

Dictionary.OrderForExecutionCloseActionType classifies the reason an order-for-execution was closed or resolved. Orders-for-execution are the internal representation of pending trades that have been submitted to the execution engine. Each such order ultimately terminates — either because it was successfully executed, rejected by the market, or cancelled by various triggers.

This table exists because understanding why an order closed is critical for trade reconciliation, execution quality analysis, and operational troubleshooting. A cancellation due to a technical issue (ID 7) triggers different follow-up actions than a cancellation due to account liquidation (ID 5) or a user-initiated cancellation (ID 2).

The 12 close action types capture the full lifecycle of order termination, from normal execution (0) through system-driven cancellations for liquidation, mirror unregister, delisting, and technical failures.

---

## 2. Business Logic

### 2.1 Order Close Outcome Classification

**What**: Orders-for-execution terminate via one of 12 distinct pathways, grouped into execution outcomes and cancellation reasons.

**Columns/Parameters Involved**: `ID`, `CloseActionType`

**Rules**:
- **Execution (0)** — Order was successfully filled and converted to a position.
- **Rejection (1)** — Market or system rejected the order (e.g., insufficient liquidity, price moved beyond tolerance).
- **User Cancellations (2)** — Client voluntarily cancelled the pending order.
- **System Cancellations (3-11)** — Platform-initiated cancellations for various operational reasons: system operations, BackOffice intervention, account liquidation, CopyTrading mirror unregister, technical issues, mirror alignment, instrument delisting, replacement with full order, or DB-level close.

**Diagram**:
```
Order-for-Execution Close Outcomes
├── Success
│   └── 0 = Execution (filled → position created)
├── Market Rejection
│   └── 1 = Rejection (market/system rejected)
├── User-Initiated
│   └── 2 = Cancellation by user
└── System-Initiated Cancellations
    ├── 3  = System Operation
    ├── 4  = BackOffice
    ├── 5  = Account Liquidation
    ├── 6  = Mirror Unregister
    ├── 7  = Technical Issue
    ├── 8  = Mirror Alignment
    ├── 9  = Delist
    ├── 10 = Replacement with full order
    └── 11 = Close by DB
```

---

## 3. Data Overview

| ID | CloseActionType | Meaning |
|---|---|---|
| 0 | Execution | The order was successfully executed and converted into a live position. The normal happy-path outcome for a pending order. |
| 1 | Rejection | The order was rejected by the market or execution engine — insufficient liquidity, price deviation beyond tolerance, or instrument unavailability. |
| 2 | Cancellation by user | The client manually cancelled the pending order before it could execute. Voluntary withdrawal. |
| 5 | Cancellation due to Account Liquidation | The order was cancelled because the customer's account was being liquidated (equity fell below margin requirements or BSL triggered). All pending orders are force-cancelled during liquidation. |
| 7 | Cancellation due to Technical Issue | The order was cancelled due to a platform technical failure — connectivity issues, execution engine errors, or timeout conditions. Requires operational investigation. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | tinyint | NO | - | CODE-BACKED | Identifier for the close action type. 0=Execution (success), 1=Rejection, 2=Cancellation by user, 3=Cancellation by System Operation, 4=Cancellation by BackOffice, 5=Cancellation due to Account Liquidation, 6=Cancellation due to Mirror Unregister, 7=Cancellation due to Technical Issue, 8=Cancellation due to Mirror Alignment, 9=Cancellation due to Delist, 10=Cancellation due to replacement with full order, 11=Cancellation due close by DB. |
| 2 | CloseActionType | varchar(50) | NO | - | CODE-BACKED | Human-readable description of the close action. Used in execution reporting and order lifecycle tracking. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No direct FK consumers found in the codebase. This table likely serves as a reference lookup for the order execution engine at the application layer.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in SSDT codebase. Consumed by the application-layer execution engine.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| CIX | CLUSTERED | ID ASC | - | - | Active |

### 7.2 Constraints

None. Note: The table has a clustered index but no formal PRIMARY KEY constraint.

---

## 8. Sample Queries

### 8.1 List all close action types
```sql
SELECT  ID,
        CloseActionType
FROM    [Dictionary].[OrderForExecutionCloseActionType] WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Find all cancellation-type outcomes
```sql
SELECT  ID,
        CloseActionType
FROM    [Dictionary].[OrderForExecutionCloseActionType] WITH (NOLOCK)
WHERE   CloseActionType LIKE 'Cancellation%'
ORDER BY ID;
```

### 8.3 Separate success vs failure outcomes
```sql
SELECT  CASE WHEN ID = 0 THEN 'Success'
             WHEN ID = 1 THEN 'Rejection'
             ELSE 'Cancellation'
        END AS OutcomeCategory,
        ID,
        CloseActionType
FROM    [Dictionary].[OrderForExecutionCloseActionType] WITH (NOLOCK)
ORDER BY ID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.OrderForExecutionCloseActionType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.OrderForExecutionCloseActionType.sql*
