---
object: Dealing_CommoditiesIntraHour_Clients
schema: Dealing_dbo
type: Table
description: Per-minute intra-hour trading activity of eToro clients in commodity and oil instruments (IDs 17, 18, 19, 22, 96 and conversion instruments). Captures volume, open position units/value, unrealized PnL start/end, realized PnL, and bid/ask prices at minute granularity.
etl_sp: Dealing_dbo.SP_IntraHourCommodityReport
frequency: Daily
status: Active (last: 2026-03-10)
row_count: 11,862,507
distribution: ROUND_ROBIN
index: CLUSTERED (Date ASC)
batch: 14
quality: 8.5
---

# Dealing_CommoditiesIntraHour_Clients

Per-minute snapshot of eToro **client-side** trading activity for commodity instruments (Oil, Gold, Copper, WTI Oil, EuroOIL, and related futures conversion instruments). Covers hedge-server 225 only. Tracks open position value, minute-by-minute volume flows, and unrealized/realized PnL to support intraday hedging oversight.

Companion table: `Dealing_CommoditiesIntraHour_Etoro` captures the **LP/eToro-side** perspective (Liquidity Accounts) for the same instruments.

## Source & Lineage

| Layer | Object | Role |
|-------|--------|------|
| Position source | `DWH_dbo.Dim_Position` | All positions on InstrumentIDs ∈ {17,18,19,22,96,150,151,...}, HedgeServerID=225 |
| Price source | `CopyFromLake.PriceLog_History_CurrencyPrice` | Minute-level bid/ask prices, 5-day lookback for weekend smearing |
| Writer | `Dealing_dbo.SP_IntraHourCommodityReport` | Daily, OpsDB Priority 0 |

**Instruments covered**: Oil (17), Gold (18), Natural Gas (19), Silver (22), Copper (96), and instrument 150/151 (priced from Gold/Silver). Instruments added via PortfolioConversionConfigurations. Excludes HedgeServerID=24 (Apr 2023), runs on HS=225 only (since Apr 2025).

## 1. Business Purpose

- Provides minute-level view of commodity trading activity for the Dealing desk to monitor intraday hedging exposures
- Used alongside `Dealing_CommoditiesIntraHour_Etoro` to compare client positions vs LP hedging activity
- Supports detection of large intraday position buildups that may trigger hedging action

## 2. Key Concepts

| Concept | Explanation |
|---------|-------------|
| OP (Open Position) | Units and value of positions open at the start of each minute |
| UnrealizedStart / UnrealizedEnd | PnL of open positions at minute start/end using bid/ask prices |
| Realized | PnL of positions closed within that minute |
| Price smearing | 5-day lookback fills price gaps on weekends — minute rows exist for all calendar days |
| Instrument 150/151 | Priced from Gold (22) prices by convention |

## 3. Grain

One row per **Date × Minute_Start × InstrumentID**. Each minute has a 1-minute window from Minute_Start to Minute_End.

## 4. Elements

| Column | Type | Description | Tier | Notes |
|--------|------|-------------|------|-------|
| Date | date | Trading date | Tier 2 | Clustered index key |
| Minute_Start | datetime | Start of 1-minute interval (e.g., `2026-03-10 09:00:00`) | Tier 2 | Key for time-series analysis |
| Minute_End | datetime | End of 1-minute interval (Minute_Start + 1 min) | Tier 2 | Always Minute_Start + 1 minute |
| InstrumentID | int | Commodity instrument ID | Tier 1 | Oil=17, Gold=18, NatGas=19, Silver=22, Copper=96 |
| VolumeBuy | bigint | Volume of buy trades executed in this minute (open buys + close sells) | Tier 2 | In instrument units × rate |
| VolumeSell | bigint | Volume of sell trades executed in this minute (open sells + close buys) | Tier 2 | In instrument units × rate |
| OP_Buy_Units | float | Total units of long open positions at minute start | Tier 2 | Sum of AmountInUnitsDecimal for IsBuy=1 |
| OP_Buy | float | USD value of long open positions at minute start (units × Bid price) | Tier 2 | Bid price from price smearing |
| OP_Sell_Units | float | Total units of short open positions at minute start | Tier 2 | Sum of AmountInUnitsDecimal for IsBuy=0 |
| OP_Sell | float | USD value of short open positions at minute start (units × Ask price) | Tier 2 | Ask price from price smearing |
| UnrealizedStart | float | Unrealized PnL of open positions at minute start | Tier 2 | Computed from position entry vs start price |
| UnrealizedEnd | float | Unrealized PnL of open positions at minute end | Tier 2 | From next minute's UnrealizedStart |
| Realized | float | Realized PnL of positions closed during this minute | Tier 2 | NetProfit + FullCommissionOnClose |
| Bid | float | Bid price at minute start (for dominant instrument direction) | Tier 2 | From smeared price grid |
| Ask | float | Ask price at minute start | Tier 2 | From smeared price grid |
| UpdateDate | datetime | ETL metadata: row write timestamp | Tier 1 | ETL metadata (blacklist canonical) |

## 5. Common Query Patterns

```sql
-- Gold intraday OP and PnL for a specific date
SELECT Minute_Start, OP_Buy_Units, OP_Sell_Units,
       UnrealizedStart, UnrealizedEnd, Realized
FROM Dealing_dbo.Dealing_CommoditiesIntraHour_Clients
WHERE Date = '2026-03-10' AND InstrumentID = 18  -- Gold
ORDER BY Minute_Start;

-- Daily max open position by instrument
SELECT Date, InstrumentID,
       MAX(OP_Buy_Units - OP_Sell_Units) AS MaxNetLongUnits
FROM Dealing_dbo.Dealing_CommoditiesIntraHour_Clients
WHERE Date >= DATEADD(DAY, -7, GETDATE())
GROUP BY Date, InstrumentID
ORDER BY Date DESC, MaxNetLongUnits DESC;
```

> **Performance note**: 11.8M rows, ROUND_ROBIN distribution. Filter by Date (clustered index). For multi-instrument queries, InstrumentID is not a distribution key — large joins on InstrumentID across many dates may be slow.

## 6. Data Quality & Caveats

- Covers only **HedgeServerID = 225** as of Apr 2025 (changed from HS=127 Apr 2023, HS=225 Apr 2025)
- Price smearing: rows exist for weekends/gaps using last known price — `BidFirst`/`AskFirst` may reflect prices from up to 5 days prior
- Minute rows where no activity occurs may have zeros but still appear (driven by minute grid)
- Only valid customers (IsValidCustomer = 1) are included

## 7. Related Objects

| Object | Relationship |
|--------|-------------|
| `Dealing_dbo.Dealing_CommoditiesIntraHour_Etoro` | LP-side view, same SP, same instruments |
| `Dealing_dbo.Dealing_IndiciesIntraHour_Clients` | Equivalent for indices instruments |
| `Dealing_dbo.Dealing_IndiciesIntraHour_Etoro` | LP-side indices intra-hour |

## 8. Operational Notes

- **ETL**: `SP_IntraHourCommodityReport` runs daily (OpsDB Priority 0, SB_Daily)
- **Key change**: Moved from HS=127 to HS=225 on 2025-04-23 (SR-310993) — potential gap in continuity
- SP copies `CopyFromLake.PriceLog_History_CurrencyPrice` and `CopyFromLake.etoro_Hedge_ExecutionLog` as temp tables during execution

---
*Quality score: 8.5/10 — Solid SP analysis. Hedge server transition is a key operational note.*
