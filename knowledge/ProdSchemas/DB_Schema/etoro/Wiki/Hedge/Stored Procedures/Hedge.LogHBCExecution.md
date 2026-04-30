# Hedge.LogHBCExecution

> Atomic transactional writer for the HBC execution audit trail: inserts one parent row into Hedge.HBCExecutionLog and all child orders from a Hedge.HBCOrder TVP into Hedge.HBCOrderLog in a single transaction. The sole SQL write path for HBC (Hedge By Customer) execution events; a failed TVP insert rolls back both writes.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Writes to Hedge.HBCExecutionLog + Hedge.HBCOrderLog atomically; @Orders TVP = Hedge.HBCOrder |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.LogHBCExecution` is the exclusive write path for recording HBC (Hedge By Customer) execution results. HBC is eToro's order-based hedging path where hedge orders are triggered directly by customer trade events and routed through the ExecutionAPI component of the HedgeServer.

When the HedgeServer finishes processing an HBC execution cycle, it calls this procedure once per execution attempt, passing the execution summary as scalar parameters and the individual FIX orders placed during that attempt as a `Hedge.HBCOrder` TVP. The procedure writes BOTH tables atomically:
1. **Hedge.HBCExecutionLog** - one row: the execution summary (result, lot amounts, rates, timing, success/failure).
2. **Hedge.HBCOrderLog** - one row per TVP entry: individual FIX orders placed within this execution cycle.

If the execution failed before any orders were placed (e.g., rate validation failure), the caller passes an empty `@Orders` TVP - HBCExecutionLog still gets a row (IsSuccess=0) but HBCOrderLog gets nothing. This is why HBCExecutionLog has rows without corresponding HBCOrderLog rows.

**Historical note**: The procedure comment states "@IsManualRequest" was renamed from "@ShouldWaitForConfirm". The column in `Hedge.HBCExecutionLog` retains the old name `ShouldWaitForConfirm` - the parameter was renamed to reflect that this flag indicates a manual dealer desk request (not just a "wait for confirm" flag). This disconnect is preserved in the INSERT mapping: `@IsManualRequest -> ShouldWaitForConfirm`.

---

## 2. Business Logic

### 2.1 Atomic Two-Table Write

**What**: Both the execution summary and all child orders are written in a single explicit transaction, preventing partial writes.

**Columns/Parameters Involved**: All scalar parameters, `@Orders TVP`

**Rules**:
- `BEGIN TRAN` wraps both INSERTs. Either both commit or neither does.
- First INSERT: HBCExecutionLog (one row, all scalar parameters).
- Second INSERT: HBCOrderLog (N rows from `SELECT ... FROM @Orders`).
- Empty TVP (@Orders with 0 rows): only HBCExecutionLog is written (failed/validation-rejected executions).

**Diagram**:
```
HedgeServer Application (HBC execution cycle complete)
  |
  | Builds @Orders Hedge.HBCOrder TVP (0 or more rows)
  | Sets scalar params: @ExecutionID, @IsSuccess, @FailReason, etc.
  v
EXEC Hedge.LogHBCExecution(@ExecutionID, ..., @IsSuccess, @FailReason, ..., @Orders)
  |
  | BEGIN TRAN
  |   INSERT INTO Hedge.HBCExecutionLog (1 row - execution summary)
  |   INSERT INTO Hedge.HBCOrderLog SELECT ... FROM @Orders (0..N rows)
  | COMMIT
  | -- OR -- BEGIN CATCH: rollback if @@TRANCOUNT=1, commit if nested; THROW
  v
