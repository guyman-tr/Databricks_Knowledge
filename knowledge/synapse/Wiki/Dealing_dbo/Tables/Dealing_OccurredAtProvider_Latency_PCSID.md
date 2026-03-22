---
object: Dealing_dbo.Dealing_OccurredAtProvider_Latency_PCSID
type: Table
schema: Dealing_dbo
database: Synapse DWH
documented: 2026-03-21
quality_score: 7.0
status: stale_pipeline
---

# Dealing_OccurredAtProvider_Latency_PCSID

## 1. Purpose

Most-aggregated view of price feed latency — rolled up to **PCSID only** (LP and instrument detail dropped). Answers: "Is this eToro price collection server systematically receiving late prices from all LPs?" Produced by `SP_OccurredAtProvider_Latency`. One of three granularity levels for the OccurredAtProvider latency family (most aggregated).

> **⚠️ PIPELINE STALE since Jan 11, 2025.** 2,049 rows (smallest table — one row per PCSID per day).

## 2. Data Profile

| Metric | Value |
|--------|-------|
| **Row count** | 2,049 |
| **Date range** | 2022-08-02 – 2025-01-11 ⚠️ STALE |
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
| PCSID | int | Price Collection Server ID — the eToro server receiving prices from LP. (Tier 2 — CopyFromLake.PriceLog_History_CurrencyPrice) |
| CountInstances | int | Total ≥3s latency events across all LPs and instruments for this PCSID/date. (Tier 2 — computed) |
| MaxLatency | int | Maximum latency in seconds across all LPs/instruments for this PCSID/date. (Tier 2 — computed) |
| AVGLatency | int | Average latency in seconds across all LPs/instruments for this PCSID/date. (Tier 2 — computed) |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last updated. (Tier 1 — ETL metadata canonical) |

## 5. Business Rules & Relationships

- **Most aggregated level**: LP identity and instrument detail lost — only PCSID remains. Use `_Instrument` table to drill down.
- **PCSID scope**: A single PCSID row aggregates across all LPs sending to that server. High `AVGLatency` here suggests a server-level network issue rather than LP-specific.
- **Same filter chain**: ≥3s latency, CountInstances > 1 — consistent with sibling tables.
- **Row count**: 2,049 rows vs 1,962 for `_LiquidityAccountID` — slightly more rows because some dates have multiple PCSIDs with delays but single LP.

## 6. Query Notes

```sql
-- PCSID with most delay days
SELECT PCSID, COUNT(DISTINCT CAST(Date AS date)) AS DaysWithDelay,
       AVG(AVGLatency) AS TypicalDelay_s, MAX(MaxLatency) AS WorstDelay_s
FROM [Dealing_dbo].[Dealing_OccurredAtProvider_Latency_PCSID]
GROUP BY PCSID
ORDER BY DaysWithDelay DESC
```

## 7. Production Lineage

DWH-computed rollup from CopyFromLake price feed logs. No upstream production wiki.

## 8. Known Issues & Notes

- **STALE since 2025-01-11** — CopyFromLake feed disruption.
- **No LP context** — use `_Instrument` or `_LiquidityAccountID` tables for LP-level drill-down.
- **`Date` is datetime** — use CAST to date for day-level grouping.

---
*Quality score: 7.0/10 | Documented: 2026-03-21 | Writer: SP_OccurredAtProvider_Latency*
