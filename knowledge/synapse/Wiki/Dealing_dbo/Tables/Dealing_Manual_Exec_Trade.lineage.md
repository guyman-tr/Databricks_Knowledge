---
object: Dealing_Manual_Exec_Trade
lineage_type: Staging → DWH Trade Log
production_source: Dealing_staging.External_Etoro_Hedge_ManualOrderExecutionLog
---

# Dealing_Manual_Exec_Trade — Lineage Map

## Data Flow

```
Dealing_staging.External_Etoro_Hedge_ManualOrderExecutionLog (RequestTypeID IN (0,3))
                │ → #Manual (OrderID, Sender, RequestTypeID, InstrumentID, IsBuy, AmountInUnits)
                │
Dealing_staging.Etoro_Hedge_ExecutionLog (ExecutionTime ∈ [Date, Date+1))
                │ → #Executed (ParentOrderID, InstrumentID, Units, ExecutionRate, LP, HedgeServer, Success)
                │
                ▼
          #Final_Manual = LEFT JOIN on ManualOrder.OrderID = Executed.ParentOrderID
            FILTER: Success=1 OR RequestTypeID=3
            ISNULL(Executed.InstrumentID, Manual.InstrumentID) → resolved InstrumentID
            Units signed: (IsBuy=1 → +1, else -1) × ISNULL(e.Units, m.AmountInUnits)
                │
DWH_dbo.Dim_Instrument ──► InstrumentDisplayName
Dealing_staging.etoro_Trade_LiquidityAccounts ──► LiquidityAccountName
                │
                ▼
        Dealing_Manual_Exec_Trade (Date, OrderID, InstrumentID, IsBuy, Units, Sender, ...)
```

## Refresh Schedule
Daily — SP_Manual_Exec_Trade, OpsDB Priority 0, ProcessType 1 (SQL). Active.
