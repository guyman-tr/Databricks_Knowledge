---
object: Dealing_Manual_Exec
lineage_type: Staging → DWH Summary
production_source: Dealing_staging.Etoro_Hedge_ExecutionLog + External_Etoro_Hedge_ManualOrderExecutionLog
---

# Dealing_Manual_Exec — Lineage Map

## Data Flow

```
Dealing_staging.External_Etoro_Hedge_ManualOrderExecutionLog (RequestTypeID=0)
                │ → #Manual (OrderID, Type='Manual')
                │
Dealing_staging.Etoro_Hedge_ExecutionLog (all executions)
                │ → #Executed
                │
DWH_dbo.Fact_CurrencyPriceWithSplit + Dim_Instrument
                │ → #Rates (FX conversion)
                │
Dealing_staging.PriceLog_History_CurrencyPrice
                │ → #Prices (fallback for rejected orders)
                │
                ▼
          #Executed_FX (SUM Volume in USD, grouped by HedgeServer×LP×Type×IsSuccess)
                │
Dealing_staging.etoro_Hedge_HBCExecutionLog ──► #HBC_PI (PI block trades)
                │
                ▼
        Dealing_Manual_Exec (Date, Type, HedgeServer, LP, Volume, Count_Trades, IsSuccess)
```

## Production Source
Hedge execution logs from eToro's LP hedging system (EMS / Hedge Server).

## Refresh Schedule
Daily — SP_Manual_Exec, OpsDB Priority 0, ProcessType 1 (SQL). STALE since 2024-11-02.
