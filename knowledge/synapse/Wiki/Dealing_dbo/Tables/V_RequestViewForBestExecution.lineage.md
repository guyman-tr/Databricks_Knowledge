# Lineage Map — Dealing_dbo.V_RequestViewForBestExecution

**Generated**: 2026-03-21
**Type**: View — UNION of two execution log sources
**Pattern**: UNION of RequestExecutionLog (last 24h) + EMSOrders (all non-auto)

## ETL Chain

```
Dealing_staging.eToroLogs_Real_Hedge_RequestExecutionLog (REL)
  LEFT JOIN Dealing_staging.eToroLogs_Real_Hedge_RequestLimitExecutionLog (RLEL)
    ON RequestID + RequestTime >= GETDATE()-1
  → Leg 1: RequestID, RequestTime, ClientViewRate, IsManual, TriggerRate,
            TriggerPriceRateID, MarketTriggerRateTime, MainTriggerRateTime

UNION

Dealing_staging.eToroLogs_Real_Hedge_EMSOrders (EO)
  JOIN CopyFromLake.PriceLog_History_CurrencyPrice (HCP)
    ON TriggerPriceRateID = PriceRateID
  WHERE HedgeExecutionModeID != 3
  → Leg 2: ExecutionID→RequestID, RequestTime, ClientViewRate,
            FlowType→IsManual (1=auto→0, else→1), TriggerRate,
            TriggerPriceRateID, ReceivedOnPriceServer→MarketTriggerRateTime,
            Occurred→MainTriggerRateTime

        └── Dealing_dbo.V_RequestViewForBestExecution
```

## Column Lineage

| View Column | Leg 1 Source | Leg 2 Source | Transform |
|-------------|-------------|--------------|-----------|
| `RequestID` | REL.RequestID | EO.ExecutionID | Direct / renamed |
| `RequestTime` | REL.RequestTime | EO.RequestTime | Direct |
| `ClientViewRate` | REL.ClientViewRate | EO.ClientViewRate | Direct |
| `IsManual` | REL.IsManual | EO.FlowType | FlowType=1 → 0 (auto), else 1 (manual) |
| `TriggerRate` | REL.TriggerRate | EO.TriggerRate | Direct |
| `TriggerPriceRateID` | REL.TriggerPriceRateID | EO.TriggerPriceRateID | Direct |
| `MarketTriggerRateTime` | REL.MarketTriggerRateTime | EO.ReceivedOnPriceServer | Direct / renamed |
| `MainTriggerRateTime` | REL.MainTriggerRateTime | EO.Occurred | Direct / renamed |

## Governance

- **No ETL / No writer**: This is a view — data is always read live from staging tables
- **Leg 1 time filter**: RequestTime >= GETDATE()-1 (last 24 hours only from RequestExecutionLog)
- **Leg 2 filter**: HedgeExecutionModeID != 3 (excludes fully-automated EMS executions)
- **Near-real-time**: Sources are staging tables (eToroLogs) — updated in near-real-time
- **No OpsDB entry**: Views are not tracked in Service Broker orchestration
