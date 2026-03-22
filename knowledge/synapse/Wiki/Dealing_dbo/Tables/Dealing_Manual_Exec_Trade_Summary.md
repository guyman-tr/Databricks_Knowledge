---
object: Dealing_Manual_Exec_Trade_Summary
schema: Dealing_dbo
type: Table
description: Daily instrument×HedgeServer summary linking manual execution trades to client NOP, total eToro hedging activity, and NOP start/end. Bridges manual dealer trades with the overall hedging picture.
etl_sp: Dealing_dbo.SP_Manual_Exec_Trade
frequency: Daily
status: Active (last: 2026-03-10)
row_count: not sampled (daily inserts)
distribution: ROUND_ROBIN
index: CLUSTERED (Date ASC)
batch: 14
quality: 8.5
---

# Dealing_Manual_Exec_Trade_Summary

Instrument-level daily summary that combines three data sources: (1) manual dealer trades, (2) total eToro hedging activity, and (3) client NOP from BI_DB_PositionPnL. Also includes NOP_Start and NOP_End (from netting tables) and Zero (from tree-size tables). Used for dealer reconciliation — comparing manual intervention against the full hedging and client-side context.

## Source & Lineage

| Layer | Object | Role |
|-------|--------|------|
| Computed | `#Final_Manual` (from SP) | Manual order aggregates (count, units, amount) per instrument+HedgeServer |
| Source | `BI_DB_dbo.BI_DB_PositionPnL` | Client-side NOP and units per instrument+HedgeServer on DateID |
| Source | `Dealing_staging.Etoro_Hedge_ExecutionLog` | Total eToro execution volume (manual + automatic) |
| Source | `Dealing_staging.etoro_Hedge_Netting` + `etoro_History_Netting_History` | LP netting positions at start-of-day and end-of-day |
| Source | `BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW` + `Dealing_DailyZeroPnL_Stocks` | Zero (residual tree positions) |
| Dimension | `DWH_dbo.Fact_CurrencyPriceWithSplit` | End-of-day prices for NOP_Start/NOP_End computation |
| Writer | `Dealing_dbo.SP_Manual_Exec_Trade` | Daily, same SP as Dealing_Manual_Exec_Trade |

**NOP_Start/End computation**: From the netting tables — takes the most recent LP netting position (ROW_NUMBER DESC) before start-of-day / end-of-day, values using EOD price (Bid for long, Ask for short → negative for long NOP by convention).

## Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `Date` | date | NULL | Report date. |
| `InstrumentID` | int | NULL | Instrument. One row per instrument × HedgeServerID per day. |
| `InstrumentDisplayName` | varchar(100) | NULL | Instrument display name. Denormalized. |
| `HedgeServerID` | int | NULL | Hedge server ID. Note: named HedgeServerID (vs. HedgeServer in Manual_Exec_Trade). |
| `Etoro_Manual_Trades` | decimal(22,8) | NULL | Count of manual orders for this instrument × HedgeServer today. |
| `Etoro_Manual_Units` | decimal(22,8) | NULL | Sum of signed units from manual trades. |
| `Etoro_Manual_Amount` | decimal(22,8) | NULL | Dollar amount of manual trades: SUM(-Units × ExecutionRate). Positive = sold (short hedge). |
| `Clients_Total_Units` | decimal(22,8) | NULL | Total client net units (buy − sell) from BI_DB_PositionPnL for this instrument+HedgeServer. |
| `Clients_Total_Amount` | decimal(22,8) | NULL | Total client NOP in USD from BI_DB_PositionPnL. |
| `Etoro_Total_Units` | decimal(22,8) | NULL | Total eToro execution units (manual + automatic) from ExecutionLog. |
| `Etoro_Total_Volume` | decimal(22,8) | NULL | Total eToro executed volume in USD (SUM(Units × ExecutionRate)). |
| `Etoro_Total_Amount` | decimal(22,8) | NULL | Net eToro executed amount with direction sign (buy − sell × rate). |
| `NOP_Start` | decimal(22,8) | NULL | LP netting position NOP at start of day (using prior-day EOD price). Negative = eToro is net long (LP holds hedge). |
| `NOP_End` | decimal(22,8) | NULL | LP netting position NOP at end of day. |
| `Zero` | decimal(22,8) | NULL | Total zero-position tree volume (from BI_DB_DailyZero_TreeSize_NEW + Dealing_DailyZeroPnL_Stocks). Represents positions where NOP nets to zero. |
| `UpdateDate` | datetime | NULL | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |

## Distributions & Observations

- Active: → 2026-03-10 (daily)
- ROUND_ROBIN — filter by Date + InstrumentID for efficient access
- Etoro_Manual_Amount uses negative sign convention: `-SUM(Units × Rate)` — positive value means eToro sold (increased short hedge)
- NOP_Start and NOP_End from netting tables: ROW_NUMBER() OVER (PARTITION BY InstrumentID, HedgeServerID ORDER BY SysEndTime DESC) = 1 selects latest netting state before the time boundary
- Note: NOP_Start/End may not tie exactly to BI_DB_PositionPnL due to intraday netting timing differences

## Business Context

The reconciliation table for manual execution days. Dealers use this to answer: "We manually executed X units of Apple today — how did that compare to the total eToro hedge, and what was our NOP before and after?" Essential for crisis response post-mortems and for ensuring manual trades didn't over- or under-hedge client exposure.

## Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_Manual_Exec_Trade` | Trade-level sibling — same SP, one row per order |
| `BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW` | Zero source |
| `Dealing_DailyZeroPnL_Stocks` | Stocks zero source (added Feb 2024) |

## Quality Score: 8.5/10
*Strong: three-source bridge structure explained, NOP convention documented, column directions clarified. Active confirmed.*
