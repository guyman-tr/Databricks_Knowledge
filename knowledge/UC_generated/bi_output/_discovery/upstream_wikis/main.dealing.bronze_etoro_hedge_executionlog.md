# Hedge.ExecutionLog

> High-volume append-only log of every hedge order execution event - each row captures a single state transition (sent, partial fill, fill, reject, cancel) from a liquidity provider, enabling fill rate analysis, latency measurement, and execution discrepancy detection.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | No PK. CLUSTERED index on LogTime (time-ordered append log) |
| **Partition** | No |
| **Indexes** | 2 active (CLUSTERED on LogTime + NC on LiquidityAccountID, LogTime DESC, Success, OrderID) - both FILLFACTOR=95 |

---

## 1. Business Meaning

Hedge.ExecutionLog is the central execution audit trail for the eToro hedge system. Every time a hedge order changes state - when it is sent to the liquidity provider, when it receives a partial fill, when it is fully filled, rejected, or cancelled - a row is written to this table. Each row is a snapshot of the order's state at a specific moment in time; multiple rows can exist for the same order as it progresses through its lifecycle.

The table holds 2,374,781 rows spanning 2023-01-04 to 2026-03-19 and is actively written. 69% of rows are successful executions; 31% are rejections or failures - typical for a high-frequency hedge execution environment where partial fills and re-routing are common.

Unlike most log tables, Hedge.ExecutionLog has **no primary key constraint** - it relies solely on a clustered index on LogTime for physical ordering. This is an intentional design for a high-write append-only table where uniqueness is not enforced at the DB level. The hedge server generates unique identifiers (OrderID/EMSOrderID) that serve as logical identifiers.

The table supports two execution flows:
- **Legacy/HedgeServer flow**: OrderID is the internal hedge order ID (bigint > 0), ParentOrderID is a GUID
- **EMS (Execution Management System) / HBC flow**: OrderID = -1, EMSOrderID is the key identifier in format `{ExternalID}_{sequence}` (e.g., "35564138_1")

---

## 2. Business Logic

### 2.1 Order State Lifecycle

**What**: Each row represents one state transition in an order's lifecycle. An order may generate multiple rows.

**Columns/Parameters Involved**: `OrderID`, `OrderState`, `Success`, `FailID`, `FailReason`

**Rules**:
- OrderState FK to Dictionary.HedgeOrderState (WITH NOCHECK - existing rows not re-validated):

| ID | Name | Count | Success |
|---|---|---|---|
| 0 | None | - | - |
| 1 | Sent | 0 (not observed) | - |
| 2 | New | 150,367 | mixed |
| 3 | Partial | 1,040,923 | mixed |
| 4 | Fill | 455,368 | 1 |
| 5 | Reject | 727,763 | 0 |
| 6 | Fail | 0 (not observed) | 0 |
| 7 | Cancelled | 360 | - |

- A typical fill sequence: OrderState=2 (New - order acknowledged), then one or more OrderState=3 (Partial fill), then OrderState=4 (Full fill) OR OrderState=5 (Reject).
- Success=1 for fills (OrderState=4); Success=0 for rejects (OrderState=5).
- FailID and FailReason are populated for failed/rejected orders: FailID is a numeric error code; FailReason is a varchar description from the provider.
- **No PK**: Multiple rows per order are expected and intentional. The table is a timeline of state transitions, not a current-state snapshot.

### 2.2 EMS vs Legacy Order Identification

**What**: Two different order identification schemes coexist in the table depending on which execution pathway generated the order.

**Columns/Parameters Involved**: `OrderID`, `ParentOrderID`, `EMSOrderID`, `OMSProviderOrderID`, `OMSProviderExecID`

**Rules**:
- **Legacy/HedgeServer path**: `OrderID` > 0 (e.g., the internal hedge order ID from Trade.HedgeOrders); `ParentOrderID` is the parent hedge order GUID; `EMSOrderID` is NULL.
- **EMS/HBC path**: `OrderID` = -1; `ParentOrderID` = GUID(0) (00000000-...); `EMSOrderID` = "{ExternalID}_{sequence}" string key; `OMSProviderOrderID` and `OMSProviderExecID` are present for OMS-routed orders (NULL for direct EMS).
- The SSRS_Latency_Report joins this table to EMS orders via `EMSOrderID COLLATE Latin1_General_BIN` (binary collation match needed for case-sensitive comparison).
- GetExecutionLogData queries by `EMSOrderID` to get aggregated partial fills for an EMS order.

