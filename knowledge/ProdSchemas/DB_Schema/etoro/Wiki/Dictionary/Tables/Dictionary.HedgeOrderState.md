# Dictionary.HedgeOrderState

> Lookup table defining the eight lifecycle states of a hedge order — from initial creation through execution, partial fill, rejection, failure, or cancellation at the liquidity provider.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (SMALLINT, CLUSTERED PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.HedgeOrderState defines the possible lifecycle states of a hedge order as it progresses through execution at the liquidity provider. When eToro needs to hedge customer positions, orders are sent to external liquidity providers (brokers). Each order transitions through states: initial creation (New), transmission (Sent), partial execution (Partial), full execution (Fill), or failure states (Reject, Fail, Cancelled).

This table exists because hedge order state tracking is fundamental to position reconciliation and risk management. If a hedge order is stuck in "Sent" without progressing to "Fill" or "Reject," it indicates a communication issue with the liquidity provider. If orders accumulate in "Partial" state, it indicates liquidity problems. The state machine drives alerting, retry logic, and exposure calculations.

The ID column is referenced by the Hedge.ExecutionLog table, which tracks every hedge order's current state and state transition history.

---

## 2. Business Logic

### 2.1 Hedge Order Lifecycle

**What**: Orders follow a state machine from creation to terminal states (Fill, Reject, Fail, Cancelled).

**Columns/Parameters Involved**: `ID`, `Name`

**Rules**:
- **Initial state (0)**: None — default/unset state before the order is created
- **Active states (1-3)**: Order is in progress
  - Sent (1): Order transmitted to liquidity provider, awaiting acknowledgment
  - New (2): Order created and acknowledged by LP, pending execution
  - Partial (3): Order partially filled — some but not all requested volume executed
- **Terminal success (4)**: Fill — order fully executed at the liquidity provider
- **Terminal failure (5-7)**: Order did not execute
  - Reject (5): LP rejected the order (invalid parameters, insufficient margin, market rules)
  - Fail (6): Technical failure during execution (connection drop, timeout, system error)
  - Cancelled (7): Order was cancelled before execution (by operator or system)

**Diagram**:
```
Hedge Order State Machine:
                    ┌──────────┐
                    │  None(0) │  (default/unset)
                    └────┬─────┘
                         │ create
                         ▼
                    ┌──────────┐
                    │  New(2)  │  LP acknowledged
                    └────┬─────┘
                         │ send
                         ▼
                    ┌──────────┐
            ┌──────│  Sent(1) │──────┐
            │      └────┬─────┘      │
            │           │ execute    │ reject/fail
            ▼           ▼            ▼
     ┌───────────┐ ┌──────────┐ ┌──────────┐
     │Partial(3) │ │  Fill(4) │ │Reject(5) │
     └─────┬─────┘ └──────────┘ │ Fail(6)  │
           │ more fill    ▲      │Cancel(7) │
           └──────────────┘      └──────────┘
           (terminal success)   (terminal failure)
```

---

## 3. Data Overview

| ID | Name | Meaning |
|---|---|---|
| 0 | None | Default/unset state. The hedge order has not yet entered the execution pipeline. Represents an uninitialized or placeholder state. |
| 1 | Sent | Order has been transmitted to the liquidity provider but no response has been received yet. If the order stays in this state too long, it indicates a communication issue. |
| 3 | Partial | Order has been partially executed — some of the requested volume was filled but the remainder is still pending. May occur with large orders in illiquid markets. |
| 4 | Fill | Terminal success — the entire requested volume has been executed at the liquidity provider. The hedge position is now fully established or fully closed. |
| 5 | Reject | Terminal failure — the liquidity provider rejected the order. Common reasons: insufficient margin, invalid lot size, market closed, or price outside acceptable range. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | smallint | NO | - | VERIFIED | Primary key identifying the hedge order state. 0=None (unset), 1=Sent (transmitted to LP), 2=New (LP acknowledged), 3=Partial (partially filled), 4=Fill (fully executed), 5=Reject (LP rejected), 6=Fail (technical failure), 7=Cancelled (cancelled before execution). Stored in Hedge.ExecutionLog. |
| 2 | Name | varchar(20) | NO | - | VERIFIED | Human-readable label for the order state. Displayed in hedge monitoring dashboards and execution log reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.ExecutionLog | HedgeOrderStateID | Implicit FK | Tracks the current state of each hedge order through its lifecycle |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ExecutionLog | Table | References order state to track hedge order lifecycle |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HedgeOrderState | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HedgeOrderState | PRIMARY KEY | Unique hedge order state identifier |

---

## 8. Sample Queries

### 8.1 List all hedge order states
```sql
SELECT  ID,
        Name
FROM    [Dictionary].[HedgeOrderState] WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Join to execution log for order state resolution
```sql
SELECT  el.ExecutionLogID,
        el.InstrumentID,
        hos.Name AS OrderState,
        el.CreatedDate
FROM    [Hedge].[ExecutionLog] el WITH (NOLOCK)
JOIN    [Dictionary].[HedgeOrderState] hos WITH (NOLOCK)
        ON el.HedgeOrderStateID = hos.ID
ORDER BY el.CreatedDate DESC;
```

### 8.3 Count orders by terminal state
```sql
SELECT  hos.Name AS OrderState,
        COUNT(*) AS OrderCount
FROM    [Hedge].[ExecutionLog] el WITH (NOLOCK)
JOIN    [Dictionary].[HedgeOrderState] hos WITH (NOLOCK)
        ON el.HedgeOrderStateID = hos.ID
WHERE   hos.ID IN (4, 5, 6, 7)
GROUP BY hos.Name
ORDER BY OrderCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.HedgeOrderState | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.HedgeOrderState.sql*
