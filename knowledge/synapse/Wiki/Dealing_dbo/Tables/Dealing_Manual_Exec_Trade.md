---
object: Dealing_Manual_Exec_Trade
schema: Dealing_dbo
type: Table
description: Trade-level detail for manual hedge executions: each row is one LP order placed by a dealer, with instrument, direction, units, execution rate, sender identity, and request type. Active.
etl_sp: Dealing_dbo.SP_Manual_Exec_Trade
frequency: Daily
status: Active (last: 2026-03-10)
row_count: not sampled (daily inserts)
distribution: ROUND_ROBIN
index: CLUSTERED (Date ASC)
batch: 14
quality: 8.5
---

# Dealing_Manual_Exec_Trade

Row-level log of individual manual hedge orders sent to LPs by dealers. Each record represents one order from `External_Etoro_Hedge_ManualOrderExecutionLog` (RequestTypeID 0 = executed, or 3 = special type) joined to the execution log. The `Sender` field identifies who placed the order. Active through 2026-03-10.

## Source & Lineage

| Layer | Object | Role |
|-------|--------|------|
| Source | `Dealing_staging.External_Etoro_Hedge_ManualOrderExecutionLog` | Manual orders (RequestTypeID IN (0,3)) |
| Source | `Dealing_staging.Etoro_Hedge_ExecutionLog` | Actual execution details (Units, ExecutionRate, LP) |
| Dimension | `DWH_dbo.Dim_Instrument` | InstrumentDisplayName |
| Reference | `Dealing_staging.etoro_Trade_LiquidityAccounts` | LiquidityAccountID → name |
| Writer | `Dealing_dbo.SP_Manual_Exec_Trade` | Daily, OpsDB Priority 0 |

**Join logic**: ManualOrderExecutionLog (OrderID) LEFT JOIN ExecutionLog (ParentOrderID). Filter: `Success=1 OR RequestTypeID=3`. Units are signed: Buy → positive, Sell → negative (×−1 multiplier).

**RequestTypeID values**:
- 0 = Executed (standard manual order)
- 3 = Special type (included even if not matched in ExecutionLog)

**Sender format**: "HedgeClient102 (by donco)" — system component + operator name in parentheses.

Also populates `Dealing_Manual_Exec_Trade_Summary` in the same SP execution.

## Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `Date` | date | NULL | Report date. |
| `OrderID` | varchar(100) | NULL | UUID of the manual order from ManualOrderExecutionLog. Links to LP-side order tracking. |
| `InstrumentID` | int | NULL | Instrument traded. Resolved from ExecutionLog or ManualOrder (ISNULL fallback). |
| `InstrumentDisplayName` | varchar(100) | NULL | Instrument display name. Denormalized from Dim_Instrument. |
| `HedgeServer` | int | NULL | Hedge server ID. Note: stored as `HedgeServer` (no "ID") unlike other tables. |
| `LiquidityAccountID` | int | NULL | LP account identifier. |
| `LiquidityAccountName` | varchar(100) | NULL | LP account name. Denormalized. |
| `IsBuy` | int | NULL | 1 = buy order, 0 = sell order. |
| `Units` | decimal(16,6) | NULL | Position size in instrument units. Signed: positive for buy, negative for sell (×IsBuy_factor applied). |
| `ExecutionRate` | decimal(16,6) | NULL | Execution price. From ExecutionLog if executed; from ManualOrder.Rate if RequestTypeID=3. |
| `UpdateDate` | datetime | NULL | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |
| `Sender` | varchar(100) | NULL | Identity of who sent the order. Format: "HedgeClientN (by username)". Used for dealer audit trail. |
| `ExecutionTime` | datetime | NULL | Actual execution timestamp (from ExecutionLog, or HedgeStartTime from ManualOrder as fallback). |
| `RequestTypeID` | int | NULL | Request type: 0 = standard executed manual order, 3 = special type. |

## Distributions & Observations

- Active: → 2026-03-10 (daily)
- ROUND_ROBIN — filter by Date for efficient queries
- Sample (2026-03-10): InstrumentID 10920 (Tenaya Therapeutics), LP "EMSX Citadel Real 1 - BNY 298393", Sender "HedgeClient102 (by donco)", Units -1000 and -1909 (sell orders)
- UUID OrderIDs: the same OrderID may appear twice if both the Manual log and Execution log have the record (trade executed + execution confirmation)
- RequestTypeID=3: included regardless of success — may represent error corrections or special market operations

## Business Context

The most granular manual execution log — used to audit exactly which orders each dealer placed, at what rates, for which instruments. Compared against the summary table to reconcile LP-side vs. client-side NOP for manual-intervention days. Also used by Compliance for best-execution reporting.

## Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_Manual_Exec_Trade_Summary` | Aggregated sibling — same SP, instrument-level NOP context |
| `Dealing_Manual_Exec` | Parent summary — type/LP/HedgeServer daily aggregation |

## Quality Score: 8.5/10
*Strong: order join logic, signed units, Sender format, RequestTypeID semantics all documented. Active data confirmed.*
