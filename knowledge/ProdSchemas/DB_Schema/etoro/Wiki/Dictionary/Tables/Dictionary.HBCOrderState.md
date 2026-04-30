# Dictionary.HBCOrderState

> Lookup table defining the six lifecycle states of HBC (Hedge Back-to-Client) orders — from initial creation through pending, filled, rejected, cancelled, or unrecoverable states.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | OrderStateID (SMALLINT, CLUSTERED PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.HBCOrderState defines the lifecycle states for HBC (Hedge Back-to-Client) orders. HBC orders are part of eToro's hedging infrastructure — when the hedge server needs to unwind or adjust a hedge position, it creates orders that flow back through the system toward the client-facing trade engine. Each order progresses through a state machine from creation to terminal completion.

This table exists because HBC order processing is asynchronous and multi-step. An order may be created, wait in a pending state while liquidity is sourced, and then either fill successfully, get rejected by the liquidity provider, be cancelled by the system, or enter an unrecoverable error state. Tracking these states enables monitoring, alerting, and recovery workflows for the hedge operations team.

OrderStateID is stored on Hedge.HBCOrderLog to track each order's current and historical states. The unrecoverable state (5) represents the most severe failure — an order that could not be processed and requires manual intervention.

---

## 2. Business Logic

### 2.1 HBC Order State Machine

**What**: HBC orders progress through a defined lifecycle with terminal success and failure states.

**Columns/Parameters Involved**: `OrderStateID`, `OrderStateName`

**Rules**:
- **New (0)**: Order just created — initial state when the hedge server generates an HBC order
- **Pending (1)**: Order submitted and awaiting execution — the order has been sent to the execution venue but not yet filled
- **Filled (2)**: Terminal success — the order was executed at the requested or better price. The hedge position has been adjusted.
- **Rejected (3)**: Terminal failure — the liquidity provider or execution venue rejected the order (insufficient liquidity, price moved, etc.)
- **Cancelled (4)**: Terminal — the order was cancelled before execution, typically by the hedge system when conditions changed
- **UnRecoverable (5)**: Terminal critical failure — the order encountered an error that cannot be automatically retried. Requires manual intervention by the hedge operations team.

**Diagram**:
```
HBC Order Lifecycle:
New (0) ──► Pending (1) ──┬──► Filled (2)         ✓ Success
                          ├──► Rejected (3)         ✗ Failure
                          ├──► Cancelled (4)        ✗ Cancelled
                          └──► UnRecoverable (5)    ✗ Critical failure
```

---

## 3. Data Overview

| OrderStateID | OrderStateName | Meaning |
|---|---|---|
| 0 | New | Order just created by the hedge server. The HBC order has been generated but not yet submitted for execution. This is a transient state — orders move to Pending quickly. |
| 1 | Pending | Order submitted and awaiting fill. The execution venue is processing the order. During high-volume periods or illiquid instruments, orders may remain pending longer. |
| 2 | Filled | Order successfully executed. The hedge position has been adjusted as requested. This is the desired terminal state — the HBC operation completed successfully. |
| 3 | Rejected | Order rejected by the execution venue or liquidity provider. Common reasons: price moved beyond acceptable slippage, insufficient liquidity, or market closed. May be retried with adjusted parameters. |
| 5 | UnRecoverable | Critical failure state — the order encountered an error that the system cannot automatically resolve. Requires manual intervention from the hedge operations team. Examples: persistent connection failures, invalid instrument state, or irreconcilable position mismatch. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderStateID | smallint | NO | - | VERIFIED | Primary key identifying the HBC order state. 0=New, 1=Pending, 2=Filled, 3=Rejected, 4=Cancelled, 5=UnRecoverable. Stored on Hedge.HBCOrderLog to track order lifecycle progression. |
| 2 | OrderStateName | varchar(20) | NO | - | VERIFIED | Human-readable label for the order state. Used in hedge monitoring dashboards, order log displays, and alerting systems. Describes the current status of the HBC order in the execution pipeline. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.HBCOrderLog | OrderStateID | Implicit Lookup | Tracks order state transitions in the HBC order log |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.HBCOrderLog | Table | References OrderStateID to track HBC order states |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HBCOrderState | CLUSTERED PK | OrderStateID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HBCOrderState | PRIMARY KEY | Unique order state identifier |

---

## 8. Sample Queries

### 8.1 List all HBC order states
```sql
SELECT  OrderStateID,
        OrderStateName
FROM    [Dictionary].[HBCOrderState] WITH (NOLOCK)
ORDER BY OrderStateID;
```

### 8.2 Count HBC orders by state
```sql
SELECT  s.OrderStateName,
        COUNT(*) AS OrderCount
FROM    [Hedge].[HBCOrderLog] o WITH (NOLOCK)
JOIN    [Dictionary].[HBCOrderState] s WITH (NOLOCK)
        ON o.OrderStateID = s.OrderStateID
GROUP BY s.OrderStateName
ORDER BY OrderCount DESC;
```

### 8.3 Find unrecoverable HBC orders requiring attention
```sql
SELECT  o.*,
        s.OrderStateName
FROM    [Hedge].[HBCOrderLog] o WITH (NOLOCK)
JOIN    [Dictionary].[HBCOrderState] s WITH (NOLOCK)
        ON o.OrderStateID = s.OrderStateID
WHERE   o.OrderStateID = 5
ORDER BY o.CreatedDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.HBCOrderState | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.HBCOrderState.sql*
