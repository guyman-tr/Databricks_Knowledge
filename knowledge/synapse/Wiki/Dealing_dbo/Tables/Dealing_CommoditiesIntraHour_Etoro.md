---
object: Dealing_CommoditiesIntraHour_Etoro
schema: Dealing_dbo
type: Table
description: Per-minute intra-hour LP/eToro-side hedge activity for commodity instruments (Oil, Gold, NatGas, Silver, Copper). Captures LP net open position (Units_NOP, NOP), buy/sell execution volumes, and mark-to-market values (ValueStart, ValueEnd, ValueRealized) at minute granularity.
etl_sp: Dealing_dbo.SP_IntraHourCommodityReport
frequency: Daily
status: Active (last: 2026-03-10)
row_count: 12,567,580
distribution: ROUND_ROBIN
index: CLUSTERED (Date ASC)
batch: 14
quality: 8.0
---

# Dealing_CommoditiesIntraHour_Etoro

Per-minute snapshot of **eToro LP/hedge-side** activity for commodity instruments. Produced by the same SP and same run as `Dealing_CommoditiesIntraHour_Clients`, this table captures what the liquidity provider is doing — hedge execution volumes, net open position in units and USD, and mark-to-market values — to support intraday hedging oversight.

Companion table: `Dealing_CommoditiesIntraHour_Clients` captures the **client-side** perspective for the same instruments.

## Source & Lineage

| Layer | Object | Role |
|-------|--------|------|
| Execution log | `CopyFromLake.etoro_Hedge_ExecutionLog` | LP hedge execution records (buy/sell volumes per minute) |
| NOP source | `Dealing_staging.External_Etoro_Hedge_Netting` | Current LP net open position by instrument |
| Historical NOP | `Dealing_staging.etoro_History_Netting_History` | Historical LP NOP for realized value calculation |
| Price source | `CopyFromLake.PriceLog_History_CurrencyPrice` | Minute-level prices for NOP valuation; 5-day lookback |
| Writer | `Dealing_dbo.SP_IntraHourCommodityReport` | Daily, OpsDB Priority 0 — same run as Clients table |

**Instruments covered**: Oil (17), Gold (18), Natural Gas (19), Silver (22), Copper (96), plus instruments 150/151. HedgeServerID=225 since Apr 2025 (SR-310993).

## 1. Business Purpose

- Provides minute-level view of LP hedge activity to compare against client-side commodity exposure
- Used alongside `Dealing_CommoditiesIntraHour_Clients` to assess hedge effectiveness: are LP positions offsetting client risk?
- LiquidityAccountID/Name identifies which LP counterparty is hedging each commodity
- ValueStart/ValueEnd/ValueRealized tracks LP mark-to-market P&L by minute

## 2. Key Concepts

| Concept | Explanation |
|---------|-------------|
| Units_NOP | LP net open position in instrument units (long − short) |
| NOP | LP net open position valued in USD (Units_NOP × Price × ConversionRate) |
| ValueStart / ValueEnd | Mark-to-market USD value of LP NOP at minute start/end using bid prices |
| ValueRealized | Realized value from LP positions closed during this minute |
| LiquidityAccountID | Identifies the specific LP account — one account per hedge server |

## 3. Grain

One row per **Date × Minute_Start × InstrumentID × LiquidityAccountID**. Multiple LP accounts may appear for the same instrument/minute if multiple LPs are active.

## 4. Elements

