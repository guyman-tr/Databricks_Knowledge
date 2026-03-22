---
object: Dealing_Manual_Exec_Trade_Summary
lineage_type: Multi-source DWH Summary
production_source: Manual orders + ExecutionLog + BI_DB_PositionPnL + Netting tables
---

# Dealing_Manual_Exec_Trade_Summary — Lineage Map

## Data Flow

```
#Final_Manual (manual trades) ──────────────────────────────────────────────┐
                                                                             │
BI_DB_dbo.BI_DB_PositionPnL (DateID=@DateID) ──► #Clients (NOP, Units)     │
                                                          │                  │
Dealing_staging.Etoro_Hedge_ExecutionLog ──────► #Total_Etoro (volume)      │
                                                          │                  │
etoro_Hedge_Netting + etoro_History_Netting_History ──► #NOP_Start          │
  (last netting state before start-of-day × EOD price) ──► #NOP_End        │
                                                          │                  │
BI_DB_DailyZero_TreeSize_NEW                              │                  │
+ Dealing_DailyZeroPnL_Stocks ──────────────────► #Zero  │                  │
                                                          │                  │
                                              ◄───────────┘◄─────────────────┘
                                              GROUP BY InstrumentID, HedgeServerID
                                                          │
                                                          ▼
                                   Dealing_Manual_Exec_Trade_Summary
```

## Refresh Schedule
Daily — SP_Manual_Exec_Trade, OpsDB Priority 0, ProcessType 1 (SQL). Active.
