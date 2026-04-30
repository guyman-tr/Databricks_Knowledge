# Dictionary.ExecutionServicesOpeartionType

## 1. Business Meaning

### What It Is
A memory-optimized lookup table defining the operation types processed by the trade execution services — the complete catalog of trading operations from order creation through position lifecycle management.

### Why It Exists
The execution services layer handles every trading operation: opening/closing orders, cancellations, mirror/copy trades, admin operations, and position adjustments. Each operation needs a classified type for routing, logging, and state machine transitions. The memory-optimized storage reflects the high-throughput, low-latency requirements of trade execution.

### How It's Used
Referenced by the execution services infrastructure to classify trading operations. Limited SSDT references (only the DDL and a QA job script), indicating this table is primarily consumed by the in-memory trading engine at the application layer.

---

## 2. Business Logic

### Operation Categories

**Order Submission (IDs 1-8)**
| ID | Operation | Description |
|----|-----------|-------------|
| 1 | OrderForOpen | Standard order to open a new position |
| 2 | OrderForOpenInMirror | CopyTrading: open position mirroring another user |
| 3 | OrderForClose | Standard order to close a position |
| 4 | OrderForCloseInMirror | CopyTrading: close mirrored position |
| 5 | CancelDelayedOrderForOpen | Cancel a pending open order |
| 6 | CancelDelayedOrderForClose | Cancel a pending close order |
| 7 | CancelOrderForOpen | Cancel an active open order |
| 8 | CancelOrderForClose | Cancel an active close order |

**Status Updates (IDs 9-12)**
| ID | Operation | Description |
|----|-----------|-------------|
| 9 | OrderForOpenStatusUpdateRejected | Open order rejected by provider/market |
| 10 | OrderForCloseStatusUpdateRejected | Close order rejected |
| 11 | OrderForCloseStatusUpdateFilled | Close order filled successfully |
| 12 | OrderForOpenStatusUpdateFilled | Open order filled successfully |

**Position Lifecycle (IDs 13-20)**
| ID | Operation | Description |
|----|-----------|-------------|
| 13 | PositionClose | Close an existing position |
| 14 | PositionCloseByLimit | Position closed by stop-loss/take-profit trigger |
| 15 | PositionOpen | Open a new position |
| 16 | OperationalOpenPosition | Operational/system-initiated position open |
| 17 | OperationalClosePosition | Operational/system-initiated position close |
| 18 | OperationalPositionAdjustment | Adjust an existing position (corporate actions, corrections) |
| 19 | DirectOpenPosition | Direct position open (bypasses order queue) |
| 20 | DirectClosePosition | Direct position close (bypasses order queue) |

**Specialized Close Operations (IDs 21-22)**
| ID | Operation | Description |
|----|-----------|-------------|
| 21 | OrderForCloseByLimit | Close order triggered by limit/rate condition |
| 22 | OrderForCloseByRate | Close order triggered by specific rate |

**Admin Operations (IDs 23-25)**
| ID | Operation | Description |
|----|-----------|-------------|
| 23 | AdminOrderForOpenWithHedge | Admin opens position with hedge execution |
| 24 | AdminOrderForOpenWithoutHedge | Admin opens position without hedge |
| 25 | AdminPositionOpen | Admin direct position open |

---

## 3. Data Overview

| ID | OpeartionType |
|----|--------------|
| 1 | OrderForOpen |
| 2 | OrderForOpenInMirror |
| 3 | OrderForClose |
| 4 | OrderForCloseInMirror |
| 5 | CancelDelayedOrderForOpen |
| 6 | CancelDelayedOrderForClose |
| 7 | CancelOrderForOpen |
| 8 | CancelOrderForClose |
| 9 | OrderForOpenStatusUpdateRejected |
| 10 | OrderForCloseStatusUpdateRejected |
| 11 | OrderForCloseStatusUpdateFilled |
| 12 | OrderForOpenStatusUpdateFilled |
| 13 | PositionClose |
| 14 | PositionCloseByLimit |
| 15 | PositionOpen |
| 16 | OperationalOpenPosition |
| 17 | OperationalClosePosition |
| 18 | OperationalPositionAdjustment |
| 19 | DirectOpenPosition |
| 20 | DirectClosePosition |
| 21 | OrderForCloseByLimit |
| 22 | OrderForCloseByRate |
| 23 | AdminOrderForOpenWithHedge |
| 24 | AdminOrderForOpenWithoutHedge |
| 25 | AdminPositionOpen |

---

## 4. Elements

| Column | Type | Null | Description | Confidence |
|--------|------|------|-------------|------------|
| **ID** | `tinyint` | NO | Primary key (identity, auto-increment). Operation type identifier (1-25). | `MCP` |
| **OpeartionType** | `varchar(50)` | NO | PascalCase operation name. Note: column name contains a typo ("Opeartion" vs "Operation"). | `MCP` |

---

## 5. Relationships

### Referenced By
No explicit FK references in SSDT. Consumed by the in-memory trading engine at the application layer.

### References To
None — leaf lookup table.

---

## 6. Dependencies

### Depends On
None.

### Depended On By
- Execution services trading engine (application layer)

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| **Primary Key** | `ID` (nonclustered) |
| **Indexes** | `IX_ID` — nonclustered hash index with BUCKET_COUNT=64 |
| **Memory-Optimized** | **Yes** — `MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA` |
| **Row Count** | 25 |
| **Identity** | Yes — `tinyint IDENTITY(1,1)` |
| **Temporal** | No |

> **Note**: This is a **memory-optimized (In-Memory OLTP)** table, consistent with its role in the high-throughput trading execution path. The hash index with 64 buckets is sized for the small cardinality (25 rows).

---

## 8. Sample Queries

```sql
-- Get all execution service operation types
SELECT  ID,
        OpeartionType
FROM    Dictionary.ExecutionServicesOpeartionType WITH (NOLOCK)
ORDER BY ID;

-- Get order-related operations only
SELECT  ID,
        OpeartionType
FROM    Dictionary.ExecutionServicesOpeartionType WITH (NOLOCK)
WHERE   OpeartionType LIKE 'Order%'
ORDER BY ID;

-- Get admin operations
SELECT  ID,
        OpeartionType
FROM    Dictionary.ExecutionServicesOpeartionType WITH (NOLOCK)
WHERE   OpeartionType LIKE 'Admin%';
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found for this table.

---

*Generated: 2026-03-14 | Quality Score: 9.0 | Phases: DDL ✓ MCP ✓ Codebase ✓*