Hedge.HBCExecutionLog: 1 row (execution result)
Hedge.HBCOrderLog:     0..N rows (individual FIX orders)
```

### 2.2 Nested Transaction Safety

**What**: The error handler distinguishes between standalone and nested transaction contexts.

**Columns/Parameters Involved**: `@@TRANCOUNT`

**Rules**:
- `IF @@TRANCOUNT = 1 -> ROLLBACK TRAN`: This procedure is the outermost transaction - roll back the work done here.
- `IF @@TRANCOUNT > 1 -> COMMIT TRAN`: This procedure is nested inside a caller's transaction - commit the inner savepoint, letting the outer transaction decide the final outcome.
- `THROW`: In both cases, the exception is re-raised to the caller. The hedge server application must handle it (log, retry, alert).

### 2.3 @IsManualRequest -> ShouldWaitForConfirm Mapping

**What**: Parameter name and column name diverged due to a refactoring - the INSERT explicitly maps the renamed parameter to the old column name.

**Columns/Parameters Involved**: `@IsManualRequest`, `ShouldWaitForConfirm`

**Rules**:
- The procedure comment: "changing parameter name from @ShouldWaitForConfirm to @IsManualRequest".
- DDL column in HBCExecutionLog: `ShouldWaitForConfirm BIT`.
- INSERT maps: `@IsManualRequest -> ShouldWaitForConfirm`.
- Semantics: `@IsManualRequest = 1` means this execution was initiated by a dealing desk operator via HedgeClient (manual order requiring explicit dealer confirmation), as opposed to an automated system-triggered hedge.
- NULL for standard automated HBC executions. True for manual dealing desk orders.

### 2.4 Lot Rounding: Requested vs Executed

**What**: The caller provides both the pre-rounding requested amount and the post-rounding executed amount.

**Columns/Parameters Involved**: `@RequestAmountInLots`, `@ExecutionAmountInLots`

**Rules**:
- `@RequestAmountInLots`: the exact lot amount calculated from exposure before lot-size rounding (e.g., 2.46 lots).
- `@ExecutionAmountInLots`: the actual lots submitted to and filled by the provider (whole number after ceiling rounding, e.g., 3.000000).
- Over-hedging by rounding up is by design. `GetHBCEstimationsDiscrepencies` validates that ExecutionAmountInLots matches the sum of customer position lot counts.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExecutionID | BIGINT | NO | - | CODE-BACKED | Externally assigned execution identifier (no IDENTITY in HBCExecutionLog). Assigned by the HedgeServer application. Maps to HBCExecutionLog.ExecutionID (CLUSTERED PK). Links to Trade position data via InitExecutionID/EndExecutionID. |
| 2 | @HedgeServerID | INT | NO | - | CODE-BACKED | The hedge server instance performing this execution. FK to Trade.HedgeServer. Maps to HBCExecutionLog.HedgeServerID. |
| 3 | @InstrumentID | INT | NO | - | CODE-BACKED | The instrument being hedged. Implicit FK to Trade.Instrument. Maps to HBCExecutionLog.InstrumentID. |
| 4 | @LiquidityAccountID | INT | NO | - | CODE-BACKED | The liquidity account (provider connection) used. FK to Trade.LiquidityAccounts. Maps to HBCExecutionLog.LiquidityAccountID. |
| 5 | @RequestAmountInLots | DECIMAL(16,6) | NO | - | CODE-BACKED | Pre-rounding lot amount calculated from exposure. May be fractional (e.g., 2.460000). Maps to HBCExecutionLog.RequestAmountInLots. |
| 6 | @ExecutionAmountInLots | DECIMAL(16,6) | NO | - | CODE-BACKED | Post-rounding lot amount actually submitted to the provider. Whole number in practice (e.g., 3.000000). Maps to HBCExecutionLog.ExecutionAmountInLots. |
| 7 | @IsBuy | BIT | NO | - | CODE-BACKED | Direction: 1=Buy hedge, 0=Sell hedge. Maps to HBCExecutionLog.IsBuy and propagated to all HBCOrderLog rows via @Orders TVP. |
| 8 | @IsManualRequest | BIT | NO | - | CODE-BACKED | Whether this is a manual dealer desk request. Renamed from @ShouldWaitForConfirm. Maps to HBCExecutionLog.ShouldWaitForConfirm (old column name retained). NULL for automated executions; 1 for dealing desk manual orders. |
| 9 | @InitialRate | dtPrice | NO | - | CODE-BACKED | eToro market rate at the time the hedge order was initiated (customer's reference rate). dbo.dtPrice high-precision decimal. Maps to HBCExecutionLog.InitialRate. |
| 10 | @ExecutionRate | dtPrice | NO | - | CODE-BACKED | The eToro-side execution rate recorded. May be spread-adjusted for manual or limit-adjusted for TP/SL executions. Maps to HBCExecutionLog.ExecutionRate. |
| 11 | @LPExecutionRate | dtPrice | NO | - | CODE-BACKED | The actual fill rate returned by the LP. NULL for failed executions (passed as 0/NULL by caller). Maps to HBCExecutionLog.LPExecutionRate. |
| 12 | @MarketRateIDAtExecutionEnd | BIGINT | NO | - | CODE-BACKED | Reference to the market rate record at execution completion. For post-trade audit. Maps to HBCExecutionLog.MarketRateIDAtExecutionEnd. |
| 13 | @IsSuccess | BIT | NO | - | CODE-BACKED | Whether the execution completed successfully: 1=success, 0=failure. Maps to HBCExecutionLog.IsSuccess. |
| 14 | @FailReason | VARCHAR(250) | YES | NULL | CODE-BACKED | Human-readable failure reason for @IsSuccess=0. NULL for successful executions. Maps to HBCExecutionLog.FailReason. |
| 15 | @IsCancelExecution | BIT | NO | - | CODE-BACKED | 1 if this is a cancellation of a previous execution. Maps to HBCExecutionLog.IsCancelExecution. |
| 16 | @CancelledExecutionID | BIGINT | NO | - | CODE-BACKED | For @IsCancelExecution=1: the ExecutionID being cancelled. 0 for non-cancel executions. Maps to HBCExecutionLog.CancelledExecutionID. |
| 17 | @StartTime | DATETIME | NO | - | CODE-BACKED | When the execution was initiated (order sent to provider). Maps to HBCExecutionLog.StartTime. |
| 18 | @EndTime | DATETIME | NO | - | CODE-BACKED | When the execution completed (fill received or failure detected). Maps to HBCExecutionLog.EndTime. |
| 19 | @Orders | Hedge.HBCOrder (TVP) | NO | - | CODE-BACKED | READONLY TVP containing individual FIX orders placed during this execution cycle. Each row maps to one HBCOrderLog row: (OrderID, ExecutionID, HedgeID, IsBuy, IsCancelOrder, OrderState, RequestAmountInLots, ExecutionAmountInLots, ExecutionRate, StartTime, EndTime, FailReason). Empty TVP for failed executions where no orders were placed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Hedge.HBCExecutionLog | Writer (INSERT) | Inserts one execution summary row (scalar parameters) |
| - | Hedge.HBCOrderLog | Writer (INSERT from TVP) | Inserts 0..N child order rows from @Orders TVP |

### 5.2 Referenced By (other objects point to this)

Not found in SQL repo. PROD\BIadmins holds VIEW DEFINITION permission. Called from the HedgeServer application's HBC execution logging path.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.LogHBCExecution (procedure)
|-- Hedge.HBCExecutionLog (table) [INSERT - execution summary]
|   |-- Trade.HedgeServer (FK)
|   +-- Trade.LiquidityAccounts (FK)
|-- Hedge.HBCOrderLog (table) [INSERT from @Orders TVP - child orders]
|   |-- Hedge.HBCExecutionLog (FK - back-reference to parent row just inserted)
|   +-- Dictionary.HBCOrderState (FK)
+-- Hedge.HBCOrder (TVP type) [@Orders parameter type]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.HBCExecutionLog | Table | INSERT target for execution summary |
| Hedge.HBCOrderLog | Table | INSERT target for child orders from TVP |
| Hedge.HBCOrder | User Defined Type (TVP) | @Orders parameter type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo. | - | Called from HedgeServer application HBC execution logging path. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| BEGIN TRAN / COMMIT | Explicit transaction | Both INSERTs (HBCExecutionLog + HBCOrderLog) are committed together or not at all. Prevents orphaned execution rows without child orders, or child order rows without a parent execution. |
| Nested transaction safety | @@TRANCOUNT check | IF @@TRANCOUNT = 1 -> ROLLBACK (standalone); IF @@TRANCOUNT > 1 -> COMMIT (nested inside outer transaction). THROW re-raises to caller in both cases. |
| @Orders READONLY | TVP parameter mode | The TVP is read-only - cannot be modified inside the procedure. |
| FK parent-before-child | Implicit ordering | HBCExecutionLog is inserted BEFORE HBCOrderLog to satisfy the FK (HBCOrderLog.ExecutionID -> HBCExecutionLog.ExecutionID WITH CHECK). |

---

## 8. Sample Queries

### 8.1 Log a successful HBC execution with one fill order
```sql
DECLARE @Orders Hedge.HBCOrder
INSERT INTO @Orders VALUES (
    NEWID(),        -- OrderID
    13797342,       -- ExecutionID
    998916,         -- HedgeID
    0,              -- IsBuy (sell)
    0,              -- IsCancelOrder
    2,              -- OrderState = Filled
    0.02,           -- RequestAmountInLots
    1,              -- ExecutionAmountInLots
    34933.70,       -- ExecutionRate
    GETUTCDATE(),   -- StartTime
    GETUTCDATE(),   -- EndTime
    NULL            -- FailReason
)

