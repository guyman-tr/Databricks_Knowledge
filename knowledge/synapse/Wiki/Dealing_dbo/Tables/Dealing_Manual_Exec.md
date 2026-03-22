---
object: Dealing_Manual_Exec
schema: Dealing_dbo
type: Table
description: Daily summary of hedge execution activity at LP×HedgeServer×Type level. Covers manual, automatic, and HBC_PI (block trade PI) executions with USD volume and trade counts. STALE since Nov 2024.
etl_sp: Dealing_dbo.SP_Manual_Exec
frequency: Daily
status: ⚠️ STALE since 2024-11-02
row_count: ~46,329
distribution: ROUND_ROBIN
index: CLUSTERED (Date ASC)
batch: 14
quality: 8.0
---

# Dealing_Manual_Exec

Daily aggregated view of all hedge executions broken down by execution type (Manual/Automatic/HBC_PI), hedge server, and liquidity provider. Volume is converted to USD using FX rates from Fact_CurrencyPriceWithSplit. Stale since November 2024 — last data 2024-11-02.

## Source & Lineage

| Layer | Object | Role |
|-------|--------|------|
| Source | `Dealing_staging.Etoro_Hedge_ExecutionLog` | All LP executions for the day (ExecutionTime range) |
| Source | `Dealing_staging.External_Etoro_Hedge_ManualOrderExecutionLog` | Manual dealer orders (RequestTypeID=0 = executed) |
| Source | `Dealing_staging.etoro_Hedge_HBCExecutionLog` | HBC (High-Block-Count) PI executions |
| Dimension | `DWH_dbo.Fact_CurrencyPriceWithSplit` | FX rates for USD conversion |
| Dimension | `DWH_dbo.Dim_Instrument` | Instrument currency pair for FX conversion |
| Reference | `Dealing_staging.etoro_Trade_LiquidityAccounts` | LiquidityAccountID → LiquidityAccountName |
| Writer | `Dealing_dbo.SP_Manual_Exec` | Daily, OpsDB Priority 0 |

**Three execution types** in the output:
1. **Manual**: Order originated in `External_Etoro_Hedge_ManualOrderExecutionLog` (RequestTypeID=0)
2. **Automatic**: All other executions in `Etoro_Hedge_ExecutionLog` not in the Manual log
3. **HBC_PI**: HBC executions where ExecutionID appears in `Dim_Position` (PI's open/close positions) — block trades for Popular Investor clients

**USD volume computation** (complex multi-currency):
- Units × ExecutionRate (or Bid/Ask from PriceLog if rejected) × FX conversion
- Special cases: InstrumentID 19 (GBPUSD?) ×0.01, InstrumentID 22 (JPYUSD?) ×0.001

## Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `Date` | date | NULL | Report date. |
| `Type` | varchar(50) | NULL | Execution type: 'Manual', 'Automatic', or 'HBC_PI'. |
| `HedgeServer` | int | NULL | Hedge server ID (foreign key to hedge server configuration). |
| `LiquidityAccountID` | int | NULL | LP account identifier. |
| `LiquidityAccountName` | varchar(100) | NULL | LP account name (e.g., 'DLT', 'MarketMakerIM'). Denormalized from etoro_Trade_LiquidityAccounts. |
| `Volume` | decimal(16,6) | NULL | Total traded volume in USD for this date/type/server/LP combination. NULL for HBC_PI rows (block count only, no volume computation). |
| `Count_Trades` | int | NULL | Number of individual execution events in this group. |
| `IsSuccess` | int | NULL | 1 = successful executions; 0 = failed/rejected executions. Separate rows for success and failure. |
| `UpdateDate` | datetime | NULL | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |

## Distributions & Observations

- ⚠️ **STALE**: Last data 2024-11-02. The SP likely stopped due to changes in Dealing_staging source tables or SP scheduling
- 46,329 rows total (2021-07-01 → 2024-11-02) — modest size
- Sample (2024-11-02): DLT LP: 212,609 USD Volume, 2289 successful trades; MarketMakerIM: 3,758,293 USD, 9180 successful trades
- HBC_PI rows have NULL Volume (only Count_Trades and IsSuccess=1)
- IsSuccess=0 rows: Volume is NULL (rejected orders have no execution price)
- SP takes ~36 minutes to run (comment in code) — heavy cross-join of FX rates

## Business Context

Intended for daily LP execution monitoring by the Dealing team. Answers: "How much volume did each LP execute today, and what fraction was manual vs. automatic?" The HBC_PI type specifically tracks block trades for Popular Investors (GuruStatusID >= 2). Now superseded by newer tables or reporting tools (stale since Nov 2024).

## Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_Manual_Exec_Trade` | Child table — trade-level detail for manual executions only |
| `Dealing_Manual_Exec_Trade_Summary` | Summary variant with NOP context and client-side comparison |

## Quality Score: 8.0/10
*Good: three execution types explained, USD conversion logic documented, staleness noted. Minor deduction: root cause of Nov 2024 stall not identified.*
