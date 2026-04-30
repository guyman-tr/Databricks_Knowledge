# Hedge.HBCOrder

> Table-valued parameter type carrying a set of HBC (Hedge Broker Connect) order records for batch processing by HBC-related stored procedures.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | User Defined Type (TABLE type) |
| **Key Identifier** | No primary key (heap TVP) |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

`Hedge.HBCOrder` is a Table-Valued Parameter (TVP) type representing a batch of HBC (Hedge Broker Connect) orders. HBC is the eToro proprietary protocol/subsystem used to route hedge orders to certain liquidity providers that use a non-FIX connection method.

Each row in this TVP corresponds to one HBC order - its identifier, execution details, direction, state, and timing. The TVP allows procedures to receive and process multiple HBC orders in a single call.

This type is used by `Hedge.LogHBCExecution` (to log bulk HBC execution results), `Hedge.ListUnsupportedInstruments` (to find instruments in the batch that are not supported), and `Hedge.SSRS_Latency_Report` (for latency reporting). Data originates from the HBC routing subsystem of the hedge server.

---

## 2. Business Logic

### 2.1 HBC Order Lifecycle Fields

**What**: Each row captures an HBC order from creation through execution or failure.

**Columns/Parameters Involved**: `OrderID`, `ExecutionID`, `HedgeID`, `OrderState`, `IsCancelOrder`, `StartTime`, `EndTime`

**Rules**:
- `OrderID` (uniqueidentifier): HBC-assigned GUID for this order - differs from the integer `OrderID` used in FIX-based flows.
- `ExecutionID` (bigint): sequential execution counter for correlation with `Hedge.HBCExecutionLog`.
- `HedgeID` (int): links back to the parent hedge position in `Trade.Hedge` that this HBC order is hedging.
- `IsCancelOrder = 1`: this is a cancellation request for a previously sent HBC order.
- `OrderState`: current state of the HBC order (maps to Dictionary.HBCOrderState).
- `StartTime` / `EndTime`: request window timing for the HBC order submission cycle.

### 2.2 Execution Amount Tracking

**What**: The TVP captures both requested and actual execution amounts for slippage/fill analysis.

**Columns/Parameters Involved**: `RequestAmountInLots`, `ExecutionAmountInLots`, `ExecutionRate`

**Rules**:
- `RequestAmountInLots`: what was requested by the hedge server.
- `ExecutionAmountInLots`: what was actually filled by the HBC broker. If less than requested, a partial fill occurred.
- `ExecutionRate` (dbo.dtPrice): the price at which the HBC order was executed. NULL for unfilled or cancelled orders.

**Diagram**:
```
HBC Routing Subsystem
  |
  | assembles Hedge.HBCOrder TVP rows
  |
  +-> Hedge.LogHBCExecution -> Hedge.HBCExecutionLog (table)
  +-> Hedge.ListUnsupportedInstruments -> returns unsupported instruments
  +-> Hedge.SSRS_Latency_Report -> latency analysis
```

---

## 3. Data Overview

