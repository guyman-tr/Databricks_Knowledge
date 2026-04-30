# Hedge.LogExecution

> Single-row writer for Hedge.ExecutionLog: records one state-transition event for a hedge order (sent, partial fill, fill, reject, cancel), supporting both the legacy HedgeServer order path (OrderID > 0) and the EMS/HBC path (OrderID = -1, EMSOrderID is the key). Called by the hedge server application on every execution lifecycle event.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Writes to Hedge.ExecutionLog; LogTime = GETUTCDATE() |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.LogExecution` is the primary single-row write path for `Hedge.ExecutionLog` - the central hedge execution audit trail. It is called by the hedge server application on each state transition of a hedge order: when the order is sent to the liquidity provider, when a partial fill is received, when the order is fully filled, and when it is rejected or cancelled. A single hedge order generates multiple calls to this procedure as it progresses through its lifecycle.

The procedure is a thin persistence layer with 23 parameters that map directly to ExecutionLog columns. The only server-side computation is `LogTime = GETUTCDATE()` - the DB insert timestamp. All other values are supplied by the calling application. A TRY/CATCH block re-throws any exceptions to the caller (THROW), ensuring the hedge server application can handle DB write failures and take corrective action (retry, alert, etc.).

Two execution paths share this procedure:
- **Legacy/HedgeServer path**: `@OrderID` > 0 (internal hedge order bigint); `@ParentOrderID` = GUID of the parent order.
- **EMS (Execution Management System) / HBC path**: `@OrderID` = -1 (sentinel value); `@EMSOrderID` = `"{ExternalID}_{sequence}"` string key (e.g., "35564138_1"); `@ParentOrderID` = NULL.

For bulk EMS execution logging, `Hedge.ExecutionLogInsertBulk` is used instead (TVP-based). This single-row variant is used when individual execution events arrive sequentially from the hedge server.

---

## 2. Business Logic

### 2.1 State Transition Logging (One Call Per Event)

**What**: Each call to LogExecution appends one row representing a single state event in an order's lifecycle.

**Columns/Parameters Involved**: `@OrderState`, `@Success`, `@FailID`, `@FailReason`, `@OrderID`, `@EMSOrderID`

**Rules**:
- Multiple rows per order are expected. A typical fill sequence: call with OrderState=2 (New - order acknowledged), then OrderState=3 (Partial fill), then OrderState=4 (Full fill) OR OrderState=5 (Reject).
- `@Success = 1` for fills (OrderState=4 and OrderState=3 partial fills). `@Success = 0` for rejects (OrderState=5) and failures.
- `@FailID` and `@FailReason`: populated only on failure/reject calls. NULL for successful state events.
- Hedge.ExecutionLog has NO primary key - multi-row-per-order is by design (append-only event log).

**Diagram**:
```
Hedge Server Application receives LP response
  |
  | For each order state event:
  |   @OrderState = 2 (New) -> first LP acknowledgement
  |   @OrderState = 3 (Partial) -> partial fill received
  |   @OrderState = 4 (Fill) -> fully filled
  |   @OrderState = 5 (Reject) -> LP rejected
  v
EXEC Hedge.LogExecution(@HedgeServerID, @LiquidityAccountID, ..., @OrderState, @Success, ...)
  |
  | BEGIN TRY
  | INSERT INTO Hedge.ExecutionLog(LogTime=GETUTCDATE(), ...)
  | END TRY / BEGIN CATCH -> THROW (re-raise to application)
  v
