---
object: Dealing_dbo.Dealing_OccurredAtProvider_Latency_Instrument
type: Table
schema: Dealing_dbo
database: Synapse DWH
documented: 2026-03-21
quality_score: 8.0
status: stale_pipeline
---

# Dealing_OccurredAtProvider_Latency_Instrument

## 1. Purpose

Most-granular view of price feed latency from Liquidity Providers (LPs). Measures the delay between when a price event occurred at the LP (`OccurredOnProvider`) and when eToro's Price Collection Server received it (`ReceivedOnPriceServer`). Grouped by **Instrument × LP × PCSID**. Only records where `CountInstances > 1` and absolute latency ≥ 3 seconds are included — filters out normal sub-3-second delivery. Produced by `SP_OccurredAtProvider_Latency`. Used to identify which LP/instrument combinations suffer systematic price feed delays.

> **⚠️ PIPELINE STALE since Jan 11, 2025.** 133,816 rows — same date CopyFromLake feeds stopped.

## 2. Data Profile

| Metric | Value |
|--------|-------|
| **Row count** | 133,816 |
| **Date range** | 2022-08-02 – 2025-01-11 ⚠️ STALE |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on Date ASC |
| **Date type** | datetime (not date — includes time component) |

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
| Date | datetime | Price event date (includes time). Note: datetime not date. (Tier 2 — SP_OccurredAtProvider_Latency) |
| InstrumentID | int | Instrument identifier. (Tier 2 — CopyFromLake.PriceLog_History_CurrencyPrice) |
| InstrumentDisplayName | varchar(80) | Instrument display name. (Tier 2 — CopyFromLake.PriceLog_History_CurrencyPrice) |
| InstrumentType | varchar(30) | Instrument asset class (Stocks, Crypto, FX, etc.). (Tier 2 — CopyFromLake.PriceLog_History_CurrencyPrice) |
| Symbol | varchar(20) | Trading symbol (e.g. AAPL, EURUSD). (Tier 2 — CopyFromLake.PriceLog_History_CurrencyPrice) |
| Exchange | varchar(100) | Exchange or venue for this instrument. (Tier 2 — CopyFromLake.PriceLog_History_CurrencyPrice) |
| LiquidityAccountID | int | LP account identifier — which LP delivered this price feed. (Tier 2 — CopyFromLake.PriceLog_History_CurrencyPrice) |
| LiquidityAccountName | varchar(80) | LP account name. (Tier 2 — CopyFromLake.PriceLog_History_CurrencyPrice) |
| PCSID | int | Price Collection Server ID — which eToro server received the price. (Tier 2 — CopyFromLake.PriceLog_History_CurrencyPrice) |
| CountInstances | int | Number of price events with ≥3s latency on this date for this grouping. Only rows with CountInstances > 1 are inserted. (Tier 2 — computed) |
| MaxLatency | int | Maximum latency in seconds across all instances: MAX(DATEDIFF(ss, OccurredOnProvider, ReceivedOnPriceServer)). (Tier 2 — computed) |
| AVGLatency | int | Average latency in seconds: AVG(DATEDIFF(ss, OccurredOnProvider, ReceivedOnPriceServer)). (Tier 2 — computed) |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last updated. (Tier 1 — ETL metadata canonical) |

## 5. Business Rules & Relationships

- **Latency filter**: Only price events with `|DATEDIFF(ss, OccurredOnProvider, ReceivedOnPriceServer)| ≥ 3` seconds included. Positive = delayed delivery; negative = out-of-order/clock skew.
- **`CountInstances > 1` filter**: Single-instance anomalies excluded — only systematic (multi-event) delays are recorded.
- **Three granularity levels**: This table is the most detailed (Instrument × LP × PCSID). Sibling tables `_LiquidityAccountID` and `_PCSID` provide rolled-up views.
- **Downstream use**: `SP_Latency_SuspiciousCIDs` cross-references this table to identify clients who traded during price-feed delay windows.
- **PCSID**: Price Collection Server ID — identifies which eToro internal server was receiving prices from the LP. Useful for diagnosing server-specific network issues.
- **Negative latency**: `OccurredOnProvider > ReceivedOnPriceServer` can indicate LP clock misconfiguration or out-of-order delivery.

## 6. Query Notes

```sql
-- Most-delayed LP/instrument combinations
SELECT LiquidityAccountName, InstrumentDisplayName, InstrumentType,
       AVG(AVGLatency) AS TypicalDelay_s, MAX(MaxLatency) AS WorstDelay_s,
       SUM(CountInstances) AS TotalDelayedEvents
FROM [Dealing_dbo].[Dealing_OccurredAtProvider_Latency_Instrument]
WHERE Date >= '2024-01-01'
GROUP BY LiquidityAccountName, InstrumentDisplayName, InstrumentType
ORDER BY TypicalDelay_s DESC
```

## 7. Production Lineage

DWH-computed analytics from CopyFromLake price feed logs. No upstream production wiki.

## 8. Known Issues & Notes

- **STALE since 2025-01-11** — `CopyFromLake.PriceLog_History_CurrencyPrice` feed disruption.
- **`Date` is datetime** (not `date`) — include time truncation in GROUP BY if aggregating by day.
- **Latency in seconds** (not milliseconds) — unlike EMS-based latency tables which use milliseconds.

---
*Quality score: 8.0/10 | Documented: 2026-03-21 | Writer: SP_OccurredAtProvider_Latency*