### 2.3 Execution Latency Chain

**What**: Multiple timestamps capture each phase of the execution latency, enabling end-to-end measurement.

**Columns/Parameters Involved**: `LogTime`, `SendTime`, `ReceivedTime`, `ExecutionTime`

**Rules**:
- `LogTime` = GETUTCDATE() at DB insert (set by LogExecution and ExecutionLogInsertBulk procedures). DB server time; measures logging lag.
- `SendTime` = datetime2(7) when the order was sent to the liquidity provider. Set by the calling application.
- `ReceivedTime` = datetime2(7) when the execution response was received from the provider.
- `ExecutionTime` = datetime2(7) from the provider's own timestamp confirming the execution.
- Latency calculations used in SSRS_Latency_Report:
  - Metric 1: `DATEDIFF(ms, RequestTime, SendTime)` = Request processing time (CES/HBS to first order send)
  - Metric 2: `DATEDIFF(ms, SendTime, ReceivedTime)` = Provider round-trip latency (market response time)
  - Metric 3: `DATEDIFF(ms, ReceivedTime, StatusUpdateTime)` = Response processing time (received to status update)
  - Metric 4: Metric1 + Metric3 = Total internal latency (excluding provider market time)
  - Metric 5: Execution throughput (orders per second per LiquidityAccount)

### 2.4 Partial Fill Aggregation

**What**: GetExecutionLogData aggregates partial fills for an EMS order to compute total executed units and average rate.

**Columns/Parameters Involved**: `EMSOrderID`, `OrderState`, `Units`, `ExecutionRate`, `LogTime`

**Rules**:
- Filter: `OrderState = 3` (Partial fills only) + `EMSOrderID` match + time window
- Returns: `SUM(Units)` as TotalExecutedUnits; `SUM(Units * ExecutionRate) / SUM(Units)` as volume-weighted average execution rate
- `LogTime BETWEEN @FromDate AND DATEADD(SECOND, -5, @ToDate)` - 5-second trailing buffer prevents reading race-condition rows from concurrent inserts
- This pattern is used by the EMS system to reconcile partial fill sequences against the expected total.

### 2.5 Provider Identifiers

**What**: The table tracks both eToro-side and provider-side identifiers for cross-system reconciliation.

**Columns/Parameters Involved**: `ProviderOrderID`, `ProviderExecID`, `ProviderPartyIds`, `RateIDAtSent`

**Rules**:
- `ProviderOrderID` (varchar 50): The order ID assigned by the liquidity provider (GUID format for FIX-based providers like ZBFX).
- `ProviderExecID` (varchar 50): The execution confirmation ID from the provider. Populated on fill/partial fill.
- `ProviderPartyIds` (varchar 50): FIX party identifiers (e.g., clearing firm, broker IDs) from the execution report.
- `RateIDAtSent` (bigint): The ID of the price rate snapshot that was active when the order was sent. Used for slippage analysis: comparing the rate sent vs. the rate received.

---

## 3. Data Overview

2,374,781 rows | Active table (2023-01-04 to 2026-03-19 in this environment)

| LogTime | HedgeServerID | LiquidityAccountID | InstrumentID | OrderID | IsBuy | OrderState | Success | Units | ProviderUnits | EMSOrderID | Meaning |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 2026-03-19 00:04:47 | 2 | 8 | 1008 | -1 | false | 4 (Fill) | true | 6 | 6 | "35564138_1" | EMS order fully filled - 6 units of InstrumentID 1008 sold via LiquidityAccount 8. |
| Recent typical | 2 | 8 | varies | -1 | false | 3 (Partial) | true | N | N | "{ID}_{seq}" | Partial fill in a multi-fill sequence. SUM'd by GetExecutionLogData for weighted avg rate. |
| Historical | varies | varies | varies | >0 | varies | 5 (Reject) | false | N | null | null | Legacy HedgeServer order rejected. FailReason explains the provider's reason. |

