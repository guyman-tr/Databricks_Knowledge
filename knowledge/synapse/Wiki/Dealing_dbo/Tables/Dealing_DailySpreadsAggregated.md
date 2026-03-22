---
object: Dealing_dbo.Dealing_DailySpreadsAggregated
type: Table
schema: Dealing_dbo
database: Synapse DWH
documented: 2026-03-21
quality_score: 7.5
status: stale_pipeline
---

# Dealing_DailySpreadsAggregated

## 1. Purpose

Hourly pivot table of average bid-ask spreads per instrument × LP combination — one row per instrument/LP/date with 24 `hourN` float columns representing the average spread during each UTC hour. Produced by `SP_DailySpreadsAggregated` using a hardcoded mapping of 20 LPs to their instruments. The `Name` column holds the LP name. `AvgAskAt23` is a special column capturing average Ask price during hours 14–16 UTC (US mid-session). Used by trading/pricing teams to analyze intraday spread patterns per LP.

> **⚠️ PIPELINE STALE since Feb 17, 2025.** 227,720 rows.

## 2. Data Profile

| Metric | Value |
|--------|-------|
| **Row count** | 227,720 |
| **Date range** | 2022-04-08 – 2025-02-17 ⚠️ STALE |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on Date ASC |

## 3. ETL / Writer

| Property | Value |
|----------|-------|
| **Writer SP** | `Dealing_dbo.SP_DailySpreadsAggregated` |
| **Frequency** | Daily (outside OpsDB) |
| **Load mode** | DELETE WHERE Date = @Date, then INSERT |
| **Source** | `CopyFromLake.PricesFromProvider_MarketCurrencyPrice` (bid-ask price feed) |

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Trade date. (Tier 2 — SP_DailySpreadsAggregated) |
| InstrumentName | varchar(100) | Instrument name. (Tier 2 — hardcoded LP-instrument mapping in SP) |
| InstrumentTypeID | int | Instrument type identifier. (Tier 2 — hardcoded LP-instrument mapping in SP) |
| InstrumentID | int | Instrument identifier. (Tier 2 — hardcoded LP-instrument mapping in SP) |
| LiquidityAccountID | int | LP account identifier. (Tier 2 — hardcoded LP-instrument mapping in SP) |
| Name | varchar(9) | LP name (short code). Maps to one of the 20 hardcoded LPs in SP. (Tier 2 — hardcoded LP-instrument mapping in SP) |
| hour0–hour23 | float (×24) | Average bid-ask spread during UTC hour N on this date. NULL if no price ticks in that hour. (Tier 2 — PIVOT computed) |
| count_hour0–count_hour23 | int (×24) | Number of price ticks used to compute the average spread for hour N. (Tier 2 — PIVOT computed) |
| updateDate | datetime | ETL metadata: timestamp when this row was last updated. Note: lowercase 'u'. (Tier 1 — ETL metadata canonical) |
| AvgAskAt23 | float | Average Ask price during UTC hours 14–16 (US mid-session). Column name is misleading — named "At23" for internal reasons but captures 14–16 UTC. (Tier 2 — computed) |

## 5. Business Rules & Relationships

- **Hardcoded LP mapping**: The SP contains a hardcoded list of 20 LPs with their corresponding instruments. New LPs or instruments require SP modification to be included.
- **PIVOT structure**: Wide table design (24 hourN + 24 count_hourN columns). For time-series analysis, unpivot to narrow form.
- **`AvgAskAt23` naming**: Column name is misleading — despite the "23" in the name, it captures average Ask at hours 14–16 UTC (US market mid-session). Use with caution.
- **`Name` varchar(9)**: LP short code — limited to 9 characters, matches the hardcoded LP list.
- **Source**: `CopyFromLake.PricesFromProvider_MarketCurrencyPrice` — same feed family as `PriceLog_History_CurrencyPrice` used by OccurredAtProvider. Disruption of this feed caused the Feb 2025 stale date.
- **FX variant**: `Dealing_DailySpreadsAggregatedFX` is a parallel table for FX instruments only (stopped Apr 2024).

## 6. Query Notes

```sql
-- Average spread by hour for a specific LP and instrument
SELECT Date, Name AS LP,
       hour9, hour10, hour11, hour12, hour13, hour14, hour15, hour16
FROM [Dealing_dbo].[Dealing_DailySpreadsAggregated]
WHERE InstrumentName = 'AAPL'
  AND Date >= '2024-01-01'
ORDER BY Date
```

```sql
-- Unpivot to narrow form (single hour per row)
SELECT Date, InstrumentName, Name AS LP, LiquidityAccountID,
       HourUTC, AvgSpread
FROM [Dealing_dbo].[Dealing_DailySpreadsAggregated]
UNPIVOT (AvgSpread FOR HourUTC IN (
    hour0,hour1,hour2,hour3,hour4,hour5,hour6,hour7,
    hour8,hour9,hour10,hour11,hour12,hour13,hour14,hour15,
    hour16,hour17,hour18,hour19,hour20,hour21,hour22,hour23
)) AS unpvt
WHERE Date = '2024-06-01'
```

## 7. Production Lineage

DWH-computed analytics from CopyFromLake price feed. No upstream production wiki.

## 8. Known Issues & Notes

- **STALE since 2025-02-17** — `CopyFromLake.PricesFromProvider_MarketCurrencyPrice` feed disruption.
- **`AvgAskAt23` naming mismatch** — captures hours 14–16 UTC, not hour 23.
- **Hardcoded LP mapping** — expanding coverage requires SP code change.
- **`updateDate` is lowercase** — inconsistent with standard `UpdateDate` convention in other Dealing_dbo tables.

---
*Quality score: 7.5/10 | Documented: 2026-03-21 | Writer: SP_DailySpreadsAggregated*