EXEC [Hedge].[LogHBCExecution]
    @ExecutionID              = 13797342,
    @HedgeServerID            = 1,
    @InstrumentID             = 100000,
    @LiquidityAccountID       = 10,
    @RequestAmountInLots      = 0.02,
    @ExecutionAmountInLots    = 1.0,
    @IsBuy                    = 0,
    @IsManualRequest          = 0,
    @InitialRate              = 34930.00,
    @ExecutionRate            = 34933.70,
    @LPExecutionRate          = 34933.70,
    @MarketRateIDAtExecutionEnd = 9876543210,
    @IsSuccess                = 1,
    @FailReason               = NULL,
    @IsCancelExecution        = 0,
    @CancelledExecutionID     = 0,
    @StartTime                = GETUTCDATE(),
    @EndTime                  = GETUTCDATE(),
    @Orders                   = @Orders
```

### 8.2 Verify the parent/child pair was written
```sql
SELECT el.ExecutionID, el.InstrumentID, el.IsSuccess,
       ol.OrderID, ol.OrderState, ol.ExecutionAmountInLots
FROM Hedge.HBCExecutionLog el WITH (NOLOCK)
JOIN Hedge.HBCOrderLog ol WITH (NOLOCK) ON ol.ExecutionID = el.ExecutionID
WHERE el.ExecutionID = 13797342
```

### 8.3 Failed executions (no child orders written)
```sql
SELECT el.ExecutionID, el.InstrumentID, el.FailReason, el.StartTime
FROM Hedge.HBCExecutionLog el WITH (NOLOCK)
WHERE el.IsSuccess = 0
  AND NOT EXISTS (
      SELECT 1 FROM Hedge.HBCOrderLog ol WITH (NOLOCK)
      WHERE ol.ExecutionID = el.ExecutionID
  )
ORDER BY el.StartTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL repo | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.LogHBCExecution | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.LogHBCExecution.sql*
