# Hedge.ExecutionLogTableType

> Table-valued parameter type carrying a batch of hedge order execution log entries for bulk insert into the execution log table.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | User Defined Type (TABLE type) |
| **Key Identifier** | No primary key (heap TVP) |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

`Hedge.ExecutionLogTableType` is a Table-Valued Parameter (TVP) type whose structure mirrors the `Hedge.ExecutionLog` table. It enables the hedge server application to pass a batch of execution log records to `Hedge.ExecutionLogInsertBulk` in a single round-trip, rather than inserting records one at a time.

Each row in this TVP represents one hedge order lifecycle event - a single attempt to send an order to a liquidity provider (FIX connection), including the request details, provider response, timing data, and success/failure outcome. Batch insertion is critical for the hedge server, which may execute many orders per second during high-volatility market events.

Data flows into this TVP from the hedge server application after each execution cycle. The populated TVP is passed to `Hedge.ExecutionLogInsertBulk`, which writes all rows into `Hedge.ExecutionLog` atomically.

---

## 2. Business Logic

### 2.1 Execution Lifecycle Capture

**What**: Each TVP row records the complete state of a single hedge order attempt, from send to provider response.

**Columns/Parameters Involved**: `OrderID`, `ParentOrderID`, `SendTime`, `ExecutionTime`, `ProviderExecID`, `OrderState`, `Success`, `FailID`, `FailReason`

**Rules**:
- `Success = 1` and `OrderState` = successful state: order was filled by the liquidity provider.
- `Success = 0` with `FailID` and `FailReason` populated: order was rejected or failed - reason is logged for alerting/monitoring.
- `ParentOrderID` (uniqueidentifier) links child fill events back to the originating hedge request - used for partial fill reconciliation.
- `ProviderOrderID`, `ProviderExecID`, `OMSProviderExecID`, `OMSProviderOrderID`: cross-reference identifiers from the liquidity provider and OMS systems for trade reconciliation.
- `RateIDAtSent`: captures the market rate ID at the moment the order was sent, enabling slippage analysis.

### 2.2 Multi-System Order Tracking

**What**: The TVP supports tracking an order across multiple systems - FIX/EMS and OMS.

**Columns/Parameters Involved**: `EMSOrderID`, `OMSProviderExecID`, `OMSProviderOrderID`, `ProviderPartyIds`

**Rules**:
- `EMSOrderID`: the order ID assigned by the Execution Management System.
- `OMSProviderExecID` / `OMSProviderOrderID`: equivalents from the Order Management System, enabling cross-system reconciliation.
- `ProviderPartyIds`: counterparty identifiers from the FIX protocol, used for multi-party execution reporting.

**Diagram**:
```
Hedge Server (application)
  |
  | assembles batch of ExecutionLogTableType rows
  |
  v
Hedge.ExecutionLogInsertBulk (SP)
  |
  v
Hedge.ExecutionLog (table)
     |
     +-- Prong: OrderID / ParentOrderID -> trade reconciliation
     +-- Prong: ProviderOrderID / ProviderExecID -> FIX provider reconciliation
     +-- Prong: EMSOrderID / OMS* -> OMS reconciliation
```

---

## 3. Data Overview