**Distribution summary**:
- OrderState=3 (Partial) = 44% of rows - dominant state in partial-fill heavy execution model
- OrderState=5 (Reject) = 31% of rows - typical for institutional execution (rejects trigger re-routing)
- Success=true: 69% | Success=false: 31%
- All recent active rows use HedgeServerID=2, LiquidityAccountID=8 (EMS path with OrderID=-1)

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LogTime | datetime2(7) | NO | - | CODE-BACKED | DB server UTC timestamp at row insert, set to GETUTCDATE() by LogExecution and ExecutionLogInsertBulk. Clustered index key - rows are physically ordered by log insert time. Used as the primary range filter for all time-window queries. |
| 2 | HedgeServerID | int | NO | - | CODE-BACKED | FK to Trade.HedgeServer(HedgeServerID). The hedge server that generated and sent this execution order to the provider. |
| 3 | LiquidityAccountID | int | NO | - | CODE-BACKED | FK to Trade.LiquidityAccounts(LiquidityAccountID). The liquidity provider account on which this order was executed. Used as a grouping key in the NC index and latency reports. |
| 4 | InstrumentID | int | NO | - | CODE-BACKED | The instrument being hedged (e.g., EUR/USD, Apple stock). Implicitly references Trade.Instrument. |
| 5 | OrderID | bigint | NO | - | CODE-BACKED | Internal hedge order identifier. Legacy path: positive bigint matching the hedge order system. EMS/HBC path: -1 (not applicable - EMSOrderID is the key instead). Not the OrderID from Trade.OpenedPositions - this is the hedge system's own order tracking ID. |
| 6 | ParentOrderID | uniqueidentifier | NO | - | CODE-BACKED | GUID identifying the parent hedge order that spawned this execution. EMS path: GUID(0) (all zeros = no parent). Legacy path: the parent hedge order GUID. |
| 7 | IsBuy | bit | NO | - | CODE-BACKED | Direction of the hedge order from eToro's perspective: 1=Buy, 0=Sell. A hedge order direction is typically the opposite of the customer net position. |
| 8 | OrderState | smallint | NO | - | CODE-BACKED | FK to Dictionary.HedgeOrderState (WITH NOCHECK). Current state of this order row: 0=None, 1=Sent, 2=New, 3=Partial, 4=Fill, 5=Reject, 6=Fail, 7=Cancelled. One order generates multiple rows as it transitions through states. |
| 9 | ProviderOrderID | varchar(50) | YES | - | CODE-BACKED | The order ID assigned by the liquidity provider (typically a GUID from FIX protocol). Populated when the provider acknowledges the order (OrderState >= 2). Used for reconciliation with provider statements. |
| 10 | SendTime | datetime2(7) | YES | - | CODE-BACKED | Precision timestamp when the order was dispatched to the liquidity provider. Used for Metric 1 (Request_Process_Time = RequestTime to SendTime) in latency analysis. |
| 11 | ProviderExecID | varchar(50) | YES | - | CODE-BACKED | Execution confirmation ID from the liquidity provider (GUID format). Populated on fill or partial fill (OrderState 3/4). Used for trade reconciliation and dispute resolution with the provider. |
| 12 | ExecutionTime | datetime2(7) | YES | - | CODE-BACKED | The provider's own timestamp for when the execution occurred. May differ from ReceivedTime due to network latency. Used as the authoritative trade timestamp for P&L calculations. |
| 13 | ExecutionRate | dbo.dtPrice | YES | - | CODE-BACKED | The actual execution price returned by the liquidity provider. Used in weighted average rate calculation: SUM(Units * ExecutionRate) / SUM(Units) by GetExecutionLogData. |
| 14 | FailID | int | YES | - | CODE-BACKED | Numeric error/failure code from the provider or internal routing system. Populated when Success=0. Used for categorizing reject reasons in monitoring. |
| 15 | FailReason | varchar(250) | YES | - | CODE-BACKED | Free-text rejection reason from the provider. Populated when Success=0. Typical reasons include price stale, no liquidity, size exceeded, connection failure. |
| 16 | Success | bit | NO | - | CODE-BACKED | Indicates whether this execution event represents a successful outcome: 1=successful fill or partial fill; 0=rejection or failure. Used as a filter key in the NC index and fill rate calculations. |
| 17 | ProviderPartyIds | varchar(50) | YES | - | CODE-BACKED | FIX protocol party identifiers from the execution report (e.g., clearing firm, broker, settlement IDs). Populated for providers using FIX party tags. |
| 18 | ReceivedTime | datetime2(7) | YES | - | CODE-BACKED | Precision timestamp when the hedge server received the execution response from the provider. Metric 2 = DATEDIFF(ms, SendTime, ReceivedTime) = Provider round-trip latency. |
| 19 | RateIDAtSent | bigint | YES | - | CODE-BACKED | ID of the price rate snapshot that was active when the order was sent. Used for slippage analysis by comparing execution rate vs. rate at send time. NULL for EMS orders where rate tracking uses a different mechanism. |
| 20 | OMSProviderExecID | varchar(50) | YES | - | CODE-BACKED | OMS (Order Management System) execution confirmation ID. Populated for OMS-routed orders. NULL for direct EMS orders (OrderID=-1 in recent data). |
| 21 | OMSProviderOrderID | varchar(50) | YES | - | CODE-BACKED | OMS order ID for orders routed through the OMS layer. NULL for direct EMS orders. Enables reconciliation with OMS-side execution records. |
| 22 | Units | decimal(22,8) | YES | - | CODE-BACKED | The quantity of units requested in the hedge order. High precision (22,8) to support both large quantities and fractional instruments (crypto). |
| 23 | ProviderUnits | decimal(22,8) | YES | - | CODE-BACKED | The quantity actually executed by the provider in this event. For partial fills, ProviderUnits < Units. Sum of ProviderUnits across all OrderState=3 rows for an order gives total filled. |
| 24 | EMSOrderID | varchar(50) | YES | - | CODE-BACKED | EMS (Execution Management System) order identifier. Format: "{ExternalID}_{sequence}" (e.g., "35564138_1"). The primary key for EMS/HBC flow orders (when OrderID=-1). Used as the join key in SSRS_Latency_Report and by GetExecutionLogData for partial fill aggregation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID | Trade.HedgeServer | FK (WITH NOCHECK) | FK_ExecutionLog_HedgeServer |
| LiquidityAccountID | Trade.LiquidityAccounts | FK (WITH NOCHECK) | FK_ExecutionLog_LiquidityAccounts |
| OrderState | Dictionary.HedgeOrderState | FK (WITH NOCHECK) | FK_ExecutionLog_HedgeOrderState - state classification |
| InstrumentID | Trade.Instrument | Implicit (no DDL FK) | Instrument being hedged |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.LogExecution | - | Writer | Single-row insert for one execution event |
| Hedge.ExecutionLogInsertBulk | @ExecutionLogData TVP | Writer | Bulk insert via Hedge.ExecutionLogTableType TVP |
| Hedge.GetExecutionLogData | EMSOrderID | Reader | Aggregates partial fills (OrderState=3) for EMS order reconciliation |
| Hedge.SSRS_Latency_Report | OrderID / EMSOrderID | Reader | Computes 5 latency metrics (P90/P99) per LiquidityAccount for SSRS reporting |
| Hedge.GetHBCEstimationsDiscrepencies* | OrderID | Reader | HBC discrepancy analysis (4 variants) |
| Hedge.GetLastOrderID | OrderID | Reader | Returns the most recent OrderID for a hedge server |
| Hedge.InsertKPIData | EventType=8 check | Reader | Dedup check using EventLog (not ExecutionLog directly, but referenced in same proc) |
| Hedge.ViewExecutionLog_isnull | - | Reader | View over this table |
| Hedge.ListUnsupportedInstruments | - | Reader | Identifies instruments with recent failures |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ExecutionLog (table)
  - FK: Trade.HedgeServer (HedgeServerID)
  - FK: Trade.LiquidityAccounts (LiquidityAccountID)
  - FK: Dictionary.HedgeOrderState (OrderState)
  - Implicit: Trade.Instrument (InstrumentID)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeServer | Table | FK target for HedgeServerID |
