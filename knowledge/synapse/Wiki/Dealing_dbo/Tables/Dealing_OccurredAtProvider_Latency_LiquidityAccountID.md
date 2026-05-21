---
object: Dealing_dbo.Dealing_OccurredAtProvider_Latency_LiquidityAccountID
type: Table
schema: Dealing_dbo
database: Synapse DWH
documented: 2026-03-21
quality_score: 7.5
status: stale_pipeline
---

# Dealing_OccurredAtProvider_Latency_LiquidityAccountID

## 1. Purpose

LP-level rollup of price feed latency — aggregates `Dealing_OccurredAtProvider_Latency_Instrument` by **LP × PCSID** (instrument detail dropped). Answers: "Which LP has the worst price feed delays overall, per receiving server?" Produced by `SP_OccurredAtProvider_Latency`. One of three granularity levels for the OccurredAtProvider latency family.

> **⚠️ PIPELINE STALE since Jan 11, 2025.** 1,962 rows (small — daily aggregates per LP/PCSID).

## 2. Data Profile

| Metric | Value |
|--------|-------|
| **Row count** | 1,962 |
| **Date range** | 2022-10-06 – 2025-01-11 ⚠️ STALE |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on Date ASC |
| **Date type** | datetime (not date) |

## 3. ETL / Writer

| Property | Value |
|----------|-------|
| **Writer SP** | `Dealing_dbo.SP_OccurredAtProvider_Latency` |
| **Frequency** | Daily (outside OpsDB) |
| **Load mode** | DELETE WHERE Date = @Date, then INSERT |
| **Source** | `CopyFromLake.PriceLog_History_CurrencyPrice` |

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| Date | datetime | Price event date (includes time). (Tier 2 — SP_OccurredAtProvider_Latency) |
| LiquidityAccountID | int | LP account identifier. (Tier 4 — CopyFromLake.PriceLog_History_CurrencyPrice) |
| LiquidityAccountName | varchar(80) | LP account name. (Tier 2 — CopyFromLake.PriceLog_History_CurrencyPrice) |
| PCSID | int | Price Collection Server ID — which eToro server received the price. (Tier 2 — CopyFromLake.PriceLog_History_CurrencyPrice) |
| CountInstances | int | Total number of ≥3s latency events for this LP/PCSID/date. (Tier 2 — computed) |
| MaxLatency | int | Maximum latency in seconds across all instruments for this LP/PCSID/date. (Tier 2 — computed) |
| AVGLatency | int | Average latency in seconds across all instruments for this LP/PCSID/date. (Tier 2 — computed) |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last updated. (Tier 1 — ETL metadata canonical) |

## 5. Business Rules & Relationships

- **Rollup of `_Instrument`**: Same source and filters — aggregated to LP+PCSID level without instrument breakdown.
- **Start date offset**: Data starts 2022-10-06 vs 2022-08-02 for Instrument table — SP may have been added in phases.
- **Low row count**: 1,962 rows over ~2.5 years = ~2 rows/day (2 LPs with systematic delays on average per day).
- **Latency filter**: Same as Instrument table — only ≥3s latency, CountInstances > 1.
- **LP accountability**: This is the table for LP SLA monitoring — which LP consistently delivers late prices.

## 6. Query Notes

```sql
-- LP-level latency trend by month
SELECT LiquidityAccountName, PCSID,
       YEAR(Date) AS Year, MONTH(Date) AS Month,
       AVG(AVGLatency) AS AvgDelay_s, MAX(MaxLatency) AS MaxDelay_s,
       SUM(CountInstances) AS TotalDelayedPrices
FROM [Dealing_dbo].[Dealing_OccurredAtProvider_Latency_LiquidityAccountID]
GROUP BY LiquidityAccountName, PCSID, YEAR(Date), MONTH(Date)
ORDER BY LiquidityAccountName, Year, Month
```

## 7. Production Lineage

DWH-computed rollup from CopyFromLake price feed logs. No upstream production wiki.

## 8. Known Issues & Notes

- **STALE since 2025-01-11** — CopyFromLake feed disruption.
- **Later start date** than Instrument table (Oct 2022 vs Aug 2022).
- **`Date` is datetime** — truncate to day for date-level joins.

---
*Quality score: 7.5/10 | Documented: 2026-03-21 | Writer: SP_OccurredAtProvider_Latency*
