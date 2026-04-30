# Dictionary.OrderForExecutionStatus

> Memory-optimized lookup table defining the lifecycle states for orders sent to execution (broker/exchange). IsTerminal indicates whether a state is final.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table (Memory-Optimized) |
| **Key Identifier** | ID (tinyint, PK NONCLUSTERED, IDENTITY) |
| **Partition** | N/A (in-memory) |
| **Indexes** | 2 active (HASH on ID, NONCLUSTERED PK) |
| **Durability** | SCHEMA_AND_DATA |

---

## 1. Business Meaning

Dictionary.OrderForExecutionStatus defines the lifecycle states for orders sent to execution — the broker or exchange. Every order (OrderForOpen, OrderForClose) progresses through these states from submission to a terminal outcome. The table is memory-optimized for ultra-low-latency lookups during high-throughput order processing.

The IsTerminal flag is critical: it indicates whether an order in this state is "done" — no further state changes expected. Non-terminal states (RECEIVED, PLACED, PARTIALLY_FILLED, PENDING_CANCEL, WAITING_FOR_MARKET) mean the order is still in progress. Terminal states (FILLED, REJECTED, CANCELED, EXPIRED, CANCELED_PARTIALLY_FILLED, REJECTED_PARTIALLY_FILLED) mean the order has reached its final state. This drives order lifecycle logic, stuck-order detection, and reporting.

---

## 2. Business Logic

### 2.1 Order-for-Execution State Machine

**What**: Eleven-state lifecycle for orders sent to execution. IsTerminal separates in-flight from final states.

**Columns/Parameters Involved**: `ID`, `Status`, `IsTerminal`

**Rules**:
- **Non-terminal (IsTerminal=0)**: RECEIVED (1), PLACED (2), PARTIALLY_FILLED (5), PENDING_CANCEL (6), WAITING_FOR_MARKET (11). Order can transition to other states.
- **Terminal (IsTerminal=1)**: FILLED (3), REJECTED (4), CANCELED (7), EXPIRED (8), CANCELED_PARTIALLY_FILLED (9), REJECTED_PARTIALLY_FILLED (10). No further transitions.
- **Common paths**: RECEIVED → PLACED → FILLED; PLACED → PENDING_CANCEL → CANCELED; PLACED → REJECTED; PLACED → PARTIALLY_FILLED → FILLED (or CANCELED_PARTIALLY_FILLED / REJECTED_PARTIALLY_FILLED).

**Diagram**:
```
Order-for-Execution State Machine:

                    ┌──────────────────────────────────────────────────┐
                    │                  NON-TERMINAL                     │
                    └──────────────────────────────────────────────────┘

  [1: RECEIVED] ──► [2: PLACED] ──┬──► [3: FILLED] ────────────────► (done)
                                  │
                                  ├──► [5: PARTIALLY_FILLED] ──┬──► [3: FILLED]
                                  │                            ├──► [9: CANCELED_PARTIALLY_FILLED]
                                  │                            └──► [10: REJECTED_PARTIALLY_FILLED]
                                  │
                                  ├──► [6: PENDING_CANCEL] ────► [7: CANCELED]
                                  │
                                  ├──► [4: REJECTED]
                                  │
                                  ├──► [8: EXPIRED]
                                  │
                                  └──► [11: WAITING_FOR_MARKET] ──► (back to PLACED or terminal)

                    ┌──────────────────────────────────────────────────┐
                    │                   TERMINAL                       │
                    │  3:FILLED, 4:REJECTED, 7:CANCELED, 8:EXPIRED,    │
                    │  9:CANCELED_PARTIALLY_FILLED, 10:REJECTED_PARTIALLY_FILLED │
                    └──────────────────────────────────────────────────┘
```

---

## 3. Data Overview

| ID | Status | IsTerminal | Meaning |
|---|---|---|---|
| 1 | RECEIVED | false | Order received by execution layer, not yet placed |
| 2 | PLACED | false | Order sent to broker/exchange, in progress |
| 3 | FILLED | true | Fully executed. Terminal. |
| 4 | REJECTED | true | Rejected by broker. Terminal. |
| 5 | PARTIALLY_FILLED | false | Partially executed, awaiting remainder |
| 6 | PENDING_CANCEL | false | Cancel request sent, awaiting confirmation |
| 7 | CANCELED | true | Canceled. Terminal. |
| 8 | EXPIRED | true | Expired without fill. Terminal. |
| 9 | CANCELED_PARTIALLY_FILLED | true | Canceled after partial fill. Terminal. |
| 10 | REJECTED_PARTIALLY_FILLED | true | Rejected after partial fill. Terminal. |
| 11 | WAITING_FOR_MARKET | false | Waiting for market to open |