Hedge.ExecutionLog (one row per call, clustered by LogTime)
```

### 2.2 Legacy vs EMS Order Identity

**What**: Two fundamentally different order identification schemes are supported by the same parameters.

**Columns/Parameters Involved**: `@OrderID`, `@ParentOrderID`, `@EMSOrderID`, `@OMSProviderOrderID`, `@OMSProviderExecID`

**Rules**:
- **Legacy/HedgeServer path**: `@OrderID` > 0; `@ParentOrderID` = GUID of the parent hedge entity; `@EMSOrderID` = NULL.
- **EMS/HBC path**: `@OrderID` = -1 (sentinel - means "no legacy order ID applies"); `@ParentOrderID` = NULL (defaults to NULL); `@EMSOrderID` = "{ExternalID}_{sequence}" string format.
- **OMS path (subset of EMS)**: additionally provides `@OMSProviderOrderID` and `@OMSProviderExecID` for orders routed through the Order Management System layer.
- Downstream queries (GetExecutionLogData, SSRS_Latency_Report) branch on `OrderID = -1` to choose the appropriate join key (EMSOrderID vs OrderID).

### 2.3 Latency Chain Timestamps

**What**: Three caller-provided timestamps and one DB-generated timestamp together enable full execution latency measurement.

**Columns/Parameters Involved**: `@SendTime`, `@ReceivedTime`, `@ExecutionTime`

**Rules**:
- `LogTime` = `GETUTCDATE()` at INSERT time (DB server, not application). Measures DB logging lag (time from receipt to persistence).
- `@SendTime` (DATETIME2): when the order was dispatched to the LP. Set by the hedge server application.
- `@ReceivedTime` (DATETIME2): when the LP execution response was received by the application.
- `@ExecutionTime` (DATETIME2): the LP's own timestamp for when the execution occurred.
- Latency metrics computed by SSRS_Latency_Report: `SendTime - RequestTime` = internal processing; `ReceivedTime - SendTime` = provider round-trip; `LogTime` used for DB write lag monitoring.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | INT | NO | - | CODE-BACKED | The hedge server instance writing this execution event. Maps to ExecutionLog.HedgeServerID. FK to Trade.HedgeServer. |
| 2 | @LiquidityAccountID | INT | NO | - | CODE-BACKED | The liquidity provider account (connection) used for this execution. Maps to ExecutionLog.LiquidityAccountID. FK to Trade.LiquidityAccounts. |
| 3 | @InstrumentID | INT | NO | - | CODE-BACKED | The instrument being hedged. Maps to ExecutionLog.InstrumentID. Implicit FK to Trade.Instrument. |
| 4 | @OrderID | BIGINT | NO | - | CODE-BACKED | Internal hedge order identifier. Legacy path: positive bigint from hedge order system. EMS/HBC path: -1 (sentinel - EMSOrderID is the key instead). Maps to ExecutionLog.OrderID. |
| 5 | @ParentOrderID | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | GUID of the parent hedge order. Legacy path: the parent order GUID. EMS path: NULL (defaults). Maps to ExecutionLog.ParentOrderID. |
| 6 | @Units | DECIMAL(22,8) | NO | - | CODE-BACKED | Quantity of units in the hedge order. High precision (22,8) for both large volumes and fractional crypto instruments. Maps to ExecutionLog.Units. |
| 7 | @ProviderUnits | DECIMAL(22,8) | YES | NULL | CODE-BACKED | Quantity executed by the LP in this event. For partial fills: the partial amount. NULL for order state events (New, Reject) where no units were executed. Maps to ExecutionLog.ProviderUnits. |
| 8 | @IsBuy | BIT | NO | - | CODE-BACKED | Direction of the hedge order: 1=Buy, 0=Sell. Maps to ExecutionLog.IsBuy. |
| 9 | @OrderState | SMALLINT | NO | - | CODE-BACKED | The order lifecycle state for this event: 2=New, 3=Partial, 4=Fill, 5=Reject, 7=Cancelled. FK to Dictionary.HedgeOrderState (stored WITH NOCHECK in target table). Maps to ExecutionLog.OrderState. |
| 10 | @SendTime | DATETIME2 | NO | - | CODE-BACKED | When the order was sent to the LP. DATETIME2 for sub-millisecond precision. Maps to ExecutionLog.SendTime. Used in Metric 1 latency calculation (RequestTime to SendTime). |
| 11 | @ProviderOrderID | VARCHAR(50) | YES | NULL | CODE-BACKED | LP-assigned order ID (GUID format for FIX-based LPs). Populated when LP acknowledges the order. Maps to ExecutionLog.ProviderOrderID. |
| 12 | @ProviderExecID | VARCHAR(50) | YES | NULL | CODE-BACKED | LP execution confirmation ID. Populated on fill/partial fill. Used for trade reconciliation. Maps to ExecutionLog.ProviderExecID. |
| 13 | @ExecutionTime | DATETIME2 | YES | NULL | CODE-BACKED | LP's own timestamp for execution. May differ from ReceivedTime due to network latency. The authoritative trade timestamp for P&L. Maps to ExecutionLog.ExecutionTime. |
| 14 | @ExecutionRate | dtPrice | YES | NULL | CODE-BACKED | Fill price returned by the LP. dbo.dtPrice = high-precision decimal. Used in volume-weighted average rate by GetExecutionLogData: SUM(Units * ExecutionRate) / SUM(Units). Maps to ExecutionLog.ExecutionRate. |
| 15 | @FailID | INT | YES | NULL | CODE-BACKED | Numeric error code from the LP or internal routing. Populated when @Success = 0. Maps to ExecutionLog.FailID. |
| 16 | @FailReason | VARCHAR(50) | YES | NULL | CODE-BACKED | Free-text rejection reason from the LP. Populated when @Success = 0. Common values: "price stale", "no liquidity", "size exceeded". Maps to ExecutionLog.FailReason. |
| 17 | @Success | BIT | NO | - | CODE-BACKED | Whether this event represents a successful outcome: 1=fill or partial fill; 0=reject or failure. Maps to ExecutionLog.Success. Filter key in the NC index on ExecutionLog. |
| 18 | @ProviderPartyIDs | VARCHAR(50) | YES | NULL | CODE-BACKED | FIX protocol party identifiers (clearing firm, broker IDs) from the execution report. Maps to ExecutionLog.ProviderPartyIds. |
| 19 | @ReceivedTime | DATETIME2 | YES | NULL | CODE-BACKED | When the hedge server application received the LP execution response. Metric 2 = DATEDIFF(ms, SendTime, ReceivedTime) = provider round-trip. Maps to ExecutionLog.ReceivedTime. |
| 20 | @RateIDAtSent | BIGINT | YES | NULL | CODE-BACKED | ID of the price rate snapshot active when the order was sent. Used for slippage analysis (rate at send vs execution rate). NULL for EMS orders. Maps to ExecutionLog.RateIDAtSent. |
| 21 | @EMSOrderID | VARCHAR(50) | YES | NULL | CODE-BACKED | EMS order identifier. Format: "{ExternalID}_{sequence}" (e.g., "35564138_1"). Primary key for EMS/HBC flow when @OrderID = -1. Join key in SSRS_Latency_Report and GetExecutionLogData. Maps to ExecutionLog.EMSOrderID. |
| 22 | @OMSProviderExecID | VARCHAR(50) | YES | NULL | CODE-BACKED | OMS (Order Management System) execution confirmation ID for OMS-routed orders. NULL for direct EMS. Maps to ExecutionLog.OMSProviderExecID. |
| 23 | @OMSProviderOrderID | VARCHAR(50) | YES | NULL | CODE-BACKED | OMS order ID for orders routed through the OMS layer. NULL for direct EMS. Enables reconciliation with OMS-side records. Maps to ExecutionLog.OMSProviderOrderID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Hedge.ExecutionLog | Writer (INSERT) | Inserts one execution event row; LogTime set to GETUTCDATE() server-side |

### 5.2 Referenced By (other objects point to this)

Not analyzed in SQL repo (no SQL callers found). Called from the hedge server application on each order state transition event.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.LogExecution (procedure)
+-- Hedge.ExecutionLog (table) [INSERT - one execution state event per call]
    |-- Trade.HedgeServer (FK)
    |-- Trade.LiquidityAccounts (FK)
    +-- Dictionary.HedgeOrderState (FK, NOCHECK)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ExecutionLog | Table | INSERT target for execution state events |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo. | - | Called from hedge server application on each order state transition. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TRY/CATCH with THROW | Error handling | All exceptions are re-thrown to the caller. The hedge server application handles DB write failures (retry, circuit break, alert). |
| LogTime = GETUTCDATE() | Server-side timestamp | DB insert time is always the DB server's UTC clock - not a caller parameter. Ensures consistent time source for the clustered index. |

---

## 8. Sample Queries

### 8.1 Log a successful fill for a legacy order
```sql
EXEC [Hedge].[LogExecution]
    @HedgeServerID       = 1,
    @LiquidityAccountID  = 10,
    @InstrumentID        = 1,
    @OrderID             = 998916,
    @ParentOrderID       = '6B29FC40-CA47-1067-B31D-00DD010662DA',
    @Units               = 100000.0,
    @ProviderUnits       = 100000.0,
    @IsBuy               = 1,
    @OrderState          = 4,   -- Fill
    @SendTime            = '2026-03-19 10:00:00.000',
    @ExecutionRate       = 1.08550,
    @Success             = 1,
    @ReceivedTime        = '2026-03-19 10:00:00.050',
    @ExecutionTime       = '2026-03-19 10:00:00.045'
```

### 8.2 Log an EMS partial fill
```sql
EXEC [Hedge].[LogExecution]
    @HedgeServerID       = 2,
    @LiquidityAccountID  = 8,
    @InstrumentID        = 1008,
    @OrderID             = -1,       -- EMS sentinel
    @Units               = 6.0,
    @ProviderUnits       = 3.0,      -- partial
    @IsBuy               = 0,
    @OrderState          = 3,        -- Partial
    @SendTime            = GETUTCDATE(),
    @Success             = 1,
    @EMSOrderID          = '35564138_1'
```

### 8.3 Check recent executions logged by this procedure (single-row path)
```sql
SELECT TOP 20 LogTime, HedgeServerID, InstrumentID, OrderID, EMSOrderID,
       IsBuy, OrderState, Success, Units, ProviderUnits, ExecutionRate,
       FailReason, DATEDIFF(ms, SendTime, ReceivedTime) AS ProviderRoundTripMS
FROM [Hedge].[ExecutionLog] WITH (NOLOCK)
WHERE OrderID > 0   -- legacy path (non-EMS)
ORDER BY LogTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 23 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL repo | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.LogExecution | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.LogExecution.sql*
