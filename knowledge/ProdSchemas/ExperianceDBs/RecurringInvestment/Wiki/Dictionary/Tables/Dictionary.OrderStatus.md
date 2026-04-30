# Dictionary.OrderStatus

> Lookup table defining trading order lifecycle states - from receipt through execution, cancellation, or expiry.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This table tracks the lifecycle state of a trading order placed as part of a recurring investment instance. After a successful deposit, the Order Execution Job sends an order request to the Trading API (TAPI) to buy the specified instrument. This table captures all possible states that order can be in, from initial receipt through execution or failure.

Without this table, the system could not track order progress or distinguish between different failure modes (rejection vs. cancellation vs. expiry), which is essential for the recurring investment service's monitoring, retry logic, and customer communication.

The OrderStatusId is written to PlanInstances by the Order Execution Job and subsequent status update handlers. The Confluence documentation confirms these values align with the Trading API enum: Received=1, Placed=2, Filled=3, Rejected=4, etc. Several stored procedures use OrderStatusID for filtering, including PlanInstancesGetMissingOrderOrNonFinalOrdersByOrderStatusID.

---

## 2. Business Logic

### 2.1 Order Lifecycle State Machine

**What**: Eleven-state model covering the full trading order lifecycle from receipt to terminal state.

**Columns/Parameters Involved**: `ID`, `OrderStatus`

**Rules**:
- Orders progress: Received (1) -> Placed (2) -> Filled (3) [happy path]
- WaitingForMarket (11) is a pre-Placed state when market is closed
- Terminal success: Filled (3), PartiallyFilled (5)
- Terminal failure: Rejected (4), Canceled (7), Expired (8)
- Hybrid terminal: CanceledPartiallyFilled (9), RejectedPartiallyFilled (10) - partial success + failure

**Diagram**:
```
                              +-- Filled (3) [SUCCESS]
                              |
Received (1) --> Placed (2) --+-- PartiallyFilled (5) [PARTIAL SUCCESS]
    |                         |
    |                         +-- Rejected (4) [FAIL]
    |                         |
    |                         +-- PendingCancel (6) --> Canceled (7) [FAIL]
    |                         |
    |                         +-- Expired (8) [FAIL]
    |                         |
    |                         +-- CanceledPartiallyFilled (9) [PARTIAL]
    |                         |
    |                         +-- RejectedPartiallyFilled (10) [PARTIAL]
    |
    +-- WaitingForMarket (11) --> Placed (2) [when market opens]
```

---

## 3. Data Overview

| ID | OrderStatus | Meaning |
|----|-------------|---------|
| 1 | Received | Order was received by the trading system but not yet sent to market. Initial state after the Order Execution Job submits the request to TAPI. |
| 2 | Placed | Order was sent to the market/exchange and is awaiting execution. The order is now in the exchange's order book. |
| 3 | Filled | Order was fully executed - all requested units/amount were purchased. This is the happy-path terminal state leading to position creation. |
| 4 | Rejected | Order was rejected by the market/exchange or internal validation rules. No purchase occurred. Triggers PlanEventCode in the 1200 range. |
| 5 | PartiallyFilled | Order was partially executed - some but not all units were purchased. A position was opened for the partial amount. |
| 6 | PendingCancel | Cancellation request was submitted but not yet confirmed by the exchange. Transitional state before Canceled (7). |
| 7 | Canceled | Order was successfully cancelled before full execution. Could be user-initiated (PlanEventCode 508) or system-initiated (PlanEventCode 509). |
| 8 | Expired | Order expired without being fully executed, typically because the market closed or a time limit was reached. |
| 9 | CanceledPartiallyFilled | Order was cancelled after partial execution - some units were purchased (position opened), the remainder was cancelled. |
| 10 | RejectedPartiallyFilled | Order was rejected after partial execution - similar to CanceledPartiallyFilled but due to rejection rather than cancellation. |
| 11 | WaitingForMarket | Order is queued and waiting for the market to open before it can be placed. Used when the order is submitted outside trading hours. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Unique numeric identifier for the order status. 1=Received, 2=Placed, 3=Filled, 4=Rejected, 5=PartiallyFilled, 6=PendingCancel, 7=Canceled, 8=Expired, 9=CanceledPartiallyFilled, 10=RejectedPartiallyFilled, 11=WaitingForMarket. See [Order Status](../../_glossary.md#order-status). |
| 2 | OrderStatus | varchar(50) | NO | - | VERIFIED | Human-readable label for the order lifecycle state. Aligns with Trading API enum values (per Confluence). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RecurringInvestment.PlanInstances | OrderStatusId | Implicit Lookup | Tracks the order lifecycle state for each plan instance |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | OrderStatusId column references this domain |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_OrderStatus | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all order statuses
```sql
SELECT ID, OrderStatus
FROM [Dictionary].[OrderStatus] WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Find instances with non-filled orders
```sql
SELECT pi.InstanceID, pi.PlanID, pi.OrderID, os.OrderStatus, pi.OrderTradeDate
FROM [RecurringInvestment].[PlanInstances] pi WITH (NOLOCK)
JOIN [Dictionary].[OrderStatus] os WITH (NOLOCK) ON pi.OrderStatusId = os.ID
WHERE pi.OrderStatusId NOT IN (3)
  AND pi.OrderStatusId IS NOT NULL
```

### 8.3 Count instances by order status
```sql
SELECT os.ID, os.OrderStatus, COUNT(*) AS InstanceCount
FROM [RecurringInvestment].[PlanInstances] pi WITH (NOLOCK)
JOIN [Dictionary].[OrderStatus] os WITH (NOLOCK) ON pi.OrderStatusId = os.ID
GROUP BY os.ID, os.OrderStatus
ORDER BY os.ID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | OrderStatusID based on Trading Enum with all 11 values documented; OrderID is from TAPI |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523/Recurring+Investment+Backend+HLD) | Confluence | Order Execution Job initiates order requests to Trading API |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 10/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.OrderStatus | Type: Table | Source: RecurringInvestment/Dictionary/Tables/Dictionary.OrderStatus.sql*