N/A for User Defined Type. This is an in-memory parameter container; no rows are stored persistently.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | uniqueidentifier | YES | - | CODE-BACKED | GUID assigned by the HBC subsystem to this order. Distinguishes HBC orders (GUID-based) from FIX orders (integer-based). Used for cross-system correlation. |
| 2 | ExecutionID | bigint | YES | - | CODE-BACKED | Sequential execution cycle counter. Links this HBC order to a specific execution batch in Hedge.HBCExecutionLog. |
| 3 | HedgeID | int | YES | - | CODE-BACKED | Parent hedge position ID from Trade.Hedge that this HBC order is hedging. Links the HBC order back to the underlying customer exposure. |
| 4 | IsBuy | bit | YES | - | CODE-BACKED | Direction of the HBC order: 1 = buy (hedging net short customer exposure), 0 = sell (hedging net long customer exposure). |
| 5 | IsCancelOrder | bit | YES | - | CODE-BACKED | 1 = this row is a cancellation request for a previously submitted HBC order, 0 = this is a new order submission. When 1, the broker is asked to cancel the order identified by OrderID. |
| 6 | OrderState | int | YES | - | CODE-BACKED | Current state of the HBC order. Maps to Dictionary.HBCOrderState values (e.g., Pending, Sent, Filled, Rejected, Cancelled). |
| 7 | RequestAmountInLots | decimal(16,6) | YES | - | CODE-BACKED | Amount requested to be executed, in lots. This is what the hedge server asked the HBC broker to fill. |
| 8 | ExecutionAmountInLots | decimal(16,6) | YES | - | CODE-BACKED | Amount actually executed by the HBC broker, in lots. If less than RequestAmountInLots, the order was partially filled. Difference drives follow-up orders. |
| 9 | ExecutionRate | dbo.dtPrice | YES | - | CODE-BACKED | The price at which the HBC broker executed the order. NULL for unfilled or cancelled orders. Uses the shared dtPrice type. |
| 10 | StartTime | datetime | YES | - | CODE-BACKED | Timestamp when the HBC order was submitted to the broker. Together with EndTime, bounds the execution window. |
| 11 | EndTime | datetime | YES | - | CODE-BACKED | Timestamp when the HBC order cycle completed (filled, rejected, or timed out). EndTime - StartTime = HBC execution duration. |
| 12 | FailReason | varchar(250) | YES | - | CODE-BACKED | Free-text reason when the HBC order failed or was rejected. Used for error analysis and alerting. NULL on successful fills. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeID | Trade.Hedge | Implicit | Links HBC order back to the parent hedge position being hedged |
| OrderState | Dictionary.HBCOrderState | Implicit | Maps order state integer to business label |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.LogHBCExecution | @HBCOrders parameter | TVP parameter | Receives batch of HBC orders for logging into Hedge.HBCExecutionLog |
| Hedge.ListUnsupportedInstruments | @HBCOrders parameter | TVP parameter | Checks which instruments in the batch are not supported |
| Hedge.SSRS_Latency_Report | @HBCOrders parameter | TVP parameter | Uses order timing to compute HBC execution latency statistics |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (leaf TVP type).

Note: Uses `dbo.dtPrice` for the `ExecutionRate` column.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.dtPrice | User Defined Type (scalar) | Used as data type for ExecutionRate column |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.LogHBCExecution | Stored Procedure | Logs HBC execution results using this TVP |
| Hedge.ListUnsupportedInstruments | Stored Procedure | Identifies unsupported instruments from the HBC order batch |
| Hedge.SSRS_Latency_Report | Stored Procedure | Computes HBC latency metrics from order timing data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (none) | - | - | - | - | - |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Review recent HBC executions
```sql
SELECT TOP 20 HedgeServerID, HedgeID, OrderID, IsBuy,
       RequestAmountInLots, ExecutionAmountInLots, ExecutionRate,
       StartTime, EndTime, OrderStateID
FROM [Hedge].[HBCExecutionLog] WITH (NOLOCK)
ORDER BY StartTime DESC
```

### 8.2 Find HBC partial fills
```sql
SELECT HedgeServerID, InstrumentID, OrderID,
       RequestAmountInLots, ExecutionAmountInLots,
       RequestAmountInLots - ExecutionAmountInLots AS UnfilledLots
FROM [Hedge].[HBCExecutionLog] WITH (NOLOCK)
WHERE ExecutionAmountInLots < RequestAmountInLots
  AND ExecutionAmountInLots IS NOT NULL
  AND StartTime >= DATEADD(hour, -24, GETUTCDATE())
ORDER BY UnfilledLots DESC
```

### 8.3 HBC order state distribution
```sql
SELECT HBCSL.OrderStateID, COUNT(*) AS OrderCount
FROM [Hedge].[HBCExecutionLog] HBCSL WITH (NOLOCK)
WHERE HBCSL.StartTime >= DATEADD(day, -1, GETUTCDATE())
GROUP BY HBCSL.OrderStateID
ORDER BY OrderCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.HBCOrder | Type: User Defined Type | Source: etoro/etoro/Hedge/User Defined Types/Hedge.HBCOrder.sql*