N/A for User Defined Type. This is an in-memory parameter container; no rows are stored persistently.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeServerID | int | NO | - | CODE-BACKED | Hedge server that submitted this order. Identifies which server instance generated the execution attempt. Implicit FK to Trade.HedgeServer. |
| 2 | LiquidityAccountID | int | NO | - | CODE-BACKED | Liquidity (broker) account through which the order was routed. Identifies the FIX connection used. Implicit FK to Trade.LiquidityAccounts. |
| 3 | InstrumentID | int | NO | - | CODE-BACKED | Trading instrument the order was placed on (stock, crypto, forex). Implicit FK to Trade.Instrument. |
| 4 | OrderID | bigint | NO | - | CODE-BACKED | Internal hedge order identifier. Sequential ID assigned by the hedge server to this specific order attempt. |
| 5 | ParentOrderID | uniqueidentifier | NO | - | CODE-BACKED | GUID linking this execution record to its originating hedge request. Used when a single hedge request generates multiple fill events (partial fills). |
| 6 | Units | decimal(22,8) | YES | - | CODE-BACKED | Requested order size in instrument units (lots/shares). Nullable because the order may have been cancelled before units were determined. High precision (22,8) for fractional share support. |
| 7 | IsBuy | bit | NO | - | CODE-BACKED | Order direction: 1 = buy order (hedging a net short customer exposure), 0 = sell order (hedging a net long customer exposure). |
| 8 | OrderState | smallint | NO | - | CODE-BACKED | State of the order at the time of this log record. Maps to Dictionary.HedgeOrderState values (e.g., Sent, Filled, Rejected, Cancelled). |
| 9 | ProviderOrderID | varchar(50) | YES | - | CODE-BACKED | Order ID assigned by the liquidity provider (broker) in their system. Used for reconciliation with FIX execution reports. Latin1_General_BIN collation for exact matching. |
| 10 | SendTime | datetime2(7) | YES | - | CODE-BACKED | UTC timestamp when the order was transmitted to the liquidity provider via FIX. NULL if the send failed before transmission. High precision (7) for sub-millisecond latency measurement. |
| 11 | ProviderExecID | varchar(50) | YES | - | CODE-BACKED | Execution ID assigned by the liquidity provider upon fill. Populated only when the order was successfully executed. Used for post-trade confirmation matching. |
| 12 | ExecutionTime | datetime2(7) | YES | - | CODE-BACKED | UTC timestamp when the order was filled/executed by the liquidity provider. NULL for unfilled orders. Difference from SendTime gives execution latency. |
| 13 | ExecutionRate | dbo.dtPrice | YES | - | CODE-BACKED | The rate/price at which the order was executed by the liquidity provider. Uses the shared dtPrice user-defined type. NULL for unfilled or rejected orders. |
| 14 | FailID | int | YES | - | CODE-BACKED | Numeric failure code when the order failed. Maps to Hedge.ExecutionErrorMapping.FailID for categorized error classification. NULL on success. |
| 15 | FailReason | varchar(250) | YES | - | CODE-BACKED | Free-text failure description from the liquidity provider or hedge server. Complements FailID with human-readable error detail. NULL on success. |
| 16 | Success | bit | NO | - | CODE-BACKED | Execution outcome: 1 = order was successfully filled by the liquidity provider, 0 = order failed, rejected, or cancelled. Primary status flag for execution monitoring. |
| 17 | ProviderPartyIds | varchar(50) | YES | - | CODE-BACKED | FIX protocol party identifiers from the execution report, identifying counterparties involved in the trade. Used for multi-party trade reporting. |
| 18 | ReceivedTime | datetime2(7) | YES | - | CODE-BACKED | UTC timestamp when the execution report (FIX ExecReport) was received from the liquidity provider. Together with SendTime and ExecutionTime, enables round-trip latency analysis. |
| 19 | ProviderUnits | decimal(22,8) | YES | - | CODE-BACKED | Actual units executed as reported by the liquidity provider. May differ from Units if the order was partially filled. Discrepancy triggers reconciliation logic. |
| 20 | RateIDAtSent | bigint | YES | - | CODE-BACKED | Market rate snapshot ID at the moment the order was sent. Enables slippage analysis by comparing the rate quoted at send time vs. the actual execution rate. |
| 21 | EMSOrderID | varchar(50) | YES | - | CODE-BACKED | Order identifier from the Execution Management System (EMS). Cross-references the hedge order in the EMS for multi-system order tracking. |
| 22 | OMSProviderExecID | varchar(50) | YES | - | CODE-BACKED | Provider execution ID as recorded in the Order Management System (OMS). Used when orders flow through OMS in addition to EMS for reconciliation across both systems. |
| 23 | OMSProviderOrderID | varchar(50) | YES | - | CODE-BACKED | Provider order ID as recorded in the OMS. Cross-references the order between the hedge server's FIX connection and the OMS order book. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID | Trade.HedgeServer | Implicit | Identifies the hedge server that generated the execution |
| LiquidityAccountID | Trade.LiquidityAccounts | Implicit | Identifies the broker account through which the order was routed |
| InstrumentID | Trade.Instrument | Implicit | Identifies the instrument traded |
| FailID | Hedge.ExecutionErrorMapping | Implicit | Maps failure codes to categorized error types |
| OrderState | Dictionary.HedgeOrderState | Implicit | Maps order state integer to business label |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.ExecutionLogInsertBulk | @ExecutionLogRows parameter | TVP parameter | Receives bulk execution log rows for insert into Hedge.ExecutionLog |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (leaf TVP type).

Note: Uses `dbo.dtPrice` for the `ExecutionRate` column - a shared scalar type.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.dtPrice | User Defined Type (scalar) | Used as data type for ExecutionRate column |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ExecutionLogInsertBulk | Stored Procedure | Declares a parameter of this type for bulk execution log insert |

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

### 8.1 Check recent execution log for a hedge server
```sql
SELECT TOP 10 HedgeServerID, LiquidityAccountID, InstrumentID, OrderID,
       SendTime, ExecutionTime, Success, FailReason
FROM [Hedge].[ExecutionLog] WITH (NOLOCK)
WHERE HedgeServerID = 1
ORDER BY SendTime DESC
```

### 8.2 Analyze execution latency by hedge server
```sql
SELECT HedgeServerID,
       AVG(DATEDIFF(millisecond, SendTime, ReceivedTime)) AS AvgRoundTripMs,
       COUNT(*) AS TotalOrders,
       SUM(CASE WHEN Success = 1 THEN 1 ELSE 0 END) AS FilledOrders
FROM [Hedge].[ExecutionLog] WITH (NOLOCK)
WHERE SendTime >= DATEADD(hour, -1, GETUTCDATE())
  AND SendTime IS NOT NULL
GROUP BY HedgeServerID
ORDER BY AvgRoundTripMs DESC
```

### 8.3 Find failed executions with error detail
```sql
SELECT EL.HedgeServerID, EL.InstrumentID, EL.OrderID,
       EL.FailReason, EEM.ErrorCategory, EL.SendTime
FROM [Hedge].[ExecutionLog] EL WITH (NOLOCK)
LEFT JOIN [Hedge].[ExecutionErrorMapping] EEM WITH (NOLOCK)
  ON EL.FailID = EEM.FailID
WHERE EL.Success = 0
  AND EL.SendTime >= DATEADD(hour, -1, GETUTCDATE())
ORDER BY EL.SendTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 23 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.ExecutionLogTableType | Type: User Defined Type | Source: etoro/etoro/Hedge/User Defined Types/Hedge.ExecutionLogTableType.sql*