*MCP-verified live data. 11 rows.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | tinyint | NO | IDENTITY(1,1) | VERIFIED | Primary key. 1–11. MCP-verified. Used by Trade.OrderForOpenUpdate, OrderForCloseUpdate, GetOrdersForExecutionReport*, IsOrderForOpenClosed, IsOrderForCloseClosed, and 60+ procedures. |
| 2 | Status | varchar(50) | NO | - | VERIFIED | Lifecycle state label. Values: RECEIVED, PLACED, FILLED, REJECTED, PARTIALLY_FILLED, PENDING_CANCEL, CANCELED, EXPIRED, CANCELED_PARTIALLY_FILLED, REJECTED_PARTIALLY_FILLED, WAITING_FOR_MARKET. MCP-verified. |
| 3 | IsTerminal | bit | NO | 0 | VERIFIED | 1=terminal (no further transitions), 0=in-flight. DEFAULT 0. Critical for stuck-order detection and lifecycle logic. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OrderForOpenUpdate | StatusID | Procedure | Order lifecycle updates |
| Trade.OrderForCloseUpdate | StatusID | Procedure | Order lifecycle updates |
| Trade.DeleteOrderForCloseJob, DeleteOrderForOpenJob | StatusID | Procedure | Cleanup logic |
| Trade.GetOrdersForExecutionReport* | StatusID | Procedure | Reporting |
| Trade.GetMirrorDataWithCID*, GetOpenPositionsData | StatusID | Procedure | Position data |
| Trade.PortfolioForApiInnerMot | StatusID | Procedure | Portfolio API |
| Trade.IsOrderForOpenClosed, IsOrderForCloseClosed | StatusID | Function | Terminal status checks |
| Trade.FunUnRegisterMirrorMot | StatusID | Function | Mirror operations |
| Trade.GetTotalManualOrdersForOpenAmount | StatusID | Procedure | Order amounts |
| Trade.StuckOrders, FunStuckOrders | StatusID | Procedure/Function | Stuck order detection |
| Trade.ViewBulkOrders, FailedDelayedCopyOrders | StatusID | Procedure | Bulk / failed orders |
| 60+ Trade procedures | StatusID | Implicit | Order lifecycle, reporting, validation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.OrderForExecutionStatus
  ← Trade.OrderForOpen, Trade.OrderForClose (StatusID)
  ← 60+ Trade procedures (order lifecycle, reporting, stuck detection)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForOpen | Table | StatusID FK/lookup |
| Trade.OrderForClose | Table | StatusID FK/lookup |
| Trade.OrderForOpenUpdate | Procedure | Status transitions |
| Trade.OrderForCloseUpdate | Procedure | Status transitions |
| Trade.IsOrderForOpenClosed, IsOrderForCloseClosed | Function | Check IsTerminal |
| Trade.StuckOrders, FunStuckOrders | Procedure/Function | Non-terminal = stuck |
| 60+ Trade procedures | Procedure/Function | Order processing, reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| IX_ID | NONCLUSTERED HASH | ID (BUCKET_COUNT=64) | - | - | Active |
| PK (OrderForExecutionStatus) | NONCLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PRIMARY KEY | NONCLUSTERED PK | Unique status identifier |
| DEFAULT | IsTerminal = 0 | New statuses default to non-terminal |

**Special**: `MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA` — In-memory table for low-latency lookups during order processing. Data persisted for durability.

---

## 8. Sample Queries

### 8.1 List all order-for-execution statuses
```sql
SELECT  ID,
        Status,
        IsTerminal
FROM    Dictionary.OrderForExecutionStatus WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 List terminal statuses only
```sql
SELECT  ID,
        Status
FROM    Dictionary.OrderForExecutionStatus WITH (NOLOCK)
WHERE   IsTerminal = 1
ORDER BY ID;
```

### 8.3 Resolve status ID to label for reporting
```sql
SELECT  o.OrderID,
        o.StatusID,
        s.Status  AS StatusLabel,
        s.IsTerminal
FROM    Trade.OrderForOpen o WITH (NOLOCK)
JOIN    Dictionary.OrderForExecutionStatus s WITH (NOLOCK)
        ON o.StatusID = s.ID
WHERE   o.InsertDateTime >= DATEADD(day, -1, GETUTCDATE())
ORDER BY o.InsertDateTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 60+ analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Dictionary.OrderForExecutionStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.OrderForExecutionStatus.sql*