| Trade.LiquidityAccounts | Table | FK target for LiquidityAccountID |
| Dictionary.HedgeOrderState | Table | FK target for OrderState (8 states: None through Cancelled) |
| dbo.dtPrice | User Defined Type | ExecutionRate column type |
| Hedge.ExecutionLogTableType | User Defined Type | TVP type for ExecutionLogInsertBulk |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.LogExecution | Procedure | Primary single-row writer |
| Hedge.ExecutionLogInsertBulk | Procedure | Bulk writer via TVP |
| Hedge.GetExecutionLogData | Procedure | Aggregates partial fills by EMSOrderID |
| Hedge.SSRS_Latency_Report | Procedure | End-to-end latency reporting (P90/P99 per liquidity account) |
| Hedge.GetHBCEstimationsDiscrepencies | Procedure (x4) | HBC execution discrepancy analysis |
| Hedge.GetLastOrderID | Procedure | Returns max OrderID |
| Hedge.ViewExecutionLog_isnull | View | View wrapper with ISNULL handling |
| Hedge.ListUnsupportedInstruments | Procedure | Failed execution instrument analysis |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| IDX_LogTime | CLUSTERED | LogTime ASC | - | - | Active (FILLFACTOR=95, PAGE compression) |
| IDX_HedgeExecutionLog_LogTime | NONCLUSTERED | LiquidityAccountID ASC, LogTime DESC, Success ASC, OrderID ASC | - | - | Active (FILLFACTOR=95, MAIN filegroup) |

