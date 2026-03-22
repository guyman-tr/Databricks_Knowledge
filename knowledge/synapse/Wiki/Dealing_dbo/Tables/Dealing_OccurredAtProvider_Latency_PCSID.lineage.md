---
object: Dealing_dbo.Dealing_OccurredAtProvider_Latency_PCSID
lineage_type: dwh_computed_analytics
documented: 2026-03-21
---

# Lineage: Dealing_OccurredAtProvider_Latency_PCSID

## ETL Chain

```
CopyFromLake.PriceLog_History_CurrencyPrice
  → SP_OccurredAtProvider_Latency (@Date)
    Filter: |DATEDIFF(ss, OccurredOnProvider, ReceivedOnPriceServer)| ≥ 3
    Filter: CountInstances > 1
    GROUP BY PCSID only (LP and instrument detail dropped)
    → Dealing_dbo.Dealing_OccurredAtProvider_Latency_PCSID
```

## Generic Pipeline Mapping

No entry — DWH-computed analytics from CopyFromLake price feed logs.

## Column Lineage

| Column | Source |
|--------|--------|
| Date | CopyFromLake.PriceLog_History_CurrencyPrice.Date |
| PCSID | CopyFromLake.PriceLog_History_CurrencyPrice |
| CountInstances | COUNT(*) aggregated across all LPs and instruments for this PCSID/date |
| MaxLatency | MAX(DATEDIFF(ss, OccurredOnProvider, ReceivedOnPriceServer)) |
| AVGLatency | AVG(DATEDIFF(ss, OccurredOnProvider, ReceivedOnPriceServer)) |
| UpdateDate | GETDATE() at SP execution time |

## Refresh

- **OpsDB tracked**: No
- **Pipeline status**: ⚠️ STALE since 2025-01-11 — CopyFromLake.PriceLog_History_CurrencyPrice feed stopped
