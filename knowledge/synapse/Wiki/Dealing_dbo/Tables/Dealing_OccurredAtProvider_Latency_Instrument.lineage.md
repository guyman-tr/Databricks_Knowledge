---
object: Dealing_dbo.Dealing_OccurredAtProvider_Latency_Instrument
lineage_type: dwh_computed_analytics
documented: 2026-03-21
---

# Lineage: Dealing_OccurredAtProvider_Latency_Instrument

## ETL Chain

```
CopyFromLake.PriceLog_History_CurrencyPrice
  (OccurredOnProvider, ReceivedOnPriceServer, InstrumentID,
   LiquidityAccountID, PCSID, ...)
  → SP_OccurredAtProvider_Latency (@Date)
    Filter: |DATEDIFF(ss, OccurredOnProvider, ReceivedOnPriceServer)| ≥ 3
    Filter: CountInstances > 1
    GROUP BY Instrument × LiquidityAccountID × PCSID
    → Dealing_dbo.Dealing_OccurredAtProvider_Latency_Instrument
```

## Generic Pipeline Mapping

No entry — DWH-computed analytics from CopyFromLake price feed logs.

## Column Lineage

| Column | Source |
|--------|--------|
| Date | CopyFromLake.PriceLog_History_CurrencyPrice.Date |
| InstrumentID | CopyFromLake.PriceLog_History_CurrencyPrice |
| InstrumentDisplayName | CopyFromLake.PriceLog_History_CurrencyPrice |
| InstrumentType | CopyFromLake.PriceLog_History_CurrencyPrice |
| Symbol | CopyFromLake.PriceLog_History_CurrencyPrice |
| Exchange | CopyFromLake.PriceLog_History_CurrencyPrice |
| LiquidityAccountID | CopyFromLake.PriceLog_History_CurrencyPrice |
| LiquidityAccountName | CopyFromLake.PriceLog_History_CurrencyPrice |
| PCSID | CopyFromLake.PriceLog_History_CurrencyPrice |
| CountInstances | COUNT(*) WHERE latency ≥ 3s |
| MaxLatency | MAX(DATEDIFF(ss, OccurredOnProvider, ReceivedOnPriceServer)) |
| AVGLatency | AVG(DATEDIFF(ss, OccurredOnProvider, ReceivedOnPriceServer)) |
| UpdateDate | GETDATE() at SP execution time |

## Refresh

- **OpsDB tracked**: No
- **Pipeline status**: ⚠️ STALE since 2025-01-11 — CopyFromLake.PriceLog_History_CurrencyPrice feed stopped