**Design notes**:
- No PK constraint - the table is intentionally heap-like (append-only log). The clustered index on LogTime provides time-ordered physical storage for range queries.
- NC index on (LiquidityAccountID, LogTime DESC, Success, OrderID) supports per-account fill rate queries and the account-scoped portions of latency reports.
- Both indexes use FILLFACTOR=95 (95% page fill) to accommodate appends without excessive page splits.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_ExecutionLog_HedgeOrderState | FOREIGN KEY (WITH NOCHECK) | OrderState -> Dictionary.HedgeOrderState(ID) |
| FK_ExecutionLog_HedgeServer | FOREIGN KEY (WITH NOCHECK) | HedgeServerID -> Trade.HedgeServer(HedgeServerID) |
| FK_ExecutionLog_LiquidityAccounts | FOREIGN KEY (WITH NOCHECK) | LiquidityAccountID -> Trade.LiquidityAccounts(LiquidityAccountID) |

**WITH NOCHECK**: All three FKs are defined WITH NOCHECK, meaning existing rows are not validated against the FK targets. This was likely done for performance when the FKs were added to an already-populated table.

---

## 8. Sample Queries

### 8.1 Fill rate by liquidity account (last 24 hours)
```sql
SELECT LiquidityAccountID,
       COUNT(1) AS TotalEvents,
       SUM(CASE WHEN OrderState = 4 THEN 1 ELSE 0 END) AS Fills,
       SUM(CASE WHEN OrderState = 5 THEN 1 ELSE 0 END) AS Rejects,
       CAST(SUM(CASE WHEN OrderState = 4 THEN 1.0 ELSE 0 END) / NULLIF(COUNT(1),0) AS decimal(5,2)) AS FillRate
FROM Hedge.ExecutionLog WITH (NOLOCK)
WHERE LogTime > DATEADD(day, -1, GETUTCDATE())
GROUP BY LiquidityAccountID
ORDER BY LiquidityAccountID;
```

### 8.2 Trace a single EMS order's fill sequence
```sql
SELECT LogTime, OrderState, Success, Units, ProviderUnits, ExecutionRate,
       FailReason, ReceivedTime, SendTime
FROM Hedge.ExecutionLog WITH (NOLOCK)
WHERE EMSOrderID = '35564138_1'
ORDER BY LogTime;
```

### 8.3 Provider round-trip latency (SendTime to ReceivedTime) - last hour fills
```sql
SELECT LiquidityAccountID,
       AVG(DATEDIFF(MILLISECOND, SendTime, ReceivedTime)) AS AvgLatencyMs,
       MAX(DATEDIFF(MILLISECOND, SendTime, ReceivedTime)) AS MaxLatencyMs,
       COUNT(1) AS FillCount
FROM Hedge.ExecutionLog WITH (NOLOCK)
WHERE LogTime > DATEADD(hour, -1, GETUTCDATE())
  AND OrderState = 4
  AND SendTime IS NOT NULL AND ReceivedTime IS NOT NULL
GROUP BY LiquidityAccountID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for Hedge.ExecutionLog.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 24 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,3,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.ExecutionLog | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.ExecutionLog.sql*
