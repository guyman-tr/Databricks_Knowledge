---
object: Dealing_dbo.Dealing_DailySpreadsAggregatedFX
type: Table
schema: Dealing_dbo
database: Synapse DWH
documented: 2026-03-21
quality_score: 7.0
status: stale_pipeline
---

# Dealing_DailySpreadsAggregatedFX

## 1. Purpose

FX-only variant of `Dealing_DailySpreadsAggregated` — same hourly pivot structure (hour0–hour23 average spread + count_hourN tick counts) but scoped to FX (forex) instruments only. Same SP writes both tables. Stopped significantly earlier than the main table (Apr 2024), suggesting the FX scope was removed from the SP at that point. Identical column structure to `Dealing_DailySpreadsAggregated` except `InstrumentName` is varchar(50) instead of varchar(100).

> **⚠️ PIPELINE STALE since Apr 10, 2024.** 38,559 rows.

## 2. Data Profile

| Metric | Value |
|--------|-------|
| **Row count** | 38,559 |
| **Date range** | 2022-08-25 – 2024-04-10 ⚠️ STALE |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on Date ASC |

## 3. ETL / Writer

| Property | Value |
|----------|-------|
| **Writer SP** | `Dealing_dbo.SP_DailySpreadsAggregated` (FX branch, likely removed Apr 2024) |
| **Frequency** | Was Daily (outside OpsDB) |
| **Load mode** | DELETE WHERE Date = @Date, then INSERT |
| **Source** | `CopyFromLake.PricesFromProvider_MarketCurrencyPrice` (FX instruments) |

## 4. Elements

Same structure as `Dealing_DailySpreadsAggregated` with one difference:

| Column | Type | Difference from main table |
|--------|------|---------------------------|
| InstrumentName | varchar(50) | varchar(50) here vs varchar(100) in DailySpreadsAggregated |
| All other columns | Same | Identical types and semantics |

For full column descriptions, see [Dealing_DailySpreadsAggregated](Dealing_DailySpreadsAggregated.md).

## 5. Business Rules & Relationships

- **FX scope only**: Contains only FX/forex instrument rows — no equities, crypto, or commodities.
- **Stopped Apr 2024**: Approximately 10 months before the main table stopped (Feb 2025). The FX branch was likely removed from `SP_DailySpreadsAggregated` when FX spread monitoring was deprecated or moved elsewhere.
- **`AvgAskAt23` same naming issue**: Same misleading column name as main table — captures hours 14–16 UTC, not hour 23.
- **Same query patterns**: All query patterns from `Dealing_DailySpreadsAggregated` apply, filtered to FX instruments.

## 6. Query Notes

```sql
-- FX hourly spread during US session
SELECT Date, InstrumentName, Name AS LP,
       hour13, hour14, hour15, hour16, hour17
FROM [Dealing_dbo].[Dealing_DailySpreadsAggregatedFX]
WHERE Date >= '2023-01-01'
  AND InstrumentName LIKE 'EUR%'
ORDER BY Date, InstrumentName
```

## 7. Production Lineage

DWH-computed analytics — FX-only subset of `Dealing_DailySpreadsAggregated`. Same source chain.

## 8. Known Issues & Notes

- **STALE since 2024-04-10** — FX branch removed from SP before main feed disruption.
- **`InstrumentName` varchar(50)** vs varchar(100) in main table — may truncate long FX instrument names.
- **`AvgAskAt23` naming mismatch** — same as main table.

---
*Quality score: 7.0/10 | Documented: 2026-03-21 | Writer: SP_DailySpreadsAggregated (FX branch)*