| Column | Type | Description | Tier | Notes |
|--------|------|-------------|------|-------|
| Date | date | Trading date | Tier 2 | Clustered index key |
| Minute_Start | datetime | Start of 1-minute interval | Tier 2 | Key for time-series analysis |
| Minute_End | datetime | End of 1-minute interval | Tier 2 | Always Minute_Start + 1 minute |
| InstrumentID | int | Commodity instrument ID | Tier 1 | Oil=17, Gold=18, NatGas=19, Silver=22, Copper=96 |
| LiquidityAccountName | varchar(200) | LP account name | Tier 2 | From etoro_Hedge_ExecutionLog; HedgeServerID=225 since Apr 2025 |
| LiquidityAccountID | int | LP account identifier | Tier 1 | FK to LP account registry |
| VolumeBuy | float | Count of LP hedge buy executions in this minute | Tier 2 | From etoro_Hedge_ExecutionLog |
| VolumeSell | float | Count of LP hedge sell executions in this minute | Tier 2 | From etoro_Hedge_ExecutionLog |
| Units_NOP | float | LP net open position in instrument units | Tier 1 | From netting tables; positive = net long |
| NOP | float | LP net open position in USD | Tier 1 | Units_NOP × Price × ConversionRate |
| ValueStart | float | Mark-to-market USD value of LP NOP at minute start | Tier 2 | Units_NOP × Bid at Minute_Start |
| ValueEnd | float | Mark-to-market USD value of LP NOP at minute end | Tier 2 | Units_NOP × Bid at Minute_End |
| ValueRealized | float | Realized USD value from LP positions closed in this minute | Tier 2 | From etoro_History_Netting_History |
| UpdateDate | datetime | ETL metadata: row write timestamp | Tier 1 | ETL metadata (blacklist canonical) |

## 5. Common Query Patterns

```sql
-- Gold LP NOP vs client NOP comparison for a date
SELECT e.Minute_Start,
       e.Units_NOP AS LP_NOP_Units,
       c.OP_Buy_Units - c.OP_Sell_Units AS Client_Net_Units
FROM Dealing_dbo.Dealing_CommoditiesIntraHour_Etoro e
JOIN Dealing_dbo.Dealing_CommoditiesIntraHour_Clients c
  ON e.Date = c.Date AND e.Minute_Start = c.Minute_Start AND e.InstrumentID = c.InstrumentID
WHERE e.Date = '2026-03-10' AND e.InstrumentID = 18  -- Gold
ORDER BY e.Minute_Start;

-- Daily LP NOP peak by instrument
SELECT Date, InstrumentID, LiquidityAccountName,
       MAX(ABS(Units_NOP)) AS PeakAbsNOP
FROM Dealing_dbo.Dealing_CommoditiesIntraHour_Etoro
WHERE Date >= DATEADD(DAY, -7, GETDATE())
GROUP BY Date, InstrumentID, LiquidityAccountName
ORDER BY Date DESC, PeakAbsNOP DESC;
```

> **Performance note**: 12.6M rows, ROUND_ROBIN distribution. Filter by Date (clustered index). LiquidityAccountID is not a distribution key — avoid unbounded scans.

## 6. Data Quality & Caveats

- HedgeServerID=225 since Apr 2025; historical rows may reflect different LP configurations
- NOP valuation uses the same 5-day price lookback as the Clients table (weekend price smearing)
- Instruments 150/151 priced from Gold (22) by SP convention
- ValueRealized may be 0 for minutes where no LP positions were closed

## 7. Related Objects

| Object | Relationship |
|--------|-------------|
| `Dealing_dbo.Dealing_CommoditiesIntraHour_Clients` | Client-side view, same SP, same instruments, same grain |
| `Dealing_dbo.Dealing_IndiciesIntraHour_Etoro` | Equivalent for indices instruments |
| `Dealing_dbo.Dealing_IndiciesIntraHour_Clients` | Client-side indices intra-hour |

## 8. Operational Notes

- **ETL**: `SP_IntraHourCommodityReport` runs daily (OpsDB Priority 0, SB_Daily) — writes both Etoro and Clients tables in one run
- **Key change**: Moved to HS=225 on 2025-04-23 (SR-310993)
- NOP data sourced from `Dealing_staging.External_Etoro_Hedge_Netting` (current) + `etoro_History_Netting_History` (historical)

---
*Quality score: 8.0/10 — Solid LP-side coverage. LP NOP and valuation derivation clear. Dependent on staging table freshness.*
